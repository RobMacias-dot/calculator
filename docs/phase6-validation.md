# Phase 6 — Visual Learning

## Alcance y arquitectura

30 calculadoras, siete visualizaciones, cero dependencias nuevas. Se conserva
`CalculationResult → mapper → modelo inmutable → renderer`. Las únicas adiciones
al dominio son contextos de entradas ya validadas y la capacidad visual en las
tres definiciones existentes; motores, fórmulas, modos y unidades no cambian.

| Escena | Contrato real inspeccionado | Representación e interacción |
| --- | --- | --- |
| Newton | Único modo `force`; masa ≥ 0 en kg/g y aceleración con signo en m/s²; salida N, sin clasificaciones | Bloque, F del resultado y a de la entrada. Sliders de masa 0–100 kg y aceleración −20–20. No se inventa un solver de aceleración ni entrada de fuerza. |
| Torque | Único modo `torque`; fuerza y radio ≥ 0, N y m/cm/mm; salida N·m de magnitud, perpendicularidad asumida | Pivote, brazo y fuerza perpendicular. Sliders 0–100 N y 0–5 m. Sin ángulo, signo ni simulación de giro. |
| Bernoulli | Único modo `pressure2`; P1 Pa/kPa/bar con signo, densidad > 0 kg/m³, velocidades ≥ 0 m/s, alturas con signo en m; P2 Pa y equivalencia kPa | Dos estaciones, alturas y velocidades, barras de presión con cero común. Controles de las seis entradas. Sin área, caudal, continuidad inferida ni CFD. |

Los tres renderers son estáticos: la geometría y las etiquetas enseñan las
relaciones sin un tiempo físico. Reduce Motion preserva exactamente la misma
información. Newton/Torque usan intensidades logarítmicas acotadas; Bernoulli
ajusta una escala común por pareja de alturas, velocidades y presiones antes de
obtener coordenadas. No hay fórmulas de resultado en presentación. Las etiquetas
advierten que los diagramas son ilustrativos; cero y flechas subpíxel se distinguen
mediante los valores numéricos, aunque ambos se dibujen como puntos.

## Endurecimiento y decisiones tras siete escenas

Tres fallos de Phase 5 reproducidos con pruebas que fallaban antes de corregirlos:

1. Un cambio de accesibilidad de plataforma podía descartar `disableAnimations`
   heredado de `MediaQuery`. Reynolds combina ambas fuentes al actualizarse.
2. Reynolds seguía consumiendo ticks al salir del viewport por scroll. Un listener
   de posición comprueba intersección tras layout y pausa/reanuda el controlador;
   nunca se ejecuta esa comprobación por tick ni reconstruye el formulario.
3. En Android la hoja dentro del navegador de la sección dejaba la barra inferior
   visible e interactiva. `useRootNavigator: true` cubre el shell y evita salir del
   formulario propietario del ViewModel mientras la hoja lo utiliza. La regresión
   comprueba hit testing y recorrido semántico de la navegación de fondo.

La superficie, `VisualScene`, `VisualInputControl`, `paintDiagramLabel` y la
detección de Reduce Motion siguen siendo útiles sin un rediseño. La superficie
solo evoluciona en la elección de navegador. Se añade `paintDiagramArrow`, una
función de geometría con tres consumidores y comportamiento idéntico para flechas
cortas; no se fuerza la migración del vector preexistente. Las disposiciones,
normalizaciones y textos específicos permanecen separados. Reynolds no comparte
partículas con Bernoulli porque Bernoulli no las necesita.

El registro de calculadoras conserva la única lista de capacidades. El switch
exhaustivo de siete modelos únicamente elige renderers; no hay segundo registro,
factory jerárquica, manager, escena universal ni cambios en router/ViewModel.
No se justifica una nueva abstracción de física: las coincidencias útiles son
controles, superficie accesible, etiquetas y flechas, no leyes o simulaciones.

### Cómo decidir una extensión

- Visualizar cuando una relación espacial o entre cantidades ayude a entender un
  resultado ya calculado; inspeccionar primero el contrato real del modo.
- Animar solo si el tiempo aporta información que una figura estática no ofrece.
  Toda animación debe tener pausa, ambos indicadores de movimiento reducido,
  visibilidad de ruta/viewport, estado de app y eliminación de listeners/controlador.
- Compartir solo duplicación significativa con semántica idéntica y una API más
  simple. Tres flechas justifican una función; dos fluidos no justifican un motor.

## Verificación automatizada

Baseline ejecutado antes de modificar: 397 tests Flutter y 247 casos de dominio
en Dart y dart2js/Node; analyzer sin incidencias. Suite final: 426 tests Flutter,
incluidos los anteriores y 29 nuevos. Dominio final: 247/247 Dart y 247/247
JavaScript/Node. Ningún motor tuvo que corregirse.

