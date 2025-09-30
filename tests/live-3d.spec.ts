import { test, expect } from '@playwright/test';

async function findOnLayer(page: any, layerId: string) {
  for (let i = 0; i < 8; i++) {
    const found = await page.evaluate((layer) => {
      const map = (window as any).maplibreMapInstance;
      if (!map) return false;
      const c = map.getCanvas();
      const w = c.width, h = c.height;
      for (let y = Math.floor(h * 0.25); y < Math.floor(h * 0.75); y += 20) {
        for (let x = Math.floor(w * 0.25); x < Math.floor(w * 0.75); x += 20) {
          const feats = map.queryRenderedFeatures([x, y], { layers: [layer] });
          if (feats && feats.length) return true;
        }
      }
      return false;
    }, layerId);
    if (found) return true;
    await page.waitForTimeout(600);
  }
  return false;
}

test('3D sichtbar nach Speichern (grün, volle Höhe)', async ({ page }) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => (window as any).uiReady === true, null, { timeout: 10000 });

  // Bearbeiten aktivieren
  const isEdit = await page.locator('#btn-edit').evaluate((el: HTMLElement) => el.style.display !== 'none');
  if (isEdit) await page.click('#btn-edit');

  // Grün wählen
  await page.click('#btn-green');

  // Warten bis Daten da sind
  await page.waitForFunction(() => {
    const b = (window as any).buildingsData; return !!(b && b.features && b.features.length);
  }, null, { timeout: 120000 });

  // Klicke auf irgendein Gebäude in 2D
  const canvas = page.locator('#map canvas').first();
  const bbox = await canvas.boundingBox();
  const clicked = await page.evaluate(() => {
    const map = (window as any).maplibreMapInstance; const c = map.getCanvas();
    const w = c.width, h = c.height;
    for (let y = Math.floor(h * 0.25); y < Math.floor(h * 0.75); y += 20) {
      for (let x = Math.floor(w * 0.25); x < Math.floor(w * 0.75); x += 20) {
        const feats = map.queryRenderedFeatures([x, y], { layers: ['buildings-2d'] });
        if (feats && feats.length) return { x, y };
      }
    }
    return null;
  });
  expect(clicked).not.toBeNull();
  await page.mouse.click(bbox!.x + clicked!.x, bbox!.y + clicked!.y);

  // Speichern -> Bearbeiten aus
  await page.click('#btn-save');

  // Prüfe Pitch, Layer-Visibility, und gerenderte Features in 3D
  await page.waitForFunction(() => {
    const map = (window as any).maplibreMapInstance;
    return map && map.getPitch() >= 45 && map.getLayoutProperty('buildings-3d','visibility') === 'visible';
  }, null, { timeout: 8000 });

  const has3D = await findOnLayer(page, 'buildings-3d');
  expect(has3D).toBeTruthy();
});
