import { test, expect } from '@playwright/test';

async function findRenderedBuilding(page: any) {
  // Versuche mehrfach: zoome/panne, suche mit queryRenderedFeatures
  for (let attempt = 0; attempt < 5; attempt++) {
    const candidate = await page.evaluate(() => {
      const map = (window as any).maplibreMapInstance;
      if (!map) return null;
      const canvas = map.getCanvas();
      const w = canvas.width, h = canvas.height;
      for (let y = Math.floor(h * 0.2); y < Math.floor(h * 0.8); y += 16) {
        for (let x = Math.floor(w * 0.2); x < Math.floor(w * 0.8); x += 16) {
          const feats = map.queryRenderedFeatures([x, y], { layers: ['buildings-2d'] });
          if (feats && feats.length) {
            const key = (feats[0].properties && (feats[0].properties['@id'] || feats[0].properties.osm_id)) || feats[0].id;
            return { x, y, key };
          }
        }
      }
      return null;
    });
    if (candidate) return candidate;
    // Zoome/panne und warte kurz aufs Nachladen
    await page.evaluate(() => {
      const map = (window as any).maplibreMapInstance;
      if (!map) return;
      const z = map.getZoom();
      map.easeTo({ zoom: Math.min(z + 0.7, 19), duration: 200 });
    });
    await page.waitForTimeout(900);
  }
  return null;
}

test('Live-OSM: Gebäude wird im Bearbeiten-Modus grün markiert', async ({ page }) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => (window as any).uiReady === true, null, { timeout: 10000 });

  // Sicherstellen: Bearbeiten ist aktiv; nur klicken, wenn nicht aktiv
  const isEditActive = await page.locator('#btn-edit').evaluate((el: HTMLElement) => el.classList.contains('active'));
  if (!isEditActive) {
    await page.click('#btn-edit');
  }
  await expect(page.locator('#btn-edit')).toHaveClass(/active/);

  // Grün wählen
  await page.click('#btn-green');
  await expect(page.locator('#btn-green')).toHaveClass(/active/);

  // Warte bis GeoJSON-Quelle mit Features geladen ist (erneut laden durch Pan/Zoom möglich)
  await page.waitForFunction(() => {
    const b = (window as any).buildingsData;
    return !!(b && b.features && b.features.length > 0);
  }, null, { timeout: 120000 });

  const candidate = await findRenderedBuilding(page);
  expect(candidate).not.toBeNull();

  const canvas = page.locator('#map canvas').first();
  const bbox = await canvas.boundingBox();
  expect(bbox).toBeTruthy();
  await page.mouse.click(bbox!.x + candidate!.x, bbox!.y + candidate!.y);

  // Warte bis mindestens ein Feature grün ist (aus buildingsData gelesen)
  await page.waitForFunction(() => {
    const b = (window as any).buildingsData;
    if (!b || !b.features) return false;
    return b.features.some((f: any) => f.properties && f.properties._class === 'green');
  }, null, { timeout: 10000 });

  // Speichern und prüfen, dass Änderung persistiert bleibt nach Reload
  await page.click('#btn-save');
  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => (window as any).uiReady === true, null, { timeout: 10000 });
  await page.waitForFunction(() => {
    const b = (window as any).buildingsData;
    if (!b || !b.features) return false;
    return b.features.some((f: any) => f.properties && f.properties._class === 'green');
  }, null, { timeout: 10000 });
});
