# Phase 12 — Numerical Robustness & Metamorphic Validation

## Baseline

2026-09-27. Before production edits: 502/502 Flutter tests; 255/255 pure Dart cases; the same 255 cases compiled to JavaScript and completed under Node (exit 0); analyzer 0 issues; formatter clean; git diff --check exit 0. Logs: build/phase12-baseline-*.log. Phase 11 changes were already present and uncommitted; their patch and all starting source hashes were captured in ignored build/phase12-preexisting.patch and build/phase12-start-hashes.json. Existing Phase 10/11 reports are preserved.

Product scope remains 30 calculators, 44 modes, eight scenes, three Playgrounds, six categories. No platform/dependency/publication expansion.

## Findings recorded before production changes

| ID | Classification | Minimized reproduction / observation | Mathematical source of truth and intended response |
|---|---|---|---|
| N1 | MAJOR | Quadratic a=1+2^-27, b=2, c=1−2^-27 reports a repeated root. Also a=1+2^-26,b=2,c=1−2^-26+2^-52 reports repeated. Values are exactly representable dyadic coefficients. Standalone reproduction: build/phase12-probe.dart / .log. | First discriminant is exactly 4×2^-54>0. Second is exactly −4×2^-78<0. Binary power-of-two normalization is correct but rounded products erase their differences. Preserve normalization, stable q formula and exact sign branching; compensate product-rounding error in the discriminant only. No epsilon to declare repeated roots. |
| N2 | MAJOR | Bernoulli P1=0 and P1=1 both return 0 with rho=2,v1=1e8,v2=0,z1=0,z2=1e16/(2g). Standalone probe above. A dyadic minimized pure-domain reproduction uses g=1,rho=2,v1=1,v2=0,z1=0,z2=.5,P1=2^-54: all head terms are exact +1 and −1, but sequential summation loses P1. | Pressure reference translation is linear; the exact minimized answer is P1. Use compensated summation of the existing three pressure terms, without changing the physical equation or renderer. Independently rounded non-dyadic head terms still have conditioning limits. |

The entries above were recorded before Phase 12 production edits. The following sections retain that evidence and record the completed investigation.

### Additional minimized boundaries, recorded before production edits

N1 also has an unsupported discriminant-range case: a=1+2^-52,b=2^-500,c=(1−2^-52)×2^-1002. Its exact D=2^-1104 is positive but below binary64's minimum subnormal; the old solver incorrectly reports repeated. A conservative typed range failure is appropriate when equal nonzero rounded discriminant products are too small to guarantee the multiplication-error compensation (2^-969 bound from the documented Dekker transform). That bound is a representability guard, not a tolerance that redefines D=0. Some extremely tiny genuine repeated-root problems will consequently report unsupported range instead of guessing a branch.

| ID | Classification | Reproduction | Intended response |
|---|---|---|---|
| N3 | MAJOR | Bernoulli P1=0,rho=double.minPositive,g=1. Either v1=1,v2=0,z1=z2=0, or v1=v2=0,z1=.5,z2=0: a nonzero head contribution underflows and is returned as normal zero because the final sum allows cancellation. | Validate the kinetic and potential terms individually with the existing typed range mechanism before permitting cancellation in the sum. Do not silently replace an unsupported nonzero term with zero. |

Standalone evidence: build/phase12-boundary-probe.dart / .log. Cases are explicitly outside representable term/discriminant range; the defect is a successful wrong zero/repeated classification, not lack of arbitrary-precision support.

Test-construction findings: `math.pow(2,500)` with an integer base can overflow Dart's integer result; the deterministic test table now uses floating base `2.0`, as the production normalizer already did. This was INVALID TEST ASSUMPTION, not a solver failure. Likewise arbitrary decimal coefficient scaling can change the encoded polynomial near a multiple root; such families use coefficient-conditioning bounds rather than demanding an identical branch. No tolerance was loosened to mask N1/N2/N3.

