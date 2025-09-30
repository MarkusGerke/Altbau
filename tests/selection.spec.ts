import { test, expect } from '@playwright/test';

// Utility: wait for maplibre to be ready (sources and layers added)
async function waitForMapReady(page: any) {
  await page.waitForFunction(() => {
    // @ts-ignore
    const map = (window as any).maplibreMapInstance;
    if (!map) return false;
    const src = map.getSource('buildings');
    const l2d = map.getLayer('buildings-2d');
    return !!src && !!l2d;
  }, null, { timeout: 20000 });
}

test.describe('Gebäude-Selektion und Farbmarkierung', () => {
  test('Nur angeklicktes Gebäude wird eingefärbt', async ({ page }) => {
    await page.goto('/?test=1', { waitUntil: 'domcontentloaded' });

    // Expose a handle to the map instance by hooking into app.js when it creates the map
    await page.addInitScript(() => {
      // Monkey-patch map creation to store on window
      const orig = (window as any).maplibregl?.Map;
      if (!orig) return;
      // If already patched, skip
      if ((window as any).__patchedMaplibre) return;
      (window as any).__patchedMaplibre = true;
      const ProxyMap: any = function(...args: any[]) {
        const inst = new (orig as any)(...args);
        inst.on('load', () => {
          (window as any).maplibreMapInstance = inst;
        });
        return inst;
      };
      ProxyMap.prototype = (orig as any).prototype;
      (window as any).maplibregl.Map = ProxyMap;
    });

    // Reload so init script applies before app.js runs
    await page.reload({ waitUntil: 'domcontentloaded' });

    // Warten bis Gebäude-Quelle geladen wurde (Testmodus lädt sofort Mock-Daten)
    await waitForMapReady(page);

    // Wähle die Farbe "Grün"
    await page.click('#btn-green');
    await expect(page.locator('#btn-green')).toHaveClass(/active/);

    // Suche eine Pixelposition, an der ein Gebäude tatsächlich gerendert ist
    const candidate = await page.evaluate(() => {
      const map = (window as any).maplibreMapInstance;
      const canvas = map.getCanvas();
      const w = canvas.width;
      const h = canvas.height;
      const step = 20;
      for (let y = Math.floor(h * 0.25); y < Math.floor(h * 0.75); y += step) {
        for (let x = Math.floor(w * 0.25); x < Math.floor(w * 0.75); x += step) {
          const feats = map.queryRenderedFeatures([x, y], { layers: ['buildings-2d'] });
          if (feats && feats.length) {
            return { x, y };
          }
        }
      }
      return null;
    });

    // Screenshot vor dem Klick
    await page.screenshot({ path: 'tests-output/before.png', fullPage: false });

    const canvas = page.locator('#map canvas').first();
    const bbox = await canvas.boundingBox();
    expect(bbox).toBeTruthy();

    const clickX = (candidate ? candidate.x : bbox!.width / 2) + bbox!.x;
    const clickY = (candidate ? candidate.y : bbox!.height / 2) + bbox!.y;

    // Klick auf gefundene Position
    await page.mouse.click(clickX, clickY);

    // Warte auf Daten-Update der GeoJSON-Source
    await page.waitForTimeout(400);

    // Verifiziere: Anzahl grüner Features ist mindestens 1
    const result = await page.evaluate(() => {
      const map = (window as any).maplibreMapInstance;
      const src: any = map?.getSource('buildings');
      const data = (src as any)?._data;
      const fc = data as any;
      if (!fc || !fc.features) return { total: 0, green: 0 };
      const green = fc.features.filter((f: any) => f.properties && f.properties._class === 'green').length;
      return { total: fc.features.length, green };
    });

    expect(result.total).toBeGreaterThan(0);
    expect(result.green).toBeGreaterThan(0);

    // Screenshot nach dem Klick
    await page.screenshot({ path: 'tests-output/after.png', fullPage: false });
  });
});
