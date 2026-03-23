#set document(title: "Bambu 3MF Viewer — User Manual", author: "Black Sphere Industries")
#set page(paper: "a4", margin: (top: 2.5cm, bottom: 2.5cm, left: 2cm, right: 2cm))
#set text(font: "New Computer Modern", size: 11pt)
#set heading(numbering: "1.1")

// Title page
#align(center)[
  #v(3cm)
  #text(size: 28pt, weight: "bold")[Bambu 3MF Viewer]
  #v(0.5cm)
  #text(size: 16pt, fill: rgb("#666"))[User Manual]
  #v(1cm)
  #text(size: 12pt)[Black Sphere Industries]
  #v(0.3cm)
  #text(size: 11pt, fill: rgb("#999"))[Version 1.0 --- March 2026]
  #v(3cm)
]
#pagebreak()

// Table of contents
#outline(title: "Table of Contents", indent: 1.5em)
#pagebreak()

= Introduction

Bambu 3MF Viewer is a browser-based 3D model viewer and inspection tool built by Black Sphere Industries. It specializes in previewing 3MF files from Bambu Lab 3D printers, with full support for multi-plate layouts, multi-color/multi-material models, and slicing visualization. The viewer also supports STL, OBJ, STEP, and DXF file formats.

The application runs entirely in the browser using Three.js for 3D rendering, requires no installation, and works offline as a Progressive Web App (PWA). It is designed for engineers, designers, and makers who need to quickly inspect 3D print files, verify plate layouts, check color assignments, and estimate print costs.

== Key Capabilities

- *Multi-format support* --- 3MF, STL, OBJ, STEP/STP, and DXF file loading
- *Bambu Lab 3MF parsing* --- Full support for multi-plate, multi-color Bambu Studio files
- *3D viewport* --- Interactive Three.js-based viewer with orbit, pan, and zoom controls
- *Plate management* --- View and switch between multiple build plates
- *Object panel* --- Per-object visibility, color assignment, and filament selection
- *Filament picker* --- Assign filaments to objects with color swatches
- *Infill controls* --- Adjust infill percentage, pattern, and wall count
- *Material and layer height* selection for print estimation
- *Model gallery* --- Firebase-backed shared model library with search, tags, and admin upload
- *Price quote* --- Automated cost estimation based on material, infill, and layer height
- *Drag-and-drop* file loading with visual drop zone
- *FPS counter* for performance monitoring
- *Dark and light themes* with portal theme bridging

= Getting Started

== Opening a File

There are three ways to load a 3D model:

+ *Drag and drop* --- Drag a file from your file manager onto the drop zone
+ *Browse button* --- Click "Open File" on the drop zone to use the file picker dialog
+ *Gallery* --- Click "Browse Gallery" to load a model from the shared Firebase gallery

Supported file formats: `.3mf`, `.stl`, `.obj`, `.step`, `.stp`, `.dxf`

== System Requirements

- A modern web browser with WebGL support (Chrome, Firefox, Edge, Safari)
- For large models, a device with a dedicated GPU is recommended
- No installation required --- the app runs entirely in the browser

== PWA Installation

Bambu 3MF Viewer can be installed as a Progressive Web App:

+ Open the app in Chrome or Edge
+ Click the install icon in the address bar (or use the browser menu)
+ The app installs to your desktop/home screen and works offline

= Features

== 3D Viewport

The main viewport fills the entire browser window, providing maximum space for model inspection:

- *Orbit* --- Left-click and drag to rotate the view around the model
- *Pan* --- Right-click and drag (or middle-click) to move the camera
- *Zoom* --- Scroll wheel to zoom in and out
- *Reset view* --- Double-click to reset the camera to the default position

The viewport includes a build plate grid, ambient and directional lighting, and optional wireframe rendering.

== Plate Sidebar

For multi-plate 3MF files (common with Bambu Studio), the left sidebar shows all build plates:

- Each plate is listed with its name and object count
- Click a plate to switch the viewport to that plate's contents
- The active plate is highlighted with an amber accent border
- Single-plate files hide the sidebar automatically

== Objects Panel

The right sidebar lists all objects on the current plate:

- *Visibility toggle* --- Show/hide individual objects
- *Color picker* --- Change the display color of each object
- *Filament selector* --- Assign filaments from the Bambu Lab filament library
- *Quantity spinner* --- Set the print quantity per object

=== Print Settings

Below the object list, print settings controls include:

- *Material* selection (PLA, PETG, ABS, TPU, etc.)
- *Layer height* selection (0.08mm to 0.32mm)
- *Infill percentage* slider (0--100%)
- *Infill pattern* dropdown (Grid, Gyroid, Honeycomb, etc.)
- *Wall count* selection

== Model Gallery

The gallery provides a shared library of 3D models hosted in Firebase Storage:

- *Search* --- Filter models by name using the search field
- *Tags* --- Models are tagged for easy categorization
- *Preview cards* --- Each model shows a thumbnail, name, and description
- *Admin upload* --- Authorized users can upload new models with name, description, and tags

== Price Quote

The quote system estimates print costs based on:

- Selected material and its cost per kilogram
- Model volume and calculated filament usage
- Infill percentage and pattern
- Layer height (affecting print time)
- Color selection

A floating quote card displays the estimated cost, and a detailed quote panel shows the full breakdown.

=== Pricing Administration

Admin users can access the pricing configuration modal to set:

- Material costs per kilogram
- Machine hourly rates
- Markup percentages
- Color surcharges

== Toolbar

A bottom toolbar provides quick access to:

