# Phase 15 — Discovery, Search & Quick Access UX

Validation date: 2026-10-01 (America/Mexico_City). **PASS — ready for technical review**, with the inherited uncommitted Phase 14 baseline explicitly preserved. No commit, tag, push, amend, reset or history rewrite.

## 1. Baseline

- Starting HEAD: `a62d46926f0beaab76a03ba0708e70786259ebf3`.
- The requested clean Phase 14 commit was **not present**. The working tree contained the validated Phase 14 implementation: 12 tracked modified files and three untracked files (`docs/phase14-validation.md`, `engineering_context_card.dart`, `exploration_expansion_test.dart`). All inherited changes were preserved. HEAD still identifies the Phase 10–13 checkpoint; this phase builds on the Phase 14 working tree, not on a clean Phase 14 commit.
- Fresh pre-production-edit baseline: **562/562 Flutter tests** and **283/283 pure Dart cases**, exits 0 (`build/phase15-baseline-{flutter,domain}.log`). Phase 14 recorded **283/283 JS/Node closures**; a fresh successful run of those unchanged closures is included in §12.
- The first restricted Flutter invocation produced no tests and was interrupted. Direct Dart diagnosed denied access to its telemetry configuration. SDK-authorized runs completed successfully; this is an environment access limitation, not a test failure.
- Product baseline and final product: **30 calculators / 44 modes / 8 Learn visually scenes / 6 Playgrounds / 6 categories**. `build/phase15-audit-before.log` records the pre-edit catalog and query results.

## 2. Existing discovery architecture

Reviewed HomeScreen, HomeViewModel, CalculatorRegistry/Definition/Mode, all production definitions, CategoryScreen, CalculatorTile, FavoriteButton, PreferencesController and its local repository, router, calculator capability actions and existing search/preferences/accessibility/navigation regressions before production edits.

`createInitialCatalog()` creates the sole immutable CalculatorRegistry. The original synchronous search normalized case, composed/decomposed Latin accents, whitespace and curly apostrophes. It required every query token to occur somewhere in concatenated title, description, category label and existing immutable `keywords`; order was catalog insertion order. It did not index mode labels. Formula/explanation/assumptions/input labels were not searchable.

Search is a field on Home and Tools, not a separate route. Home searches across the catalog; Tools additionally applies the selected field. Empty Home query shows categories and any Recents; empty Tools query shows the catalog. Favorites has its own list and hides Search. HomeViewModel retains query/category across navigation, and HomeScreen restores the query controller when recreated. Opening a result dismisses keyboard focus. Submit/outside tap/scroll drag dismiss the keyboard; Clear updates the controller and VM immediately. No autofocus steals focus on Home. Result count is a live region. No-result guidance and Clear filters already existed.

Each category resolves `registry.inCategory`, and search resolves the same definition objects. No remote loading state is necessary. Category empty-state copy already handles an empty supplied catalog. All six production categories are nonempty.

Favorites uses deduplicated stable IDs, insertion ordering, serialized local writes, obsolete-ID filtering and a useful empty state with Explore tools. Recents promotes stable IDs to the front, deduplicates, caps at five, persists/restores and ignores redundant opens. Calculator and direct Playground routes record through the existing controller. Guarded routes remain authoritative.

Learn visually and Explore interactively actions previously appeared only inside supported calculators. Learn visually requires valid calculation input; Playground can open before calculating. Existing flags already represent capabilities. Catalog cards previously advertised only “Ready to calculate.”

## 3. Discovery audit

The pre-edit executable audit exercised **all 30 exact titles, significant title words, category labels and full descriptions**: all passed. It also exercised all mode labels and the representative concept matrix. The following compact table reports existing meaningful concept/abbreviation coverage and actual gaps; it is not a new keyword registry. “Mode” refers to full displayed mode labels, including symbols where present.

