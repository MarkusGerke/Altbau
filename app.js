/* Fresh MVP: OSM buildings (Overpass), per-building select, color class, 3D for green/yellow */

const STORAGE_KEY = "altbau:labels";
const MAPTILER_KEY = "r1y4IRNqsEQ6iXZSMNWr";
const berlinCenter = [13.404954, 52.520008];

let currentMode = "green"; // green | yellow | red | remove
let editMode = false; // nur im Bearbeiten-Modus färben
let pendingLabels = null; // Bearbeitungs-Puffer
let buildingsData = { type: "FeatureCollection", features: [] };
// Exporte für Testautomatisierung
if (typeof window !== 'undefined') {
  window.buildingsData = buildingsData;
}

function loadLabels() {
  try { return JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}'); } catch { return {}; }
}
function saveLabels(labels) { localStorage.setItem(STORAGE_KEY, JSON.stringify(labels)); }
function migrateLegacyLabels() {
  const original = loadLabels();
  const disallowed = new Set(['ddr','ns','gray']);
  const allowed = new Set(['green','yellow','red']);
  const migrated = {};
  let removedValues = 0;
  let normalizedKeys = 0;
  let kept = 0;
  for (const k of Object.keys(original)) {
    const val = original[k];
    if (disallowed.has(val)) { removedValues++; continue; }
    if (!allowed.has(val)) { continue; }
    let nk = k;
    if (!nk.startsWith('osm:')) { nk = `osm:${nk}`; normalizedKeys++; }
    if (nk.startsWith('osm:osm:')) { nk = nk.replace(/^osm:/, ''); normalizedKeys++; }
    migrated[nk] = val;
    kept++;
  }
  const changed = JSON.stringify(original) !== JSON.stringify(migrated);
  if (changed) saveLabels(migrated);
  try {
    console.info('[altbau] Labels Migration:', { removedValues, normalizedKeys, kept, totalAfter: Object.keys(migrated).length });
  } catch {}
}
function exportLabelsToFile() {
  const labels = loadLabels();
  const dataStr = JSON.stringify(labels, null, 2);
  
  // Speichere auch lokal im data/ Verzeichnis
  try {
    // Erstelle Backup mit Zeitstempel
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupData = {
      timestamp: new Date().toISOString(),
      labels: labels,
      count: Object.keys(labels).length
    };
    
    // Download für manuellen Export
    const blob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `altbau-labels-${timestamp}.json`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
    
    console.log(`Exportiert: ${Object.keys(labels).length} Markierungen`);
  } catch (e) {
    console.error('Export-Fehler:', e);
  }
}
async function importLabelsFromFile(file) {
  const text = await file.text();
  let json = {};
  try { json = JSON.parse(text); } catch { alert('Ungültige JSON-Datei.'); return; }
  if (typeof json !== 'object' || Array.isArray(json)) { alert('Unerwartetes Format.'); return; }
  saveLabels(json);
  applyLabelsToData(buildingsData, json);
  if (typeof window !== 'undefined') { window.buildingsData = buildingsData; }
  if (window.maplibreMapInstance) window.maplibreMapInstance.getSource('buildings').setData(buildingsData);
  alert('Import erfolgreich.');
}

function buildKeyFromOSMId(feature) {
  const pid = feature && feature.properties && (feature.properties["@id"] || feature.properties.osm_id || feature.id);
  return pid ? `osm:${pid}` : null;
}

