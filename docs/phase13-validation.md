# Phase 13 — Engineering context & model applicability

**Final status: PASS.** Implementation, automated regression and representative native acceptance completed. The native gate was completed on the existing API 30 emulator on 2026-09-28; see **Native acceptance completion** below. Earlier API 37 failures are retained as historical evidence, not a current acceptance blocker.

## 1. Baseline

2026-09-28, starting HEAD `e27f9c42c482a619b4d595bd14620371946c84ec` with the completed Phase 10–12 work already uncommitted: 18 modified tracked files and 13 untracked reports/tests. Preserved starting tracked patch in `build/phase13-preexisting.patch` and SHA-256 hashes of every starting lib/test/tool/docs file in `build/phase13-start-hashes.json`. These previous changes are not Phase 13 changes.

Before production edits: Flutter **532/532** passed (`build/phase13-baseline-flutter.log`); pure Dart **283/283** passed (`build/phase13-baseline-domain.log`). The unchanged baseline also completed JS/Node (same 283 closures, silent success, exit 0), analyzer (0 issues) and formatter (140 files, 0 changes); logs use `build/phase13-baseline-*`. These remaining gates were launched before edits. An initial sandboxed Flutter launcher could not acquire its SDK cache lock and produced no test output; it was interrupted, then run with SDK access. This was not an incomplete test-suite run. The elevated baseline git invocation did not recognize the repository (exit 129); the normal workspace `git diff --check` succeeded (exit 0) after edits. A fresh pre-edit diff gate is therefore not claimed; Phase 12's recorded gate was clean.

Inspected CalculatorDefinition, CalculatorMode, numericMode, all 30 definitions/44 modes, their engines/validation/units, result and Copy presentation, CalculatorScreen, Playground disclosure, visual entry points, theme tokens, Reduce Motion handling and existing accessibility/scaling tests before production edits. Existing `CalculatorDefinition.assumptions` is already an immutable string list, rendered above inputs; it naturally holds this content. Playground already uses GlassCard + ExpansionTile with no animation.

## 2. Architecture decision

Retain `CalculatorDefinition.assumptions` for shared model notes. Add an immutable `CalculatorMode.assumptions` list for genuinely mode-specific notes, passed through numericMode as descriptive data. Display definition notes followed by current-mode notes, with no resolver, second registry, service or new content class. Shared modes read the same definition list. No notes enter calculation, validation, formatting, substitution, Copy or result state.

## 3. Content audit matrix

All definitions were reviewed against their actual solver, input validation, SI normalization, result explanation and available units. A = useful context surfaced; B = intentionally omitted. “Retained” means existing useful assumptions moved to the new disclosure without unnecessary new wording. Each mode is named below; grouped modes share one immutable definition list, not copied strings. There are **30 calculators / 44 modes**: **39 modes with context, 5 intentionally without**. This is a relevance decision, not a coverage quota.