| Calculator | Field | Existing concept/abbreviation coverage | Baseline gap / disposition |
|---|---|---|---|
| Ohm’s Law | Electrical | ohm, current, voltage, resistance | `Ohms Law` misses apostrophe; full Current/Voltage/Resistance mode labels miss. Fixed normalization/mode indexing. |
| Newton’s Second Law | Mechanical | force, mass, acceleration | `F=ma`, `F = ma` miss; Force (F) label misses. One keyword and mode indexing. |
| Reynolds Number | Fluids | flow, viscosity, density | Reynolds number (Re) label misses, including `Re` abbreviation. Mode indexing. |
| Ideal Gas Law | Thermodynamics | gas pressure, volume, amount, temperature | Full symbolic mode labels miss. Mode indexing. |
| IPv4 / CIDR Subnet | Networking | subnet, CIDR, network, hosts | `IPv4/CIDR` without spaced slash misses. Normalization. |
| Electrical Power DC | Electrical | DC, watts, current, voltage | `DC` also falsely finds “broadcast” and “wildcard”; full symbolic labels miss. Short-token matching and mode indexing. |
| Electrical Energy | Electrical | consumption, kWh, duration | Energy (E) label misses. Mode indexing. |
| Voltage Divider | Electrical | resistor divider, output voltage | No extra keyword needed. |
| Torque | Mechanical | lever, moment, rotation | Torque (τ) label misses. Mode indexing. |
| Work | Mechanical | force, displacement | Work (W) label misses. Mode indexing. |
| Mechanical Power | Mechanical | power, work, time, average power | No metadata addition needed. |
| Kinetic Energy | Mechanical | mass, speed, kinetic energy | No metadata addition needed. |
| Momentum | Mechanical | mass, velocity | Momentum (p) label misses. Mode indexing. |
| Volumetric Flow Rate | Fluids | flow, discharge, area, volume flow | No metadata addition needed. |
| Circular Pipe Flow | Fluids | pipe, diameter, discharge | `pipe velocity` misses although velocity is its actual input. One keyword. |
| Hydrostatic Pressure | Fluids | depth, liquid, pressure increase | No metadata addition needed. |
| Bernoulli — Basic | Fluids | Bernoulli, streamline, downstream pressure P2 | Title separators normalized; no metadata addition. |
| Sensible Heat | Thermodynamics | heat, cooling, temperature | Heat (Q) label misses. Mode indexing. |
| Thermal Efficiency | Thermodynamics | heat engine, efficiency | Efficiency (η) label misses. Mode indexing. |
| Temperature Converter | Thermodynamics | Celsius, Fahrenheit, Kelvin | Absolute temperature mode misses; `temperature` puts two secondary matches ahead of the converter. Mode indexing/title priority. |
| Linear Thermal Expansion | Thermodynamics | thermal expansion, coefficient, length change | No metadata addition needed. |
| Percentage Calculator | Mathematics | percentage change, percent, ratio | X% of Y / X is what % of Y labels miss. Mode indexing. |
| Pythagorean Theorem | Mathematics | hypotenuse, triangle, geometry | Leg mode labels and `missing leg` miss. Mode indexing and one keyword phrase. |
| Vector Magnitude | Mathematics | vector length, norm, 2D, 3D | No metadata addition needed. |
| Series Resistance | Electrical | series resistors, equivalent resistance | Total resistance mode misses. Mode indexing. |
| Parallel Resistance | Electrical | parallel resistors, equivalent resistance | Total resistance mode misses. Mode indexing. |
| Binary / Decimal IPv4 | Networking | binary, decimal, IPv4, bits | Decimal to binary / Binary to decimal labels miss. Mode indexing. |
| Subnet Mask ↔ CIDR | Networking | mask, CIDR, prefix | `CIDR to mask` / Mask to CIDR miss. Mode indexing. |
| Wildcard Mask | Networking | wildcard, inverse, ACL | No metadata addition needed. |
| Quadratic Equation | Mathematics | roots, polynomial, complex, discriminant | No metadata addition needed. |

Representative before/after outcomes from executable audit:

| Intent | Expected parent | Before | After |
|---|---|---|---|
| current / voltage / resistance | Ohm’s Law | Found | Found once |
| resistor divider | Voltage Divider | Found | Found once |
| force | Newton’s Second Law | Found | Found once |
| F=ma / F = ma | Newton’s Second Law | Miss | Found once |
| vector length | Vector Magnitude | Found | Found once |
| gas pressure | Ideal Gas Law | Found | Found once |
| subnet / CIDR | IPv4 / CIDR Subnet | Found | Found once |
| pipe velocity | Circular Pipe Flow | Miss | Found once |
| roots | Quadratic Equation | Found | Found once |
| thermal expansion | Linear Thermal Expansion | Found | Found once |
| CIDR to mask | Subnet Mask ↔ CIDR | Miss | Found once |
| Ohms Law | Ohm’s Law | Miss | Found once |
| IPv4/CIDR | IPv4 / CIDR Subnet | Miss | Found once |
| DC | Electrical Power DC | Found plus two irrelevant entries | Only intended entry |