Se cubren resultados sintéticos para detectar recálculo en mappers, valores con
signo/cero/extremos, unidades, normalización finita, `shouldRepaint`, controles
por teclado, errores/estado vacío, apertura/cierre repetidos, rotación de viewport,
320×640 al 200% en ambos temas y 1024×768. Las pruebas de contraste y targets de
las tres escenas nuevas pasan en claro y oscuro. No se añadieron goldens por frame.
`tool/capture_phase6.dart` genera capturas estáticas revisables bajo `build/`.

## Rendimiento y límites

Inspección de código: Reynolds mantiene un controlador, seis paths cacheados y
24 partículas; `CustomPainter.repaint` dentro de `RepaintBoundary`, sin fórmulas,
rebuild global, filtros, blur, `saveLayer` ni colecciones/paths/paints por frame.
Los tests comprueban que los ticks conservan la instancia de painter y no notifican
al ViewModel; pausa, visibilidad, segundo plano, flags y dispose se verifican por
separado. Newton, Torque y Bernoulli no tienen controlador ni repaint continuo.

No se ha medido rendimiento sostenido en hardware físico. El emulador y los tests
no demuestran 60 fps. Chrome conserva la incidencia previa de carga; no se
reescribe el runner ni se afirma que Node valide renderizado web.

## Validación Android y accesibilidad

Emulador Pixel_7, `emulator-5554`, x86_64, Android 17/API 37. APK debug instalado
y ejecutado. Se recorrieron las siete escenas desde búsqueda y formulario,
introduciendo valores, calculando, abriendo Learn visually, modificando un slider
y cerrando la hoja. Capturas y árboles accesibles revisados; no se observó crash
ni rotura de layout en esos recorridos. La segunda ejecución de Newton usó el
APK final, después de la última aclaración textual de escalas.

| Escena | Caso Android observado | Edición nativa observada |
| --- | --- | --- |
| Voltage Divider | 12 V, 1000/2000 Ω → 8 V | Vin 12 → 13.449275 V |
| Vector | (3, −4) → 5 | x 3 → 3.599034 |
| Reynolds | ρ 1000, v 2, L .05, μ .001 → Re 100000 | v 2 → 2.306763 m/s |
| IPv4 | 192.168.1.10/24 → 256 direcciones | /24 → /25 |
| Newton | 2 kg, 3 m/s² → 6 N | m → 5.072464 kg; al cerrar, resultado 15.217391 N |
| Torque | 20 N, .5 m → 10 N·m | F → 23.067633 N |
| Bernoulli | P1 100000, ρ 1000, v1 2, v2 4, z1 3, z2 1 → P2 113613.3 Pa | P1 → 112077.294686 Pa; al reabrir, P2 125690.594686 Pa |

Los archivos `build/phase6-native-*.png` y `.xml` son evidencia local, no baselines.
El script temporal de ADB permanece únicamente en `build/`, no añade infraestructura
de producto. Los valores extremos, /0 /26 /31 /32, ambos temas, 200%, rotación,
Reduce Motion, segundo plano, pausa/reanudación y dispose tienen cobertura
automatizada; no se afirma haber completado toda esa matriz manual en Android.

**TalkBack: intento real, smoke funcional pendiente.** Se activó TalkBack
17.0.0.889642762 y `dumpsys accessibility` confirmó servicio enlazado y exploración
táctil activa. Su aviso inicial de notificaciones bloqueó el recorrido: los
intentos de descartarlo mediante gestos/teclado inyectados no produjeron una
continuación fiable. No se verificó lectura hablada, Learn visually ni controles
de Newton/Reynolds con TalkBack. Se restauraron `accessibility_enabled=0` y la
ausencia original de servicios habilitados, y se cerró TalkBack. Evidencia del
bloqueo: `build/phase6-native-talkback-start.png`. No se presenta la inspección
del árbol Android como sustituto de un lector de pantalla real.

Hardware físico no disponible; VoiceOver, experiencia hablada con TalkBack y
rendimiento sostenido de dispositivo siguen pendientes. El recorrido nativo fue
en emulador debug y no proporciona mediciones de fps/raster/CPU/allocations.

## Cierre de calidad y autorrevisión

Analyzer: cero incidencias. Formato: 118 archivos sin cambios en la verificación
de `lib`, `test` y `tool`. APK debug compilado en
`build/app/outputs/flutter-apk/app-debug.apk`. `pubspec.yaml`, `pubspec.lock` y todos
los motores permanecen sin cambios. La inspección final encontró además posible
ambigüedad de los puntos para flechas subpíxel: se aclaró en las tres escenas.
Se separaron verticalmente las etiquetas de presión y el canal de Bernoulli para
conservar legibilidad con elevaciones límite y texto al 200%.

No se implementó Phase 7, otra calculadora visual, playground, backend, cuentas,
IA, analítica ni monetización.
