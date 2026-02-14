# Bambu 3MF Viewer — Build Log

A complete PWA for viewing Bambu Lab 3MF print files, built from scratch in a single coding session. What started as reverse-engineering MakerWorld's viewer became a 1,453-line single-file application with a custom 3MF parser, Three.js renderer, multi-plate layout engine, and physics-aware lay-flat optimizer.

---

## The Starting Point

The goal: build an offline-capable 3D print file viewer for Bambu Lab's `.3mf` format — a ZIP archive containing XML mesh definitions, affine transform matrices, multi-plate assignments, and per-object display colors.

We began by studying MakerWorld's web viewer to understand the format, then immediately went our own direction.

## Phase 1 — Core Viewer

The foundation was a **Three.js r170** scene with ES module imports (OrbitControls, ThreeMFLoader) wrapped in a **Tailwind CSS** UI using a zinc/amber color palette with Inter and JetBrains Mono fonts.

Key decisions early on:

- **Single-file architecture.** Everything lives in `index.html` — no build step, no bundler, no framework. Just a `<script type="module">` and Tailwind CDN.
- **Custom 3MF parser** instead of relying on Three's built-in ThreeMFLoader. Bambu's format has proprietary extensions (`partnumber` for plate assignment, `displaycolor` on `<base>` elements, nested `<component>` assemblies with their own transforms) that the stock loader doesn't handle.
- **fflate** for ZIP decompression — lightweight and fast.
- **PWA from day one.** Service worker with cache-first strategy, manifest with file handlers for `.3mf`, share target support.

The parser handles the full Bambu transform chain: `<item transform="...">` affine matrices composed with `<component>` assembly transforms, all decoded from the 12-element row-major format into Three.js Matrix4 objects.

## Phase 2 — Interaction & Materials

Next came the interactive layer:

- **Click-to-select** via raycasting on the canvas. Click any object to highlight it and see its properties.
- **Per-object color pickers** in the Objects panel, replacing an earlier global color palette.
- **Material database** with 14 filament types (PLA, PETG, ABS, ASA, TPU, nylons, carbon fiber variants, PC, PVA, HIPS) each with correct density values.
- **Weight calculator** using signed tetrahedron volume computation, with sliders for infill percentage, wall count, nozzle diameter, top/bottom layers, and layer height. The formula accounts for shell volume (perimeters + top/bottom) vs. sparse infill interior.

## Phase 3 — Auto-Layout Engine

The layout system arranges objects across 256×256mm build plates:

- **Shelf-based 2D bin-packing** — objects sorted by height descending, placed left-to-right in rows (shelves), overflow to next plate.
- **Multi-plate support** — plates are created on demand, with a tab bar at the bottom to switch between them.
- Respects a 5mm bed padding margin.

## Phase 4 — The Buildplate Saga

Rendering the actual Bambu X1C build plate shape (not just a rectangle) turned into a multi-step journey:

1. **First attempt:** `STLLoader.load('./base.stl')` — failed silently because `fetch()` doesn't work on the `file://` protocol.
2. **Second attempt:** Added fallback boxes, URL resolution with `new URL()`, progress logging — still showed a generic black rectangle.
3. **Final solution:** Extracted all 860 triangles (7,740 vertex floats) from the STL binary, base64-encoded them (~41KB), and embedded them directly in the HTML. A `decodeBedGeometry()` function decodes `atob()` → `Float32Array` → `BufferGeometry` synchronously. No network request needed, works everywhere.

Then came visual tuning — the bed went through several color iterations (`0x18181b` → `0x2a2a2a` → `0x4a4a4a`) to get a convincing dark grey "SuperTack" plate look with near-zero metalness and high roughness. The scene background was adjusted to near-black (`0x111111`) to match the loading screen overlay.

## Phase 5 — Lay-Flat Optimizer (Three Rewrites)

This was the most technically challenging feature and went through three major iterations.

### Version 1 — Face Normal Clustering

The initial approach: cluster face normals, pick the largest cluster, rotate that face downward. Simple, but it only tested rotating the cluster normal *down* — never tested flipping 180 degrees. Result: objects that should have been placed on their back surface were placed face-down instead.

### Version 2 — Dual Orientation Testing

Fixed the single-direction bias by testing both orientations per cluster (normal→down AND normal→up), plus 6 principal axis candidates. Added quaternion deduplication to avoid redundant evaluations.

