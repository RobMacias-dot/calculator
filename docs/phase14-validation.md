# Phase 14 — Interactive Exploration Expansion

Validation date: 2026-09-29. **PASS — ready for technical review.** Automated gates and all ten representative native scenarios passed. No commit, tag, push, reset, amend or history rewrite was performed.

## 1. Baseline

- Starting HEAD: `a62d46926f0beaab76a03ba0708e70786259ebf3`, `feat: complete Engineering Toolkit phases 10-13`.
- `git status --short` before edits: empty. Tracked working tree and index clean; ignored artifacts from previous validation retained. Git warned about an inaccessible user-level ignore file, but returned the repository status.
- Fresh pre-edit Flutter run: **541/541**, exit 0 (`build/phase14-baseline-flutter.log`). Fresh pure Dart run: **283/283**, exit 0 (`build/phase14-baseline-domain.log`). Phase 13's recorded JS baseline is the same **283 closures**; the fresh Phase 14 JS run is in §9.
- Initial restricted Flutter/Dart launchers produced no test results and were interrupted. Direct Dart diagnosed denied access to its user telemetry configuration. SDK/cache-authorized runs above completed before production edits. This was an environment access issue, not a failing baseline case.
- Starting product: **30 calculators / 44 modes / 8 Learn visually scenes / 3 Playgrounds / 6 categories**.

## 2. Architecture review

Inspected the original Voltage Divider, IPv4/CIDR and Ideal Gas compositions, their controls/renderers and mappers, calculator metadata, route guards, ViewModel, form fields, mode selector, PreferencesController, result/Copy presentation, visual semantics, animation lifecycle and existing regression tests before production edits.

All three use `PlaygroundScreen` and `PlaygroundContent`; they are not three separate solver implementations. The route accepts a borrowed `CalculatorViewModel` only when its definition is the exact registry definition. Direct routes construct one local instance and dispose it on exit. Borrowed instances remain owned by the calculator form. The post-frame, mounted-guarded `recordOpened` call registers direct routes through the existing PreferencesController. Recents deduplicates and persists at most five calculator IDs.

Live `CalculatorInputField` callbacks call `updateAndCalculate`; live unit changes call `setUnit(recalculate: true)`. Editor controllers preserve caret/focus and are disposed. `CalculatorModeSelector` retains the normal clear-inputs/clear-result semantics. `CalculationResultSummary`, `CalculationResultDetails` and `mapVisualModel` consume the same report. A null report removes numeric output, Copy, substitution and scene. Reading-order focus, a single keyboard-dismiss-on-drag scroll view, responsive columns and scalable text remain in place.

**Small primitive extracted:** `EngineeringContextCard`, the existing Phase 13 disclosure moved verbatim in behavior from CalculatorScreen into a shared presentation widget. Both screens now read definition notes followed by current-mode notes, reset the disclosure on mode change, and use `AnimationStyle.noAnimation`. This avoids copying the context UI and keeps lengthy assumptions below the primary exploration. Empty content is omitted by both callers. There is no new framework, registry, engine, state coordinator or result model.

The three newly enabled static renderers now honor the existing `showInputControls` flag, just as Divider, Subnet and Ideal Gas already do. Learn visually retains its sliders; Playground has one set of live numeric fields. No new slider limits or domain restrictions were added. Vector's instruction no longer promises component values “below” when its sliders are hidden; it refers to numeric component values.

## 3. Implemented Playgrounds

| Experience | Interaction and authoritative mode | Reused visualization | Invalid input and context |
|---|---|---|---|
| Newton’s Second Law | Live mass with kg/g selector and signed acceleration; existing `force` mode | `mapVisualModel` → `NewtonVisualModel` → `NewtonVisual` | Negative mass/incomplete/nonfinite input removes current report and scene. Existing zero-mass algebraic boundary remains valid. Original constant-mass/inertial-frame/net-axial-force notes appear in Engineering context and remain available when invalid. |
| Torque | Live force magnitude and radius with m/cm selector; existing `torque` mode | `mapVisualModel` → `TorqueVisualModel` → `TorqueVisual` | Negative force or radius is invalid; zero remains valid. Perpendicular-force magnitude assumption is unchanged. No angle, signed rotation or additional geometry calculation. |
| Vector Magnitude | Live signed x/y and existing `2d` / `3d` selector; 3D adds z | `mapVisualModel` → `VectorVisualModel` → `VectorVisual` | Switching mode clears values/report/scene through the existing VM. Incomplete/nonfinite input clears output. Refilling recalculates; z is absent from 2D inputs/context. Existing common-unit/orthogonal-axis note is shared and disclosure resets with mode. |

