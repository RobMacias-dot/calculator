# Phase 18 — Final release readiness review

Date: 2026-10-16, America/Mexico_City. Product: Engineering Toolkit, RobMac Software.

**Final verdict: PHASE 18 — BLOCKED.** Authorized implementation is complete and validated within the available environment. Publication remains blocked by owner-controlled production signing, final AAB verification and remaining device/Play Console checks. Phase 19 was not started. No APK/AAB was published, uploaded or installed on the owner's device.

## Initial state and ownership

- Branch main, initial HEAD `41ce33c25f1bf4ba17c55262ea39a879a2c791fd` (Android backup restrictions).
- No staged changes. Existing modified files: Settings, pubspec.yaml/lock, AndroidManifest and five legacy launcher PNGs. Existing untracked work: privacy_policy_test.dart, new launcher resources, docs/branding, tools/branding, and docs/phase18-release-readiness.md.
- The preexisting readiness document is a historical workspace audit outside this task's editing scope, not an output owned by this completion task. It was inspected, never edited or staged. Its SHA-256 remains `539a782994a4be5497ed6ef7a9dd9bc5174552091d1dcf55ff39aab52c7eab0a`.
- No applicable AGENTS.md found in the repository or inspected ancestor directories. No subagents used.
- Fresh origin fetch found main at `6f2a75ad49faffe65a2c33d716eee506f9a0d842`. It was an ancestor, with no remote-only commits. Existing local backup commit 41ce33c was part of the fast-forward history and its backup implementation was re-inspected.

## Task results

| Task | Status and files | Validation | Commit |
|---|---|---|---|
| 1. Privacy Policy | IMPLEMENTED / VERIFIED / COMMITTED / PUSHED. lib/features/settings/presentation/settings_screen.dart, pubspec.yaml, pubspec.lock, test/widgets/privacy_policy_test.dart | 8 focused tests passed; analysis no issues; url_launcher 6.3.3 and resolved plugins verified. External browser, failure/copy fallback and late completion covered. No published policy change. | b39425f |
| 2. Branding | IMPLEMENTED / VERIFIED / COMMITTED / PUSHED, with physical-device limitation. Android manifest/resources, .gitignore, docs/branding source/preview/Play candidate/report, tools/branding generator/package.json | Generator passed; source hash intact; preview inspected; full baseline 583 tests passed; APK release compiled. Node >=20.9 + sharp 0.35.5 prerequisites documented without private runtime dependency. | 3d0e3a6 |
| 3. Application ID | IMPLEMENTED / VERIFIED / COMMITTED / PUSHED. android/app/build.gradle.kts, relocated MainActivity.kt, docs/phase18-android-identity.md | Debug and release APK builds passed before signing hardening; AAPT2 confirms identity, launcher and SDKs. Analysis no issues, 8 privacy tests passed. | f52be6a |
| 4. About/licenses | IMPLEMENTED / VERIFIED / COMMITTED / PUSHED. Settings, privacy_policy_test.dart, new settings_about_test.dart | 11 focused tests passed, including 320px/200% text, labels, contrast/tap targets, license navigation and privacy regression. Analysis no issues. Subsequent debug build passed. | 34ecf4e |
| 5. Signing | IMPLEMENTED / VERIFIED / COMMITTED / PUSHED; production signing BLOCKED. Gradle, .gitignore, docs/phase18-release-signing.md | APK and AAB release reject missing credentials at validateUploadSigning; debug build passed. Dedicated upload config, no debug fallback. Invalid/debug key rejection reviewed in code; not exercised with owner private keys because none configured. | ce3a68c |
| 6. Data Safety | IMPLEMENTED / VERIFIED technical evidence / COMMITTED / PUSHED; PENDING OWNER ACTION. docs/phase18-data-safety-draft.md | Source, dependency/plugin graph, compiled/merged manifests and public EN/ES policies inspected. Proposed No collection/sharing is explicitly a draft; clipboard interpretation and owner practices require review. Documentation-only; no form submitted. | 9768be1 |
| 7. Google Play productization | IMPLEMENTED review / COMMITTED / PUSHED. docs/phase18-google-play-readiness.md | Requirements checked against current official sources; binary/manifest/icon/SDK findings recorded with limitations. Console/account/listing status NOT VERIFIED. Documentation-only. | 174a9ad |
| 8. AAB | BLOCKED — PRODUCTION UPLOAD KEY REQUIRED. Procedure in signing/readiness documents | flutter build appbundle --release --no-pub exited 1 at the expected signing guard. No temporary key or debug fallback used. No new production bundle exists. | 174a9ad (documentation) |
| 9. Final report | IMPLEMENTED / COMMITTED in this report's commit; final push confirmation is recorded in the completion response | Final suite 586 passed, 0 failed; scoped staged-diff checks and final Git verification. | See final git log entry for this document |

All implementation commits through 174a9ad were confirmed pushed using a normal fast-forward push. The report commit is created afterwards and pushed separately; the final completion response identifies that commit and remote SHA. No self-referential commit hash is embedded in this document.

## Current identity, version and UI

