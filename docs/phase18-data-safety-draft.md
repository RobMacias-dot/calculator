# Google Play Data Safety — DRAFT FOR OWNER REVIEW

Reviewed 2026-10-16 for Android `com.robmac.engineeringtoolkit`, version 0.2.0+2. Not submitted. Recheck against the final signed AAB before submitting. This is a technical proposal, not a legal determination or a security certification.

## Verified technical evidence

- `pubspec.lock`: go_router 18.0.1, shared_preferences 2.5.5, url_launcher 6.3.3; Android native plugins shared_preferences_android 2.4.28 and url_launcher_android 6.3.33. No ads, analytics, accounts, backend or crash reporting SDK found in dependencies, plugin registration or application call paths.
- `lib/features/preferences/local_preferences_repository.dart` writes only theme, favorites and recents IDs under engineering_toolkit.preferences.v1 in local Android preferences. Calculator state, searches, inputs and results stay in memory; no application network client/path was found.
- `lib/features/calculators/presentation/result_card.dart` writes calculation text to the OS clipboard only on Copy result. The user's explicit action can expose inputs in substitution text to OS/keyboard services; this is not a promise of absolute device confinement.
- Settings launches constant public HTTPS Privacy Policy and support URLs using externalApplication. No user/calculation values are appended. The browser makes its own website request; adding url_launcher does not itself create app telemetry. Its bundled WebViewActivity is not exported and the app does not select it.
- Compiled new-ID release APK before the signing hardening: no INTERNET or sensitive permissions. Only the app-scoped AndroidX signature permission. Final release merged manifest remains consistent. Debug INTERNET is for Flutter tooling, outside this release assessment.
- Manifest allowBackup=false; backup_rules and data_extraction_rules exclude all supported application backup domains for cloud and device transfer. OEM/privileged tools and historic backups remain outside a universal guarantee.

## Proposed answers

| Field | Proposed answer / classification | Evidence and owner check |
|---|---|---|
| Collect or share required user data types? | No — VERIFIED technical behavior; OWNER REVIEW of declaration required | No off-device app data flow or automatic third-party transfer found. Explicit clipboard exception considered below. Reconfirm all distributed variants/SDKs match this revision. |
| Location (approximate/precise) | Not collected/shared — VERIFIED | No location API/permission/SDK. |
| Personal information / identifiers | Not collected/shared — VERIFIED | No accounts, identity forms or identifiers transmitted. |
| Financial information | Not collected/shared — VERIFIED | No in-app financial data collection; optional external support checkout is separate. See the voluntary-support addendum below. |
| Health/fitness | Not collected/shared — VERIFIED | No related API/data flow. |
| Messages, photos/videos, audio | Not collected/shared — VERIFIED | No capture/media/message integration. |
| Files/documents, calendar, contacts | Not collected/shared — VERIFIED | No related access or transmission. |
| App activity (interactions, searches, installed apps, other user content/actions) | Not collected/shared — VERIFIED with clipboard interpretation requiring OWNER REVIEW | Recents/favorites/searches/calculations are local. Explicit Copy result delivers text to OS clipboard. No automatic export or tracking. |
| Web browsing, app info/performance (crash logs, diagnostics), device/other IDs | Not collected/shared — VERIFIED | No browsing/diagnostic/advertising identifier collection. External policy/support browser is a separate app. |
| Collection purposes, required/optional, ephemeral processing | NOT APPLICABLE under proposed No answer | No off-device collection. Do not label local calculation memory as off-device ephemeral collection. |
| Encrypted in transit | NOT APPLICABLE to app-collected data | Do not claim an encryption/security badge solely from HTTPS policy browsing. Follow the actual form branching. |
| Account creation / account deletion | No accounts — VERIFIED; account deletion NOT APPLICABLE | No sign-in or account backend. |
| Deletion request mechanism | No remote user data held — VERIFIED technical scope | Policy describes clearing local Android app storage/uninstall. Owner must answer any visible Console deletion question without inventing a remote deletion service. |
| Independent security review / payment badge | No claim — NOT VERIFIED / NOT APPLICABLE | No authorized-lab assessment or payments integration provided. |
| Families / target audience | PENDING OWNER CONFIRMATION | Do not infer age targeting from engineering content. No Families compliance badge claimed. |
| Privacy Policy | VERIFIED available; owner to enter URL | https://robmacsoftware.github.io/engineering-toolkit/privacy/ |