## 4. Search changes

Search now includes existing `CalculatorMode.label` values from each definition. It still emits one parent calculator; no mode route or separate capability entity. The existing `keywords` field gains exactly **three** entries: Newton `F=ma`, Circular Pipe Flow `velocity`, and Pythagorean `missing leg`. These are demonstrated gaps; existing phrases such as resistor divider, roots and vector length require no duplicated metadata.

Changes remain in CalculatorRegistry and the authoritative definitions. No field, registry, SearchService, SearchRepository or state-management abstraction was added. No formula or calculation callback was edited. The no-result guidance now suggests current/subnet, tool names and engineering fields; filtered Tools retains its existing field-specific guidance.

## 5. Ranking / normalization

Retain lowercasing, Latin accent normalization, trim and whitespace collapse. Remove straight/curly apostrophes for possessive titles. Treat `/`, `↔`, em/en dash, parentheses, comma and `=` as word separators. This handles `IPv4/CIDR`, displayed symbolic labels and the single Newton keyword without parsing equations. Meaningful digits, `%`, Greek letters and technical abbreviations remain intact.

All terms must match. Tokens of at most two characters match complete normalized words, preventing DC from matching inside “broadcast”/“wildcard”; longer terms retain existing substring behavior, including resistor → resistors. An empty normalized query returns the catalog. Unmatched text, Japanese Unicode and `!!!` return no results safely. Recognized-separator-only queries behave like whitespace. There is no unrestricted natural-language or typo correction.

Three stable groups, each preserving registry order: **exact normalized title; all query terms in title; secondary metadata**. The audit justified title priority: `temperature` previously put Ideal Gas and Sensible Heat before Temperature Converter; `flow` previously put Reynolds before the two flow calculators. No scores, personalization or favorite/recent influence.

## 6. Categories

No change needed. Electrical 6, Mechanical 6, Fluids 5, Thermodynamics 5, Networking 4, Mathematics 4. Tests check all six are nonempty, their 30 entries form a nonduplicated complete partition, and field queries include their members. Placement is coherent; no relocation or multi-category model.

## 7. Favorites and Recents

No behavior correction needed. Existing persistence, add/remove, idempotence, obsolete-ID restoration, serial-write recovery, most-recent ordering and five-item capacity regressions are retained. New actual search → favorite → calculator → Back → Clear → Recents → Favorites removal coverage verifies continuity and persisted restoration against the production catalog. Favorites intentionally presents its saved tools independently of the retained Home/Tools query.

## 8. Capability discovery

CalculatorTile now adds a wrapping text line using existing flags: **Learn visually**, **Explore interactively**, or both. The same tile serves Search, Tools, categories, Favorites and Recents. Unsupported tools have no capability text. Plain readable labels use ordinary text semantics and existing theme colors; no icon-only/color-only signal, badge system, extra control or duplicate navigation. The calculator remains the route target and retains its existing capability actions/valid-input rules.

## 9. Accessibility

- Automated tests inspect text and semantic presence/absence for both capabilities across all 30 actual definitions.
- Actual Tab/Enter events reach Clear search, clear the query, then reach/activate the result card. The search field's actual Flutter semantic label contains “Search tools or fields.” Submit dismisses the input keyboard; calculator return preserves query text. Initial Home does not autofocus, allowing reading first. Existing shell/category/favorite controls retain their labeled behavior.
- At 320×900 and 200% text in both light and dark, the real discovery surface scrolls to a Newton result containing both capability labels and to the no-result state without layout exception. Card width remains inside the viewport; favorite control is at least 48px. Flutter labeled-target, Android minimum-target and text-contrast guidelines pass on the exercised result view.
- Existing responsive Home/Tools/category/favorites/calculator and Reduce Motion regressions pass in the full suite. New labels add no animation and filtering is immediate.
- Native evidence is in §13. No audible TalkBack/VoiceOver, physical device or user-study claim.

