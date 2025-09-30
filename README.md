Architektour: Berlin Building Classification Tool

Quick start
- Open `index.html` in a modern browser (Chrome, Edge, Firefox, Safari).
- Click buildings to cycle classification: green → yellow → red → none.
- Classifications are saved locally (browser localStorage). Use Export/Import to move data.

What this does
- Loads a MapLibre GL map of Berlin.
- Uses the standard OpenStreetMap `building` layer from vector tiles for 3D extrusions.
- Lets you label buildings (by OSM `way`/`relation` id) as:
  - green (factor 1.0, full height)
  - yellow (factor 0.5, half height)
  - red (factor 0.0, flat)

Data sources
- Default demo uses free MapTiler tiles (you can swap providers). Add your own API key.

Develop locally
- This is a static site: no build step is required.
- For better performance with local files, serve via a simple HTTP server:
  - Python: `python3 -m http.server 8000`
  - Node: `npx http-server -p 8000 --yes`

Notes
- Your classification data is stored under the key `architektour:labels` in localStorage.
- Export produces a JSON file; Import accepts the same format.