But the scoring was still flawed: it used the *cluster's face area* as the `contactArea` parameter and multiplied it into every scoring term. This meant large face clusters always won regardless of whether the object actually sat flat in that orientation. A 0.8 penalty multiplier on flipped orientations also artificially suppressed correct answers.

### Version 3 — Actual Bed Contact Measurement

Complete rewrite of `evaluateOrientation()`. The function now:

1. **Rotates all vertices** by the candidate quaternion.
2. **Measures actual bed contact area** — sums the area of every triangle whose all three vertices are within tolerance of Y=0 after rotation.
3. **16×16 grid column analysis** — tracks which XZ columns have geometry and which reach the bed, computing support and floating ratios.
4. **Center of gravity analysis** — computes CoG height and lateral offset from the support footprint center.
5. **Aspect ratio penalty** — `totalH² / footprintArea` catches thin objects standing on their edge.

The scoring formula:

```
score = bedContactArea × 10
      + nearBedArea × 2
      + supportRatio × 500
      − floatingRatio × 800
      − totalH × 5
      − cogHeightRatio × totalH × 3      (absolute CoG height)
      − cogLateralPenalty × totalH × 2    (off-center CoG)
      − aspectPenalty × 5                 (tall-and-narrow instability)
```

The key insight was that stability penalties must **scale with object dimensions** to compete with area-based rewards. A normalized 0–1 CoG ratio with a fixed weight of 15 is meaningless next to bed contact areas measured in thousands of mm². Multiplying the ratio by `totalH` converts it back to absolute millimeters, making the penalty proportional to how dangerously tall the orientation actually is.

## Architecture Summary

The final app is a single HTML file (~106KB, ~1,453 lines) containing:

| Component | Description |
|-----------|-------------|
| **3MF Parser** | Custom XML/ZIP parser handling Bambu extensions |
| **STL Parser** | Binary + ASCII STL support for imported models |
| **Three.js Scene** | Lit environment with shadows, orbit controls |
| **Embedded Buildplate** | Base64-encoded X1C bed geometry |
| **Raycaster** | Click-to-select with highlight materials |
| **Material DB** | 14 filament types with densities |
| **Weight Calculator** | Signed tetrahedron volume + infill/wall model |
| **Bin Packer** | Shelf-based multi-plate auto-layout |
| **Lay-Flat Optimizer** | Physics-aware orientation scoring |
| **Service Worker** | Offline cache-first PWA |

Supporting files: `sw.js` (service worker), `manifest.json` (PWA manifest with file handlers), `base.stl` (source buildplate mesh), and two PWA icons in amber/zinc theme.

## Bug Fix Chronicle

Beyond the major rewrites, the session produced a steady stream of bugs found and squashed. Here's every significant one in the order we hit them.

### Bug: 3MF transforms applied in wrong order
**Symptom:** Objects appeared in wrong positions, some overlapping or floating off the plate.
**Root cause:** Bambu 3MF files use nested transforms — an `<item>` can reference a `<component>` which has its own transform, and items have their own `transform` attribute. The initial parser applied only item-level transforms, ignoring component assembly matrices.
**Fix:** Implemented `multiplyTransforms()` to compose the full chain: item transform × component transform. The 12-element row-major affine format is decoded into Three.js Matrix4 with the translation in the correct column.

### Bug: Display colors not parsed from Bambu files
**Symptom:** All objects rendered in the same default color despite having different colors in Bambu Studio.
**Root cause:** Bambu stores per-object colors as `displaycolor` attributes on `<base>` elements inside a custom namespace, not in the standard 3MF color extension. The parser wasn't looking there.
**Fix:** Added parsing of `displaycolor` from `<base>` elements during XML traversal, falling back to a generated palette when absent.

### Bug: STL buildplate invisible (the `fetch()` / `file://` problem)
**Symptom:** Buildplate showed as a generic black square with grid lines — the STL mesh never appeared.
**Root cause:** `STLLoader.load('./base.stl')` internally uses `fetch()`, which throws a CORS/network error on the `file://` protocol. The error was silently swallowed.
**First failed fix:** Added `new URL('./base.stl', location.href)` resolution, error callbacks, a fallback box geometry, and an interval check. Still failed — `fetch()` simply cannot read local files.
**Working fix:** Extracted all vertex data from the binary STL (860 triangles → 7,740 floats), base64-encoded the raw `Float32Array`, and embedded it as a constant string in the HTML. A `decodeBedGeometry()` function decodes it synchronously via `atob()`. Zero network requests, works on any protocol.