Direct numeric entry remains unrestricted by display scales. Phone interaction follows the original Playgrounds; changing an input immediately updates the existing calculation pipeline. The diagrams remain explanatory static geometry, not time simulations.

## 4. Source-of-truth evidence

The only definition changes are `supportsPlayground: true` on exactly the three existing definitions. No formula, parser, validator, unit conversion, domain engine, calculation context/result, numeric formatting, ViewModel or visual mapper was modified. No numerical tolerance changed.

`test/widgets/exploration_expansion_test.dart` compares live results against an ordinary CalculatorViewModel using identical definitions, modes, raw values and units. It compares authoritative value, formatted value, substitution and explanation without reimplementing any formula. Existing shared-VM tests now also cover all three new experiences: actual calculator → Playground navigation borrows the identical VM, changes survive back/reopen, and Learn visually consumes that same state.

`expectSynchronized` asserts report identity in result summary, reasoning and visual model. Focused coverage exercises signed Newton arrows, kg/g equivalence, torque proportional changes and m/cm equivalence, signed vector components, 2D/3D transitions, z=0 equality through the real engine, recovery and out-of-slider-range manual values. Invalid transitions assert no report, details, Copy, substitution or scene. All original numerical domain cases are unchanged.

## 5. Recents / navigation

No router, PreferencesController, persistence or Favorites change. Availability metadata enables the existing `Explore interactively` action and guarded `/playground/:calculatorId` route. Search and Tools continue to contain one entry per calculator. No additional navigation section or separate Playground entry was introduced.

The original Phase 9 direct-opening regression is retained and expanded from three to six entries. It verifies most-recent ordering, persisted restoration, the existing five-item cap, and exactly one entry/no extra persistence write when rebuilding or returning to the same calculator via the direct-link fallback. The restored-list expectation now takes five because the sample list contains six; the product's capacity did not change. Unsupported direct routes still fail safely. Ownership/disposal and borrowed-state back/reopen regressions pass for all six experiences.

## 6. Accessibility

- **Semantics:** tests inspect each new VisualScene's actual semantic label, including input quantities and current result; Vector 3D includes signed z. Painter internals remain excluded from semantic output. Result and waiting state retain their existing live-region behavior.
- **Keyboard/focus:** actual text editing, Tab traversal and Enter activation reach/open the reasoning and Engineering context panels for all three. Vector's real mode dropdown supports arrow-key/Enter selection. Existing normal form, unit-selection and original Playground keyboard regressions pass.
- **Touch targets/contrast:** the expanded responsive Playground tests pass Flutter's labeled-target, Android minimum-target and text-contrast guidelines for both themes at their exercised viewports.
- **Scaling/themes:** all six Playgrounds are exercised at 320px, phone and tablet sizes with 200% text, including expanded reasoning and each context paragraph. New Vector 3D tests exercise signed components, scene semantics and context at 320×640 / 200% in light and dark, then mode-reset behavior. No layout exception or horizontal context overflow was observed.
- **Reduce Motion:** both `disableAnimations` and `reduceMotion` are exercised for every new Playground. Results remain identical, idle VM notification count stays zero and no transient animation callback remains after settling/disposal. Context expansion has no animation. Original gas pause/lifecycle/offscreen/reduced-motion regressions remain passing.
- Native evidence and its limits are in §10. No audible TalkBack or VoiceOver session, physical-device assessment or user study is claimed.

## 7. Performance architecture

The new Newton, Torque and Vector scenes are static `CustomPaint` renderers, each inside the existing `VisualScene` RepaintBoundary. They introduce no animation controller, timer, background callback or simulation. Engineering input/unit changes trigger the normal pipeline; presentation frames do not calculate or notify the VM. Mode changes invalidate state and wait for valid input, matching the calculator's semantics.

Existing Ideal Gas/Reynolds clocks remain isolated in painters and controlled by the existing lifecycle mixin: reduced motion, pause, visibility, app lifecycle and TickerMode gate them; observers/listeners/controllers are removed/disposed. The original tick-isolation regression still verifies unchanged inputs, reports, details and zero VM notifications while a gas clock advances. No runtime FPS, energy or physical-device performance metrics are claimed.

## 8. Defects and corrections

No existing domain defect or production BLOCKER/MAJOR/MINOR/ACCESSIBILITY defect was reproduced. No mathematical correction was needed.