| Calculator | Mode IDs | Decision and content | Reason / sharing |
|---|---|---|---|
| Ohm’s Law | current, voltage, resistance | A — added | Constant ohmic resistance, operating conditions, passive polarity, omitted heating/nonlinearity/reactance; one shared list for all 3 |
| Electrical Power DC | power, voltage, current | A — expanded | DC and passive absorption/delivery convention; no AC power-factor claim; shared by all 3 |
| Electrical Energy | energy | A — expanded | Constant nonnegative power over duration; energy versus power, no tariff prediction |
| Series Resistance | series | A — retained | Ideal series connection, zero permitted, negative resistance excluded |
| Parallel Resistance | parallel | A — retained | Ideal branches, positive resistances, shorts outside this input model |
| Voltage Divider | output | A — expanded | Unloaded R2 output, resistor ratio, source/load/tolerance effects omitted |
| Newton’s Second Law | force | A — added | Constant mass, inertial frame, net axial force; individual forces not solved |
| Torque | torque | A — retained | Perpendicular force and torque magnitude, not arbitrary angle/direction |
| Work | work | A — retained | Constant parallel force, signed opposition to displacement |
| Mechanical Power | power | A — retained | Interval-average work rate, not instantaneous power |
| Kinetic Energy | energy | A — retained | Classical translational motion, nonrelativistic applicability |
| Momentum | momentum | A — retained | Classical, signed one-axis momentum |
| Reynolds Number | reynolds | A — added | Appropriate characteristic length/speed and flow-condition properties; geometry-dependent interpretation, no universal threshold |
| Volumetric Flow Rate | flow | A — retained | Mean normal velocity and signed flow direction |
| Circular Pipe Flow | flow | A — expanded | Full internal circular area, mean axial velocity, no pressure-drop/friction solver |
| Hydrostatic Pressure | pressure | A — expanded | Static constant-density fluid, fixed standard gravity, downward surface-relative depth; pressure increase excludes surface pressure |
| Bernoulli — Basic | pressure2 | A — expanded | Steady incompressible inviscid streamline, omitted machinery/losses, consistent pressure/elevation references, no cavitation feasibility check |
| Ideal Gas Law | pressure, volume, amount, temperature | A — added | One equilibrium ideal-gas state, positive absolute variables, real-gas/condensation omissions, state relation versus process; shared by all 4 |
| Sensible Heat | heat | A — retained | Constant specific heat, no phase change, temperature intervals |
| Thermal Efficiency | efficiency | A — expanded | Heat-engine ratio in [0,1], not COP; same cycle/interval and no feasibility/Carnot calculation |
| Temperature Converter | temperature | A — retained | Absolute temperature versus interval is a useful interpretation trap despite the simple conversion |
| Linear Thermal Expansion | expansion | A — expanded | Constant coefficient over interval, small strain, signed interval/coefficient, omitted phase change and restraint stresses |
| Percentage Calculator | of | B — omitted | Basic scaling already fully explained by formula/result; no physical applicability claim needed |
| Percentage Calculator | change | A — moved and expanded | Signed nonzero baseline and percentage-point distinction; mode-specific |
| Percentage Calculator | ratio | A — added | Same-unit nonzero whole, signed/unbounded ratio, no subset constraint; mode-specific |
| Pythagorean Theorem | c, a, b | A — retained | Positive nondegenerate right triangle, c is hypotenuse; shared by all 3 |
| Vector Magnitude | 2d, 3d | A — retained | Orthogonal axes, common unit; UI accepts unitless numbers and does not perform component unit conversion; shared by both |
| Quadratic Equation | roots | A — expanded | Real coefficients, nonzero a, floating-point range and sensitivity near repeated roots; no new branch/tolerance rule |
| IPv4 / CIDR Subnet | subnet | A — added | Prefix-dependent host conventions, arithmetic versus address assignability/routing |
| Binary / Decimal IPv4 | binary, decimal | B — omitted | Exact representation conversion already explained by octets/bits and input hints; no model assumptions to add |
| Subnet Mask ↔ CIDR | prefix, mask | B — omitted | Contiguous mask convention is already explicit in description, formula, explanation and validation |
| Wildcard Mask | wildcard | A — retained | Contiguous subnet-mask inversion differs from arbitrary ACL wildcards |

## 4. Implemented UX

One **Engineering context** disclosure, subtitled **Model assumptions and limitations**, appears after the result/formula and existing Learn visually / Explore interactively actions. It is closed initially, so assumptions no longer push the inputs downward. The result retains its existing automatic scroll into view. A user can calculate, copy or open a scene without expanding anything.

The existing GlassCard and Material ExpansionTile supply typography, colors, focus, touch behavior and reading order. No fixed-height text, nested scrolling, extra animation, preference or persistence was introduced. A mode-specific key resets disclosure on mode changes; notes always come directly from the current definition and mode. Empty lists render neither the card nor its spacing. Editing inputs keeps expanded static notes available while the existing ViewModel clears the report, substitution, Copy and visual model. Playground keeps its existing presentation and calculation path; its existing shared-assumption display naturally receives the richer definition notes.

