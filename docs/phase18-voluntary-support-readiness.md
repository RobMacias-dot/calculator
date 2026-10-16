# Phase 18 — voluntary support supplemental readiness report

2026-10-16, America/Mexico_City. **IMPLEMENTED / VERIFIED TECHNICALLY; RELEASE BLOCKED.** Phase 18 remains open. Phase 19 was not started. This report supplements, and does not rewrite, phase18-final-readiness-review.md or phase18-release-signing.md.

## Repository baseline and scope

- Initial HEAD: `57e15d5d5f1f7f7b4d59fc32cf2f82c1238195ae`, branch main tracking origin/main at the same SHA.
- Origin: https://github.com/RobMacias-dot/calculator.git (owner-designated repository RobMacias-dot/calculator).
- Initial status: only `?? docs/phase18-release-readiness.md`. Preserved without editing or staging. Its SHA-256 at verification: `539A782994A4BE5497ED6EF7A9DD9BC5174552091D1DCF55FF39AAB52C7EAB0A`.
- No applicable AGENTS.md found in repository or parent directories. Existing Settings, DetailPage/GlassCard, URL launcher seam, About/privacy tests, dependencies, release manifest/backup rules, signing guard and Phase 18 readiness/Data Safety documents inspected.

## App integration — IMPLEMENTED

Settings → About now includes the Material favorite-outline icon and TextButton label **Support Development**, followed by short optional-support text stating that all functionality remains free. Reuses GlassCard, DetailPage, existing English UI, spacing and typography. No startup/calculation prompts, modal solicitation, rewards, access restrictions or calculator changes.

The permanent product model is free software with no paid calculators, premium tiers, subscriptions, paid features, donor content or digital benefits. Contributions support continued maintenance and development only.

The canonical app destination is **https://robmacsoftware.github.io/support/**, opened with `LaunchMode.externalApplication`. No query parameters, identifiers or calculation values. Existing Privacy Policy launch/copy code was minimally generalized into private helpers; no new dependency or architecture. Both links retain nonblocking error Snackbars and Copy link fallback, with clipboard errors and context disposal handled safely. No preflight request or embedded checkout.

Planned website journey: official support page → language/provider selection → external checkout:

- PayPal, owner-designated international/USD: https://www.paypal.com/ncp/payment/CKD4M9EU2QCD2
- Mercado Pago, owner-designated Mexico/MXN: https://link.mercadopago.com.mx/robmacsoftware

These exact owner URLs appear only in documentation, not application source. No payment transaction, account creation or provider-setting change performed. Prior owner checkout checks do not establish settlement or universal availability.

## Validation ledger — VERIFIED with stated limits

| Check | Result |
|---|---|
| flutter analyze --no-pub | PASS, no issues (7.1 seconds). |
| flutter test --no-pub --reporter expanded | PASS, **597 passed, 0 failed**, baseline 586 plus 11 support tests. |
| Focused support/privacy/About suite | PASS, **22 passed, 0 failed** (11 support, 8 privacy, 3 About). |
| Independent support suite | PASS, **11 passed, 0 failed**; includes final smaller 320×568 viewport at 100%/200% text scale. Full suite above preceded this test-only viewport tightening; independent rerun validates it. No product code changed afterward. |
| flutter build apk --debug --no-pub | PASS, build/app/outputs/flutter-apk/app-debug.apk. Local debug artifact only, not published or installed. |
| Debug APK SHA-256 | BFADF8CFAD65366A36628F040F7A897497E2C98CDE044979B0E5BC7DB25D8D93 |
| flutter pub deps --style=compact | PASS; Flutter 3.47.2 / Dart 3.13.2; direct dependencies unchanged. |
| Android Gradle :app:processReleaseManifest :app:validateUploadSigning | EXPECTED BLOCK: exit 1 at validateUploadSigning, missing private android/key.properties. Manifest regeneration did not complete. No guard bypass or temporary key. |
| Release manifest inspection | Existing merged release manifest inspected (09:45:28 local file timestamp), consistent with unchanged Android sources/dependency lock. No INTERNET; app-scoped signature permission only. Final production artifact still unverified. |
| Source/config regression | git diff against initial HEAD shows no Android, pubspec.yaml or pubspec.lock changes. Branding/signing/history files untouched. |
| Whitespace/staging | git diff --check and git diff --cached --check pass after trimming trailing blank lines. Explicit paths only; staged changes reviewed for secrets/personal data. |
| Live official policy pages | EN and ES HTTP 200, existing October 15, 2026 date. Public HTML read only. |
| Live support destinations | English /support/ and Spanish /es/support/ both HTTP 404. **BLOCKED — SUPPORT WEBSITE NOT YET PUBLISHED**. |
| Physical-device / 16 KB runtime | NOT PERFORMED / pending. No installation, uninstallation or payment attempted. |

The focused tests assert About placement, exact URL, external-mode method-channel mapping, no preflight, false/exception launch feedback and retry, canonical clipboard content and errors, late launcher/clipboard completion after disposal, scrolling/back navigation, focus/Enter activation, semantics, contrast and Android tap targets. Existing Privacy Policy, version and license navigation tests pass. Back tests now scroll to lazy-list content before tapping, preserving their actual navigation assertions.

