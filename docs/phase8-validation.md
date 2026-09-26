# Phase 8 — Interactive Playground Pilot

## Alcance y arquitectura

Exactamente tres pilotos opt-in: Voltage Divider, IPv4/CIDR e Ideal Gas. Siguen existiendo 30 calculadoras y ocho escenas Learn visually. Sin dependencias nuevas ni cambios de fórmulas/motores. [Interactive Playground Architecture](architecture.md#interactive-playground-architecture) describe el contrato implementado.

Ruta `/playground/:calculatorId`, shell de presentación compartida y un único CalculatorViewModel. Se presta el VM del formulario ordinario; volver/reabrir conserva cambios. Un enlace directo tiene VM local y al salir abre un formulario normal nuevo. El registro resuelve capacidades e IDs, sin registro paralelo ni estado global. La entrada calcula texto pendiente mediante el pipeline original.

Los campos manuales mantienen precisión y rango del dominio. Divisor: Vin/R1/R2, unidades y Vout. IPv4: dirección textual y prefijo entero 0–32, reporte estructurado y 32 bits. Gas: Pressure/Volume/Amount/Temperature; el mecanismo existente limpia estado al cambiar objetivo y muestra las tres entradas correspondientes. Resultado, fórmula, sustitución, explicación y modelo visual reciben el mismo CalculationResult.

Política B: edición incompleta/inválida elimina resultado/sustitución/escena, muestra validación existente y espera. La fórmula del modo sigue accesible. El parser rechaza texto intermedio antes del solver, sin resultado fabricado o NaN/Infinity. Recuperarse produce un reporte nuevo.

## Pruebas y calidad

- Baseline comprobado antes de implementar: 459 tests Flutter.
- Suite final: 482/482 (459 anteriores + 23 nuevos). Incluye catálogo, capacidades, rutas, VM compartido/propio, vuelta/reapertura, Learn visually, sincronización por identidad del reporte, valores extremos, edición rápida, errores y recuperación.
- IPv4: /0, /24, /25, /31, /32, dirección válida/incompleta, sin broadcast ficticio en /31 y /32.
- Gas: dos ciclos por cuatro modos, cambios de unidades (°C/L), límites absolutos, roles sin valores antiguos, un clock, pausa, ambas señales de movimiento reducido, lifecycle y disposición sin callbacks pendientes.
- Teclado: Tab entre dirección/prefijo, edición de /32, expansión con Enter, selección de modo/unidad con flechas/Enter. Las pruebas previas conservan navegación y controles de las ocho escenas.
- Semántica, targets y contraste en claro/oscuro; 320×640, 430×932, 1024×768 al 200%, más tablet al 100%. Sin overflow. A texto grande vuelve a una columna.
- 247/247 casos Dart puro; el mismo conjunto compilado a JavaScript y ejecutado con Node termina con código 0 (el runner web no imprime un resumen).
- Analyzer: 0 incidencias. Formato: 128 archivos, 0 cambios. `git diff --check`: limpio. APK Android debug compilado. `pubspec.yaml`/`pubspec.lock` intactos.
- Capturas estáticas de revisión generadas con `flutter test tool/capture_phase8.dart --update-goldens`: teléfono claro y tablet oscura. No son goldens versionados ni pruebas de animación por frame.

Evidencia local regenerable: `build/phase8-baseline.log`, `phase8-tests.log`, `phase8-focused.log`, `phase8-domain-dart.log`, `phase8-domain-compile.log`, `phase8-domain-node.log`, `phase8-analyze.log`, `phase8-format.log`, `phase8-apk.log`, `phase8-phone.png`, `phase8-tablet.png`.

## Rendimiento

Cálculo síncrono directo, sin debounce/scheduler ni pipeline async. Una ráfaga de 20 cambios genera 20 notificaciones del VM. En Ideal Gas los ticks cambian el clock y repintan el canvas, pero conservan identidad de los widgets de campos, resumen y detalles, sin notificaciones del VM ni recálculos. Un solo controller del renderer usa VisualAnimationLifecycle, compartido únicamente con Reynolds. Sin medición de fps o perfil en dispositivo físico.

## Revisión de arquitectura

1. **¿Reutiliza CalculatorViewModel sin wrapper de dominio?** Sí; PlaygroundContent solo compone UI y mapea el reporte existente.
2. **¿Algún caso necesitó cálculo especial?** No; ni divisor, ni aritmética IPv4, ni ecuaciones de gas se añadieron a presentación.
3. **¿Qué componentes eran realmente reutilizables?** Campos/unidades, selector de modo, resumen/copia, detalles/fórmula/sustitución/explicación y selección del renderer. Se extrajeron tras verificar sus usos repetidos.
4. **¿Se justifica una shell genérica?** Sí para navegación/layout y composición de estos tres pilotos. No justifica un engine genérico.
5. **¿IPv4 reveló supuestos demasiado físicos?** Obliga a conservar entrada textual y prefijo discreto, reporte estructurado y escena estática; la shell no presupone unidades físicas ni animación.
6. **¿Gas reveló supuestos de modo único?** Sí: selector compartido, claves por modo, tres entradas y output explícito. Se reutiliza el reset actual, sin transferir valores ocultos entre modos.
7. **¿Capacidades limpias?** Un bool opcional en CalculatorDefinition; solo tres definiciones lo activan.
8. **¿Registro como fuente primaria?** Sí; router y entry points consultan la definición, sin lista secundaria de IDs de producción.
9. **¿Se puede quitar sin afectar calculadoras normales?** Sí; retirar ruta/acción/capacidad deja el flujo habitual. Edición live y controles ocultables son opt-in; defaults normales se conservan. Las extracciones compartidas no dependen de Playground.
10. **¿Un cuarto piloto sería sencillo?** En principio sí si sus inputs/reporte/renderer encajan; requiere evaluación y tests propios, no activación automática. No se añadió un cuarto.

## Self-review

Se revisaron estado, fórmulas, rebuilds, controles, roles, foco, escala, navegación y capacidades. No hay segundo VM/result state, solver, manager, service locator ni switch de cálculo por ID. Los controllers de texto se limitan al buffer de edición sincronizado con el VM. Se conserva la selección/caret durante escritura live. Los renderers ocultan sus controles redundantes solo en Playground. La ruta raíz evita que la navegación inferior descarte al propietario del VM prestado. Se corrigió una etiqueta semántica duplicada de resultado detectada en Android y se repitieron suite/analyzer/build.

## Deuda y Chrome

Pendientes reales: recorrido hablado con TalkBack, VoiceOver y mediciones físicas. No se confunde inspección del árbol semántico con validación hablada. El runner Chrome conserva su incidencia de bootstrap, fuera de alcance; no se modificó infraestructura. Dart/Node verifica dominio, no renderizado Chrome. No se implementó Phase 9.

## Android smoke y TalkBack

Pixel_7 / emulator-5554, Android 17/API 37, APK debug. Se ejercieron los tres pilotos con teclado y acciones nativas ADB; se inspeccionaron capturas y árboles UI, sin crashes o errores Flutter/AndroidRuntime en el log recogido. Esto no prueba ausencia absoluta de fugas; los tests verifican disposición de tickers.

- **Voltage Divider:** formulario → Explore interactively; 12 V, R1=1000 Ω, R2=2000 Ω → 8 V y circuito concordante. Atrás conserva resultado/sustitución; reapertura conserva las tres entradas.
- **IPv4:** dirección 192.168.1.10 con /0 → 0.0.0.0/0, 4294967296 direcciones y 0/32 bits red/host. Cambio a /32 y dirección 10.20.30.40 → una dirección, 32/0 bits y sin broadcast dirigido. Captura de los cuatro octetos y regreso al formulario.
- **Ideal Gas:** Pressure con 1 mol, 300 K, 0.025 m³ → 99773.551418 Pa; cámara, partículas y P/V/n/T concordantes. Pausa/reanudación real; dos capturas pausadas tienen idéntico canvas. Cambio a Volume limpia campos/reporte; 1 mol, 300 K, 100000 Pa → 0.024943 m³. Remove animations muestra su aviso y dos capturas tienen idéntico canvas. Atrás/reapertura conserva modo Volume y entradas. Ajustes de animación restaurados (animator: ausente; transition/window: 1.0).
- **TalkBack, un intento acotado:** esta vez el servicio enlazó con `touchExplorationEnabled=true` y no apareció el bloqueo previo de notificaciones. Un gesto dejó foco accesible visible sobre Back to calculator en el Playground de gas. No se verificó audio ni un recorrido hablado completo: sigue pendiente. Se restauraron `accessibility_enabled=0` y la ausencia de `enabled_accessibility_services`, y se detuvo TalkBack.

Evidencia local: `build/phase8-native-*.json/png`, `phase8-talkback-service.txt`, `phase8-android-errors.log`. Las capturas funcionales iniciales preceden a la corrección final de etiqueta semántica; suite/analyzer/APK se repitieron después. Se instaló el APK final y se abrió directamente `/playground/ipv4-subnet`: 10.20.30.40/32 mantiene resultado y escena concordantes y muestra una sola etiqueta `Calculated · Subnet` (antes duplicada). Evidencia: `phase8-native-final-semantics.json`. Se confirmaron los cinco ajustes restaurados: accessibility=0, servicios ausentes, animator ausente, transition/window=1.0.
