# Google Play readiness matrix — Phase 18

Reviewed 2026-10-16 (America/Mexico_City). **Overall: BLOCKED** pending owner upload key, signed AAB verification, device validation and Console requirements. No artifact was published or uploaded.

Evidence scope: compiled new-ID APK at `build/phase18/identity-release-debug-signed.apk` before About/signing changes; current Gradle/source/merged manifests; debug APK built after About/signing; tests; official documentation. The preserved release APK is explicitly DEBUG-SIGNED and is not the final source revision. Static checks do not substitute for testing the final production AAB.

| Item | Status | Evidence / remaining action |
|---|---|---|
| Android identity | PASS | applicationId, namespace, MainActivity: com.robmac.engineeringtoolkit; AAPT2 confirms package/launcher. Dart name unchanged. |
| Label/version | PASS WITH LIMITATIONS | Engineering Toolkit; 0.2.0, code 2 from pubspec and compiled APK. Owner must confirm code 2 has not already been used in Play for this package. |
| SDK configuration | PASS | APK minSdk 24, targetSdk 36, compileSdk 36. Flutter-managed values unchanged. |
| Target SDK policy | PASS | Current official mobile new-app/update requirement is API 36 since 2026-08-31; no extension is needed for this target. |
| Release permissions | PASS WITH LIMITATIONS | Compiled release APK has only com.robmac.engineeringtoolkit.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION (signature). No INTERNET or sensitive permissions. Recheck final signed AAB. Debug INTERNET is expected for development. |
| Backup | PASS WITH LIMITATIONS | allowBackup=false, fullBackupContent and dataExtractionRules references compile correctly. Both XML files exclude supported domains. OEM transfer and historic backups cannot be guaranteed; no physical restore test performed. |
| Privacy Policy | PASS | Official EN/ES HTML fetched, dated October 15, 2026, approved identity; external browser and fallback covered by widget tests. Owner must enter public URL in Console. |
| About/licenses | PASS WITH LIMITATIONS | Developer, actual embedded Flutter version, built-in LicensePage; focused widget and accessibility tests. No new runtime package. Final production/device verification pending. |
| Launcher assets | PASS WITH LIMITATIONS | Original SVG hash preserved; legacy/round/adaptive/monochrome resources compile, preview inspected, safe radius 31.8596dp <=33dp. Historical Xiaomi evidence applies to old ID only. |
| Play icon | PASS WITH LIMITATIONS | 512x512 opaque RGBA PNG, 34,087 bytes; no precut corners/external shadow. Candidate awaits owner/Console review. |
| Release signing | BLOCKED | Dedicated upload config, no debug fallback; missing-key APK/AAB builds rejected by validateUploadSigning. No owner production key configured. |
| AAB | BLOCKED | No new production AAB. Existing build/app/outputs/bundle/release/app-release.aab predates this work (October 10) and must not be distributed. |
| 64-bit | PASS WITH LIMITATIONS | Preserved release APK includes arm64-v8a and x86_64 with libapp.so, libflutter.so, libdatastore_shared_counter.so; also armeabi-v7a. Recheck final AAB splits. |
| 16 KB binary alignment | PASS WITH LIMITATIONS | All nine .so ELF PT_LOAD segments have alignment >=16384 and congruent file/virtual offsets; zipalign -c -P 16 -v 4 succeeds on preserved APK. No 16 KB emulator/device runtime test. Final AAB and Play-generated APKs remain unverified. |
| Release debuggable | PASS WITH LIMITATIONS | Attribute absent in compiled release manifest, therefore false by default. Confirm final AAB. |
| Exported components | PASS WITH LIMITATIONS | MainActivity exported as launcher. AndroidX ProfileInstallReceiver exported with android.permission.DUMP protection (expected AndroidX tooling). InitializationProvider and URL launcher WebViewActivity are not exported. No unexpected components found. |
| Dependencies | PASS WITH LIMITATIONS | Flutter 3.47.2 / Dart 3.13.2; AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, NDK 28.2.13676358. Direct product packages go_router/shared_preferences/url_launcher only. No collection SDK found; final artifact recheck needed. Build-only sharp 0.35.5 documented separately. |
| Data Safety | PASS WITH LIMITATIONS | Evidence-based draft prepared; owner must approve answers for all distributed variants and submit. |
| Store listing/content declarations | NOT VERIFIED | Owner must finish descriptions, support contact, screenshots/feature graphic, content rating, target audience, ads declaration and any applicable policy forms. No Console access/changes. |
| Developer verification/package registration | NOT VERIFIED | Owner must check identity verification and registration of this exact package/certificate in Play Console; no assumption that it is registered. |
| Testing-track requirements | NOT VERIFIED | Account type/date and production access unknown. Applicable new personal accounts require at least 12 testers continuously opted in for 14 days; owner must check applicability and complete the process. |
| Accounts/ads/backend-specific features | NOT APPLICABLE | No accounts, ads or backend found in this release scope. Do not infer audience/legal compliance from this. |
| Owner-device validation | NOT VERIFIED | New identity/About/licenses have not been tested on Xiaomi. No install, uninstall, clear-data or migration performed. Old and new identities may coexist. |

## Applicable official requirements and dates

- [Target API](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en): API 36 for new mobile apps/updates from August 31, 2026; published extension deadline November 1, 2026 is not needed here. Existing-app availability rules are distinct from new submission rules.
- [16 KB guidance](https://developer.android.com/guide/practices/page-sizes): current page states 64-bit apps targeting API 35+ must support 16 KB, and states February 1, 2027 update-release enforcement. Older official announcements mention November 1, 2025; follow the current guidance and the account-specific Console notice. A future update deadline is not an exemption from compatibility validation for this new app.
- [64-bit](https://developer.android.com/google/play/requirements/64-bit): verify all native code in the final distribution, not just Dart tests.
- [Store assets](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en): owner must prepare and review listing assets. Only the high-resolution icon is evaluated here.
- [Developer identity verification](https://support.google.com/googleplay/android-developer/answer/10841920?hl=en) and [Android verification](https://developer.android.com/developer-verification): regional rollout and package registration require owner checks in Console; not claimed complete.
- [Testing for new personal accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en): conditional on account type/date. Closed testing and production access cannot be validated from repository code.
- [Signing](https://developer.android.com/studio/publish/app-signing): owner-controlled upload credentials and Play App Signing review remain required.

## AAB completion procedure (owner)

Follow `phase18-release-signing.md` to provision/recover and back up the real upload key. Then run `flutter build appbundle --release`, verify certificate fingerprint against the approved upload certificate, record SHA-256, and inspect package/version/SDKs, permissions, backup rules, launcher resources and native libraries. Use bundletool to inspect the bundle and generate appropriate test APKs; validate their ZIP alignment and run on a 16 KB environment. Repeat privacy/licenses/launch/clipboard/preferences tests on the new identity with explicit owner permission, preserving the old app/data. Review Play pre-launch results after an owner-authorized internal testing upload. No such upload is authorized by this completion task.