async function fetchOverpassBuildingsBBox(bbox) {
  const overpassUrl = "https://overpass.kumi.systems/api/interpreter"; // mirror
  const queryBody = `
    [out:json][timeout:25];
    (
      // alle Gebäude-Klassen (building=*) inkl. Unterklassen wie apartments usw.
      way["building"](${bbox});
      relation["building"](${bbox});
      // zusätzlich Gebäude-Teile (building:part=*), damit z. B. "building part"/"part building" eingefärbt werden können
      way["building:part"](${bbox});
      relation["building:part"](${bbox});
    );
    out body;
    >;
    out skel qt;
  `;
  const resp = await fetch(overpassUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
    body: `data=${encodeURIComponent(queryBody)}`
  });
  if (!resp.ok) throw new Error(`Overpass ${resp.status}`);
  const osm = await resp.json();
  if (typeof osmtogeojson !== 'function') throw new Error('osmtogeojson nicht geladen');
  const geo = osmtogeojson(osm, { polygonFeatures: { building: true, "building:part": true } });
  geo.features.forEach((f, i) => { if (!f.id) f.id = f.properties && (f.properties["@id"] || f.properties.osm_id) || `fid_${i}`; });
  return geo;
}

function applyLabelsToData(data, labels) {
  for (const f of data.features) {
    const key = buildKeyFromOSMId(f);
    const cls = (key && labels[key]) || null;
    const normalized = (cls === 'green' || cls === 'yellow' || cls === 'red') ? cls : null;
    f.properties._class = normalized;
    // 3D-Extrusion nur für Grün/Gelb, Rot bleibt 2D (0)
    f.properties._factor = (normalized === 'green' || normalized === 'yellow') ? 1 : 0;
  }
}

function toNumber(value, fallback) {
  if (value == null) return fallback;
  if (typeof value === 'number' && isFinite(value)) return value;
  if (typeof value === 'string') {
    // Strip unit suffixes like " m" or "m"
    const m = value.match(/[-+]?[0-9]*\.?[0-9]+/);
    if (m) return Number(m[0]);
  }
  return fallback;
}

function normalizeHeights(data) {
  const DEFAULT_LEVEL_HEIGHT_M = 3.2;
  for (const f of data.features) {
    const p = f.properties || {};
    const hStr = p.height;
    const minHStr = p.min_height || p['min_height'];
    const levels = toNumber(p['building:levels'] || p.levels, null);
    const minLevels = toNumber(p['building:min_level'], null);

    let h = toNumber(hStr, null);
    if (h == null && levels != null) {
      h = levels * DEFAULT_LEVEL_HEIGHT_M;
    }
    let minH = toNumber(minHStr, null);
    if (minH == null && minLevels != null) {
      minH = minLevels * DEFAULT_LEVEL_HEIGHT_M;
    }
    if (h == null) h = 12; // fallback baseline
    if (minH == null) minH = 0;

    // Store normalized numeric values used by style
    f.properties.render_height = h;
    f.properties.min_height = minH;
  }
}

function setMode(id) {
  currentMode = id;
  const colorButtons = document.querySelectorAll('#btn-green, #btn-yellow, #btn-red, #btn-remove');
  if (editMode) {
    colorButtons.forEach(b => b.classList.toggle('active', b.id === `btn-${id}`));
  }
}

function applyViewForEditMode(map) {
  if (!map) return;
  const v = editMode ? 'none' : 'visible';
  try { if (map.getLayer && map.getLayer('buildings-3d')) map.setLayoutProperty('buildings-3d','visibility', v); } catch {}
  try { if (map.getLayer && map.getLayer('buildings-2d')) map.setLayoutProperty('buildings-2d','visibility', editMode ? 'visible' : 'none'); } catch {}
  try { if (map.getLayer && map.getLayer('building-labels')) map.setLayoutProperty('building-labels','visibility', editMode ? 'visible' : 'none'); } catch {}
  try { map.setPitch(editMode ? 0 : 60); } catch {}
  updateFilterButtonsUI();
  applyVisibilityFilter(map);
}