Google defines collection by off-device transmission and distinguishes user-initiated sharing exceptions. Proposed No-sharing treats explicit copying as a user-initiated transfer users reasonably expect. The owner must confirm that interpretation against the exact form and all supported versions; clipboard delivery is documented, not concealed. Website hosting/browser services may process network metadata independently. This review does not audit that host or claim it has no logs.

## Published policy comparison

Both official English and Spanish HTML pages were fetched successfully on 2026-10-16. They identify Engineering Toolkit, RobMac Software, com.robmac.engineeringtoolkit and October 15, 2026. English sections 2–7 match inspected offline processing, limited local preferences, explicit clipboard action, backup/OEM caveats, retention and Android storage protections. Spanish content presents the same practices. That comparison describes the previous offline/policy flows. Voluntary support now requires the public amendments proposed in phase18-voluntary-support-privacy-amendments.md; they remain unpublished. The policy was not changed. Settings also offers explicit Copy link after a browser-launch failure; it copies only the public URL. Owner must confirm contact handling, audience, distribution scope and any practices outside the app before submission.

## Official guidance consulted

- [Data Safety definitions, SDK responsibility and form](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [Google Play User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)
- [Official policy, English](https://robmacsoftware.github.io/engineering-toolkit/privacy/) and [Spanish](https://robmacsoftware.github.io/engineering-toolkit/privacy/es/)

Owner review and submission remain pending. No Play Console form was opened, changed or submitted.

## Voluntary-support addendum — 2026-10-16

**PENDING OWNER REVIEW.** The proposed No collected/shared answers remain technically defensible for the inspected Flutter implementation, conditional on the actual website, provider integration, merchant handling and all distributed variants being reviewed. They are not approval of the complete business process.

| Environment | Verified behavior / limits |
|---|---|
| A. Engineering Toolkit | A user-selected About button opens only https://robmacsoftware.github.io/support/ with externalApplication. No preflight, WebView, checkout SDK, tracking query, identifier, calculation value or user information is passed. The app has no checkout form, payment callback, payment-card processing, amount/transaction/contributor/result reception or transaction history storage. Clipboard fallback copies only the canonical URL. |
| External browser | The browser makes network requests and can process metadata, cookies and history independently. No claim that external browsing is private or data-free. Browser-launch success does not establish destination availability. |
| B. RobMac support website | Reserved EN/ES destinations returned HTTP 404 on 2026-10-16. Hosting logs, future scripts/cookies, provider redirects and privacy information are not audited. Reassess when implemented; no app telemetry does not imply no website collection. |
| C. PayPal / Mercado Pago | External services may collect card, identity and transaction information under their own terms. No SDK or response path exists in the app. No transaction performed; actual checkout/settlement/eligibility and provider fields were not verified here. |
| Developer merchant accounts | The owner may receive contributor and transaction information outside the app. Fields, purposes, retention, access and privacy-request handling require owner confirmation. Do not claim the developer receives no personal data or has no remote records across the business. |

The [official Data Safety payment-service FAQ](https://support.google.com/googleplay/android-developer/answer/10787469) distinguishes provider-collected transaction data from data the app accesses: provider data need not be declared when collected directly under provider terms and never accessed by the app. Other financial information and payment-service responses still require assessment. The same guidance defines collection, SDK/WebView responsibilities and user-initiated sharing exceptions. An external browser alone is not a blanket exemption for first-party collection or future callbacks.

Here the app supplies a public URL rather than user data and receives no payment data. This supports the scoped No answer; owner declarations about the website and merchant accounts remain unverified. Confirm final form interpretation with Google when needed, and recheck if website integration, SDKs, identifiers or return channels change. The deletion row above concerns app-held data only, not external merchant records. Public EN/ES privacy amendments and website disclosures are publication blockers. No Console submission or payment/security badge claim was made.
