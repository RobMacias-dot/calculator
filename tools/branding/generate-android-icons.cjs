// Build-time artwork tool only; no Flutter/application dependencies.
// Requires Node.js and sharp (use NODE_PATH for an existing installation).
// Run from any directory: node tools/branding/generate-android-icons.cjs
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');
const root = path.resolve(__dirname, '../..');
const res = path.join(root, 'android/app/src/main/res');
const source = fs.readFileSync(path.join(root, 'docs/branding/source/engineering_toolkit_app_blue_512.svg'), 'utf8');
const defs = source.match(/<defs>[\s\S]*?<\/defs>/)[0];
const symbol = source.match(/<g id="engineering-symbol"[\s\S]*?<\/g>/)[0];
const rect = source.match(/<rect id="blue-background"[^>]*\/>/)[0];
const svg = body => `<svg xmlns="http://www.w3.org/2000/svg" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" width="512" height="512" viewBox="0 0 512 512">${defs}${body}</svg>`;
// Uniform 60% canvas scale about the original center, without editing paths.
// Entire symbol bounds fit inside a radius of 32dp on the 108dp canvas.
const foreground = svg(`<g transform="translate(256 256) scale(0.6) translate(-256 -256)">${symbol}</g>`);
const background = svg(rect.replace(/ rx="[^"]*"| ry="[^"]*"/g, ''));
const monochrome = foreground.replace(/fill="url\(#[^)]+\)"/g, 'fill="#FFFFFF"');
const square = svg(rect.replace(/ rx="[^"]*"| ry="[^"]*"/g, '') + symbol);
async function write(file, data) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, data);
}
async function png(art, size) {
  return sharp(Buffer.from(art), { density: 384 }).resize(size, size).ensureAlpha().png().toBuffer();
}
async function main() {
  for (const [density, size] of Object.entries({ mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 })) {
    await write(path.join(res, `mipmap-${density}/ic_launcher.png`), await png(source, size));
    const round = await sharp(await png(square, size)).composite([{ input: Buffer.from(`<svg width="${size}" height="${size}"><circle cx="${size / 2}" cy="${size / 2}" r="${size / 2}" fill="white"/></svg>`), blend: 'dest-in' }]).png().toBuffer();
    await write(path.join(res, `mipmap-${density}/ic_launcher_round.png`), round);
  }
  for (const [name, art] of Object.entries({ foreground, background, monochrome })) {
    await write(path.join(res, `drawable-nodpi/ic_launcher_${name}.png`), await png(art, 432));
  }
  for (const version of [26, 33]) {
    const xml = `<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n    <background android:drawable="@drawable/ic_launcher_background" />\n    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n${version === 33 ? '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n' : ''}</adaptive-icon>\n`;
    for (const name of ['ic_launcher', 'ic_launcher_round']) {
      await write(path.join(res, `mipmap-anydpi-v${version}/${name}.xml`), xml);
    }
  }
  await write(path.join(root, 'docs/branding/google-play/engineering_toolkit_play_512.png'), await png(square, 512));
  // Preview adaptive layers through the central 72dp viewport used by launchers.
  const merged = await sharp(await png(background, 432)).composite([{ input: await png(foreground, 432) }]).png().toBuffer();
  const composed = await sharp(merged).extract({ left: 72, top: 72, width: 288, height: 288 }).resize(256, 256).png().toBuffer();
  const previews = [await png(source, 256)];
  for (const shape of ['<circle cx="128" cy="128" r="128" fill="white"/>', '<rect width="256" height="256" rx="56" fill="white"/>']) {
    previews.push(await sharp(composed).composite([{ input: Buffer.from(`<svg width="256" height="256">${shape}</svg>`), blend: 'dest-in' }]).png().toBuffer());
  }
  const themedMerged = await sharp({ create: { width: 432, height: 432, channels: 4, background: '#384E66' } }).composite([{ input: await png(monochrome, 432) }]).png().toBuffer();
  const themed = await sharp(themedMerged).extract({ left: 72, top: 72, width: 288, height: 288 }).resize(256, 256).png().toBuffer();
  previews.push(themed);
  await write(path.join(root, 'docs/branding/launcher-preview.png'), await sharp({ create: { width: 1084, height: 280, channels: 4, background: '#E5E7EB' } }).composite(previews.map((input, i) => ({ input, left: 12 + i * 268, top: 12 }))).png().toBuffer());
  const { data, info } = await sharp(await png(foreground, 432)).raw().toBuffer({ resolveWithObject: true });
  let maxRadius = 0;
  for (let y = 0; y < info.height; y++) for (let x = 0; x < info.width; x++) {
    if (data[(y * info.width + x) * 4 + 3] > 0) maxRadius = Math.max(maxRadius, Math.hypot(x + 0.5 - 216, y + 0.5 - 216) / 4);
  }
  if (maxRadius > 33) throw new Error(`Foreground outside safe zone: ${maxRadius}dp`);
  console.log(JSON.stringify({ sourceSha256: crypto.createHash('sha256').update(source).digest('hex'), foregroundMaxRadiusDp: maxRadius, safeRadiusDp: 33 }, null, 2));
}
main().catch(error => { console.error(error); process.exitCode = 1; });
