# Bambu Viewer — Changelog

## `303723e` — 2026-02-14 — Initial Release
- Single-file PWA (`index.html`) with Three.js r170 for viewing Bambu Lab `.3mf` files
- Custom Bambu 3MF parser: handles `displaycolor`, `partnumber` plate assignments, and nested `<component>` assemblies with transform chains
- fflate ZIP decompression, embedded base64 build plate geometry (860 triangles, no fetch required)
- Service worker with cache-first strategy, PWA manifest with `.3mf` file handler and share target
- Shelf-based 2D bin-packing auto-layout across 256×256mm build plates
- Lay-flat algorithm v1: face normal clustering → rotate largest cluster face downward
- Dark zinc/amber UI with Tailwind CSS

## `4536557` — 2026-02-14 — Objects Panel & Weight Calculator
- Replaced simple Colors panel with full Objects panel (right sidebar): per-object color pickers, visibility, click-to-focus
- Material density database: 14 filament types (PLA, PETG, ABS, ASA, TPU, nylons, CF variants, PC, PVA, HIPS)
- Weight calculator using signed tetrahedron volume computation
- Sliders for infill %, wall count, nozzle diameter, top/bottom layers, layer height
- Click-to-select via raycasting on canvas
- Color input swatch and range slider styling

## `9d8e8a5` — 2026-02-14 — Lay-Flat Algorithm v3
- Complete rewrite of `evaluateOrientation()`: now measures actual bed contact area instead of using cluster face area as proxy
- Tests both orientations per cluster (normal→down AND normal→up) plus 6 principal axes
- Quaternion deduplication to avoid redundant evaluations
- 16×16 grid column analysis for support/floating ratio
- Center of gravity height and lateral offset penalties scaled by object dimensions
- Aspect ratio penalty for tall-and-narrow instability

## `c2f0f69` — 2026-02-14 — Build Log
- Added `BUILD_LOG.md` documenting the development process, architecture decisions, and lay-flat optimizer iterations

## `e10b0ff` — 2026-02-14 — (Empty commit)
- No file changes

