# Bambu 3MF Viewer — Build Log

A complete PWA for viewing Bambu Lab 3MF print files, built from scratch across two coding sessions. What started as reverse-engineering MakerWorld's viewer became an ~1,850-line single-file application with a custom 3MF parser, Three.js renderer, multi-plate layout engine, physics-aware lay-flat optimizer, full Bambu Studio project integration, and a one-click "Open in Bambu Studio" button.

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

## Phase 6 — Bambu Studio Project Integration

Session two focused on making the viewer understand Bambu Studio's full project structure, not just the geometry.

### Part Names & Objects Panel

Bambu stores object and part names as `<metadata key="name" value="..."/>` inside `<object>` and `<part>` elements in `model_settings.config`. We extract these into `objectNameMap` and `partNameMap`, propagate them to Three.js meshes via `mesh.name`, and display them in the Objects panel with visibility toggles and click-to-focus.

### Plate Assignments from Bambu Studio

The initial approach used the `partnumber` attribute on `<item>` elements for plate grouping — but every item in Bambu files has `partnumber=None`. The actual plate system lives in `model_settings.config`:

```xml
<plate>
  <metadata key="plater_id" value="1"/>
  <metadata key="plater_name" value="Case + spool"/>
  <model_instance>
    <metadata key="object_id" value="3"/>
  </model_instance>
</plate>
```

We parse `<plate>` → `<model_instance>` to build `objectPlateMap` (objectId → platerId) and `plateNameMap` (platerId → name like "Case + spool", "Inserts + latches", "Gasket"). The item resolution code now checks `objectPlateMap` first, falling back to `partnumber` for non-Bambu files.

A critical bug surfaced here: `autoLayoutPlates()` was destroying the Bambu plate assignments by pooling all meshes and re-binning them across new auto-generated plates. The fix detects named Bambu plates and performs shelf-packing *within* each plate separately instead of across all plates.

### Filament Materials from 3MF

`project_settings.config` contains per-extruder slot arrays: `filament_type` (TPU, PLA, PETG, etc.), `filament_density`, `filament_settings_id`, and `filament_vendor`. These are parsed into a `filamentMaterials` array and propagated to each mesh via `mesh.userData.filament = { type, density, name, vendor }` during `addMeshToPlate()`.

This data overrides the manual material selector — when filament data is present, the material dropdown hides and the weight calculator uses per-mesh filament density instead of the global value. The summary shows a per-filament-type weight breakdown (e.g., "TPU: 12.3g", "PLA: 8.1g", "PETG: 5.4g").

### Open in Bambu Studio

Getting a browser-based viewer to launch a desktop app went through three iterations:

1. **Download button** — just downloaded the file, didn't open anything.
2. **`bambustudioopen://` protocol** — Safari rejected it as invalid.
3. **Service worker file sharing** — the winning approach. The service worker (v4) stores the loaded 3MF in a `SHARE_CACHE`, serves it at `/shared/filename.3mf` via a fetch handler, and the button navigates to `bambustudio://open?file=<URL>`. This is the same mechanism MakerWorld uses. PR #6856 on BambuStudio lifted the domain restriction that previously limited this to makerworld.com.

The button only appears for Bambu files (detected via presence of filament data).

### Progress Bar

A loading progress bar tracks each parsing stage (10%–95%). The initial implementation called `showLoading(msg, pct)` between synchronous steps, but the browser never repainted because the entire `parseBambu3MF` function ran in a single event loop tick despite being `async`. The fix: make the `progress()` helper `async` with `await new Promise(r => setTimeout(r, 0))` after each DOM update, yielding to the browser's rendering thread.

## Architecture Summary

The final app is a single HTML file (~1,850 lines) containing:

| Component | Description |
|-----------|-------------|
| **3MF Parser** | Custom XML/ZIP parser handling Bambu extensions |
| **STL Parser** | Binary + ASCII STL support for imported models |
| **Bambu Project Reader** | Parses `model_settings.config` + `project_settings.config` for plates, parts, filaments |
| **Three.js Scene** | Lit environment with shadows, orbit controls |
| **Embedded Buildplate** | Base64-encoded X1C bed geometry |
| **Raycaster** | Click-to-select with highlight materials |
| **Material DB** | 14 filament types with densities, overridden by per-mesh Bambu filament data |
| **Weight Calculator** | Signed tetrahedron volume + infill/wall model, per-filament breakdown |
| **Bin Packer** | Shelf-based multi-plate auto-layout, preserves Bambu plate groupings |
| **Lay-Flat Optimizer** | Physics-aware orientation scoring |
| **Bambu Studio Launcher** | Service worker file sharing + `bambustudio://open` protocol |
| **Service Worker** | Offline cache-first PWA + shared file serving for Bambu Studio |