## 10. Performance

One synchronous scan of 30 immutable definitions and their 44 mode labels; three small ordered result lists. Complexity scales with catalog text and query terms. No async index, debounce, cache invalidation, database, isolate, worker, service or dependency. No runtime timing/FPS claim; the architectural scale is sufficient without inventing measurements.

## 11. Defects

- **UX:** demonstrated punctuation/intent/mode misses; corrected as described in §§3–5.
- **UX:** secondary matches hid obvious titled tools on temperature/flow queries; corrected by simple title priority.
- **MINOR:** DC substring search returned unrelated IPv4/Wildcard entries; corrected short-token matching.
- **UX:** catalog cards concealed existing learning/exploration availability; corrected with wrapping capability text.
- **INVALID TEST ASSUMPTION:** initial new widget fixtures disposed an app-owned PreferencesController twice, deferred semantic-handle disposal past Flutter's verification, and tried ensureVisible on a lazy result not yet built at 200% text. Corrected test ownership/disposal/scrolling; no production lifetime or layout workaround. Focused suite then passed 10/10.
- **INVALID TEST ASSUMPTION:** an initial native command used PowerShell single quotes around a smart-apostrophe title; PowerShell treated that apostrophe as a delimiter and did not perform the intended result tap. Repeated with double-quoted full labels; calculator opening and Back/query continuity then passed. No app correction was needed.
- No reproduced mathematical defect, BLOCKER or MAJOR. No numerical tolerance changed. No claim of a pre-existing accessibility defect where the audit only justified added coverage.

## 12. Regression gates

| Gate | Final result | Evidence |
|---|---|---|
| flutter test | **572/572**, exit 0 | `build/phase15-final-tests.log` |
| flutter analyze | **0 issues**, exit 0 | `build/phase15-final-analyze.log` |
| dart format --output=none --set-exit-if-changed lib test tool | **145 files, 0 changed**, exit 0 | `build/phase15-final-format.log` |
| dart run tool/test_domain.dart | **283/283**, exit 0 | `build/phase15-final-domain.log` |
| dart compile js tool/test_domain_web.dart; node | **283 unchanged closures**, both exits 0; silent-success Node runner | `build/phase15-final-{js,node}.log` |
| git diff --check | PASS, exit 0 | `build/phase15-final-diff.log` |
| flutter build apk --release | **PASS**, exit 0; **52,672,577 bytes** | `build/phase15-final-apk.log` |
| flutter build appbundle --release | **PASS**, exit 0; **51,381,587 bytes** | `build/phase15-final-aab.log` |

APK SHA-256: `BB58A8EEC4E6C3AAC7AE12F17F4304369451939E6C0CBB4B89EDA2656A43958B`.

AAB SHA-256: `0C29AE64181DFCFA4EC027BD8F62A3F7B9E48F79BF5BE4CD82AA909BF600D741`.

The existing CupertinoIcons font warning recurred in the successful APK build. No dependency was introduced to suppress it. After adding search-label/initial-focus assertions to the existing keyboard test, the full 572-test run, analyzer and formatter were repeated successfully; production code and release binaries were unchanged.

Ten purposeful new tests cover discovery intent, full catalog/mode membership, normalization, stable relevance, capability semantics, actual quick access/navigation, keyboard activation, and both themes at 200%. All 562 Phase 14 tests are retained.

## 13. Native acceptance

Existing Phase10_API30 emulator under `build/phase10-avd`, serial `emulator-5558`, Android 11 / API 30 / x86_64, 1080×2400, 420 dpi. Fingerprint: `Android/sdk_phone_x86_64/generic_x86_64:11/RSR1.210722.013.A2/10067904:userdebug/test-keys`. Launched without a window or snapshot, host GPU. Installed the freshly built release APK using `adb install -r`, preserving local preferences. No platform compatibility matrix expansion or SDK update. Native interaction ran approximately **14:19–14:25 America/Mexico_City**; Android screenshot clock displays UTC.

Bounded ADB/UIAutomator helper: `build/phase15-native.ps1`, maximum 20 seconds per dump. Evidence below has prefix `build/phase15-api30-` and includes XML/PNG pairs. PNGs for mixed concept, no results, Learn visually and 200% result were opened and visually inspected. XML corroborates labels/state, not audible screen-reader speech.