function setEdit(on) {
  editMode = !!on;
  const btn = document.getElementById('btn-edit');
  if (btn) btn.classList.toggle('active', editMode);
  const saveBtn = document.getElementById('btn-save');
  const cancelBtn = document.getElementById('btn-cancel');
  if (editMode) {
    pendingLabels = loadLabels();
    if (saveBtn) saveBtn.disabled = false;
    if (cancelBtn) cancelBtn.disabled = false;
    // Standardfarbe im Bearbeiten-Modus: Grün
    setMode('green');
  } else {
    pendingLabels = null;
    if (saveBtn) saveBtn.disabled = true;
    if (cancelBtn) cancelBtn.disabled = true;
  }
  applyViewForEditMode(window.maplibreMapInstance);
  updateToolbarVisibility();
}

function bindToolbarHandlers() {
  const green = document.getElementById('btn-green');
  const yellow = document.getElementById('btn-yellow');
  const red = document.getElementById('btn-red');
  const removeBtn = document.getElementById('btn-remove');
  const exportBtn = document.getElementById('btn-export');
  const importBtn = document.getElementById('btn-import');
  const importInput = document.getElementById('import-file');
  const editBtn = document.getElementById('btn-edit');
  const saveBtn = document.getElementById('btn-save');
  const cancelBtn = document.getElementById('btn-cancel');
  if (green) green.onclick = () => handleColorButton('green');
  if (yellow) yellow.onclick = () => handleColorButton('yellow');
  if (red) red.onclick = () => handleColorButton('red');
  if (removeBtn) removeBtn.onclick = () => handleColorButton('remove');
  if (exportBtn) exportBtn.onclick = () => exportLabelsToFile();
  if (importBtn && importInput) {
    importBtn.onclick = () => importInput.click();
    importInput.onchange = () => {
      const f = importInput.files && importInput.files[0];
      if (f) importLabelsFromFile(f);
      importInput.value = '';
    };
  }
  if (editBtn) editBtn.onclick = () => setEdit(!editMode);
  if (saveBtn) saveBtn.onclick = () => {
    if (!pendingLabels) return;
    saveLabels(pendingLabels);
    setEdit(false);
    applyLabelsToData(buildingsData, loadLabels());
    if (typeof window !== 'undefined') { window.buildingsData = buildingsData; }
    if (window.maplibreMapInstance) window.maplibreMapInstance.getSource('buildings').setData(buildingsData);
  };
  if (cancelBtn) cancelBtn.onclick = () => {
    applyLabelsToData(buildingsData, loadLabels());
    if (typeof window !== 'undefined') { window.buildingsData = buildingsData; }
    if (window.maplibreMapInstance) window.maplibreMapInstance.getSource('buildings').setData(buildingsData);
    setEdit(false);
  };
}

// Sichtbarkeits-Filter (außerhalb Bearbeiten): alle an = true
let visibleClasses = { green: true, yellow: true };

function updateFilterButtonsUI() {
  const ids = ['green','yellow'];
  for (const id of ids) {
    const el = document.getElementById(`btn-${id}`);
    if (!el) continue;
    if (!editMode) el.classList.toggle('active', !!visibleClasses[id]);
  }
}

function applyVisibilityFilter(map) {
  if (!map || editMode) return;
  const active = Object.keys(visibleClasses).filter(k => visibleClasses[k]);
  if (map.getLayer && map.getLayer('buildings-3d')) {
    try { map.setFilter('buildings-3d', ['in', ['get','_class'], ['literal', active]]); } catch {}
  }
}

function handleColorButton(id) {
  if (editMode) {
    setMode(id);
  } else {
    visibleClasses[id] = !visibleClasses[id];
    updateFilterButtonsUI();
    applyVisibilityFilter(window.maplibreMapInstance);
  }
}

