const { chromium } = require('/opt/node22/lib/node_modules/playwright');
(async () => {
  const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
  const page = await browser.newPage({ viewport: { width: 2300, height: 1000 }, deviceScaleFactor: 1 });
  await page.goto('file://' + __dirname + '/board2.html');
  await page.waitForTimeout(500);
  for (const id of ['c1','c2','c3','c4']) {
    await page.locator('#' + id).screenshot({ path: __dirname + '/' + id + '.png' });
  }
  await browser.close();
})();