- **UX integration correction:** the new renderers initially lacked the `showInputControls` option already used by original Playgrounds. Added that existing option so full numeric forms are not accompanied by duplicate slider controls. Learn visually behavior is retained.
- **UX integration correction:** reused the Phase 13 context disclosure in Playground, replacing unheaded definition-only notes in the input card. This preserves shared content, includes mode notes and keeps primary inputs shorter.
- **INVALID TEST ASSUMPTION:** a new invalid-state loop passed an empty string as the previous substitution after the first invalid edit, then incorrectly matched an empty text editor. Fixed the test to restore a valid state before each invalid case; production validation was not changed.
- A development-time metadata insertion initially targeted Torque's mode instead of its definition and caused compilation failure. It was corrected before the passing full run. This did not alter the mode API or engine. No failed validation run is presented as a pass.

## 9. Regression gates

| Gate | Final result | Evidence |
|---|---|---|
| `flutter test` | **562/562**, exit 0 | `build/phase14-final-tests.log` |
| `dart run tool/test_domain.dart` | **283/283**, exit 0 | `build/phase14-final-domain.log` |
| `dart compile js tool/test_domain_web.dart -o build/phase14-domain.js`; Node | Same **283 closures**, compile and Node exit 0; silent-success runner | `build/phase14-final-js.log`, `build/phase14-final-node.log` |
| `flutter analyze` | **0 issues**, exit 0 | `build/phase14-final-analyze.log` |
| `dart format --output=none --set-exit-if-changed lib test tool` | **143 files, 0 changes**, exit 0 | `build/phase14-final-format.log` |
| `git diff --check` | PASS, exit 0 | `build/phase14-final-diff.log` |
| `flutter build apk --release` | PASS, **52,672,577 bytes**, exit 0 | `build/phase14-final-apk.log` |
| `flutter build appbundle --release` | PASS, **51,366,594 bytes**, exit 0 | `build/phase14-final-aab.log` |

APK SHA-256: `FE8642608A707BD4FA5E8E1A8D141C5EBED79169C49CC4C4EAE08724221FDBAD`.

AAB SHA-256: `DF9708DE1EDE1F7CD326B45EE3FE21255FFC64B3B202A4F0CC955828FB6DBD14`.

The existing CupertinoIcons font warning recurred in the successful APK build. No dependency was added to suppress it. The 21 additional Flutter cases extend behavioral, route/ownership and responsive/accessibility coverage; the purpose is regression protection, not a count target. All previous 541 cases, Phase 11 corrections, Phase 12 numerical checks and Phase 13 context tests remain in the passing run.

## 10. Native acceptance

Runtime: existing `Phase10_API30` AVD under `build/phase10-avd`, serial `emulator-5558`, Android 11 / API 30 / x86_64, 1080×2400 at 420 dpi. Fingerprint: `Android/sdk_phone_x86_64/generic_x86_64:11/RSR1.210722.013.A2/10067904:userdebug/test-keys`. Launched once with no snapshot/window, host GPU and disabled crash reporting. Installed this phase's release APK with `adb install -r`. No SDK/AVD update or compatibility matrix restart; API 37 was not used. Native interaction ran approximately 14:17–14:25 America/Mexico_City (20:17–20:25 in Android's UTC logs).

The existing bounded ADB/UIAutomator helper was adapted under ignored `build/phase14-native.ps1`; each dump has a 20-second limit with no automatic retry. Captures use `build/phase14-api30-*.{xml,png}`. Runtime/launch evidence is under `build/phase14-native-runtime.txt` and `build/phase14-emulator*.log`.

The following filenames have prefix `build/phase14-api30-`. PNG evidence for Newton valid/invalid, updated Torque, Vector 2D/3D and Recents was opened and visually inspected; XML corroborates the actual labels and state. Screenshots are from the release app on Android, not widget renders.

