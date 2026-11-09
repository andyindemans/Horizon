// Generates the Horizon icon set into src/stable from icons/horizon/horizon-mark.svg.
// Usage: npm --prefix icons/horizon install && node icons/horizon/generate.mjs
import { execFileSync } from 'node:child_process';
import { copyFileSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '..', '..');
const stable = join(root, 'src', 'stable');
const markPath = join(here, 'horizon-mark.svg');
const MASTER = 1024;

const out = (...parts) => {
  const file = join(stable, ...parts);
  mkdirSync(dirname(file), { recursive: true });
  return file;
};

// --- raster helpers ---------------------------------------------------------

const master = await sharp(readFileSync(markPath), { density: 72 })
  .resize(MASTER, MASTER)
  .png()
  .toBuffer();

const resized = (size) =>
  size === MASTER
    ? Promise.resolve(master)
    : sharp(master).resize(size, size, { kernel: 'lanczos3' }).png().toBuffer();

const canvas = async (width, height, background, layers) =>
  sharp({ create: { width, height, channels: 4, background } })
    .composite(await Promise.all(layers.map(async ({ size, left, top }) => ({
      input: await resized(size),
      left,
      top
    }))))
    .png()
    .toBuffer();

const centered = (width, height, size) => ({
  size,
  left: Math.floor((width - size) / 2),
  top: Math.floor((height - size) / 2)
});

// --- container writers ------------------------------------------------------

function writeIco(entries) {
  // entries: [{ size, png }]; PNG-compressed ICO
  const header = Buffer.alloc(6);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(entries.length, 4);

  let offset = 6 + 16 * entries.length;
  const dir = entries.map(({ size, png }) => {
    const entry = Buffer.alloc(16);
    entry.writeUInt8(size >= 256 ? 0 : size, 0);
    entry.writeUInt8(size >= 256 ? 0 : size, 1);
    entry.writeUInt8(0, 2);
    entry.writeUInt8(0, 3);
    entry.writeUInt16LE(1, 4);
    entry.writeUInt16LE(32, 6);
    entry.writeUInt32LE(png.length, 8);
    entry.writeUInt32LE(offset, 12);
    offset += png.length;
    return entry;
  });

  return Buffer.concat([header, ...dir, ...entries.map((entry) => entry.png)]);
}

function writeIcns(chunks) {
  // chunks: [{ type, png }]
  const body = chunks.map(({ type, png }) => {
    const head = Buffer.alloc(8);
    head.write(type, 0, 'ascii');
    head.writeUInt32BE(png.length + 8, 4);
    return Buffer.concat([head, png]);
  });
  const total = 8 + body.reduce((sum, chunk) => sum + chunk.length, 0);
  const head = Buffer.alloc(8);
  head.write('icns', 0, 'ascii');
  head.writeUInt32BE(total, 4);
  return Buffer.concat([head, ...body]);
}

async function writeBmp(png) {
  // 24-bit, bottom-up, flattened onto white
  const { data, info } = await sharp(png)
    .flatten({ background: '#ffffff' })
    .removeAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const { width, height } = info;
  const rowSize = Math.ceil((width * 3) / 4) * 4;
  const pixels = Buffer.alloc(rowSize * height);
  for (let y = 0; y < height; y++) {
    const dstRow = (height - 1 - y) * rowSize;
    for (let x = 0; x < width; x++) {
      const src = (y * width + x) * 3;
      const dst = dstRow + x * 3;
      pixels[dst] = data[src + 2];
      pixels[dst + 1] = data[src + 1];
      pixels[dst + 2] = data[src];
    }
  }

  const file = Buffer.alloc(14 + 40);
  file.write('BM', 0, 'ascii');
  file.writeUInt32LE(14 + 40 + pixels.length, 2);
  file.writeUInt32LE(14 + 40, 10);
  file.writeUInt32LE(40, 14);
  file.writeInt32LE(width, 18);
  file.writeInt32LE(height, 22);
  file.writeUInt16LE(1, 26);
  file.writeUInt16LE(24, 28);
  file.writeUInt32LE(0, 30);
  file.writeUInt32LE(pixels.length, 34);
  file.writeInt32LE(2835, 38);
  file.writeInt32LE(2835, 42);
  return Buffer.concat([file, pixels]);
}

const icoFromSizes = async (sizes) =>
  writeIco(await Promise.all(sizes.map(async (size) => ({ size, png: await resized(size) }))));

// --- generate ---------------------------------------------------------------

const transparent = { r: 0, g: 0, b: 0, alpha: 0 };
const white = { r: 255, g: 255, b: 255, alpha: 1 };

// windows
writeFileSync(out('resources', 'win32', 'code.ico'), await icoFromSizes([16, 20, 24, 32, 40, 48, 64, 96, 128, 256]));
writeFileSync(out('resources', 'win32', 'code_70x70.png'), await canvas(70, 70, transparent, [centered(70, 70, 45)]));
writeFileSync(out('resources', 'win32', 'code_150x150.png'), await canvas(150, 150, transparent, [{ size: 64, left: 44, top: 25 }]));