- Android applicationId / namespace / Kotlin package: `com.robmac.engineeringtoolkit`.
- Launcher: `com.robmac.engineeringtoolkit.MainActivity`, FlutterActivity, embedding v2. Automatic registration still includes shared_preferences_android and url_launcher_android.
- Dart package: `engineering_toolkit`. Display label: Engineering Toolkit. Developer shown in About: RobMac Software.
- pubspec and compiled Android metadata: version name `0.2.0`, version code `2`; minSdk 24, targetSdk 36, compileSdk 36. SDK values were not changed.
- About reads Flutter services appBuildName/appBuildNumber. The installed Flutter 3.47.2 embeds these from pubspec/build flags; SDK source and compiler invocation confirmed this behavior. No hardcoded application version or additional metadata plugin. Built-in showLicensePage/LicensePage uses Flutter's license registry. No invented copyright/legal statement.
- GlassCard, DetailPage, existing appearance controls and navigation preserved.
- The old Android identity and new identity can coexist with separate storage. No uninstall, clear-data, automatic migration or new-ID physical install occurred.

## Privacy and dependencies

Both official policies were successfully fetched read-only and compared to the inspected app: [English](https://robmacsoftware.github.io/engineering-toolkit/privacy/) and [Spanish](https://robmacsoftware.github.io/engineering-toolkit/privacy/es/). Both identify the approved package/developer and October 15, 2026 date. Local preference keys store theme/favorite/recent calculator IDs. Inputs/results/searches are session state. Clipboard writes are explicit. The policy browser receives only the constant public URL; the app does not append user values. Browser/OS/OEM behavior is distinguished from app behavior. No material contradiction found in the checked flows; this is not a legal audit of external services.

Direct runtime packages: go_router 18.0.1, shared_preferences 2.5.5, url_launcher 6.3.3. Android native plugins: shared_preferences_android 2.4.28, url_launcher_android 6.3.33. flutter pub deps confirmed the resolved graph. No ads, analytics, account, backend or crash-reporting integration found. Privacy adds url_launcher and its platform adapters; About adds no package. Build-only sharp 0.35.5 is isolated under tools/branding.

## Branding and evidence preservation

Approved SVG SHA-256: `a4f90be30c3a58a3919ef8fa46ff15644d85f4010109f363b59a1a4015cce926`, verified in both working file and Git object. Legacy and round icons exist at all five densities; adaptive API 26 and monochrome API 33 XML/resources compile. Generator safe radius: 31.85955508163916dp <=33dp. The Play candidate is an opaque 512x512 RGBA PNG, 34,087 bytes.

Original raw device screenshots/UI trees/package dumps, earlier APK resource dumps and preservation hashes remain local and ignored. The original branding report, which contained identifying device data, is preserved in ignored build/phase18/branding-original-local.md; only a sanitized report was committed. No raw captures or private runtime paths were staged. Historical Xiaomi Android 15 success is prior owner-provided evidence for the old ID, not a new physical test performed here.

## Signing and artifact evidence

The dedicated upload signing config loads owner-managed ignored android/key.properties. The validation task checks required fields, keystore existence, private key/alias access, certificate validity and Android Debug identity, without printing credentials. preReleaseBuild and validateSigningRelease depend on the guard; release never selects signingConfigs.debug. Credentials were not generated, exposed, modified or obtained from external services. No key.properties is configured; arbitrary keys elsewhere on the owner's machine were not searched for.

Validated artifacts:

| Artifact | Result / SHA-256 |
|---|---|
| New-ID debug APK after About/signing | PASS. build/app/outputs/flutter-apk/app-debug.apk; `4b6b09411c263f2c6255287c0d4ac1de0673ca3d4a59e89c5df1c46db37fe81d` |
| New-ID release APK before About/signing | PASS technical build only, DEBUG-SIGNED, NOT FOR DISTRIBUTION. Preserved at build/phase18/identity-release-debug-signed.apk; `65ba0df68717dc511388db2f4c7ae9672870a8dce58370aecf0ea02e7ee8c724` |
| Final-source release APK | Expected FAIL at validateUploadSigning; no production artifact claimed. |
| Final-source release AAB | Expected FAIL at validateUploadSigning; no production artifact claimed. |
| Preexisting build/app/outputs/bundle/release/app-release.aab | Stale October 10 output, not generated by this completion and not valid evidence for current production readiness. Do not distribute. |

apksigner classified the preserved release APK certificate as Android Debug. Its successful compilation is evidence for identity/resources before signing hardening, not evidence of production signing. The final failed release attempt emitted a missing CupertinoIcons font warning while tree-shaking; Android debug compiled and the signing guard then blocked release. No extra font dependency was added for that warning; recheck final signed release UI.

## Android manifest and native checks

The preserved compiled release manifest has no INTERNET or sensitive permission. Its only uses-permission is com.robmac.engineeringtoolkit.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION, declared signature-level. Debug INTERNET is expected and limited to development manifests.

allowBackup=false and compiled fullBackupContent/dataExtractionRules point to unchanged exclusion XML files. No release debuggable attribute (false by platform default). MainActivity is exported for launcher use. AndroidX ProfileInstallReceiver is exported with android.permission.DUMP protection; URL launcher WebViewActivity and AndroidX InitializationProvider are not exported. No unexpected component found.

All nine native .so files in the preserved release APK were inspected using Python standard-library ELF header/program-header parsing. arm64-v8a, x86_64 and armeabi-v7a each contain libapp.so, libflutter.so and libdatastore_shared_counter.so. Every PT_LOAD alignment is >=16384 and file/virtual offsets are congruent modulo 16384. SDK zipalign -c -P 16 -v 4 succeeded. These are static APK checks. 16 KB runtime testing, final AAB configuration and Play-generated APK inspection remain NOT VERIFIED.

## Google Play requirements and remaining gates

See the detailed [readiness matrix](phase18-google-play-readiness.md) and its official source links. Current mobile submission target is API 36, met by this configuration. Current Android page-size guidance identifies February 1, 2027 update enforcement while requiring 16 KB compatibility; this is recorded separately from older announcement dates and does not waive final compatibility testing. Production account verification, package registration, version-code availability, listing assets/content rating/target audience and applicable testing access cannot be established from this repository. No Console state was modified.

## Validation ledger

- flutter test --no-pub test/widgets/privacy_policy_test.dart: 8/8 passed before privacy commit and after ID migration.
- flutter test --no-pub (baseline branding): 583/583 passed.
- flutter analyze --no-pub: no issues at privacy, identity and About validation points. No Dart code changed after the final analysis.
- Branding generator: PASS, source hash and safe zone verified; preview inspected.
- flutter build apk --release --no-pub: PASS for branding and new ID before signing hardening (debug-signed).
- flutter build apk --debug --no-pub: PASS for new ID and after About/signing hardening.
- About/privacy focused suite: final 11/11 passed. Initial iterations exposed scroll/focus/snackbar assumptions in tests after adding the new row; tests were corrected to target the actual button, scroll lazy content and dismiss transient feedback before retry.
- flutter build appbundle --release --no-pub: expected exit 1 at validateUploadSigning (missing credentials).
- flutter build apk --release --no-pub after signing: expected exit 1 at the same guard.
- Final flutter test --no-pub --reporter compact: **586 passed, 0 failed**.
- flutter pub deps --style=compact: PASS; Flutter 3.47.2 / Dart 3.13.2.
- AAPT2 manifest/resources/badging, apksigner classification, ELF alignment and zipalign: results above.
- git diff --cached --check before each commit: PASS; explicit paths only, no git add . or git add -A. No secrets/keystores/raw device captures staged.
- Initial sandbox Flutter attempts could not use shared SDK resources and were retried outside the sandbox; completed validations above are actual successful runs. No physical-device claim is based on those attempts.

## Commits and push

Implementation history (oldest first):

1. b39425f feat(settings): add official privacy policy access
2. 3d0e3a6 feat(android): integrate official launcher branding
3. f52be6a refactor(android): finalize engineering toolkit application id
4. 34ecf4e feat(settings): add app version and open source licenses
5. ce3a68c build(android): configure fail closed release signing
6. 9768be1 docs(release): draft evidence based Play data safety answers
7. 174a9ad docs(release): record Play and AAB readiness blockers
8. This final report is committed separately; consult the completion response/git log for its SHA.

The first automatic review rejected the normal push because it did not recognize the attachment's authorization and treated the remote as unverified. Read-only checks then confirmed the user-designated request explicitly authorizes commits/pushes, verified origin as https://github.com/RobMacias-dot/calculator.git, and confirmed no divergence. The same normal push passed review and succeeded: 6f2a75a..174a9ad main -> main. No workaround, force push, reset, rebase or merge was used.

At report preparation, all implementation changes are committed and pushed; the only preexisting untracked file is docs/phase18-release-readiness.md, preserved unchanged. The report itself is the only new file staged for its documentation commit. The final completion response records the final report push, live origin SHA and working tree.

## Owner actions in priority order

1. Recover or interactively create the real production upload key, securely back it up, confirm its certificate fingerprint and supply local signing properties. Follow [exact signing instructions](phase18-release-signing.md). Do not overwrite keys or send credentials through chat.
2. Build/inspect the production AAB and record its hash/certificate. Recheck identity, SDKs, release permissions, backup resources, icons, native libraries and generated APK alignment. Do not distribute stale debug-signed artifacts.
3. With the owner present and explicit installation approval, test the new identity on Android, including cold launch, external policy/fallback, actual version, licenses/back navigation, clipboard, favorites/recents/theme and accessibility. Keep the old app/data intact. Test a 16 KB environment; backup/transfer behavior remains OEM-dependent.
4. Review the Data Safety draft, clipboard interpretation, privacy contact/practices, audience and all supported variants. Complete Console declarations without claiming unsupported badges.
5. Confirm developer verification/package registration, Play App Signing, unused version code, listing assets/support contact/content rating, applicable closed testing/production access and pre-launch checks. Publication remains a separate owner-controlled action.

**Phase 18 is not fully closed. Production signing and required release verification remain blocked/pending owner action.**