## `6a39b93` — 2026-02-14 — Bambu Color System & Custom Parser Priority
- Switched parser order: custom Bambu parser first, ThreeMFLoader as fallback (stock loader drops Bambu-specific data)
- Full Bambu extruder-based color system: reads `project_settings.config` for filament colors/materials per extruder slot
- Reads `model_settings.config` for per-object extruder assignments
- `parseColor()` helper: handles Bambu 8-char hex with alpha (#RRGGBBAA), strips alpha for Three.js
- Per-object filament material data (type, density, name, vendor) from project settings
- `hasFilamentData` flag for detecting when 3MF provides filament info

## `b2dcf51` — 2026-02-15 — Progress Bar & Bambu Studio Button
- Added progress bar to loading overlay (amber fill, animated width transitions)
- "Open in Bambu Studio" button via `bambustudio://` protocol
- Progress callbacks throughout `parseBambu3MF()`: decompressing, reading config, building mesh index, etc.
- Stored loaded file reference for Bambu Studio handoff

## `5c66419` — 2026-02-15 — README
- Added `README.md` with feature list, getting started guide, project structure, and tech stack

## `5b28a08` — 2026-02-15 — Build Log Update
- Updated `BUILD_LOG.md` with additional development notes

## `ae4c873` — 2026-02-15 — Multi-Plate "All Plates" View
- "All Plates" mode: grid layout showing all plates simultaneously with proper spacing
- Saved/restored plate positions when switching between all-plates and single-plate views
- `updateObjectsPanelAll()`: combined objects panel with plate headers
- `updateModelInfoAll()`: aggregate stats across all plates
- Camera fitting to entire scene in all-plates mode

## `38e89b8` — 2026-02-15 — Cloned Beds in All-Plates View
- Each plate in all-plates view now gets its own cloned bed model
- Beds positioned at each plate's grid location
- Clones properly cleaned up when returning to single-plate view
- Increased plate gap from 40mm to 60mm for better spacing

## `04dcc1d` — 2026-02-15 — Async Processing & FPS Counter
- FPS counter display (bottom-left)
- `processModel()` made async with yielding between heavy steps
- XML parsing optimization: `getElementsByTagName` instead of `querySelectorAll` for large meshes
- Yield after every 2 meshes during parsing to avoid blocking UI
- Progress percentage updates during mesh index building
- Loading overlay made fully opaque (`bg-black` instead of `bg-black/90`)

## `4f4effd` — 2026-02-15 — Loading Overlay Fix
- Changed loading overlay background from `bg-black/90` to `bg-black` (fully opaque during load)

## `2808e0f` — 2026-02-15 — 3MF Parser Optimization
- Pre-parse all model XML documents once (reuse `DOMParser` results across steps)
- Pre-allocated `Float32Array` and `Uint32Array` for vertex/triangle data (eliminated push loops)
- Direct typed array usage in `createGeometryFromMesh()` — no copy when already typed
- Deferred `computeVertexNormals()` to `finalizeGeometry()` after lay-flat
- Yielding before heavy sync decompression

## `3ba90c2` — 2026-02-15 — PBR Rendering Pipeline
- Post-processing pipeline: EffectComposer with RenderPass → SSAO → Bloom → Vignette → SMAA → OutputPass
- Procedural FDM layer-line textures: canvas-generated normal map and roughness map simulating real 3D-printed surfaces
- `MeshPhysicalMaterial` with clearcoat, sheen, IOR (1.46 for PLA), specular controls
- Custom PMREM environment: 5-panel studio lighting (key, rim, fill, bounce, accent) rendered into a cube map
- 4K shadow maps on directional key light
- Layer height dropdown (0.08–0.32mm) affecting FDM texture scale
- SSAO toggle button in toolbar

## `f3552ff` — 2026-02-15 — 3-Tier Graphics Quality
- Three quality tiers: Ultra / High / Performance
- Ultra: full PBR (clearcoat + sheen), SSAO, Bloom, Vignette, SMAA, 4K shadows, DPR 2
- High: PBR textures (no clearcoat/sheen), Bloom + Vignette + SMAA, 2K shadows, DPR 2
- Performance: `MeshStandardMaterial`, no post-processing, 1K shadows, DPR 1, built-in AA
- Quality toggle button with label in toolbar
- Stored references to all post-processing passes for runtime enable/disable

## `6c9aa0e` — 2026-02-15 — Auto Graphics Quality
- Automatic quality scaling based on FPS: downgrade if <30 FPS for 3 seconds, upgrade if ≥59 FPS for 3 seconds
- FPS counter now shows quality tier indicator (U/H/P)
- Manual quality selection disables auto-downgrade (re-enables when cycling back to Ultra)
- Streak-based detection to avoid quality flip-flopping
- Renderer anti-aliasing enabled (`antialias: true`)

## `8f1561e` — 2026-02-15 — UI Cleanup & New Features
- Removed "Open in Bambu Studio" button and associated `loadedFile` state
- Removed separate model-info panel element
- Added isometric camera view button in toolbar
- Added "Pick Face to Flatten" button (face-pick lay-flat mode)
- Added light controls popup: azimuth, elevation, and intensity sliders
- Added light toggle button in toolbar
- Flipped camera/environment Z-axis orientation (environment panels and lights repositioned)
- Initial camera set to top-down (0, 400, 0) instead of isometric
- Added OBJLoader import
- Multi-format file support in drop zone: 3MF, STL, OBJ, STEP

## `b9d2eba` — 2026-02-15 — STL/OBJ/STEP Loaders & Face-Pick Lay-Flat
- STL loader: `STLLoader` with auto-coloring and FDM material
- OBJ loader: `OBJLoader` with per-mesh FDM material and naming
- STEP loader: OpenCascade (`occt-import-js`) loaded via script tag, typed array optimization
- Face-pick lay-flat mode: click a face to rotate that face onto the bed
- Face highlight on hover during pick mode
- Light controls: directional light position controlled by azimuth/elevation/intensity sliders
- Procedural PEI build plate texture: stipple grain + directional brush marks (normal + roughness maps)
- Build plate UV generation for texture mapping

## `f48b0bb` — 2026-02-15 — STEP Loader Fix
- Fixed STEP loader: `occt-import-js` is not an ES module — switched from `import()` to script tag loading with `window.occtimportjs`
- Typed array checks: use existing `Float32Array`/`Uint32Array` directly when already the right type
- Avoids unnecessary array copies in geometry creation

## `08a3661` — 2026-02-15 — DXF Support
- Full DXF 2D → 3D extrusion pipeline with user-selectable thickness and wall width
- DXF thickness popup: height and wall width inputs
- Entity support: LINE, POLYLINE, LWPOLYLINE, CIRCLE, ARC, ELLIPSE, SPLINE, 3DFACE
- Raw DXF pre-scan for reliable closed polyline detection (bypasses dxf-parser flag issues)
- Skip reference/construction layers (CENTER, BASE_CIRCLE, CONSTRUCTION, REFERENCE, HIDDEN)
- Bore hole detection: small circles fully contained in larger shapes become holes
- `manualExtrude()`: custom triangulation via `THREE.ShapeUtils.triangulateShape()` for complex concave polygons (involute gears)
- Separate vertex groups with explicit normals for sharp edges (bottom, top, side walls)
- 3-phase pipeline: shape creation → extrusion → manual buffer merge
- `yieldToUI()` helper using `requestAnimationFrame` + `setTimeout` for smooth progress updates
- `strokeToShape()`: converts open paths into thin closed shapes for extrusion
- Added `test_gear.dxf` test file
- File input now accepts `.dxf`

## `457ddb9` — 2026-02-15 — DXF Performance & Quality Fixes
- DXF extrusion performance: time-based yielding, pre-computed rotation matrix, reduced curve segments (64→48)
- Manual buffer merge: pre-allocated typed arrays replacing `BufferGeometryUtils.mergeGeometries()`
- Sub-step progress: building shapes, detecting holes, extruding (per-entity count), merging, finalizing
- Phase 1 entity progress with per-entity yield
- Improved closed polyline detection with relative proximity threshold