const innoBig = [
  [100, 164, 314, 126],
  [125, 192, 386, 147],
  [150, 246, 459, 190],
  [175, 273, 556, 211],
  [200, 328, 604, 255],
  [225, 355, 700, 273],
  [250, 410, 797, 317]
];
for (const [scale, width, height, size] of innoBig) {
  const png = await canvas(width, height, white, [centered(width, height, size)]);
  writeFileSync(out('resources', 'win32', `inno-big-${scale}.bmp`), await writeBmp(png));
}

const innoSmall = [
  [100, 55, 55, 44],
  [125, 64, 68, 52],
  [150, 83, 80, 63],
  [175, 92, 97, 76],
  [200, 110, 106, 86],
  [225, 119, 123, 103],
  [250, 138, 140, 116]
];
for (const [scale, width, height, size] of innoSmall) {
  const png = await canvas(width, height, white, [centered(width, height, size)]);
  writeFileSync(out('resources', 'win32', `inno-small-${scale}.bmp`), await writeBmp(png));
}

// windows per-type icons: upstream 256px entry plus a small mark badge
const win32Dir = join(stable, 'resources', 'win32');
const typeIcons = readdirSync(win32Dir)
  .filter((name) => name.endsWith('.ico') && name !== 'code.ico')
  .sort();
const badge = await sharp(master)
  .resize(64, 64, { kernel: 'lanczos3' })
  .flatten({ background: '#F5F6F7' })
  .png()
  .toBuffer();

for (const name of typeIcons) {
  try {
    const upstream = execFileSync('git', ['-C', join(root, 'vscode'), 'show', `HEAD:resources/win32/${name}`], {
      maxBuffer: 64 * 1024 * 1024,
      stdio: ['ignore', 'pipe', 'pipe']
    });

    const count = upstream.readUInt16LE(4);
    let png;
    for (let i = 0; i < count; i++) {
      const entry = 6 + i * 16;
      const width = upstream.readUInt8(entry) || 256;
      const size = upstream.readUInt32LE(entry + 8);
      const offset = upstream.readUInt32LE(entry + 12);
      const data = upstream.subarray(offset, offset + size);
      if (width === 256 && data.subarray(1, 4).toString('ascii') === 'PNG') {
        png = data;
        break;
      }
    }
    if (!png) {
      throw new Error('no 256px PNG entry');
    }

    const base = await sharp(png)
      .resize(256, 256)
      .composite([{ input: badge, left: 150, top: 185 }])
      .png()
      .toBuffer();

    const sizes = [256, 128, 96, 64, 48, 32, 24, 20, 16];
    const entries = await Promise.all(sizes.map(async (size) => ({
      size,
      png: size === 256 ? base : await sharp(base).resize(size, size, { kernel: 'lanczos3' }).png().toBuffer()
    })));
    writeFileSync(out('resources', 'win32', name), writeIco(entries));
  } catch (err) {
    console.warn(`WARN: skipped ${name}: ${err.message}`);
  }
}

// macOS
writeFileSync(out('resources', 'darwin', 'code.icns'), writeIcns([
  { type: 'ic07', png: await resized(128) },
  { type: 'ic08', png: await resized(256) },
  { type: 'ic09', png: await resized(512) },
  { type: 'ic10', png: await resized(1024) }
]));

// linux
writeFileSync(out('resources', 'linux', 'code.png'), await resized(1024));
copyFileSync(markPath, out('resources', 'linux', 'code.svg'));

// server
writeFileSync(out('resources', 'server', 'favicon.ico'), await icoFromSizes([16, 32, 48, 256]));
writeFileSync(out('resources', 'server', 'code-192.png'), await resized(192));
writeFileSync(out('resources', 'server', 'code-512.png'), await resized(512));

// workbench
copyFileSync(markPath, out('src', 'vs', 'workbench', 'browser', 'media', 'code-icon.svg'));

// letterpress watermarks (40x40, viewBox 1024)
const letterpress = (id, fill, groupOpacity) => `<?xml version="1.0" encoding="UTF-8"?>
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0" y="0" width="40" height="40" viewBox="0 0 1024 1024">
  <g id="${id}" fill="${fill}"${groupOpacity === 1 ? '' : ` opacity="${groupOpacity}"`}>
    <circle cx="512" cy="240" r="170" opacity="0.7"/>
    <polygon points="512,150 772,300 512,450 252,300" opacity="0.55"/>
    <polygon points="512,450 772,300 772,600 512,750" opacity="0.8"/>
    <polygon points="252,300 512,450 512,750 252,600" opacity="1"/>
  </g>
</svg>
`;
const letterpressDir = ['src', 'vs', 'workbench', 'browser', 'parts', 'editor', 'media'];
writeFileSync(out(...letterpressDir, 'letterpress-dark.svg'), letterpress('horizon_grey_dark_letterpress', '#B2B2B2', 0.3));
writeFileSync(out(...letterpressDir, 'letterpress-light.svg'), letterpress('horizon_grey_light_letterpress', '#B2B2B2', 0.1));
writeFileSync(out(...letterpressDir, 'letterpress-hcDark.svg'), letterpress('horizon_grey_hc_dark_letterpress', '#3C3C3C', 1));
writeFileSync(out(...letterpressDir, 'letterpress-hcLight.svg'), letterpress('horizon_grey_hc_light_letterpress', '#B2B2B2', 1));

console.log('Horizon icons generated');