| Requested scenario | Outcome | Actual evidence |
|---|---|---|
| 1. Open Search | **PASS** | `home`: actual Home search field, existing Recents and shell controls; tapped/editable field via the helper. |
| 2. Exact-title search | **PASS** | `exact`: Voltage Divider, one result, both capability labels. |
| 3. Non-title engineering concept | **PASS** | `concept-mixed`: Newton found from `f=Ma`, one result. |
| 4. Mixed case/whitespace | **PASS** | Same actual query included two leading/trailing spaces and mixed-case `f=Ma`; intended parent remained the only result. |
| 5. No-result state | **PASS** | `no-results`: unmatchedconcept gives 0 tools, guidance and Clear filters. |
| 6. Open result and return | **PASS** | `opened`: Newton input form/Calculate; Android Back → `returned`: original mixed-case/spaced query retained. |
| 7. Favorites | **PASS** | `favorited`, `favorites`, `favorite-removed`: add from Search, show saved tool, remove in Favorites, useful empty state. |
| 8. Recents continuity | **PASS** | `recents`, `recents-after-capabilities`: Newton first, once, ahead of previous Vector/Torque; retained after app-process restart in `large-home`/`restored-home`. |
| 9. Learn visually | **PASS** | Search card advertised it; after mass 2 kg/acceleration 3 m/s² → 6 N, `capability-actions` and `learn-visually` show opening the original scene with matching values. |
| 10. Playground | **PASS** | Opened Explore interactively from the same form. `playground`, `playground-result`: existing inputs 2/3, result 6 N, matching scene semantics; returned through calculator to Home. |
| 11. Keyboard/focus | **PASS**, bounded scope | Actual Android KEYCODE_TAB twice then KEYCODE_ENTER from focused Search reached/opened the Newton result (`keyboard-opened`). Query helper used Android Back to dismiss soft keyboard; result opens without it. No external physical keyboard was used. |
| 12. 200% text | **PASS** | Temporarily set system font_scale=2.0; `large-search-top`, `large-result`, `large-result-lower` show scalable search, count and complete wrapped calculator/capability text. Scrolling exposes the full card without horizontal clipping. |

Font scale restored to original **1.0** in a finally block, with original/large/restored readbacks under `build/phase15-*-font-scale.txt`. Native runs used light theme; dark theme, contrast/target guidelines and 320px scaling are automated evidence. No spoken TalkBack/VoiceOver or physical device assessment is claimed.

Final diagnostics at 14:26 America/Mexico_City: app alive, PID 4739; crash buffer **0 bytes** (`build/phase15-final-crash.log`), and no FATAL EXCEPTION, fatal signal, unhandled Dart exception or ANR marker in captured logcat (`build/phase15-final-logcat.log`). Exit history is saved in `build/phase15-exit-info.txt`; deliberate helper force-stops are not application crashes. Native evidence assertions are saved in `build/phase15-native-evidence-check.log`. The task-started emulator was shut down after acceptance; no device was running when this task began.

## 14. Scope discipline

Phase 15 changes no dependency, mathematical engine, CalculatorViewModel or HomeViewModel, parser, validator, conversion, numerical formatting, result model, platform code/configuration, package identity, signing or catalog count. Inherited Phase 14 changes remain visible separately in the working tree, including its six-Playground baseline. No account, backend, analytics, AI, calculation history, content expansion or publication. No Git history action.

## 15. Product assessment

Exact names and representative engineering intent now find existing calculators using one small local implementation. The audit verified many intents already worked; changes target actual misses. Mode intent resolves the authoritative parent once, titled tools precede secondary text, and supported learning/exploration is visible before opening a calculator.

Remaining limits: no arbitrary natural-language understanding, typo correction or exhaustive synonym dictionary. Longer-token substring matching can return related secondary tools (for example force matches Reynolds' description of forces). A search for a mode opens the calculator's ordinary initial mode, not a mode deep link. Favorites has no separate query field. Native acceptance passed **12/12 requested representative scenarios**; the technical-review working tree includes preserved Phase 14 changes and this phase's changes, so the owner should review that baseline distinction when committing.
