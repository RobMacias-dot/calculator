# Phase 7 — Advanced Animated Scene — Ideal Gas

## Contrato inspeccionado antes de modificar

Se conservan las 30 calculadoras. Ideal Gas añade la octava capacidad visual.
Baseline ejecutado: 426 tests Flutter, 247 casos de dominio Dart, los mismos 247
compilados con dart2js/Node y analyzer sin incidencias. Se preservan los cambios
de Phase 6 que ya estaban presentes en el working tree.

| Modo existente | Entradas | Salida |
| --- | --- | --- |
| `pressure` | n, T, V | P en Pa |
| `volume` | n, T, P | V en m³ |
| `amount` | P, V, T | n en mol |
| `temperature` | P, V, n | T en K |

Unidades existentes: Pa/kPa/bar/atm, m³/L, mol y K/°C. El parser normaliza antes
de validar: todas las cantidades SI son finitas y estrictamente positivas.
Se permite temperatura Celsius negativa por encima de −273.15 °C. No hay un
estado cero válido; el dominio rechaza overflow y underflow del resultado a cero.
No se modifican motores, ecuaciones, modos ni validaciones.

`CalculationResult` contiene valor sin redondear, unidad, texto formateado,
fórmula, sustitución, explicación y advertencias. El callback de contexto de
`numericMode` retiene ahora los tres inputs SI validados y el identificador de
la variable resuelta, después de un cálculo exitoso. No resuelve nada adicional.
`CalculatorViewModel` sigue almacenando strings y unidades seleccionadas;
`updateAndCalculate` actualiza la revisión del formulario y calcula/notifica una
vez por edición. Cambiar de modo limpia entradas/resultado según su contrato previo.

## Advanced Animated Scene — Ideal Gas

`CalculationResult → IdealGasVisualizationMapper → immutable IdealGasVisualizationModel → renderer`.
El mapper toma la variable resuelta directamente de `report.value`; las demás
provienen del contexto validado. Un resultado sintético distinto del valor físico
esperado demuestra en tests que el mapper no recalcula. Las etiquetas presentan
P, V, n, T con unidades SI y marcan la variable calculada; el formulario conserva
fórmula, sustitución y edición manual. El registro sigue siendo la única lista
primaria de capacidades; el switch de modelos únicamente selecciona el renderer.

La cámara rectangular tiene un pistón cuya altura representa el volumen. Para
cualquier estado válido la fracción de cámara permanece entre 0.28 y 0.90.
Las escalas visuales usan `log10(1 + 9 × clamp(value, 0, ceiling) / ceiling)`;
el clamp precede a la división para evitar overflow incluso en valores extremos.
Los techos pedagógicos son 0.1 m³, 5 mol y 1000 K. No son límites de dominio.

La cantidad visual va de **12 a 36 puntos**, con buckets redondeados de la escala
de moles. Mantiene una cámara legible incluso con cantidades pequeñas; al ampliar
volumen sin cambiar n, los mismos puntos se dispersan. La temperatura define una
intensidad entre 0.15 y 1 y un período ilustrativo de 8800 a 2000 ms. Un texto
estático muestra esa intensidad también con movimiento reducido. Saturación,
conteo mínimo y buckets implican que variaciones muy pequeñas/extremas pueden no
cambiar la geometría: los valores numéricos siempre permanecen disponibles.

Posición del pistón, cantidad/velocidad/distribución de puntos son ilustrativas.
Los puntos no representan moléculas individuales. Una tabla inmutable de 36
semillas algebraicas se crea una sola vez, sin `Random()`. Cada posición se deriva
de la fase mediante reflexión triangular; los ciclos enteros hacen continuo el
reinicio del reloj. No hay colisiones físicas, fuerzas ni presión calculada desde
las paredes. El motor existente es el único responsable cuantitativo.

Solo existen controles para las tres entradas del modo. Rangos exploratorios SI:
P 10000–500000 Pa, V 0.001–0.1 m³, n 0.1–5 mol, T 100–1000 K. Son cantidades
positivas de escala educativa; `VisualInputControl` reutiliza `fromBase` para
preservar la unidad elegida. La entrada manual admite el resto del dominio;
un valor fuera del slider no cambia hasta una edición explícita.

## Animación y rendimiento

Sí se justifica extraer `VisualAnimationLifecycle`: Reynolds e Ideal Gas comparten
exactamente pausa manual, ambas señales de Reduce Motion, `TickerMode`, app en
primer plano, intersección con viewport tras scroll/layout y eliminación de
listeners/controlador. El mixin acepta únicamente utilidad y período; no conoce
partículas, gas ni fórmulas. Reemplaza el bloque local de lifecycle de Reynolds.
Reynolds conserva su condición de velocidad cero y su período de cuatro segundos.