Presentation test review: an existing extreme Bernoulli mapper fixture used rho=1e-200 and v2=1e-100, whose nonzero kinetic term underflows. N3 correctly invalidates that fixture; the mapper's finite-success sample now uses rho=1e-100 (kinetic term -5e-301), and the new presentation regression explicitly checks scene/report removal on the unsupported case. New Copy assertions initially assumed it included formula/explanation; existing Copy intentionally contains title, result and substitution. That INVALID TEST ASSUMPTION was corrected; formula/explanation are asserted in the UI separately, with no product behavior change.

## Numerical methodology and comparison policy

The existing pure-Dart case aggregator now includes 28 deterministic property groups, rather than registering each generated input as a separate test. The same closures run in Flutter, Dart VM and compiled JavaScript/Node. No randomness, seed, dependency, second engine, runtime validation framework or symbolic solver was introduced. `test/domain/numerical_checks.dart` supplies only a scale table, outcome/finite checks and a comparison helper with a required explicit relative budget. Failure context identifies the property and inputs; minimized reproductions are permanent regressions.

The nine normalized engineering scales are 1e-12, 1e-9, 1e-6, 1e-3, 1, 1e3, 1e6, 1e9, 1e12. Inputs are selected by each model: gas states stay positive, torque remains a magnitude, efficiency remains within [0,1], expansion uses small strain, and unit families scale only named fields. This is a bounded matrix, not a Cartesian sweep of every double through every field.

Let e=2^-52, binary64 spacing at 1. Comparisons use |actual−expected| <= absolute + relative × max(|actual|,|expected|), with finite checks on both sides. Budgets are conservative operation-count/conditioning allowances for the selected families, not claimed universal error bounds or changes to validation semantics:

| Relationship | Criterion and rationale |
|---|---|
| Integer networking, root kind, valid/invalid classification, dyadic pressure cancellation, exact odd-sign symmetry | Exact equality; no tolerance |
| Ohm/DC inverse modes, percentage share, ordinary vector/ratio operations | 8e relative; a few rounded products/divisions and mode conversions without difficult cancellation |
| Gas round trips, scaling physical products, Reynolds, ordinary Bernoulli reference changes | 16e relative; several rounded arithmetic stages |
| One alternative unit / mixed alternatives | 16e / 32e relative, respectively; independent conversion factors plus calculation. Pythagorean examples use 64e for leg inversion conditioning |
| Thin triangle mode inversion | 8e relative plus 8e c²/missingSide absolute; the inverse derivative amplifies hypotenuse rounding as the missing side shrinks |
| Near-equal dyadic percentage | Exact delta; nearby binary subtraction is exact for these inputs |
| Near-equal Bernoulli speed and Pythagorean leg | 8e relative against an independently expanded 2delta+delta² expression |
| Known quadratic roots | 8e relative plus 32e × (r²+|br|+|c|)/rootGap; residual <=32e × sum of absolute polynomial terms |
| Repeated roots after inexact decimal coefficient scaling | 8sqrt(e) × |r| forward allowance, including imaginary part, because a multiple root has square-root sensitivity to coefficient perturbation. Exact dyadic constructions still require the exact repeated branch |
| Constructed complex roots | 16e real relative; imaginary absolute allowance 16e(u²+v²)/v for coefficients of (x−u)²+v² |
| Absolute temperature cycles | Absolute degree bound 8e(|original|+|intermediate|+273.15+459.67), because offset cancellation makes relative error near zero inappropriate |