Initial focused iteration had six failures because the added content caused the lazy ListView to dispose the offscreen Back widget; tests used ensureVisible on an absent element. Replaced those calls with scrollUntilVisible and reran successfully. An initial sandbox SDK command produced no result and was interrupted; successful validations used shared SDK/cache access. No failed attempt is counted as a PASS.

## Android security regression

Identity/namespace remain `com.robmac.engineeringtoolkit`. AAPT2 on the new debug APK confirms package, version 0.2.0/code 2, Engineering Toolkit label and com.robmac.engineeringtoolkit.MainActivity launcher. All launcher resources remain unchanged. allowBackup=false and both backup XML exclusion sets remain intact, with historical/OEM limitations unchanged.

Existing merged release manifest has the exported launcher and the AndroidX ProfileInstallReceiver protected by android.permission.DUMP; InitializationProvider and bundled URL launcher WebViewActivity are not exported. The app never selects that WebView. No new exported component or release INTERNET permission was introduced. Debug INTERNET is development-only. Because fresh release processing hit the signing guard, these release conclusions combine existing merged output with unchanged native sources and dependencies; final signed-AAB inspection remains mandatory.

No ads, analytics, user accounts, backend, payment SDK, device identifiers or payment callbacks introduced. Search of application URL/network call sites finds only the two public Settings destinations and the shared external launcher. No keystore/credential file tracked; key.properties is absent and ignored. Upload-only release config and fail-closed guard unchanged; no debug fallback. No new production signed AAB generated, and stale artifacts must not be distributed.

## Privacy and payments review

- [Data Safety draft](phase18-data-safety-draft.md): minimally updated to say no in-app financial data collection and separate app, external browser, unaudited website, providers and merchant accounts. Scoped No collected/shared answers are technically defensible for inspected app behavior, **PENDING OWNER REVIEW** for final declaration and business practices. No Console changes.
- [Bilingual amendment proposal](phase18-voluntary-support-privacy-amendments.md): EN/ES additions mapped to existing sections 2, 4 and 6, with section 8 publication-date handling. Owner must finalize actual merchant-record practices and applicable external policy links before publishing. No public policy edited.
- [Payments assessment](phase18-voluntary-support-compliance.md): **PENDING OWNER / GOOGLE PLAY POLICY REVIEW**. No-benefit requirement supported; creator/merchant identity and 100% condition including fee treatment unresolved. Website indirection does not establish eligibility. No charitable/tax-exempt status assumed. Alternatives are removing the app support entry in a separately reviewed revision or deferring release; no billing/regional workaround added.

## Remaining publication gates and owner work

1. **BLOCKED:** supply/recover owner production upload key securely; follow phase18-release-signing.md. No production credentials generated here.
2. **BLOCKED:** generate final signed production AAB, confirm approved certificate/version, inspect effective permissions, components, backup, branding, 64-bit and native alignment. Recheck Play-generated APKs.
3. **PENDING OWNER:** validate the new Android identity on a physical device with explicit installation authorization. Exercise calculations, theme/favorites/recents, About/version/licenses, both external links and back behavior, absent-browser/clipboard failures, accessibility and offline use. No physical-device PASS claimed.
4. **PENDING:** run 16 KB runtime validation; historical static alignment evidence does not satisfy this gate.
5. **PENDING OWNER:** finish applicable Play Console identity/package registration, signing, unused version code, listing/assets/contact, content rating/audience, Data Safety, closed testing/production access and pre-launch requirements. No publishing authorized or performed.
6. **BLOCKED — SUPPORT WEBSITE NOT YET PUBLISHED:** separately implement /support/ and /es/support/ in the website repository, add language navigation, optional/no-benefit copy and exact approved provider links. Audit hosting/privacy behavior, provider eligibility/amount interfaces and applicable terms. Test real external navigation without making a payment. Browser-launch true does not prove a live page.
7. **PENDING WEBSITE WORK:** owner-review and publish both public privacy amendments with truthful merchant handling and appropriate revision date. Website/privacy publication is a release blocker; no website repository modified here.
8. **PENDING OWNER / GOOGLE PLAY POLICY REVIEW:** confirm recipient/account status, fees/net proceeds and creator eligibility for the entire app-to-provider journey. Resolve uncertainty with Google before distribution; do not label compliance PASS.

## Git delivery record

**COMMITTED:**

- `c64760c703aa85113d7868df84678db67fc0f64c` — feat(settings): add voluntary support access (Settings, support tests, privacy back-scroll adaptation).
- `e5c6080e7a2caf8db9edd3c2df785058bf9ef33d` — docs(privacy): prepare voluntary support disclosures (Data Safety, bilingual amendment, payments review).
- This report and living readiness matrix form the separate `docs(release): update support readiness gates` commit; identify its SHA in git log and the completion response, avoiding a self-referential commit hash.

At report preparation, fetch of origin/main succeeded and showed 0 remote-only / 2 local-only commits, with origin/main still at the initial SHA. Normal push is authorized by the attached request and is the remaining delivery step after this report is committed. The completion response records actual push outcome, final HEAD and live origin/main agreement; this preparation snapshot does not assert a push before it happens. No force push, reset, automatic rebase, unrelated-file staging or artifact publication.

**Final release status: BLOCKED / Phase 18 OPEN**, despite technically verified app integration. Required website work, public privacy amendments, owner/policy review, production signing/AAB, device/16 KB and Console gates remain outstanding.