## 5. Technical content examples

Representative final UI wording (selective excerpts):

- Voltage Divider: “The resistor ratio sets the ideal output. A connected load, source resistance and resistor tolerances can change it; these effects are not included.”
- Ideal Gas: “Pressure is absolute, not gauge; temperature is absolute and converted to kelvin. Pressure, volume, amount and temperature must all be positive.”
- Bernoulli: “Pressure, kinetic and elevation terms exchange along the streamline. Use one elevation datum for both stations; the result does not check cavitation or whether the assumed flow can be sustained.”
- Reynolds: “For full circular pipe flow, use mean speed and internal diameter. Other geometries require their own length and speed conventions; there is no universal laminar/turbulent threshold.”
- Linear Expansion: “Use a coefficient appropriate to the material and entered temperature interval. ΔT is final minus initial temperature; phase changes, varying coefficients and restraint stresses are outside the model.”
- IPv4: “Counts use the traditional network/broadcast exclusions for /0–/30, both endpoints for /31 point-to-point links, and one address for /32.”
- Percentage change: “Compare quantities in the same units. A change between two percentages is relative change here, not a difference in percentage points.”
- Quadratic: “Roots close to a repeated root can be sensitive to small coefficient changes. A supported numeric result describes the entered polynomial, not measurement uncertainty; some extreme ranges cannot be resolved.”

