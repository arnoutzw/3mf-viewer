# Bambu 3MF Viewer

A lightweight, offline-capable PWA for viewing Bambu Lab `.3mf` print files directly in the browser. No server required â runs entirely client-side.

## Features

- **3MF & STL support** â drag-and-drop or file picker for `.3mf` and `.stl` files
- **Bambu Studio integration** â reads plate assignments, part names, filament colors, and material data directly from Bambu project files
- **Multi-plate layout** â preserves Bambu Studio plate groupings with named plates, auto-layouts parts per plate
- **Filament-aware** â displays per-object material type (PLA, PETG, TPU, etc.) and uses actual filament densities for weight estimation
- **Weight calculator** â per-filament weight breakdown with density from the 3MF, or manual material selection for generic files
- **Lay-flat algorithm** â automatically orients parts flat on the build plate
- **Open in Bambu Studio** â one-click button to open the file in Bambu Studio via `bambustudio://` protocol (macOS)
- **Objects panel** â collapsible list of all parts with visibility toggles, material labels, and click-to-focus
- **Dark UI** â minimal dark theme built with Tailwind CSS
- **Installable PWA** â works offline via service worker, installable on desktop and mobile
- **File handler** â registers as a `.3mf` file handler so you can open files directly from your OS

## Getting started

Host the files with any static server, or open `index.html` directly. For the full PWA experience (offline, installable, file handler), serve over HTTPS.

```bash
# quick local server
npx serve .
```

Then open `http://localhost:3000` and drop a `.3mf` file onto the viewer.

## Project structure

```
index.html      â entire app (single-file: HTML + CSS + JS + Three.js)
sw.js           â service worker for offline caching + Bambu Studio file sharing
manifest.json   â PWA manifest with file handler and share target
icon-192.png    â app icon 192Ã192
icon-512.png    â app icon 512Ã512
base.stl        â build plate model
```

## Tech stack

Three.js (r162), Tailwind CSS (CDN), fflate for ZIP decompression â all loaded from CDN, zero build step.


## Theme Support

The app supports two themes:

- **Dark** (default) - Dark background with amber accents
- **ASML Light** - Light theme following ASML corporate design (deep blue #10069f, cyan accents)

When embedded in the Black Sphere Industries portal, theme changes are communicated via `postMessage`:

```javascript
// Sent to parent when theme changes
window.parent.postMessage({ type: "theme-change", theme: "dark" | "asml" }, "*");
```

## License

MIT
