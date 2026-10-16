// One still for checking: node frame.mjs <scene> <look> <t> <out.png>
import { chromium } from '/opt/node-tools/node_modules/playwright/index.mjs';
import { pathToFileURL } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';
const [scene, look, t, out] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 393, height: 916 } });
page.on('pageerror', e => console.error('PAGE ERROR', e.message));
page.on('console', m => { if (m.type() === 'error') console.error('CONSOLE', m.text()); });
await page.goto(pathToFileURL(path.resolve('tess-motion.html')).href + `?record&scene=${scene}&look=${look}&dpr=2`);
await page.evaluate(() => window.ready);
const data = await page.evaluate(t => { window.renderAt(t); return document.getElementById('screen').toDataURL('image/png'); }, parseFloat(t));
fs.writeFileSync(out, Buffer.from(data.slice(data.indexOf(',') + 1), 'base64'));
await browser.close();