Ideal Gas tiene un único `AnimationController`, sin timers ni controladores de
pistón/etiquetas. Cambiar volumen actualiza inmediatamente la geometría. La pausa
solo afecta presentación y persiste durante segundo plano. Cerrar elimina el
controlador; reabrir crea una escena nueva. Reduce Motion detiene todo movimiento
continuo y conserva cámara, pistón, puntos, cantidades, controles y señal térmica.

`CustomPainter(repaint: visualClock)` está dentro del `RepaintBoundary` de
`VisualScene`. Los ticks no reconstruyen widgets ni etiquetas y no notifican al
ViewModel ni calculan resultados; pruebas con contador explícito verifican esto.
Tres paints se construyen por instancia de painter, los rectángulos se cachean por
tamaño y las semillas son compartidas e inmutables. No se asignan listas, paths o
paints por frame; los únicos temporales por punto son `Offset` para Canvas. No hay
blur, sombras, filtros, `saveLayer`, widgets por partícula ni dependencias nuevas.
`shouldRepaint` compara fase, geometría, cantidad y colores.

No se ha medido rendimiento sostenido en hardware físico. La inspección y los
widget tests demuestran aislamiento, no fps físicos ni ausencia total de GC.

## Accesibilidad

Un único nodo semántico resume P/V/n/T, variable calculada y significado del
movimiento. Ninguna partícula es un nodo individual. Los sliders existentes
exponen etiqueta, valor, unidad y teclado; pausa es un botón estándar.
Las etiquetas cuantitativas quedan fuera del canvas, dentro del scroll. Se prueba
320×640 al 200%, ambos temas, contraste, targets y tablet/rotación. Los colores
proceden de `ColorScheme`; no se añaden colores exclusivos de un tema.

## Revisión de arquitectura

1. **Lifecycle compartido:** sí, por duplicación significativa e idéntica semántica;
   API pequeña con utilidad/período, ninguna API de simulación.
2. **Partículas específicas:** sí, tabla y reflexión viven en Ideal Gas.
3. **Sistema genérico de partículas:** no está justificado.
4. **Duplicación de matemática de dominio:** ninguna; solo escalas y coordenadas.
5. **Registro único:** se mantiene la capacidad en la definición original.
6. **Comprensión:** contexto, mapper/modelo, renderer y mixin de lifecycle se pueden
   leer directamente, sin DSL, service locator ni framework.
7. **Eliminación independiente:** se puede retirar la capacidad/contexto/renderer
   visual sin afectar los cuatro cálculos numéricos ni sus tests de dominio.

## Validación final

- **459 tests Flutter:** los 426 anteriores y 33 nuevos de Phase 7.
- **247/247** casos de dominio en Dart y los mismos **247/247** en dart2js/Node.
- Analyzer: **0 issues**. Formato: **123 archivos, 0 cambios** en la verificación.
- APK debug compilado de nuevo tras la corrección final de Reduce Motion.
- Motores y `pubspec.yaml`/`pubspec.lock` sin modificaciones; **0 dependencias nuevas**.
- Dos capturas estáticas generadas por `tool/capture_phase7.dart` y revisadas:
  `build/phase7-gas-normal.png` y `build/phase7-gas-large.png`.

La suite añade tests por modo, resultados sintéticos, SI/Celsius/litros/atm,
valores pequeños/grandes válidos, rechazo de reportes inválidos, límites visuales,
reflexión determinística y continuidad de ciclo, `shouldRepaint`, integración,
teclado, conservación de valores manuales, estados vacíos/errores, pausa y app,
viewport, reapertura, rotación, TickerMode, flags, temas y accesibilidad.
No se duplicó la suite de ecuaciones ni se añadió una suite de goldens animados.

## Autorrevisión

Se reprodujo un fallo de la primitiva previa: `MediaQuery(disableAnimations:
false)` podía ocultar `platformDispatcher.accessibilityFeatures.disableAnimations`
al montar la escena. Dos tests fallaron antes de corregirlo (Ideal Gas/Reynolds).
`reduceVisualMotion` ahora combina ambas fuentes y `reduceMotion` de plataforma;
el observer utiliza ese único helper. El fix también protege la transición modal.
Se acotó el grosor del pistón por tamaño para que viewports diminutos no produzcan
un rectángulo de vástago invertido. La inspección confirmó ausencia de fórmulas
PV/nRT o constante de gas en renderers/mappers, así como de timers, Random sin
seed, paquetes nuevos, service locators y managers de física/partículas.