| Required scenario | Outcome | Native evidence |
|---|---|---|
| 1. Newton direct open | **PASS** | `newton-start.{xml,png}`: actual Playground route, mass/acceleration inputs and waiting state. |
| 2. Valid interaction/result | **PASS** | `newton-valid.{xml,png}`: mass 2 kg, acceleration −3 m/s², result −6 N; both arrows point in the negative direction and quantity semantics match. |
| 3. Invalid-input clearing | **PASS** | `newton-invalid.{xml,png}`: mass −1 shows the existing validation error; waiting state replaces result/Copy/scene. Expanded Engineering context remains readable. |
| 4. Torque interaction | **PASS** | `torque-valid.{xml,png}`: 10 N and 0.5 m → 5 N·m; `torque-updated.{xml,png}`: 20 N at the same radius → 10 N·m, with updated force geometry. |
| 5. Vector 2D | **PASS** | `vector-2d.{xml,png}`: x=−3, y=4 → magnitude 5, signed geometry and component semantics. |
| 6. Vector 3D | **PASS** | `vector-3d-zero.{xml,png}`: x=−3, y=4, z=0 → 5; `vector-3d.{xml,png}`: z=−12 → 13, labeled oblique projection. |
| 7. 2D/3D switching | **PASS** | Actual dropdown taps: `vector-mode-menu.xml`, `vector-3d-waiting.xml`, `vector-return-2d-waiting.xml`; both changes clear old fields/result/scene. Refilling 2D gives 5 again (`vector-return-2d.xml`), unaffected by previous z=−12. |
| 8. Direct opening in Recents | **PASS** | After direct opens and an app-process restart to Home, `recents.{xml,png}` shows Vector Magnitude, Torque and Newton’s Second Law once each, in most-recent-first order. Older unrelated Recents remain. |
| 9. Engineering context | **PASS** | `newton-context.{xml,png}` shows expansion; `newton-invalid.{xml,png}` shows both original Phase 13 notes in full, retained without a numeric result. |
| 10. Large text / Reduce Motion | **PASS** for representative native large text | Temporarily set Android font scale to 2.0. `vector-large-{inputs,result,lower,context}.{xml,png}` shows scrollable inputs, wrapped result heading, stable diagram and complete expanded context. Result/lower/context PNGs were visually inspected: no horizontal overflow or permanently clipped text. Both Reduce Motion flags are covered by widget tests; no separate native motion-setting check is claimed. |

Native XML checks are saved in `build/phase14-native-evidence-check.log`; these corroborate specific valid results, invalid-state omissions, mode clearing and Recents. They do not substitute for the visual inspection above.

**Crash/restoration status:** crash buffer empty (**0 bytes**, `build/phase14-final-crash.log`); captured logcat has no `FATAL EXCEPTION`, fatal signal, unhandled Dart exception or ANR marker. It does contain the known API 30 `EGL Error: Success (12288)` diagnostics followed by Impeller/OpenGLES initialization; rendering and interaction succeeded. Full log: `build/phase14-final-logcat.log`. Exit history (`build/phase14-exit-info.txt`) records four `USER REQUESTED` exits matching helper route force-stops, with no recorded crash exit. The app was alive (PID 4879) at final diagnostic collection. No unplanned emulator loss occurred; the task-started emulator was intentionally shut down via `adb emu kill` after acceptance (`build/phase14-emulator-shutdown.log`).

Font scale was restored to its original **1.0**, verified in `build/phase14-original-font-scale.txt` and `build/phase14-restored-font-scale.txt`; the temporary 2.0 readback is `build/phase14-large-font-scale.txt`. No other global accessibility setting was changed. Native captures use the light theme; dark theme, minimum-target/contrast guidelines and both Reduce Motion flags are automated widget evidence. No physical device, spoken screen reader, platform compatibility expansion or FPS claim.

## 11. Scope discipline

Final product: **30 calculators / 44 modes / 8 Learn visually scenes / 6 Interactive Playgrounds / 6 categories**.

No dependency, mathematical engine, ViewModel, unit, result-state, parser, validator, platform code/configuration, package ID, signing or version change. Calculator/mode/scene/category catalogs are unchanged; exactly three existing definitions gain Playground availability. No new persistence, services, state-management packages, backend, navigation section, account, export, history, AI, analytics or distribution feature. No commit, tag or push.

## 12. Product assessment

**Yes:** the three experiences add immediate exploration of trusted relationships while preserving one authoritative report. Signed acceleration makes Newton's axial direction visible; force/radius edits expose the perpendicular torque model's proportionality; actual 2D/3D modes connect vector components to magnitude without a new mathematical path. The existing numeric-entry interaction, shared diagram and optional reasoning/context keep complexity proportional to user value.

Remaining limits are deliberate: blank direct opens require initial numeric entry; phone users scroll between inputs and larger scenes; mode switches clear inputs rather than retaining a comparison state. Geometry is illustrative and 3D is a labeled projection. There is no continuous motion model, arbitrary torque angle, vector operation expansion, or user-study evidence. Audible assistive technology and physical-device performance remain unverified.
