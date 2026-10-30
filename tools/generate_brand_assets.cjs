/** Render the single native SVG source into all platform launcher sizes.
 * Run: node tools/generate_brand_assets.cjs
 * Uses normal `sharp` resolution, or the Codex bundled image runtime.
 */
const fs = require('node:fs/promises');
const path = require('node:path');
const os = require('node:os');
let sharp;
try { sharp = require('sharp'); }
catch (_) {
  sharp = require(path.join(os.homedir(), '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp'));
}
const root = path.resolve(__dirname, '..');
const res = path.join(root, 'android/app/src/main/res');

async function write(relative, contents) {
  const destination = path.join(root, relative);
  await fs.mkdir(path.dirname(destination), { recursive: true });
  await fs.writeFile(destination, contents);
}
async function raster(svg, relative, size, opaque = false) {
  let image = sharp(Buffer.from(svg), { density: 384 }).resize(size, size);
  if (opaque) image = image.flatten({ background: '#496650' }).removeAlpha();
  const output = await image.png({ compressionLevel: 9 }).toBuffer();
  await write(relative, output);
  return output.length;
}

(async () => {
  const svg = await fs.readFile(path.join(root, 'web/icons/wearloop.svg'), 'utf8');
  for (const [density, size] of Object.entries({ mdpi:48, hdpi:72, xhdpi:96, xxhdpi:144, xxxhdpi:192 })) {
    await raster(svg, `android/app/src/main/res/mipmap-${density}/ic_launcher.png`, size);
  }
  const iconset = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  const contents = JSON.parse(await fs.readFile(path.join(root, iconset, 'Contents.json'), 'utf8'));
  for (const image of contents.images) {
    if (!image.filename) continue;
    const size = Math.round(parseFloat(image.size) * parseFloat(image.scale));
    await raster(svg, `${iconset}/${image.filename}`, size, true);
  }
  await raster(svg, 'web/favicon.png', 48);
  for (const size of [192,512]) {
    await raster(svg, `web/icons/Icon-${size}.png`, size);
    await raster(svg, `web/icons/Icon-maskable-${size}.png`, size, true);
  }
  const storeBytes = await raster(svg, 'docs/store-assets/wearloop-icon-512.png', 512, true);
  await write('docs/store-assets/wearloop-icon.svg', svg);

  const foreground = `<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="64" android:viewportHeight="64">
    <path android:pathData="M28,23c0,-7 11,-8 11,-1c0,4 -7,6 -7,10l17,10c2,1 1,4 -1,4H16c-2,0 -3,-3 -1,-4l12,-7"
        android:fillColor="@android:color/transparent" android:strokeColor="#F7F8F2"
        android:strokeWidth="3.5" android:strokeLineCap="round" android:strokeLineJoin="round" />
    <path android:pathData="M44,15c8,-1 11,4 8,10c-7,1 -11,-3 -8,-10Z" android:fillColor="#C9D5A9" />
    <path android:pathData="M45,23l5,-5" android:fillColor="@android:color/transparent"
        android:strokeColor="#496650" android:strokeWidth="1.4" android:strokeLineCap="round" />
</vector>
`;
  await write('android/app/src/main/res/drawable/wearloop_foreground.xml', foreground);
  await write('android/app/src/main/res/values/brand_colors.xml', '<?xml version="1.0" encoding="utf-8"?>\n<resources><color name="wearloop_icon_background">#496650</color></resources>\n');
  for (const version of [26,33]) {
    await write(`android/app/src/main/res/mipmap-anydpi-v${version}/ic_launcher.xml`, `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/wearloop_icon_background" />
    <foreground android:drawable="@drawable/wearloop_foreground" />
${version === 33 ? '    <monochrome android:drawable="@drawable/wearloop_foreground" />\n' : ''}</adaptive-icon>
`);
  }
  const indexPath = path.join(root, 'web/index.html');
  let index = await fs.readFile(indexPath, 'utf8');
  const inline = svg.trim().replace('<svg xmlns="http://www.w3.org/2000/svg"', '<svg aria-hidden="true"');
  index = index.replace(/<svg\b[^>]*>[\s\S]*?<\/svg>/, inline);
  await fs.writeFile(indexPath, index);
  console.log(`Brand assets generated; Play store icon:512x512 RGB PNG, ${storeBytes} bytes.`);
})().catch(error => { console.error(error); process.exitCode=1; });