Solo se actualiza una expectativa previa: la lista de capacidades pasa de siete
a ocho porque Ideal Gas es una incorporación intencional. El resto de los 426
casos previos se conserva. No se implementa Phase 8.


## Android y accesibilidad real

Emulador `emulator-5554`, Pixel_7 x86_64, Android 17/API 37. El primer APK de
Phase 7 permitió búsqueda → Ideal Gas → modo Volume → n=1 mol, T=300 K,
P=100000 Pa → V=0.024943 m³ → Learn visually. Durante la exploración la presión
cambió a 208227.409326 Pa; al ajustar T a 757.608696 K el volumen pasó a
0.030251 m³. Ajustar n a 1.987802 mol produjo V=0.060133 m³. Se observaron las
etiquetas sincronizadas, expansión del pistón y mayor cantidad de puntos.
Se ejercitaron pausa, reanudación, scroll, cierre y reapertura, sin crash observado.
Capturas: `build/phase7-native-gas-initial.png`, `gas-expanded-paused`,
`gas-resumed` y `gas-reopened` bajo el mismo prefijo.

Tras recompilar e instalar el APK final (fix del helper de Reduce Motion), se
recorrió el modo Pressure: n=1 mol, T=300 K, V=0.025 m³ → P=99773.551418 Pa.
Se activaron las tres escalas de animación Android en cero; cambiar solamente
`animator_duration_scale` no activaba la señal Flutter en este emulador. La escena
mostró explícitamente Reduce Motion, conservó datos, puntos y cámara, y retiró
el botón de movimiento. Dos capturas separadas tienen **píxeles idénticos en la
región del canvas**, comparación local de imágenes, no medición de fps.
Evidencia: `build/phase7-native-gas-reduced-final.png` y
`build/phase7-native-gas-reduced-static-second.png`. Se cerró la escena, navegó a
Home, volvió a abrir Ideal Gas y salió de nuevo, sin error observado.

**TalkBack sigue pendiente.** Se activó TalkBack 17.0.0.889642762;
`dumpsys accessibility` confirmó servicio enlazado, feedback hablado y exploración
táctil. Volvió a aparecer el permiso inicial de notificaciones de Android
Accessibility Suite. Un intento mediante el control “Don’t allow” y teclado no
permitió descartarlo de forma fiable. Se detuvo el intento y se restauraron
`accessibility_enabled=0` y la ausencia original de servicios habilitados; se
cerró TalkBack. Captura `build/phase7-native-talkback-attempt.png`.
No se validó audio hablado ni recorrido con lector de pantalla. Los árboles
semánticos y tests no se presentan como sustituto de esa validación.

La automatización local tuvo un intento fallido de entrada por timing del teclado
al desactivar animaciones; se añadió espera breve al script temporal ADB y se
repitió el caso. No exigió modificar código de producto.

**Reynolds con el APK final:** ρ=1000 kg/m³, v=2 m/s, L=0.05 m y μ=0.001 Pa·s
produjeron Re=100000. Se abrió Learn visually con Remove animations activo y se
observó el fallback estático. Al restaurar las escalas volvió el botón Pause flow.
Se pausó, reanudó y ajustó v a 2.693237 m/s, obteniendo Re=134661.835749; cerrar la
hoja mostró el mismo resultado y la sustitución actualizada en el formulario.
Capturas `build/phase7-native-reynolds-reduced.png`, `reynolds-paused` y
`reynolds-running` bajo el mismo prefijo. No se observó crash durante el recorrido.

Se verificó por lectura final la restauración exacta de la configuración temporal:
`animator_duration_scale=null`, `transition_animation_scale=1.0`,
`window_animation_scale=1.0`, `enabled_accessibility_services=null` y
`accessibility_enabled=0`. La primera consulta de confirmación fue bloqueada por
un límite de uso de la revisión automática; el reintento autorizado después de
continuar la tarea confirmó estos valores y no queda ninguna restauración pendiente.

## Deuda y límites

Pendientes reales: recorrido hablado fiable de TalkBack, VoiceOver (sin entorno
Apple), rendimiento sostenido en hardware físico y la incidencia previa de carga
del runner Chrome. No se reintentó ni refactorizó Chrome en Phase 7; Node valida
el dominio JavaScript, no el renderizado del navegador. No se afirma 60 fps,
medición de CPU/raster/allocations ni ausencia de fugas a partir del emulador;
los tests verifican dispose y ausencia de callbacks activos al retirar la escena.
No se introduce otra deuda arquitectónica ni se añade otra visualización.