- *View modes* --- Solid, wireframe, X-ray
- *Model name toggle* --- Show/hide the model name overlay
- *Measurement tools* --- Measure distances and dimensions
- *Screenshot* --- Capture the current viewport
- *Reset view* --- Return to the default camera angle
- *Open/Gallery buttons* --- Load a new file or browse the gallery

= User Interface

== Layout Overview

The interface is organized as a full-screen 3D viewport with overlay panels:

+ *Drop zone* --- Full-screen overlay shown on initial load, with drag-and-drop area, Open File button, and Gallery button
+ *Top bar* --- Model name display and Open/Gallery buttons (visible after loading a model)
+ *Plate sidebar* (left) --- Build plate list for multi-plate files
+ *Objects panel* (right) --- Object list, filament/color controls, and print settings
+ *Bottom toolbar* --- View controls and tools
+ *Loading overlay* --- Progress bar shown during file parsing
+ *FPS counter* --- Optional performance display

== Theme Support

Bambu 3MF Viewer supports two themes:

- *Dark theme* (default) --- Dark zinc backgrounds with amber accents; dark viewport background
- *Light theme* --- Light backgrounds with deep blue (\#10069f) accents; light viewport background

When embedded in the BSI portal, the theme is synchronized automatically via postMessage. In standalone mode, the theme can be toggled locally.

= Workflows

== Inspecting a Bambu Studio 3MF File

+ Export your project from Bambu Studio as a `.3mf` file
+ Drag the file onto the Bambu 3MF Viewer drop zone
+ The viewer parses all plates, objects, and color assignments
+ Use the plate sidebar to switch between build plates
+ Use the objects panel to toggle visibility and check color assignments
+ Orbit, pan, and zoom to inspect model geometry from all angles

== Estimating Print Cost

+ Load a model into the viewer
+ In the objects panel, select the desired material
+ Adjust infill percentage and layer height
+ The price quote updates automatically
+ Click the quote card for a detailed cost breakdown
+ Use the quote panel to compare different material/infill combinations

== Uploading to the Gallery

+ Click "Browse Gallery" to open the gallery panel
+ (Admin only) The upload section appears at the top
+ Enter a display name, description, and tags
+ Click "Select File" and choose a `.stl`, `.3mf`, or `.obj` file
+ The upload progress bar shows transfer status
+ Once complete, the model appears in the gallery grid

== Sharing a Model View

+ Load the model you want to share
+ Adjust the camera angle to the desired view
+ Use the screenshot button in the toolbar to capture the viewport
+ The screenshot is saved as a PNG image

= Architecture

== Architecture Overview

#figure(
  image("uml-architecture.svg", width: 100%),
  caption: [Bambu 3MF Viewer system architecture showing the browser client, Three.js rendering pipeline, file parsers, and Firebase gallery backend],
)

== Class Diagram

#figure(
  image("uml-class-diagram.svg", width: 100%),
  caption: [Class diagram showing the Viewer, Scene, FileParser, PlateManager, ObjectPanel, Gallery, and QuoteEngine components],
)

== Load Sequence

#figure(
  image("uml-seq-load.svg", width: 100%),
  caption: [File loading sequence: user drops file, parser extracts geometry, Three.js scene builds mesh hierarchy],
)

== Gallery Sequence

#figure(
  image("uml-seq-gallery.svg", width: 100%),
  caption: [Gallery interaction sequence: browsing, searching, selecting, and loading models from Firebase Storage],
)

== State Diagram

#figure(
  image("uml-states.svg", width: 100%),
  caption: [Application state transitions: empty state, loading, viewing, gallery browsing, and error states],
)

= Configuration

== Supported File Formats

#table(
  columns: (auto, auto, auto),
  align: (left, left, left),
  table.header([*Format*], [*Extensions*], [*Notes*]),
  [3MF], [`.3mf`], [Full Bambu Studio support: plates, colors, filaments],
  [STL], [`.stl`], [Binary and ASCII; single object per file],
  [OBJ], [`.obj`], [With optional MTL material files],
  [STEP], [`.step`, `.stp`], [CAD interchange format],
  [DXF], [`.dxf`], [2D/3D AutoCAD drawing exchange format],
)

== Gallery Administration

Gallery models are stored in Firebase Storage under the BSI project. Admin users (identified by Firebase Auth role) can:

- Upload new models with metadata
- Delete existing gallery entries
- Models are available to all users of the viewer

== Performance Settings

For optimal performance with large models:

- Reduce the browser window size to lower the rendering resolution
- Hide non-essential objects using the visibility toggles
- Use solid rendering mode instead of wireframe for complex models
- The FPS counter helps identify performance bottlenecks

= Troubleshooting

== Model Not Loading

- Verify the file format is supported (3MF, STL, OBJ, STEP, DXF)
- Check the browser console for parsing errors
- For very large files (>100MB), loading may take several seconds --- watch the progress bar
- Ensure WebGL is enabled in your browser settings

== Colors Not Showing on 3MF Files

- Color information must be present in the 3MF file (exported from Bambu Studio or similar)
- Plain 3MF files without color data will display in the default material color
- Use the objects panel color picker to manually assign colors

== Gallery Not Loading

- Gallery requires Firebase connectivity; check your internet connection
- If the gallery appears empty, no models have been uploaded yet
- Admin upload requires appropriate Firebase Auth permissions

== Performance Issues

- Close other browser tabs to free GPU memory
- Reduce the window size for lower rendering resolution
- Hide complex objects using the visibility toggle
- Consider using a device with a dedicated GPU for models with millions of triangles
- The FPS counter (if visible) should show 30+ FPS for smooth interaction

== Drag and Drop Not Working

- Ensure the file has a supported extension
- On some browsers, drag-and-drop may not work from certain file managers
- Use the "Open File" button as an alternative
- Check that no browser extension is intercepting drag events
