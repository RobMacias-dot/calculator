# Android launcher branding

Approved blue artwork is preserved byte for byte in `source/engineering_toolkit_app_blue_512.svg`.
SHA-256: `a4f90be30c3a58a3919ef8fa46ff15644d85f4010109f363b59a1a4015cce926`.

Includes legacy and round icons at 48/72/96/144/192 px, API 26 adaptive background/foreground, API 33 monochrome layer, and an opaque 512x512 Google Play candidate. Foreground scale is 60%; generated visible radius must be <=33 dp. Artwork paths and gradients are unchanged.

## Reproduce

Install Node.js >=20.9 and npm, then from the repository root:

```sh
npm install --prefix tools/branding
node tools/branding/generate-android-icons.cjs
```

The build-only dependency is pinned to sharp 0.35.5; npm must be able to download its platform binary. No private runtime path or Flutter dependency is required. The generator resolves sharp from its own node_modules. NODE_PATH may optionally supply an existing compatible installation. Commit only intentional image changes; do not commit node_modules.

`launcher-preview.png` shows legacy, circular adaptive, rounded adaptive and themed previews. `google-play/engineering_toolkit_play_512.png` is a candidate, not an uploaded asset.

## Evidence boundaries

Previous owner-provided physical validation reported PASS on Xiaomi Android 15 under the old application ID. No physical-device testing is claimed for the new ID. Raw captures, package dumps, prior APK dumps and preservation records stay local and are excluded from Git. The original report is preserved in ignored build/phase18/branding-original-local.md. No device was installed, uninstalled, or cleared in this completion run.
