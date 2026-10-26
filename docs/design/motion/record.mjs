// Records one scene of tess-motion.html at exactly 60 fps: node record.mjs <scene> <look> <out.mp4> [dpr]
import { chromium } from '/opt/node-tools/node_modules/playwright/index.mjs';
import { spawn } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [scene = 'work', look = 'obsidian', out = `${scene}-${look}.mp4`, dpr = '2'] = process.argv.slice(2);
const FPS = 60;
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 393, height: 916 } });
const url = pathToFileURL(path.resolve('tess-motion.html')).href + `?record&scene=${scene}&look=${look}&dpr=${dpr}`;
await page.goto(url);
await page.evaluate(() => window.ready);
const duration = await page.evaluate(() => window.sceneDuration());
const frames = Math.ceil(duration * FPS);
const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-vcodec', 'png', '-framerate', String(FPS), '-i', '-',
  '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-preset', 'medium', '-movflags', '+faststart', out]);
for (let i = 0; i < frames; i++) {
  const data = await page.evaluate(t => { window.renderAt(t); return document.getElementById('screen').toDataURL('image/png'); }, i / FPS);
  const buf = Buffer.from(data.slice(data.indexOf(',') + 1), 'base64');
  if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
}
ff.stdin.end();
await new Promise(r => ff.on('close', r));
await browser.close();
console.log(`${out}: ${frames} frames, ${duration.toFixed(2)} s`);