The compensation design was checked against primary references: [INRIA's verified Dekker multiplication transform](https://toccata.gitlabpages.inria.fr/toccata/gallery/Dekker.en.html) documents the split and representability preconditions, including the 2^-969 product bound; [Neumaier's 1974 summation paper](https://onlinelibrary.wiley.com/doi/abs/10.1002/zamm.19740540106) provides the compensated-summation basis. The implementation here is regression-tested on VM, JavaScript and Android; it is not a formal verification. [Goldberg's floating-point discussion](https://docs.oracle.com/cd/E19422-01/819-3693/ncg_goldberg.html) supplies background on cancellation and rounding.

## Coverage matrix: all 30 calculators / 44 modes

All 44 modes retain the Phase 11 canonical content/state audit. Every decimal input in the catalog additionally receives missing, malformed, NaN, positive/negative Infinity and overflowing-text rejection tests. The matrix below describes the new properties; it does not imply every property is meaningful for every calculator.

| Calculator(s) | Modes | New mathematical properties and boundary coverage |
|---|---:|---|
| Ohm's Law | 3 | V/I/R round trips, passive signed states, 9×9 scale combinations, alternative units, resistance zero/positive distinctions |
| DC Power | 3 | P/V/I round trips, both independent sign choices, 9×9 scales, units, nonzero signed denominators |
| Ideal Gas | 4 | One state solved for P/V/n/T over 9×9 n/V scales and T=1,300,1e6; units including pressure and volume alternatives; strict-positive boundaries |
| Electrical Energy | 1 | Power homogeneity, seconds/minutes/hours and energy factors, nonnegative boundaries |
| Series Resistance; Parallel Resistance | 1 each | R_eq(kR)=kR_eq, all resistor unit alternatives, zero/nonzero rules, overflow and subnormal output rejection |
| Voltage Divider | 1 | Common positive resistor scaling leaves Vout unchanged, signed input voltage symmetry, units and zero resistor boundaries |
| Newton's Second Law | 1 | Mass scaling, signed acceleration symmetry, gram/kg equivalence, zero mass and overflow |
| Torque | 1 | Radius scaling, units, zero magnitude boundaries; negative force rejected rather than imposing odd symmetry |
| Mechanical Work; Mechanical Power | 1 each | Distance/work scaling, inverse-time scaling, signed force/work symmetry, units and distance/time boundaries |
| Kinetic Energy | 1 | Speed-square homogeneity, mass units, zero/nonnegative speed, unsupported intermediate overflow |
| Momentum | 1 | Mass scaling, odd velocity symmetry, units and zero mass |
| Reynolds Number | 1 | Separate density/speed/length/viscosity scaling, unit alternatives, positive inputs and zero speed |
| Volumetric Flow; Pipe Flow | 1 each | Area and diameter-square homogeneity, signed velocity, units, positive geometry and range failures |
| Hydrostatic Pressure | 1 | Depth homogeneity, units, nonnegative depth/positive density, intermediate overflow |
| Bernoulli — Basic | 1 | Pressure/elevation reference changes, station reversal, units, near-equal speeds, cancellation, individual term range checks, scene/Copy consistency |
| Sensible Heat | 1 | Mass homogeneity, odd temperature interval, units, mass/specific-heat boundaries and range failures |
| Thermal Efficiency | 1 | Common positive work/heat scaling, units, zero and adjacent representable values around 1 |
| Temperature Converter | 1 | All C/F/K affine cycles, absolute zero and its neighbors, separate delta-C/delta-K semantics |
| Linear Expansion | 1 | Length homogeneity, signed coefficient/temperature interval at model-valid small strain, units, positive length, range failure |
| Percentage | 3 | Of/share/change relationships, common signed ratio scaling, near-equal changes, zero denominator and range failures |
| Pythagorean Theorem | 3 | c→a/b recovery including thin triangles, units, c immediately above/equal to leg, near-equal substitution fidelity |
| Vector Magnitude | 2 | Global sign invariance, positive scale homogeneity, component permutation, 2D=3D at z=0 |
| Quadratic Equation | 1 | Repeated/distinct/complex constructions, positive and negative coefficient scaling, residuals, compensated D sign, unsupported D range |
| IPv4/CIDR Subnet | 1 | Exact network mask/alignment/block endpoints/counts at every prefix 0..32, /31 convention |
| IPv4 Representation | 2 | Exact decimal↔binary round trips across representative and walking-bit addresses |
| Subnet Mask ↔ CIDR | 2 | Exact mask↔prefix at all 33 prefixes |
| Wildcard Mask | 1 | Exact mask XOR wildcard equals all 32 ones |

## Unit equivalence and solve-mode round trips

`equivalence_cases.dart` traverses the existing catalog, tests every alternative input unit separately and then combines alternatives in the same problem. Independent literal factor fixtures generate equivalent raw input; they do not reuse the production unit's scale property. Twenty-two calculators are covered by this combined unit-equivalence runner, including the gas temperature alternatives; Temperature Converter receives a separate exhaustive affine-cycle family. Coverage includes milli/kilo/mega electrical units, grams, cm/mm, cm², litres and litre flow rates, minute/hour, kPa/bar/atm and thermal/energy factors. The selected scale fields are explicit per calculator. Conversion-factor and inverse-unit tests supplement the whole-pipeline comparisons so shared conversion errors cannot pass only through self-consistency.

All invertible modes are compared as unformatted domain values. Ohm recovers V and R from I; DC recovers V and I from P; gas recovers each other state variable from computed P. Percentage uses 25% share followed by ratio/change. Pythagorean modes recover both legs for aspect ratios 1, 2^-8 and 2^-20. Vectors are not solve modes: their valid cross-mode relation is 2D=3D with z=0. Networking mode relations are exact representations rather than floating comparisons.

## Sign, scale, boundary and near-equal results

The deterministic groups pass for their supported input families. Signed tests follow each engine's model, including negative voltage/current, acceleration, work, momentum, volume flow, Bernoulli reference pressure/elevation, sensible heat and small-strain expansion. Torque and kinetic-energy speed are magnitudes and retain their negative-input rejection. No new sign convention was invented.

`boundary_cases.dart` exercises negative-minimum-subnormal, zero, minimum-positive-subnormal and 1e-12 around explicit positive/nonnegative input rules. A valid nonzero input may still give a typed numeric-range failure; it must not be reclassified as an invalid sign or epsilon-sized zero. Signed nonzero denominators are tested on both sides. Efficiency includes 0, the minimum subnormal, the predecessor of 1, 1, and the successor of 1. Absolute-zero C/F neighbors are separated by their local 2^-44 spacing; Kelvin includes both signs of the minimum subnormal. Triangle c=1 is rejected with known leg 1; c=1+2^-52 succeeds.

Near-equal families use separations 2^-8, 2^-20, 2^-40 and 2^-52. Percentage delta is exact for the chosen dyadic operands; Pythagorean and Bernoulli differences retain their sign and use the stated local error budgets. Substitution strings contain the actual encoded changed operand at every separation. Thermal models receive delta-temperature directly, so no fictitious subtraction of two absolute temperatures was added; interval signs and unit identity are tested separately from absolute cycles.

## Quadratic stress results

Repeated families use r=-1024,-5,-.125,0,.125,5,1024. Distinct families include (-3,2), (1,2), (-7,-.5), (1e-8,1e8), (1,1+1/4096), and (-2,0). Complex families use u=-5,0,3 and v=.25,2,10 in (x−u)²+v². Global coefficient scales include -8, -.1, 2^-500, .1, 1, 3, 1e-100, 1e100 and 2^500; focused sign regressions also use negative binary scaling. These exercise separated, close, zero, repeated and conjugate roots without requiring an impossible exact branch after inexact coefficient encoding.

The minimized dyadic N1 cases previously returned repeated roots on both sides of D=0. They now return two real roots and conjugate complex roots, respectively, with the analytical roots within 8e. The tiny-discriminant case now returns typed numericRange. Stable q-based roots, binary normalization and exact sign comparisons remain. No epsilon declares a small D to be zero.

## Networking exactness and affine temperature results

Networking uses BigInt and exact checks in VM and JavaScript: every prefix 0..32 is paired with zero/all-one, typical, high-bit boundary and walking-one/walking-zero addresses. Decimal/binary recovery, contiguous mask inversion, XOR wildcard, network bit masking, block alignment, last address, total/usable counts and endpoints pass. /31 and /32 retain their no-broadcast convention; /31 counts both point-to-point endpoints. Existing invalid mask, prefix parser and address tests remain.

Absolute temperature cycles cover absolute zero, negative Celsius, -40 C/F, 0 C, ordinary temperatures, high supported temperatures and all three intermediate unit choices. The explicit affine absolute error allowance handles cancellation near zero. Delta-C and delta-K remain identical signed intervals. Encoding the minimum positive Kelvin value as Celsius loses it to the -273.15 offset; returning zero Kelvin is documented representational loss, not a conversion defect hidden by a relative tolerance.

## Nonfinite behavior, production changes and focused regressions

Before production edits, the expanded pure suite passed 279/283 groups: four groups failed on N1, N2, N3 and N1's unsupported-range branch. The original 255 remained passing. Separate standalone probes and the pre-edit report captured the causes.

Only two production files changed during Phase 12:

- `lib/features/calculators/domain/engines/mathematics.dart`: recover multiplication residuals for the discriminant with a local Dekker helper; guard uncertifiable tiny equal products; retain the existing normalization, q formulation and typed failure API.
- `lib/features/calculators/domain/engines/fluids.dart`: check the two Bernoulli head terms before summation, then compensate the three-term sum locally. Equations, constants, input constraints and result pipeline are unchanged.

No changes to ViewModels, widgets, visual renderers, Playgrounds, dependencies or Android configuration were needed. Comparing starting file hashes confirms that all other production files and the Phase 10/11 reports remain byte-identical. The existing test aggregator includes the four new case collections plus a small numerical helper. One old mapper fixture was made representable as explained above; a new widget file covers both changed engines.

Permanent focused regressions require exact dyadic D branch classification, retained small Bernoulli pressure for both head orders and signed pressure, and typed failures for lost nonzero heads/uncertifiable discriminants. Widget regressions verify distinct/complex roots, coefficient substitution, formula and explanation, actual clipboard result/substitution, edit invalidation and invalid-input recovery. Bernoulli's visual mapper retains the same authoritative CalculationResult; the scene displays P2=1 Pa for the cancellation case, and an unsupported term clears the result and scene. No affected engine has a Playground; the existing three Playground suites remain part of the full regression gate.

Finite-but-extreme examples explicitly require numericRange, including overflowing Ohm/Newton, gas intermediates, series sum, parallel subnormal output, kinetic energy, pipe flow, hydrostatic pressure, sensible heat, percentage subtraction and expansion. NaN/Infinity are never accepted as normal results in these families. There is no clamping, catch-and-hide behavior or substitution of zero for a lost nonzero term.

## Intentionally unsolved numerical limitations

| Classification | Evidence and disposition |
|---|---|
| NUMERICAL LIMITATION / DOCUMENTED | Very thin triangle a=1,b=2^-30 rounds its computed c to 1. The inverse has no remaining information about b and correctly rejects equal c/known leg. |
| NUMERICAL LIMITATION / DOCUMENTED | Decimal scaling of a repeated-root polynomial can perturb the encoded coefficients enough to change its mathematical branch. Conditioning-aware bounds apply to those constructed families; exact dyadic branch tests stay exact. |
| NUMERICAL LIMITATION / DOCUMENTED | Bernoulli compensation preserves the sum of computed head terms; it cannot recover input information or errors already lost while computing each term. Large nearly cancelling physical terms still have poor relative conditioning. |
| NUMERICAL LIMITATION / DOCUMENTED | Binary64 cannot represent arbitrary discriminants or roots. Equal tiny discriminant products below the transform's reliable residual range are conservatively rejected, including some genuine repeated-root equations. |
| NUMERICAL LIMITATION / DOCUMENTED | Intermediate overflow/underflow may reject a problem whose final algebraic result could be representable after a different rearrangement. Examples: KE m=1e308,v=1.8; gas n=1e308,T=300,V=1e308; percentage 1e308→-1e308. These already return typed range failure; no unsupported-range rewrite was justified. |
| NUMERICAL LIMITATION / DOCUMENTED | Affine temperature offsets can erase tiny Kelvin differences, as demonstrated above. Output formatting still uses the established compact precision; it is not an uncertainty/significant-figures guarantee. |
| INVALID TEST ASSUMPTION | Integer-base math.pow generation, identical-branch expectations after inexact scaling, and expecting formula/explanation in the existing Copy payload were corrected in tests, not production. |

No arbitrary precision, universal condition estimator, exact polynomial arithmetic or proof over all binary64 inputs is claimed. Existing physical/model assumptions remain authoritative. Phase 10 deferred platform/accessibility/distribution items are unchanged: API 30 EGL diagnostics, SDK CupertinoIcons warning, earlier JAR streaming diagnostics, generated build-host metadata, Chrome bootstrap, physical/ARM testing, sustained performance/battery/thermal tests, audible TalkBack/VoiceOver, backup/device transfer, production identity/signing and publication. No Phase 13 work is included.

## Final validation gates

| Gate | Result / evidence |
|---|---|
| flutter test | 532/532 passed, including all 28 property groups, Phase 11 regressions, eight visual scenes and three Playgrounds; `build/phase12-final-tests.log` |
| flutter analyze | 0 issues; `build/phase12-final-analyze.log` |
| dart format --output=none --set-exit-if-changed lib test tool | 140 files, 0 changes; `build/phase12-final-format.log` |
| dart run tool/test_domain.dart | 283/283 passed; `build/phase12-final-domain.log` |
| dart compile js tool/test_domain_web.dart -o build/phase12-domain.js; node build/phase12-domain.js | Compiled; same 283 closures completed under Node with exit 0 (silent-success runner); `build/phase12-final-js.log`, `build/phase12-final-node.log` |
| git diff --check | Exit 0; `build/phase12-final-diff.log` |

The first full Flutter attempt ended at 513 completed tests with 19 Playground cases marked “did not complete”, without a specific assertion explaining the interruption. An isolated unchanged Playground rerun passed all 23, then the unchanged complete suite passed all 532. This incomplete attempt is not passing evidence and its cause was not established. The first analyzer run found six missing-brace style notices in new tests; these were fixed without changing test behavior, and the final analyzer/formatter passed. One attempted tool execution was not started because automatic approval review reached its usage limit; after the user's instruction to continue, the same authorized command ran normally. None of these harness/style events was classified as an engine defect.

| Release gate | Result / evidence |
|---|---|
| flutter build apk --release | Passed, 52,607,041 bytes; `build/phase12-final-apk.log`, `build/app/outputs/flutter-apk/app-release.apk` |
| flutter build appbundle --release | Passed, 51,346,664 bytes; `build/phase12-final-aab.log`, `build/app/outputs/bundle/release/app-release.aab` |

SHA-256: APK `7CD9FF2FB86B41890478D49BE33EF52DFA791AD3830325FA362C12B234F94CF0`; AAB `434BE64AA0A9563D8AA46C19A039AD2D5ECE0993E733398BF60AA65021AD9827`.

The existing SDK-origin CupertinoIcons warning recurred during the successful APK build. Artifacts retain version 0.2.0/code 2, application ID `com.engineeringtoolkit.engineering_toolkit`, minSdk 24, targetSdk 36 and the existing internal/debug signing configuration. No publication or fresh bundletool/split-install validation is claimed.

### Bounded API 37 native smoke

The newly built release APK was installed successfully on the existing Pixel_7 emulator: API 37, x86_64, 16,384-byte pages. UIAutomator snapshots use unique remote paths and validate their XML root; screenshots were visually inspected. No API 24/30 matrix or Android configuration changes were needed.

Accepted scenarios:

1. N1 positive dyadic case: a=1.0000000074505806,b=2,c=.9999999925494194 shows x1=-1 and x2=-.9999999850988389, positive-discriminant explanation and precise substituted coefficients. The long second root wraps without clipping. `build/phase12-api37-quadratic-positive.{xml,png}`.
2. Copy on that result shows the native “Result copied” confirmation; `build/phase12-api37-quadratic-copied.xml`. Exact clipboard contents are asserted by widget tests, not inferred from this toast.
3. N1 negative dyadic case: a=1.0000000149011612,b=2,c=.999999985098839 shows conjugates -1 ± 1.818989e-12i with negative-discriminant explanation and precise substitution. `build/phase12-api37-quadratic-negative.{xml,png}`.
4. N1 tiny-discriminant case: a=1.0000000000000002,b=3.054936363499605e-151,c=2.3331590462580467e-302 shows the supported-numeric-range error. The previous complex result and Copy are absent; only the general formula remains. `build/phase12-api37-quadratic-range.{xml,png}`.
5. N2 Bernoulli with P1=1,rho=2,v1=100000000,v2=0,z1=0,z2=509858106488964.1 shows P2=1 Pa (0.001 kPa), matching formula, full substitution and explanation. Copy confirms natively. `build/phase12-api37-bernoulli-cancellation.{xml,png}` and `bernoulli-copied.xml`.
6. Opening Learn visually preserves P2=1 Pa in the scene, station labels and semantic summary, with the same inputs and signed pressure bars. `build/phase12-api37-bernoulli-visual.{xml,png}`. Widget identity assertions verify that the mapper consumes the original report rather than recalculating.
7. N3 Bernoulli after changing rho to 5e-324, v1=1 and z2=0 (P1 remains 1; v2=z1=0) gives the numeric-range error. No prior result or Copy remains, and Learn visually is disabled with its valid-input guidance. `build/phase12-api37-bernoulli-range-inputs.xml` and `bernoulli-range.{xml,png}`.

The native crash buffer is empty (`build/phase12-api37-crash.log`); installed package metadata is in `build/phase12-api37-package.txt`. The task's emulator was stopped after capture. Logs, standalone probes, helper scripts, screenshots and release artifacts stay in ignored `build/`; this is the only new Phase 12 documentation file.

## Final classification and consistency decision

| Classification | Final disposition |
|---|---|
| BLOCKER | None outstanding in the exercised scope |
| MAJOR | N1, N2 and N3 reproduced before edits, corrected locally and covered by permanent regressions; no outstanding reproduced major defect |
| MINOR | No new product defect identified |
| NUMERICAL LIMITATION / DOCUMENTED | Ill-conditioned inversions and coefficients, affine encoding loss, rounded head terms, conservative discriminant guard and unsupported intermediate ranges remain as described above |
| INVALID TEST ASSUMPTION | Incorrect generator/encoding/Copy assumptions were corrected without loosening failure tolerances or changing the product to satisfy the tests |

**Yes, within the supported families and ranges exercised, the engine is internally consistent across equivalent modes, units, legitimate signs, scales and difficult representable inputs after the three fixes.** The original engine did contain actual correctness defects, so the pre-edit baseline alone was insufficient evidence. This conclusion is bounded by the documented binary64 conditioning and range limits; it is not proof for every finite input or an expansion of the idealized engineering models. Unsupported operations fail through existing typed errors rather than normal NaN/Infinity or a fabricated zero/repeated root in the reproduced cases.

Phase 11's five corrections remain protected, and the product remains 30 calculators, 44 modes, eight visual scenes, three Playgrounds and six categories. No new features, dependencies, architecture, platform configuration, public distribution or Phase 13 work was implemented. Phase 12 ends with this report.