### Bug: Buildplate too dark, indistinguishable from background
**Symptom:** User reported "this is still black" after initial color change.
**Root cause:** First color (`0x18181b`) was nearly identical to the scene background (`0x3f3f46`) under the ambient lighting. High metalness (default) made it reflect the dark environment rather than showing its own color.
**Fix:** Iteratively adjusted through three rounds: `0x18181b` → `0x2a2a2a` → `0x4a4a4a`, while dropping metalness to 0.02 and pushing roughness to 0.98 for a matte "SuperTack" textured plate appearance.

### Bug: Scene background too bright after bed color change
**Symptom:** After making the bed lighter grey, the background looked washed out by comparison.
**Fix:** Matched scene background to the loading overlay's `bg-black/90`, settling on `0x111111` (near-black) for strong contrast with the grey bed.

### Bug: Lay-flat only tested one rotation direction
**Symptom:** Object 2 placed face-down when its back surface was completely flat and clearly optimal.
**Root cause:** For each face cluster, the algorithm only computed `makeQuat(normal, down)` — rotating that face's normal to point downward. It never tested the opposite: rotating the normal to point *up*, which puts the *opposite* face on the bed. For an object where the back is flat but the back's normal points away from the bed, this meant the correct orientation was never even considered.
**Fix:** Added `makeQuat(normal, up)` for every cluster, doubling the candidate pool. Also added 6 principal axis orientations as fallback candidates and quaternion deduplication to keep evaluation count reasonable.

### Bug: Lay-flat scoring biased by cluster area, not actual contact
**Symptom:** Even after the dual-direction fix, object 2 (18.1g) was still placed face-down instead of on its large flat back surface.
**Root cause:** `evaluateOrientation()` received the cluster's total face area as a `contactArea` parameter and used it as a *multiplier* in every scoring term. This meant the score was dominated by which cluster had the most face area in the original mesh — not by how much area actually touched the bed after rotation. A large face cluster would always win even if, in the rotated position, only a tiny edge touched the bed.
**Additional factor:** A hardcoded `0.8` penalty multiplier on "flipped" orientations (normal→up) artificially reduced scores for correct orientations by 20%.
**Fix:** Complete rewrite. The function now takes the raw `faces` array, rotates all vertices, and computes *actual* bed contact area by iterating every triangle and summing areas where all three vertices are within tolerance of Y=0. The cluster area parameter was removed entirely. The 0.8 flip penalty was removed. All clusters are now evaluated (not just top 12).

### Bug: Comment parentheses caused syntax warnings
**Symptom:** Linter flagged unbalanced parentheses in the lay-flat function.
**Root cause:** Inline comments used `a)` and `b)` notation, which the paren-counter interpreted as unmatched closing parens.
**Fix:** Rewrote comments to avoid bare parentheses.

### Bug: CoG penalty too weak to influence thin objects
**Symptom:** A thin, light object (object 6) was placed on its side — tall and unstable — despite having a large flat face that should obviously be the bed contact surface.
**Root cause:** The center-of-gravity penalty used normalized ratios (0–1) with small fixed weights (15 for height, 12 for lateral offset), producing a maximum penalty of ~27 points. Meanwhile, `bedContactArea × 10` produces values in the thousands for any reasonable face. The CoG penalty was statistically irrelevant.
**Fix:** Made all stability penalties dimension-aware. `cogHeightRatio` is now multiplied by `totalH` to produce absolute millimeters, weighted at 3.0. Lateral offset is similarly scaled by `totalH × 2.0`. Added a new `aspectPenalty = totalH² / footprintArea × 5.0` term that specifically catches the "thin object on its side" degenerate case — a 50mm-tall object on a 90mm² edge footprint scores 139 points of penalty vs. near-zero when flat. Also bumped the base height penalty from `2.0` to `5.0`.

## What Made It Work

A few principles that kept this session productive:

- **Embed, don't fetch.** When `fetch()` failed for local files, embedding the geometry as base64 solved it permanently with zero runtime dependencies.
- **Measure, don't estimate.** The lay-flat optimizer only worked correctly once it started measuring actual bed contact area instead of using face cluster area as a proxy.
- **Scale penalties with geometry.** Dimensionless ratios with fixed weights get drowned out by dimension-ful metrics. The CoG penalty only became effective when multiplied by `totalH` to produce values in the same unit-space as bed contact area.
- **Test both directions.** The 180° flip bug was a simple oversight — always test the complement of any orientation candidate.