The implementation is the source of truth. Supporting checks used [OpenStax's Bernoulli treatment](https://openstax.org/books/university-physics-volume-1/pages/14-6-bernoullis-equation), [OpenStax's linear-expansion treatment](https://openstax.org/books/university-physics-volume-2/pages/1-3-thermal-expansion), and [RFC 3021](https://www.rfc-editor.org/info/rfc3021/). No universal Reynolds threshold, pressure/temperature validity cutoff, material lookup or certification claim was added.

## 6. Defects discovered

CONTENT C1: Percentage Calculator currently shows “Percentage change divides by the signed initial value, which must be nonzero” above inputs in all three modes, although `of` has no initial value and accepts zero operands. Move that note to `change`, explain its negative-baseline interpretation there, and give `ratio` its own denominator context. No mathematical correction is needed.

No new BLOCKER, MAJOR, MINOR or mathematical defect was reproduced. The existing numerical limitations remain as documented in Phase 12. Test implementation issues were corrected locally: a missing Preferences import, an INVALID TEST ASSUMPTION that the semantics dump would contain the action word “Expand” (Flutter exposes the state “Collapsed” plus a tap action), and SemanticsHandle teardown that needed to run in try/finally before Flutter's end-of-test verification. These did not require a production workaround or relaxed numerical tolerance.

**Historical validation blocker (environment; native gate now completed on API 30):** the API 37 emulator exited during the initial native smoke and disappeared from ADB, including after a bounded recovery. Its first log reported hanging QEMU main-loop/CPU threads. This is not classified as an app defect; the second exit's cause was not established. The completion section records the successful alternative runtime and the limits of attribution.

## 7. Accessibility

The new behavioral tests exercise actual Material semantic nodes: a labeled tap action and **Collapsed/Expanded** state hints, rather than duplicating semantics around the control. Android's existing ExpansionTile implementation also provides a state live region. Tab traversal reaches the disclosure; Enter expands and Space collapses it. Labeled-target and Android minimum-touch-target guidelines pass. Notes follow the heading in definition-then-mode reading order.

Long Bernoulli notes were opened and individually scrolled into view at **320×568 logical pixels / 200% text** in both light and dark themes. No layout exception or horizontal overflow occurred; text rectangles stayed within the viewport. The existing theme and 48-pixel control conventions are reused. Both platform disableAnimations and reduceMotion flags were exercised; the panel uses AnimationStyle.noAnimation and leaves no active animation callback. No audible TalkBack or VoiceOver session is claimed.

Additional widget-render captures loaded the existing review fonts and were visually inspected: `build/phase13-review-{light,dark}-{0,1,2}.png`, generated by ignored `build/capture_phase13.dart` (two capture cases passed; `build/phase13-visual-review.log`). They show the long content wrapping within the existing single page scroll in both themes. These are Flutter widget renders, not Android or physical-device screenshots, and do not replace native acceptance.

## 8. Regression status

The full suite passed **541/541**, comprising the unchanged 532 baseline cases and nine purposeful context behavior tests. These cover immutable note ownership; omitted shells; mode-specific replacement; shared gas notes through all four modes; invalid report/scene removal with context retained; semantics/keyboard/targets; long light/dark 200% layouts; and reduced motion.

All 283 pure-domain closures pass on Dart VM and compiled JavaScript/Node. Phase 11/12 engines, units, formatting, validation, result models, ViewModel, visual renderers and numerical test files are byte-identical to the captured starting hashes. Compensated quadratic discriminants, exact branching, stable q, conservative range failures, Bernoulli term checks/compensated summation, unit equivalence, inverse modes, networking exactness, affine cycles, near-equal operands and invalid/nonfinite input gates remain intact. No tolerance changed. All eight scenes and three Playgrounds remain in the passing full suite.

Neither the baseline full run nor the final full run had “did not complete” Playground cases. The focused test failures above were identified and corrected before the full run; they were not hidden by unchanged repeated reruns.

## 9. Validation gates

| Gate | Result / evidence |
|---|---|
| flutter test | **541/541**, exit 0; `build/phase13-final-tests.log` |
| flutter analyze | **0 issues**, exit 0; `build/phase13-final-analyze.log` |
| dart format --output=none --set-exit-if-changed lib test tool | **141 files, 0 changes**, exit 0; `build/phase13-final-format.log` |
| dart run tool/test_domain.dart | **283/283**, exit 0; `build/phase13-final-domain.log` |
| dart compile js tool/test_domain_web.dart -o build/phase13-domain.js; node build/phase13-domain.js | Same **283 closures**, compile and Node exit 0; silent-success runner; `build/phase13-final-js.log`, `build/phase13-final-node.log` |
| git diff --check | Workspace invocation exit 0; `build/phase13-final-diff.log` |
| flutter build apk --release | Passed, **52,672,577 bytes**; `build/phase13-final-apk.log`, `build/app/outputs/flutter-apk/app-release.apk` |
| flutter build appbundle --release | Passed, **51,366,186 bytes**; `build/phase13-final-aab.log`, `build/app/outputs/bundle/release/app-release.aab` |
| Bounded native Android smoke | **PASS**, all seven representative scenarios on existing Phase10_API30, Android 11 / API 30 / x86_64; see Native acceptance completion |

SHA-256: APK `E121A11C7F3478CF6737E00CB2473D2D15A40B2BB8E6FF46225B426E8EAD2A0A`; AAB `BAC0BCE15AFB9A73AC4D140BFD54BADE15EBCA5F058D773EE5C991006FE468B8`. The existing SDK-origin CupertinoIcons warning recurred during the successful APK build. No package/signing configuration changed.

### Initial bounded native attempt (historical; superseded by completion below)

The new APK installed successfully on the existing **Pixel_7 / API 37 / x86_64 / 16,384-byte pages** emulator. Opening `/calculator/ohms-law` succeeded. A validated UIAutomator XML capture (`build/phase13-api37-ohm-start.xml`) showed the existing mode selector, inputs and Calculate control, with the former assumptions block absent above the form. An initial null-root snapshot was retried by the existing bounded helper and produced that valid XML.

During the subsequent input/result attempt, UIAutomator stalled, ADB reported offline/not found, and the emulator process exited. `build/phase13-emulator.log` records hanging QEMU main-loop and CPU threads. Recovery used software rendering, two cores and no snapshots. That startup first stopped at a prior-crash consent dialog; the documented `-no-metrics -crash-report-mode disabled` flags bypassed it without sending a report. The recovered emulator booted and accepted the calculator launch, then again disappeared during UIAutomator capture. Logs: `build/phase13-emulator-recovery*.log`, `build/phase13-emulator-recovered*.log`; helper: `build/phase13-native.ps1`. No emulator update, AVD deletion, app-code workaround or further retry loop was performed.

| Requested native scenario | Evidence / gap at the initial API 37 attempt |
|---|---|
| Simple calculator | Ohm initial screen verified; completed result/context interaction still pending |
| Substantial physical assumptions | Native Bernoulli/gas disclosure pending; widget behavior and long-content rendering passed |
| Mode switching | Native pending; percentage and all four gas modes passed widget tests |
| Invalid input with retained context | Native pending; report/substitution/Copy/scene removal and retained expanded notes passed widget test |
| Learn visually | Native pending; new divider transition and existing eight-scene regression suite passed |
| Calculator without context | Native pending; both IPv4 representation and subnet-mask modes tested without an empty shell |
| Large text / long context | Native pending; 320px / 200% light/dark widget tests and captures passed |

At that initial attempt, no completed native result, native expanded-context screenshot, native crash-buffer clearance or full native pass could be claimed. The subsequent API 30 completion below closes those acceptance gaps. No physical-device run or audible TalkBack is claimed in either attempt.

## 10. Scope discipline

No dependency, mathematical engine, ViewModel, result-state, unit, formatting, platform configuration, package identity, signing or feature-catalog change. No new calculator/mode/scene/Playground/category: **30 / 44 / 8 / 3 / 6**. No backend, CMS, AI, service, localization expansion or persistence. Existing version 0.2.0/code 2, application identity and internal signing remain unchanged. No publication or physical-device evidence is claimed.

## 11. Product assessment

**Yes, within the existing models.** The calculator now offers concise, discoverable assumptions and limitations alongside its result without requiring an engineer to read them before calculating. Students can distinguish absolute from gauge pressure, mean from centreline velocity, net from applied force, and arithmetic host counts from assignable addresses. Mode-specific percentage notes no longer explain the wrong operation.

Remaining content gaps are deliberate: users must supply appropriate properties and geometry; the app does not certify physical applicability, estimate measurement uncertainty or test feasibility. The disclosure requires discovery below the result/actions, especially on long forms. No user study or audible assistive-technology assessment has been performed. Binary64 limitations and previously deferred platform/distribution items from Phase 12 remain. The native gate is now complete on API 30; the old API 37 environment failure's exact cause remains undetermined. This phase improves explanation of the supported models, not the models' reach.

## Native acceptance completion

Completed 2026-09-28, approximately 19:31–19:42 America/Mexico_City (Android logcat uses UTC, 2026-09-29 01:31–01:42). This was bounded completion of Phase 13, not a new product phase or a repeat Android compatibility campaign.

### Runtime and artifact

- **Emulator**, existing `Phase10_API30` AVD under `build/phase10-avd/`, serial `emulator-5558`. Android 11, API **30**, **x86_64**, 4,096-byte pages, 1080×2400 physical pixels at 420 dpi.
- Fingerprint: `Android/sdk_phone_x86_64/generic_x86_64:11/RSR1.210722.013.A2/10067904:userdebug/test-keys`.
- Used the exact existing Phase 13 release APK, installed with `adb install -r`. Both APK and AAB SHA-256 hashes were rechecked and match §9. Installed package evidence: `build/phase13-completion-package.txt`; runtime evidence: `build/phase13-completion-runtime.txt`.
- One API 30 launch, using the existing AVD with `-no-snapshot -no-window -gpu host -no-boot-anim -no-metrics -crash-report-mode disabled`. The process was retained in a live command session so its exit status could be recorded. No AVD, SDK image, dependency, app platform setting or signing configuration was created, updated or deleted.
- No physical Android device was available in the initial ADB inventory. The phase-10 API 24 AVD was also found but did not need to be started. Another API 37 emulator registered on `emulator-5554` after initial enumeration; no completion commands targeted or stopped it. All acceptance operations explicitly targeted `emulator-5558`.

### Diagnostic classification

**E — unable to determine the exact cause of the previous API 37 loss within the bounded investigation.** Historical QEMU hangs establish a runtime failure but do not establish whether Engineering Toolkit or UIAutomator triggered it. No new API 37 retry campaign was needed once the previously available API 30 runtime proved stable. No application-triggered crash (C) or reproducible application UI defect (D) was found. UIAutomator did not destabilize API 30 in the exercised sequence; this does not prove that it was unrelated to the earlier API 37 failure.

The following progressive observations separated the running app from capture tooling before the acceptance flows:

| Stage | Observation and evidence |
|---|---|
| Boot / launcher without Toolkit | One probe occurred before `sys.boot_completed` and before Android activity/input services were ready; those commands reported missing services. After boot completed, Toolkit was explicitly stopped, Home opened, and the launcher remained stable for **55 seconds**. ADB stayed `device`; launcher PID 1145. No app failure was inferred from the premature boot probe. |
| Toolkit launched, left idle | Ohm remained idle for **59 seconds**. App PID **2195** and ADB `device` were unchanged; crash buffer empty. |
| Normal interaction without UIAutomator | Screenshot plus `adb input` entered **12 V / 6 Ω**, pressed Calculate and displayed **2 A**. PID stayed 2195; crash buffer empty. The result screenshot predates the first UIAutomator call. |
| UIAutomator / capture | One bounded dump (20-second cap, no automatic retry) completed with fresh XML; ADB and PID 2195 remained unchanged. Subsequent scenario dumps and screenshots also completed without an emulator loss. |

Timestamps/PIDs: `build/phase13-completion-diagnostic.log`. Boot and idle logs: `build/phase13-completion-boot-logcat.log`, `build/phase13-completion-app-idle-logcat.log`. Stage crash buffers: `build/phase13-completion-{launcher,app-idle,interaction,capture}-crash.log`. Emulator logs: `build/phase13-completion-emulator.log` and `build/phase13-completion-emulator-error.log`. The small existing smoke helper was adapted under ignored `build/phase13-completion-native.ps1`; no automation framework or package was added.

### Required scenarios

All evidence filenames in this table have prefix **`build/phase13-completion-api30-`**. Each `.png` listed was captured from Android; the screenshots used to assess layout were opened and visually inspected. XML captures corroborate the visible labels/state, rather than substituting for visual inspection.

| Scenario | Outcome | Concrete native evidence |
|---|---|---|
| 1. Simple calculator | **PASS** | Ohm opened, accepted 12 V and 6 Ω, displayed 2 A with formula/substitution/Copy. Engineering context was visible after the result, expanded, and showed both notes without visible layout corruption. `ohm-idle.png`, `ohm-result-before-uiautomator.png`, `ohm-result.xml`, `ohm-context.{png,xml}`. |
| 2. Substantial physical context | **PASS** | Ideal Gas with n=1 mol, T=300 K, V=0.025 m³ displayed **99773.551418 Pa**. All three context paragraphs were visible at ordinary scale, wrapping within the card; no horizontal overflow or clipped paragraph was observed. `gas-result.{png,xml}`, `gas-context.{png,xml}`. |
| 3. Mode switching | **PASS** | Percentage `change` showed signed-baseline/percentage-point notes. Switching to `ratio` replaced them with the nonzero-whole note. Returning to `of` removed the entire context shell. `percentage-change-context.{png,xml}`, `percentage-ratio-context.{png,xml}`, `percentage-of-no-context.{png,xml}`. Saved XML checks confirm the ratio note and absence of the old signed-initial note. |
| 4. Invalid-input transition | **PASS** | After a valid gas result and expanded context, returned from the visual sheet and cleared amount. The main report, substitution and Copy disappeared immediately; Learn visually became disabled and valid-input guidance appeared. Calculate showed “Enter a value.” The context remained expanded with its three static notes. `gas-incomplete.{png,xml}`, `gas-invalid-error.xml`, `gas-invalid-context.{png,xml}`. Saved XML has no previous pressure, Copy, Substitution or gas visualization summary; Learn visually is `enabled=false`, `clickable=false`. The native edit was made in the main form after closing the visual sheet; dynamic invalidation of an already-open sheet remains covered by the existing widget regression, not misrepresented as a native action. |
| 5. Learn visually coexistence | **PASS** | Opened Learn visually from gas with context expanded; the piston scene and calculated pressure both retained **99773.551418 Pa**, matching the report. Pause and close controls worked, and the main inputs retained 1, 300 and 0.025. `gas-visual.{png,xml}`, `gas-visual-inputs.xml`, `gas-return-inputs.xml`. |
| 6. Calculator without context | **PASS** | IPv4 Representation's native page ends with its formula card and normal page padding; no empty context card/header or added context gap. `ipv4-no-context.{png,xml}`. The returning Percentage `of` state also has no shell. |
| 7. Large / long content | **PASS** | Temporarily set Android `font_scale=2.0`, opened gas context, and scrolled from its wrapped heading through all paragraphs and the visible end of the final paragraph/card. No horizontal overflow or permanently clipped note was visible. `gas-large-context-{top,middle,end}.{png,xml}`. This is native light-theme evidence; detailed 320px light/dark scaling and semantic traversal remain covered by the existing Flutter tests. |

Native XML assertions are recorded in `build/phase13-completion-evidence-check.log`. They check the invalid-state omissions, disabled Learn visually control, mode-note replacement, and absent shells; they do not assert every paragraph's exact wording.

### Crash status, restoration and scope

The final Android crash buffer is **empty (0 bytes)**: `build/phase13-completion-final-crash.log`. The captured app-session logcat contains no `FATAL EXCEPTION`, fatal signal, unhandled Dart exception or ANR marker. It does contain the previously documented API 30 **`EGL Error: Success (12288)`** diagnostics followed by Impeller/OpenGLES initialization; native rendering and interactions succeeded. This is not a claim that logcat is free of all errors. Full evidence: `build/phase13-completion-final-logcat.log`; filtered review: `build/phase13-completion-logcat-review.log`.

Android process-exit history reports four exits with **reason 10 (USER REQUESTED)**, matching the helper's explicit force-stop/route changes, with no crash exit in the captured history: `build/phase13-completion-exit-info.txt`. The app was alive at final evidence collection. The task-owned API 30 emulator was then shut down intentionally via `adb emu kill`; its retained launcher returned **exit 0** (`build/phase13-completion-emulator-exit.log`). No unplanned API 30 exit occurred.

Font scale was initially absent/default. After the 2.0 check its override was deleted; Android materialized the effective default **1.0**, confirmed by a readback. The temporary screen timeout was restored to its original **2147483647**. Before/after evidence: `build/phase13-completion-{original,restored}-font-scale.txt`, `build/phase13-completion-large-font-scale.txt`, and `build/phase13-completion-{original,restored}-screen-timeout.txt`. No physical-device testing or audible TalkBack/VoiceOver is claimed.

**No production or test-source changes were required.** Start/end SHA-256 comparison found zero changed files in `lib`, `test`, `tool` and the inspected Android files (`build/phase13-native-completion-start-hashes.json`, `build/phase13-completion-source-verification.log`). Only this report and ignored diagnostic/capture artifacts were changed or added during completion. The previously passing **541 Flutter / 283 Dart / same 283 JS closures**, analyzer and formatter gates remain the applicable regression evidence; they were verified from their existing logs rather than rerun without a code change. Existing release APK/AAB hashes were verified again. `git diff --check` was run for the report update; no numerical tolerance or product scope changed.

### PASS

Implementation, automated regression and representative native acceptance completed. All seven requested native scenarios passed on the existing API 30 emulator. **Phase 13 is closed with PASS**; no outstanding application defect or native acceptance scenario remains. The historical API 37 root cause is still undetermined and is not generalized into an application defect or a promise of universal runtime stability.