function updateToolbarVisibility() {
  const editBtn = document.getElementById('btn-edit');
  const saveBtn = document.getElementById('btn-save');
  const cancelBtn = document.getElementById('btn-cancel');
  const green = document.getElementById('btn-green');
  const yellow = document.getElementById('btn-yellow');
  const removeBtn = document.getElementById('btn-remove');
  const red = document.getElementById('btn-red');
  if (editBtn) editBtn.style.display = editMode ? 'none' : '';
  const inEditDisplay = editMode ? '' : 'none';
  if (saveBtn) saveBtn.style.display = inEditDisplay;
  if (cancelBtn) cancelBtn.style.display = inEditDisplay;
  // Farb-/Filter-Buttons sind in beiden Modi sichtbar (im Editieren als Farbauswahl, sonst als Filter)
  if (green) green.style.display = '';
  if (yellow) yellow.style.display = '';
  if (removeBtn) removeBtn.style.display = editMode ? '' : 'none';
  if (red) red.style.display = editMode ? '' : 'none';
}

function initMap() {
  const labels = loadLabels();
  const url = new URL(window.location.href);
  const isTest = url.searchParams.get('test') === '1';

  function createTestBuildings(centerLngLat) {
    const [lng, lat] = centerLngLat;
    const dx = 0.0005, dy = 0.0003;
    const makePoly = (idMul, ox, oy) => ({
      type: 'Feature',
      id: `test_${idMul}`,
      properties: { '@id': `test_${idMul}` },
      geometry: {
        type: 'Polygon',
        coordinates: [[
          [lng - dx + ox, lat - dy + oy],
          [lng + dx + ox, lat - dy + oy],
          [lng + dx + ox, lat + dy + oy],
          [lng - dx + ox, lat + dy + oy],
          [lng - dx + ox, lat - dy + oy],
        ]]
      }
    });
    return {
      type: 'FeatureCollection',
      features: [
        makePoly(1, 0, 0),
        makePoly(2, 0.0012, 0.0006)
      ]
    };
  }

  const map = new maplibregl.Map({
    container: "map",
    // MapTiler Dataviz Vektor-Style
    style: `https://api.maptiler.com/maps/dataviz/style.json?key=${MAPTILER_KEY}`,
    center: berlinCenter,
    zoom: 16,
    pitch: 0,
    bearing: 0,
    antialias: true,
  });
  // Map-Instanz für Tests verfügbar machen
  if (typeof window !== 'undefined') {
    window.maplibreMapInstance = map;
  }

  map.on('load', async () => {
    // Entferne Alt-Markierungen (DDR/NS/Grau) aus localStorage
    migrateLegacyLabels();
    if (isTest) {
      buildingsData = createTestBuildings(berlinCenter);
      applyLabelsToData(buildingsData, labels);
      if (typeof window !== 'undefined') { window.buildingsData = buildingsData; }
    }
    map.addSource('buildings', { type: 'geojson', data: buildingsData, promoteId: 'id' });

    map.addLayer({ id: 'buildings-2d', type: 'fill', source: 'buildings', paint: {
      'fill-color': [ 'case',
        ['==', ['coalesce', ['feature-state','_class'], ['get','_class']], 'green'], '#2ecc71',
        ['==', ['coalesce', ['feature-state','_class'], ['get','_class']], 'yellow'], '#f1c40f',
        ['==', ['coalesce', ['feature-state','_class'], ['get','_class']], 'red'], '#e74c3c',
        '#bbbbbb' ],
      'fill-opacity': 0.5,
      'fill-outline-color': '#333' } });

    // Hausnummern als Labels im Bearbeiten-Modus über den Füllungen anzeigen
    map.addLayer({ id: 'building-labels', type: 'symbol', source: 'buildings', layout: {
      'text-field': ['coalesce', ['get','addr:housenumber'], ['get','addr:housename'], ''],
      'text-size': 12,
      'symbol-placement': 'point',
      'text-allow-overlap': true,
      'visibility': 'none'
    }, paint: {
      'text-color': '#111',
      'text-halo-color': '#ffffff',
      'text-halo-width': 1.25,
      'text-halo-blur': 0.2
    }});

    // Hinweis: Feature-State ist in Filtern nicht erlaubt; deswegen filtern wir nur nach Properties
    // und steuern die tatsächliche Höhe über _factor. _factor ist 1 für Grün/Gelb, sonst 0.
    map.addLayer({ id: 'buildings-3d', type: 'fill-extrusion', source: 'buildings', layout: { visibility: 'none' },
      filter: ['in', ['get','_class'], ['literal',['green','yellow']]],
      paint: {
        'fill-extrusion-color': ['case',
          ['==', ['get','_class'], 'green'], '#2ecc71',
          /* yellow */ '#f1c40f'],
        'fill-extrusion-height': [ 'let','base', ['coalesce', ['to-number',['get','render_height']], 12], ['*', ['var','base'], ['coalesce', ['feature-state','_factor'], ['get','_factor'], 0]] ],
        'fill-extrusion-base': ['to-number',['get','min_height'],0],
        'fill-extrusion-opacity': 0.95 } });

    // Initialzustand auf Map anwenden
    setMode(currentMode);
    applyViewForEditMode(map);
    if (typeof window !== 'undefined') { window.uiReady = true; }

    map.on('dblclick', () => {
      const v = map.getLayoutProperty('buildings-3d','visibility');
      map.setLayoutProperty('buildings-3d','visibility', v === 'none' ? 'visible' : 'none');
      map.setPitch(v === 'none' ? 60 : 0);
    });

    map.on('click', 'buildings-2d', (e) => {
      if (!editMode && !isTest) return; // nur einfärben im Bearbeiten-Modus (außer Testmodus)
      const f = e.features && e.features[0];
      if (!f) return;
      const key = buildKeyFromOSMId(f);
      if (!key) return;
      const labels = pendingLabels || loadLabels();
      labels[key] = currentMode;
      pendingLabels = labels; // im Puffer belassen bis Speichern
      // Sofortiges Rendering-Feedback über Feature-State
      try {
        map.setFeatureState({ source: 'buildings', id: f.id }, { _class: currentMode, _factor: (currentMode==='green'||currentMode==='yellow')?1:0 });
      } catch {}
      for (const g of buildingsData.features) {
        const gKey = buildKeyFromOSMId(g);
        if (gKey === key) { g.properties._class = currentMode; g.properties._factor = (currentMode==='green'||currentMode==='yellow')?1:0; break; }
      }
      if (typeof window !== 'undefined') { window.buildingsData = buildingsData; }
      map.getSource('buildings').setData(buildingsData);
    });
    map.on('mousemove', 'buildings-2d', () => { map.getCanvas().style.cursor = 'pointer'; });
    map.on('mouseleave', 'buildings-2d', () => { map.getCanvas().style.cursor = ''; });

    async function loadCurrentBBox() {
      const b = map.getBounds();
      const bbox = `${b.getSouth().toFixed(6)},${b.getWest().toFixed(6)},${b.getNorth().toFixed(6)},${b.getEast().toFixed(6)}`;
      buildingsData = await fetchOverpassBuildingsBBox(bbox);
      normalizeHeights(buildingsData);
      applyLabelsToData(buildingsData, loadLabels());
      if (typeof window !== 'undefined') { window.buildingsData = buildingsData; }
      map.getSource('buildings').setData(buildingsData);
    }

    if (!isTest) {
      try {
        await loadCurrentBBox();
      } catch (e) {
        console.error(e);
      }
      // Hinweis: Kein automatischer Test-Fallback im Normalbetrieb; es werden ausschließlich OSM-Daten genutzt
    }

    let t = null;
    map.on('moveend', () => {
      if (isTest) return; // im Testmodus keine Overpass-Reloads
      if (t) clearTimeout(t);
      t = setTimeout(async () => {
        try { await loadCurrentBBox(); } catch (e) { /* ignore transient errors */ }
      }, 500);
    });
  });
}

document.addEventListener('DOMContentLoaded', () => {
  bindToolbarHandlers();
  setMode('green');
  setEdit(false);
  updateToolbarVisibility();
  initMap();
});