Supporting files: `sw.js` (service worker v4), `manifest.json` (PWA manifest with file handlers), `base.stl` (source buildplate mesh), and two PWA icons in amber/zinc theme.

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

### Bug: `partnumber` is always `None` in Bambu 3MF files
**Symptom:** All objects ended up on Plate 0 despite having three distinct plates in Bambu Studio.
**Root cause:** The parser was using the `partnumber` attribute on `<item>` elements, but Bambu sets this to `None` for all items. Plate assignments are stored separately in `model_settings.config` under `<plate>` → `<model_instance>` elements.
**Fix:** Parse `model_settings.config` to build `objectPlateMap` (objectId → platerId) and use it as the primary lookup, falling back to `partnumber` only for non-Bambu files.

### Bug: `autoLayoutPlates()` destroying Bambu plate groupings
**Symptom:** After parsing three named plates correctly, the layout engine merged everything into two auto-generated plates with generic names.
**Root cause:** `autoLayoutPlates()` pooled all meshes from all plates into a single array, then re-binned them across new plates using shelf packing. This destroyed the original Bambu plate assignments and names.
**Fix:** Added detection of named Bambu plates (`hasBambuPlates`). When present, the layout runs *within* each existing plate separately rather than pooling across plates. Only falls back to cross-plate re-binning for generic files.

### Bug: Bambu Studio button downloads file instead of opening app
**Symptom:** Clicking "Open in Bambu Studio" just downloaded the `.3mf` file.
**Root cause:** First implementation created a blob download link, which is a browser download action, not a protocol handler invocation.
**Fix:** Replaced with `bambustudio://open?file=<URL>` protocol. Required a service worker to serve the file at a stable URL that Bambu Studio can fetch.

### Bug: Safari rejects `bambustudio://open` URL as invalid
**Symptom:** User got "Safari kan de pagina niet openen omdat het adres ongeldig is" (Safari can't open the page because the address is invalid).
**Root cause:** The `file=` parameter was pointing to a blob URL, which Bambu Studio can't fetch. The protocol handler needs a real HTTP(S) URL that the desktop app can download from.
**Fix:** Service worker v4 stores the file in a `SHARE_CACHE` and serves it at `/shared/filename.3mf`. The button passes this origin-relative URL to the protocol handler, giving Bambu Studio a fetchable endpoint.

### Bug: Progress bar shows "reading" for entire load time
**Symptom:** Despite eight `progress()` calls at different stages, the bar stayed at its initial state throughout loading.
**Root cause:** `parseBambu3MF` is `async` but all its work is synchronous within a single event loop tick. The `showLoading()` calls update DOM properties (`textContent`, `style.width`) but the browser batches these and only repaints after the function returns — by which time loading is complete.
**Fix:** Made `progress()` async with `await new Promise(r => setTimeout(r, 0))` after each DOM update. The `setTimeout(0)` yields to the browser's event loop, allowing a repaint between each parsing stage.

## What Made It Work

A few principles that kept this session productive:

- **Embed, don't fetch.** When `fetch()` failed for local files, embedding the geometry as base64 solved it permanently with zero runtime dependencies.
- **Measure, don't estimate.** The lay-flat optimizer only worked correctly once it started measuring actual bed contact area instead of using face cluster area as a proxy.
- **Scale penalties with geometry.** Dimensionless ratios with fixed weights get drowned out by dimension-ful metrics. The CoG penalty only became effective when multiplied by `totalH` to produce values in the same unit-space as bed contact area.
- **Test both directions.** The 180° flip bug was a simple oversight — always test the complement of any orientation candidate.
- **Read the proprietary config, not the standard spec.** Bambu's plate system, filament data, and part names all live in non-standard config files (`model_settings.config`, `project_settings.config`) rather than in standard 3MF attributes. The format is documented nowhere — you have to unzip and read the XML.
- **Don't destroy what you parsed.** The auto-layout engine was correct in isolation but destructive in context — it re-binned plates that were already correctly assigned. Feature interactions like this are easy to miss.
- **Yield to the renderer.** An `async` function isn't actually asynchronous if all its work is synchronous. DOM updates are batched until the event loop is free. A single `setTimeout(0)` after each progress call is all it takes to let the browser repaint.
