# Phase 17 — Accessibility & Performance Closure

Fecha inicial: 2026-10-06. Continuación: 2026-10-10, America/Mexico_City.

**PASS WITH LIMITATIONS — corrección completa, gates e instalación verificados; owner confirma re-verificación física.**

No se declara preparación para publicación pública. Este reporte documenta evidencia de esta fase; no repite la aceptación sostenida de Phase 16 ni convierte sus resultados en un benchmark.

Las secciones 1–7 conservan el baseline, las mediciones y el checklist originales del 6 de octubre. Las observaciones de ausencia de escucha humana o de cambios de producción describen esa sesión histórica; las secciones 8–12 las actualizan con evidencia del owner y la corrección del 10 de octubre. T7 del feedback actual es una comprobación perceptual de scroll, no la prueba opcional de texto al 200% del checklist original.

## 1. Baseline

- Rama `main`; HEAD y referencia local `origin/main`: `637082dca27d399556e2eca07623db06246dbcdb`.
- Working tree inicial limpio. Git emitió warnings al leer el ignore global; los comandos de inspección finalizaron correctamente.
- Historial esperado confirmado: Phase 14 `4cfec2b`, Phase 15 `d2a3e38`, Phase 16 `637082d`.
- `git diff d2a3e38 HEAD --stat`: únicamente `docs/phase16-validation.md`; producción no cambió desde la APK física documentada en Phase 16. No se contactó el remoto: igualdad con `origin/main` significa igualdad con la referencia local disponible.
- APK release local SHA-256: `BB58A8EEC4E6C3AAC7AE12F17F4304369451939E6C0CBB4B89EDA2656A43958B`.
- AAB release local SHA-256: `0C29AE64181DFCFA4EC027BD8F62A3F7B9E48F79BF5BE4CD82AA909BF600D741`.
- Ambos coinciden con Phase 16. Se evitó rebuild release innecesario. El AAB conserva el alcance incremental del reporte anterior.
- Hash de la APK instalada, obtenido con `pm path` y `sha256sum`, también coincide exactamente. No se deduce esa identidad únicamente de versionName.
- Sin features, dependencias, cambios de producción ni acciones de historial.

## 2. Hardware y release

ADB del SDK existente disponible tras ejecución autorizada; inicialmente el sandbox negó ejecutar su binario. `adb get-state` devolvió `device`; un único destino fue utilizado sin exponer serial.

| Propiedad | Lectura actual |
|---|---|
| Fabricante/modelo | Xiaomi / 23129RA5FL, coincidente con Phase 16 |
| Android/API/ABI | 15 / 35 / arm64-v8a |
| Resolución/densidad | 1080×2400 / 440 dpi |
| Package | com.engineeringtoolkit.engineering_toolkit |
| Versión instalada | 0.2.0, versionCode 2; minSdk 24, targetSdk 36 |
| Última actualización inicial | 2026-10-05 22:26:08, coincidente con la instalación de Phase 16 |
| Flags de package iniciales | Sin DEBUGGABLE; release documentada anteriormente |
| Batería inicial | 18/100; AC powered=true; status=2, charging |
| Temperatura de batería inicial | 354 = 35.4 °C |
| Ajustes iniciales | font_scale=1.0; enabled_accessibility_services=null |

Temperatura de batería y carga son contexto exploratorio, sin inferencia de throttling, consumo ni temperatura de CPU/GPU. El arranque inicial `am start -W` informó COLD, Status ok, TotalTime 799 ms; no es una distribución de startup ni un benchmark Flutter.

## 3. Metodología y escenarios

Helpers temporales, XML, PNG y logs se conservan únicamente en `build/phase17/`, ignorado por Git. La preparación localiza y comprueba controles; las ventanas críticas usan comandos `adb shell input` predefinidos. No hay screenshots ni UIAutomator durante esas ventanas. Se espera asentamiento, resetea `gfxinfo`, limpia el historial de la capa Flutter en SurfaceFlinger, ejecuta la interacción y recupera primero sus tiempos y después framestats. Las capturas y las comprobaciones funcionales se hacen después.

Tres repeticiones dentro del mismo proceso por escenario: observación inicial y dos reproducciones para detectar consistencia gruesa. Es un screening exploratorio; no demuestra significancia, estabilidad universal ni equivalencia entre dispositivos. Un patrón adverso exige investigación adicional. No se toma como benchmark la duración del helper, que incluye ADB y pausas deliberadas.

P1/P2/P4 con edición incluyen IME y se interpretan separados del scroll sin IME. P3 Newton usa una escena estática; no se mide una animación del modelo que no existe. SurfaceFlinger mide presentación/composición de buffers de la capa Flutter, incluyendo planificación del sistema; no separa build/layout/paint/raster. Los intervalos entre presentaciones también incluyen pausas intencionales y periodos sin cambios.

Referencias de interpretación: [Android gfxinfo](https://developer.android.com/tools/dumpsys), [AOSP FrameTracker](https://android.googlesource.com/platform/frameworks/native/+/refs/heads/main/services/surfaceflinger/FrameTracker.cpp), [Flutter profiling en dispositivo físico](https://docs.flutter.dev/perf/ui-performance) y [DevTools Performance](https://docs.flutter.dev/tools/devtools/performance). El historial SurfaceFlinger es un ring de 128 registros: se excluyen filas cero y fences pendientes; no se asume cobertura completa si se llena. Las columnas son desired present, actual present y frame ready, en nanosegundos. Los percentiles P2P se calculan sobre diferencias de actual present consecutivos mediante rango más cercano; no son duraciones de raster ni un porcentaje de jank.

## 4. Resultados e interpretación

### 4.1. Release física: ventanas independientes

Cada tripleta corresponde a repeticiones 1/2/3. Jank legacy se conserva separado del contador actual. Ninguno se convierte en FPS ni se suma al otro.

| Ventana | Qué se ejecutó | Android frames | Android janky | Android legacy | Registros válidos de la capa Flutter |
|---|---|---|---|---|---|
| P1 | Home → Tools → Newton → Back → Home/Search F=ma → Newton; focus/dismiss explícitos | 59 / 59 / 59 | 3 / 3 / 2 | 28 / 28 / 26 | 100 / 100 / 106 |
| P2 | Campos vacíos → 2 kg y 3 m/s² → dismiss → Calculate → 6 N | 118 / 118 / 118 | 6 / 4 / 6 | 57 / 56 / 54 | 127 / 127 / 127, potencialmente truncados |
| P3-open | Resultado 6 N → Learn visually → Close | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 37 / 37 / 37 |
| P3 | Modal previamente abierto → scroll abajo/arriba → Close | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 70 / 70 / 70 |
| P4-open | Resultado 6 N → Explore interactively → Back | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 4 / 4 / 4 |
| P4 | Playground previamente abierto, acceleration 3 → 4 con IME/dismiss → 8 N | 59 / 59 / 59 | 1 / 2 / 2 | 0 / 0 / 0 | 81 / 79 / 79 |
| P5 | Tools/All fields, catálogo de 30 herramientas → scroll abajo/arriba | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 84 / 83 / 84 |

Fuentes: `*-reset.txt`, `*-start.txt`, `*-end.txt`, `*-gfxinfo.txt`, `*-latency.txt`, `summary.json` y helpers `measure.ps1`, `scroll.ps1`, `navigation-calculator.ps1` en `build/phase17/`. El proceso release se mantuvo en PID 17630 durante estos ensayos; profile es otro proceso y se reporta separado. No se hicieron capturas ni dumps UI dentro de las ventanas críticas. La lectura auxiliar de hash/batería a 02:26:32 UTC quedó entre P1-3, final 02:26:30.102, y P2-3, inicio 02:26:37.268, fuera de esas ventanas.

Verificación después de cada repetición: P1 llegó al formulario con Calculate; P2 confirmó resultado 6 N; Learn volvió a 6 N; Playground confirmó 8 N tras editar y 6 N después de restaurar acceleration=3. Las comprobaciones XML de `6 N`/`8 N` se corroboraron como nodos de salida, excluyendo EditText. PNG representativos de formulario, resultado, modal y Playground se inspeccionaron; acreditan estados finales, **no observación continua de fluidez**. P5 terminó con catálogo desplazado y controles de navegación disponibles. No hubo interacción humana continua de rendimiento en esta fase.

Interpretación de outliers:

- P1 P2P máximo 1336.54 / 1303.09 / 1336.56 ms; P4-open 852.02 / 835.33 / 818.63 ms. Son intervalos entre buffers en flujos discretos con sleeps y contenido estático: no equivalen a frames bloqueados de esa duración ni a latencia de respuesta.
- P2 llena el ring; se conserva como muestra parcial sin afirmar distribución completa de presentaciones. IME, resize y ventana Android forman parte de la operación medida.
- P4 edición tiene P2P máximo ~334.12 ms, con pausas explícitas entre inputs; no se clasifica ese intervalo solo como jank.
- P3 scroll/cierre: P2P p50 ~16.72 ms; p95 33.43 ms en las tres repeticiones; máximos 33.44 / 33.44 / 33.45 ms. P5: p50 ~16.71 ms; p95 33.43 / 33.43 / 33.42 ms; máximos 33.45 / 33.46 / 33.44 ms. El periodo reportado por la capa fue 16666666 ns. La repetición de intervalos de aproximadamente dos periodos justifica investigar; no identifica por sí sola el responsable.

`gfxinfo` produjo percentiles 4950 ms con cero frames en esas ventanas: son datos sin muestra, **no tiempos válidos de rendering**. El Pipeline=Skia(OpenGL) de ese contador describe HWUI Android; no se usa para identificar el backend Flutter.

### 4.2. Investigación profile sin cambios de producción

Se construyó `flutter build apk --profile`, exit 0, assembleProfile 73.9 s; APK temporal SHA-256 `799079E03AD13D466FB693E205C7A48DB8D72980BE8F990AA1E11A4745C262D9`. Se ejecutó con `flutter run --profile --no-dds --host-vmservice-port=8181 --use-application-binary=build/app/outputs/flutter-apk/app-profile.apk`. Mismo código, package, configuración y SDK; sin profiling package, instrumentation de producción ni cambios de renderer. El log del engine mostró intento Vulkan y después Impeller OpenGLES; los eventos ReactorGLES corroboran la ruta GL observada en profile. No se atribuye ese backend al contador HWUI.

Se usó el [Dart VM Service Protocol](https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md) local para seleccionar streams Dart/Embedder/GC, limpiar timeline antes de cada ventana y recuperar eventos después, sin screenshots ni UI dumps durante el gesto. Tres ventanas P5 y tres de scroll del modal Newton P3. El profile P3 mantiene el modal abierto: no es idéntico al P3 release que incluye cierre, ni una comparación A/B para declarar mejora. No se conectó DevTools con overlays o tracking extra de rebuilds.

El parser local empareja eventos Frame asíncronos por thread/id y eventos B/E de los scopes nombrados por thread; utiliza timestamps en microsegundos. No suma scopes anidados. Reporta pares completos; un Frame y un Animator al borde de P3-1 quedaron sin pareja y se excluyeron. Son duraciones de scopes de timeline, no una lectura directa de `FrameTiming.buildDuration/rasterDuration` ni medición exclusiva de GPU. Fuentes `profile-P[35]-*.json`, `profile-summary.json`, `profile-summary.ps1`.

| Ventana | Frame UI pares | UI p95 / max ms | GPURasterizer::Draw pares | Draw p50 / p95 / max ms | Draw >16.667 ms | Submit p50 / p95 ms |
|---|---:|---|---:|---|---:|---|
| P5-1 | 81 | 1.73 / 3.74 | 81 | 22.03 / 23.73 / 35.10 | 80 | 21.73 / 23.26 |
| P5-2 | 81 | 1.67 / 2.92 | 81 | 21.94 / 24.12 / 47.08 | 80 | 21.61 / 23.65 |
| P5-3 | 80 | 1.63 / 3.27 | 80 | 21.87 / 24.38 / 45.57 | 79 | 21.48 / 23.96 |
| P3-1 | 63 | 3.56 / 7.75 | 64 | 28.42 / 34.10 / 42.59 | 63 | 28.00 / 33.61 |
| P3-2 | 60 | 1.46 / 2.16 | 60 | 27.31 / 31.95 / 59.99 | 59 | 26.89 / 31.46 |
| P3-3 | 61 | 1.10 / 1.70 | 61 | 26.48 / 28.76 / 60.19 | 60 | 26.14 / 28.34 |

**Hallazgo reproducible:** en ambas superficies el scope Draw excede frecuentemente un periodo de 60 Hz, mientras UI permanece corto. El tiempo predominante está contenido en `SurfaceFrame::Submit`; el scope CompositorContext::ScopedFrame::Raster tiene p95 menor de 0.4 ms en estas muestras y SurfaceFrame::Encode p95 entre 4.54–10.55 ms. Hay eventos PipelineFull repetidos. Esto acota la investigación a entrega/presentación/raster del engine y su interacción con GPU/driver/compositor; no demuestra trabajo síncrono caro de dominio o ViewModels ni una causa de build/layout. No se identifica un widget culpable por intuición.

Los scopes Submit pueden incluir esperas/entrega; no se afirma que todo ese tiempo sea cómputo GPU. La atribución exacta sigue pendiente. `adb input swipe` genera alta cadencia de eventos (630 DispatchPointerDataPacket en P5-1 para dos swipes), y profile introduce overhead: se necesita corroborar con gesto humano o trace que separe esperas de presentación de trabajo útil antes de clasificar una corrección de producción. Esa contaminación residual se conserva explícita; no invalida los datos ni permite descartarlos como mero ruido.

Se revisaron GlassCard, AppScaffold, formulario y composición Playground: GlassCard no introduce filtro backdrop por tarjeta; el formulario calcula y hace ensureVisible tras la acción; Playground escucha VM y mantiene cálculo único. No existe evidencia para optimizar Search de 30 herramientas, registry, math engine o ViewModels. **En la sesión inicial, el riesgo PERFORMANCE seguía abierto; la conclusión actual está en §9/§12.** No se declara rendimiento perfecto ni ausencia de jank, y no se introduce una corrección sin causa plausible demostrada.

## 5. Relación con Phase 16

Los 4745 frames/626 janky/13.19% Android de Phase 16 mezclaban preparación, IME, capturas, navegación, UIAutomator y periodos inactivos. No sirven de denominador comparativo ni permiten afirmar una mejora porcentual. Aquí las ventanas son separadas y el contador Android se contrasta con la capa Flutter: un contador de cero frames no prueba fluidez del renderer.

## 6. Accessibility structural audit

Inspección de fuentes actuales, tests existentes y XML físico representativo; no equivale a escucha humana.

| Superficie | Evidencia estructural / límite |
|---|---|
| Bottom navigation | Label, button, selected y onTap explícitos; Tooltip excluido y ExcludeSemantics del contenido visual evitan duplicar el destino. Orden Home/Favorites/Tools/Settings. |
| Home/Search | Label Search tools or fields; Clear search con tooltip; sin autofocus inicial; conteo en liveRegion; estado No tools found y acción de recuperación. Anuncio de cambios pendiente de owner. |
| Favorites/capability discovery | Tooltip Add/Remove incluye calculator; capacidades aparecen como texto dentro de la tarjeta. Son información de discovery; las acciones están dentro del calculator. |
| Calculator fields/units | TextFormField con labelText, errorText y next; dropdown con label de campo+unit; unidad única m/s² expuesta como texto. Orden construido Mass, Mass unit, Acceleration, Unit, Calculate, Reset. |
| Calculate/errors/result | Calculate elimina focus y lleva el scroll a resultado/error; issues generales y resultado usan liveRegion; resultado SelectableText, unidad y detalles alcanzables. No se garantiza anuncio audible automático. |
| Learn visually | Modal en root navigator cubre shell; Close visualization con tooltip; escena tiene un nodo image con descripción numérica significativa y canvas excluido. XML físico del modal no muestra destinos de shell. |
| Sliders | label de magnitud, semanticFormatterCallback con valor/unidad y acciones Slider del framework; límites descritos como texto. El valor manual fuera de rango se conserva y el thumb queda acotado; la lectura humana de este caso no se ha verificado. |
| Playground | ReadingOrderTraversalPolicy; campos/unidades existentes; resultado liveRegion; descripción de escena y Back to calculator. Política de teclado no certifica por sí sola traversal TalkBack. |
| Settings/Back/Close | Theme label y tooltips específicos. Orden, contención modal, duplicados audibles y restauración del foco requieren comprobación humana. |

Regresión actual seleccionada: `flutter test test/widgets/calculator_accessibility_test.dart test/widgets/discovery_test.dart test/widgets/visual_learning_test.dart test/widgets/playground_test.dart --reporter expanded`, exit 0, 82 tests pasaron. Incluye semántica de discovery, Tab/Enter, formularios con texto 200%, unidad/errores, modal que oculta shell y Playground responsive. Se reporta alcance de las pruebas, sin usar el conteo para certificar TalkBack.

## 7. Checklist audible para el owner (5–10 minutos)

Usar la release en el Xiaomi. Activar TalkBack desde ajustes de accesibilidad; avanzar con swipe derecho/izquierdo y activar con doble tap. Usar sus gestos de scroll. Esta secuencia está preparada, **no ejecutada audiblemente**.

- **T1 (1 min):** Home → Favorites → Tools → Settings → Home. Confirmar cada destino anunciado una sola vez, estado seleccionado entendible, acción disponible y orden lógico. No cambiar Theme.
- **T2 (1 min):** Search, escribir `F=ma`, cerrar teclado. Escuchar Search, Clear search, `1 tool`, Newton’s Second Law, acción Add/Remove de favorito y textos Learn visually / Explore interactively. Recorrer con swipes y abrir Newton. Las capacidades de la tarjeta son texto informativo.
- **T3 (1–2 min):** Mass=2, Mass unit=kg; Acceleration=3, Unit=m/s²; Calculate. Confirmar labels/unidades, orden, resultado **6 N**, unidad, Formula, Substitution `F = 2 kg × 3 m/s²` y Explanation. Distinguir anuncio espontáneo de resultado y descubrimiento al recorrer con swipes.
- **T4 (1 min):** Cambiar Mass a `-1` y Calculate. Escuchar/localizar `Mass must be zero or greater.`, entender qué corregir y recuperar con Mass=2, Acceleration=3, Calculate → 6 N. Si el teclado no permite el signo, borrar Mass y probar Calculate con campo vacío. Registrar si el error se anunció solo o se encontró por recorrido.
- **T5 (1–2 min):** Abrir Learn visually. Escuchar descripción con mass 2 kg, acceleration 3 m/s² y net force 6 N; no una secuencia absurda de elementos canvas. Recorrer hasta controles Mass/Acceleration; verificar valor/unidad y acción de ajuste de un slider, después devolver acceleration a 3 mediante el formulario si cambió. Comprobar que focus no llega a navegación detrás del modal; Close visualization y retorno de foco razonable.
- **T6 (1–2 min):** Con 2/3/6 N, Explore interactively. Recorrer inputs, unidades, resultado y descripción. Cambiar acceleration a 4; confirmar **8 N** y descripción actualizada. Back to calculator debe conservar 2/4/8 N y permitir seguir recorriendo.
- **T7 (opcional, 1 min):** Anotar ajuste original de tamaño de texto. Solo si puedes restaurarlo, aumentar a 200% y repetir Home → Newton, campos/Calculate/result y Back con TalkBack. Confirmar controles alcanzables, lectura y scroll. Restaurar tamaño original y estado original de TalkBack al terminar.

Respuesta del owner por fila: `T1: PASS`, o `announcement duplicated / control skipped / wrong label / focus lost / reading order wrong / result not announced / other`, indicando control, palabras escuchadas y pasos. Para T7 también se acepta `NOT RUN` con motivo. Anotar Android, versión y si fue la release descrita. Si algo impide continuar, registrar el paso exacto sin inventar los siguientes resultados.

## 8. Owner audible results — evidencia humana recibida el 10 de octubre

Fuente: feedback explícito del owner sobre el mismo Xiaomi físico de Phase 16/17. Es escucha humana de la release anterior a la corrección; no se convierte en aceptación audible de una APK nueva.

| Caso | Resultado humano | Evidencia / observación |
|---|---|---|
| T1 — Navigation | PASS | Home → Favorites → Tools → Settings → Home; destinos entendibles, en orden y activatables. Favorites fue pronunciado en inglés en una pasada y con pronunciación parecida al español en otra. Observación TTS/locale; no se ha demostrado semántica o locale forzado por la app como causa, por lo que no se clasifica como defecto. |
| T2 — Search | PASS | F=ma, Newton’s Second Law, capacidad de favorito e información de discovery entendibles; Learn visually claro. f=m no descubre Newton hasta completar f=ma: candidato futuro de UX/discovery, no defecto de Phase 17. Search no cambia. |
| T3 — Calculator/result | PASS | Mass=2 kg, acceleration=3 m/s²; Calculate y recorrido de Result, Formula, Substitution, Explanation entendibles. Explicación de masa, aceleración y fuerza clara para el owner. Ningún defecto reproducido. |
| T4 — Validation | PASS | Mass inválida expuso Mass must be zero or greater.; el owner entendió qué corregir. Ningún defecto de accesibilidad reproducido. |
| T5 — Learn visually | PASS con ACCESSIBILITY MINOR reproducido | Controles, foco y descripción semántica de escena usables; valores de sliders Mass y Acceleration leídos con aproximadamente 14 decimales. Precisión hablada excesiva. |
| T6 — Explore interactively | PASS con el mismo ACCESSIBILITY MINOR reportado | Entradas, resultado y descripción significativa de masa/aceleración legibles; el owner reporta la misma verbosidad de valores. La inspección de esta fuente muestra que Playground oculta sliders (§9); conservar el feedback y comprobar la superficie exacta en la release corregida. |
| T7 — Performance perceptual | PASS | Con TalkBack desactivado, scroll de Tools por el catálogo y Newton Learn visually percibido fluido, sin stutter apreciable ni degradación progresiva observada. Corrobora únicamente los escenarios ejercitados; no certifica FPS ni invalida las mediciones. |

No se deduce anuncio espontáneo automático de resultados/errores del hecho de que el owner los recorriera y entendiera. No se afirma una nueva ejecución humana al 200% de tamaño de texto.

## 9. Defectos, corrección mínima y decisión de rendimiento

**ACCESSIBILITY MINOR — precisión hablada:** `VisualInputControl` ya tiene un único `semanticFormatterCallback`, compartido por las escenas visuales. Se conserva `NumberFormatting.format` y se añade el parámetro opcional `decimals`, con el default existente de seis. Solo el callback pide `decimals: 4`; el recorte existente elimina ceros finales. Ejemplos: 2 → 2, 2.5 → 2.5, 2.125 → 2.125, 2.123456789 → 2.1235. Se conserva el símbolo de unidad, kg o m/s². Magnitudes muy pequeñas/grandes mantienen la notación científica existente, con mantisa de hasta cuatro decimales en ese callback, evitando convertir un valor diminuto en cero.

No hay un segundo formateador de sliders en Playground: `PlaygroundContent` usa `VisualModelView(showInputControls: false)` y campos manuales. Ambos recorridos se deben escuchar para contrastar el feedback, pero no se añade un slider ni se redondea el texto editable. La causa exacta de los ~14 decimales escuchados no se deduce de la fuente: el callback anterior ya formateaba a seis decimales. La corrección limita explícitamente el contrato semántico actual, incluidos valores de incremento/decremento generados por Flutter; el audio físico decidirá si resuelve todo lo reportado.

La primera corrección no tocó onChanged, conversión de unidades, ViewModel, dominio, Search, resultados, sustituciones ni descripción de escena. El feedback posterior de la captura mostró que ese alcance era insuficiente (§9.1). La nueva prueba inspecciona el árbol semántico real de Newton, con valor actual e incrementos/decrementos de Mass y Acceleration. También ejerce el callback de edición con 3.123456789 y verifica que VM conserva ese texto completo y que el resultado es exactamente el producto de los doubles sin redondear, diferente del producto de los valores semánticos redondeados. El informe no atribuye el feedback a una causa no demostrada.

**PERFORMANCE — limitación técnica retenida, sin corrección de producción justificada:** las presentaciones repetidas de ~33 ms y los scopes Draw/Submit medidos en §4 permanecen como evidencia reproducible. No se aisló causa atribuible a widget, dominio o ViewModel; tampoco se separó definitivamente trabajo GPU/driver de esperas de presentación. El owner percibió fluidos los scrolls de Tools y Newton Learn visually y no reprodujo ralentización progresiva. Por tanto, no se reprodujo un defecto de rendimiento visible para el usuario dentro del alcance ejercitado; permanece documentada la limitación técnica de tiempos de presentación. No procede una optimización especulativa de producción en Phase 17. No se afirma rendimiento perfecto, ausencia general de jank ni 60 FPS garantizados.

Observaciones de helpers/entorno históricos de la sesión inicial: adaptación de dot-source/PSScriptRoot; dismiss explícito del IME restaurado por Search; corrección de sintaxis HTTP del VM Service; parada deliberada de profile y restauración de release. No son defectos de accesibilidad o rendimiento de la aplicación. En esta continuación, ADB inicialmente no encontró dispositivos; tras conectar el owner el Xiaomi, devolvió device y modelo 23129RA5FL. Las verificaciones inicialmente lanzadas en sandbox quedaron sin salida útil; se detuvieron esos procesos y se reejecutaron con acceso al SDK. Los primeros ajustes de la prueba corrigieron el nodo inspeccionado y los incrementos de Flutter; no requirieron ampliar la corrección de producción.

Roadmap preservado, sin diseño ni implementación en esta fase:

1. Discovery parcial de alias técnicos: f=m podría comenzar a mostrar Newton antes de f=ma. Matching determinista de prefijos controlados es solo una posible dirección futura.
2. Localización eventual English + Spanish deseada por el owner; English-first aceptable mientras se difiere localización completa. La pronunciación variable de Favorites no prueba defecto de app.

### 9.1. Reproducción posterior — etiquetas visuales con decimales largos

Tras reinstalar la primera corrección, el owner proporcionó captura del Xiaomi mostrada en Android Studio: Mass 53.929227941176435 kg aparece tanto junto a Input acceleration 3 m/s² como en el título Mass del slider. Net force F = 161.787684 N ya utiliza el formato habitual de resultado. La captura demuestra texto visual excesivamente preciso; no demuestra por sí sola qué nodo pronunció TalkBack. No se registra PASS de la primera corrección ni se interpreta la captura como defecto del motor.

Causa localizada en fuente: quantityLabel usaba NumberFormatting.operand, cuyo fallback devuelve el double completo cuando el formato compacto no round-tripea. Esta función alimenta títulos de controles, líneas de cantidades y resúmenes semánticos de escena. Por ello limitar solo semanticFormatterCallback no cubría esas otras lecturas, y el mismo texto se propagaba a la escena de Playground aun sin sliders.

Corrección adicional mínima: quantityLabel usa NumberFormatting.format(input.baseValue, decimals: 4). Se mantiene el helper de presentación existente y la unidad; no se altera NumberFormatting.operand ni sus usos en las sustituciones exactas del reporte. El cambio se aplica a sus consumidores visuales compartidos (no es una regla especial para Newton); no toca campos editables, motores, ViewModels, valores de contexto, resultados ni geometría. Las etiquetas y el resumen de escena de Newton pasan de 53.929227941176435 kg a 53.9292 kg. La salida de fuerza mantiene sus seis decimales habituales, pues no es un valor de entrada del slider.

Cobertura adicional con el valor exacto de la captura, en Learn visually y Playground: texto Mass 53.9292 kg · Input acceleration 3 m/s², título del slider cuando existe y nodo semántico de escena con magnitudes/unidades útiles. Se comprueba que VM conserva 53.929227941176435, el reporte mantiene su identidad al renderizar, el resultado equivale al producto double completo por 3 y difiere del producto de 53.9292 por 3. La sustitución conserva el operando exacto. Las tres pruebas focalizadas pasaron; se repiten los gates completos sobre esta corrección adicional.
## 10. Regression gates — continuación

La tabla siguiente conserva los gates de la primera corrección. Tras la captura del owner se repitieron sobre §9.1; los resultados nuevos están debajo. Todos estos gates históricos pasaron sobre la primera corrección de producción. Los primeros intentos fallidos de test/formatter se conservan como diagnóstico y no se confunden con los resultados finales.

| Gate | Resultado final | Evidencia local |
|---|---|---|
| flutter test --reporter expanded | PASS, 573/573, exit 0 | correction-flutter-test-final.log; correction-final-gates.txt |
| flutter analyze | PASS, sin incidencias, exit 0 | correction-analyze-final.log |
| dart format --output=none --set-exit-if-changed lib test tool | PASS, 146 archivos, 0 cambios, exit 0 | correction-format-final.log |
| dart run tool/test_domain.dart | PASS, 283/283, exit 0 | correction-domain.log; correction-gates.txt |
| dart compile js tool/test_domain_web.dart -o build/phase17/correction-domain.js | PASS, exit 0 | correction-js-compile.log |
| node build/phase17/correction-domain.js | PASS, mismas 283 closures, exit 0 | correction-node.log (vacío por éxito); correction-gates.txt |
| git diff --check | PASS, exit 0; además revisión explícita de whitespace/conflict markers en archivos untracked | Inspección final de Git/archivos |
| flutter build apk --release | PASS, exit 0, assembleRelease 64.7 s | correction-apk.log |
| flutter build appbundle --release | PASS, exit 0, bundleRelease 9.1 s | correction-aab.log |

SHA-256 APK release: `7A984FCF85A684E3AB0CACD71322809277EA616171229305C41B06FEEBBC9B04`.
SHA-256 AAB release: `896241368FACA9A03B75AC65896D6A2B1FAF6D352FCB599A375F97AB0558E94D`.

Artefactos: build/app/outputs/flutter-apk/app-release.apk y build/app/outputs/bundle/release/app-release.aab. APK instalada y ejecutada en el Xiaomi; AAB solo compilado, sin instalación desde bundle ni prueba de distribución. El build emitió el warning existente de fuente CupertinoIcons no incluida; terminó correctamente y no se alteraron assets/dependencias para este cambio.

El intento de formatter sobre todo el directorio incluyó probes históricos ignorados en build/ y detectó siete archivos fuera de las fuentes del producto. El gate final usa el alcance de Phase 16, lib/test/tool. No se modifica ningún probe para fingir limpieza. La prueba nueva confirma tanto el producto 2.123456789 × 3 como 2.123456789 × 3.123456789 con entradas completas; el segundo difiere de 2.1235 × 3.1235. La revisión del diff confirma que ningún consumidor existente cambia su default de seis decimales y no hay cambios en motores ni ViewModels.

Logs locales build/phase17/correction-*, ignorados por Git; evidencian ejecuciones nuevas de esta continuación.

### 10.1. Gates definitivos tras la captura y corrección de etiquetas (§9.1)

| Gate | Resultado final | Evidencia local |
|---|---|---|
| flutter test --reporter expanded | PASS, 575/575, exit 0 | labels-flutter-test-final.log; labels-final-gates.txt |
| flutter analyze | PASS, sin incidencias, exit 0 | labels-analyze-final.log; labels-final-gates.txt |
| dart format --output=none --set-exit-if-changed lib test tool | PASS, 146 archivos, 0 cambios, exit 0 | labels-format-final.log; labels-format-exit.txt |
| dart run tool/test_domain.dart | PASS, 283/283, exit 0 | labels-domain.log; labels-gates.txt |
| dart compile js tool/test_domain_web.dart -o build/phase17/labels-domain.js | PASS, exit 0 | labels-js-compile.log; labels-gates.txt |
| node build/phase17/labels-domain.js | PASS, mismas 283 closures, exit 0 | labels-node.log; labels-gates.txt |
| git diff --check | PASS, exit 0; whitespace/conflict markers de untracked comprobados aparte | Revisión final de Git/archivos |
| flutter build apk --release | PASS, exit 0, assembleRelease 38.2 s | labels-apk.log; labels-gates.txt |
| flutter build appbundle --release | PASS, exit 0, bundleRelease 8.1 s | labels-aab.log; labels-gates.txt |

SHA-256 APK actual: EFB0D2E54CE7D3740AF14081817CA5B22B570AB2C63CD09AFB9BFFF17B00085A.
SHA-256 AAB actual: 0A362212E794FD3A355AB95B054D0A69DC1CA222F185E2C4B11EB30A238BF70E.

La primera ejecución tras §9.1 detectó un test histórico que exigía texto visual exacto en Voltage Divider. Se ajustó ese contrato compartido a etiqueta compacta y se reforzó que contexto, sustitución y resultado conservan el operando exacto 1.0000001; no se eliminó la cobertura de precisión. Ideal Gas usa su ruta separada de etiquetas y mantiene sus expectativas existentes. La segunda suite completa pasó. El último cambio posterior fue solo dart format sobre ese test; el formatter final pasó sin cambios pendientes. Los logs de intentos anteriores no se presentan como gates finales.
## 11. Physical re-verification, limitations y Git

Instalación corregida completada con adb install -r: Success, sin clear data. Arranque release Status ok, COLD, TotalTime 1513 ms; muestra única, sin inferencia de rendimiento. SHA-256 del base.apk instalado coincide exactamente con la APK corregida indicada en §10. Package com.engineeringtoolkit.engineering_toolkit, versión 0.2.0/code 2, minSdk 24/targetSdk 36; flags sin DEBUGGABLE. Evidencia correction-install.txt, correction-launch.txt, correction-installed-sha256.txt y correction-package.txt. No se cambiaron ajustes de TalkBack por automatización ni se hicieron inputs mientras el owner verifica.

Instalación final tras §9.1: adb install -r devolvió Success en el Xiaomi 23129RA5FL, sin clear data. Se reinició la app y am start -W devolvió Status ok, COLD, TotalTime 1874 ms; observación única, sin benchmark. El hash leído del base.apk instalado coincide exactamente con EFB0D2E54CE7D3740AF14081817CA5B22B570AB2C63CD09AFB9BFFF17B00085A. Evidencia labels-install.txt, labels-launch.txt, labels-apk-sha256.txt y labels-installed-sha256.txt. La instalación y hash iniciales anteriores quedan como historial de la primera corrección, no identidad de la release actual.

**Re-verificación física del owner: PASS dentro del alcance solicitado.** Después de instalar y abrir la APK final se solicitó revisar Newton Learn visually moviendo Mass y escuchar etiquetas/escena con TalkBack, unidades y foco, además de la descripción de Newton Explore interactively. La respuesta literal del owner fue «perfecto». Se registra como aceptación humana de esa revisión agrupada en el mismo Xiaomi; no se inventa una transcripción audible, una secuencia adicional de valores ni un nuevo recorrido completo T1–T7. Esta confirmación es independiente de las pruebas semánticas automatizadas. No se reportan nuevas regresiones de unidades, escena o foco/navegación en ese feedback. No se alteraron ajustes Android ni se automatizaron gestos durante la revisión del owner.

Se conservan las limitaciones originales: un dispositivo/API/ABI; mediciones exploratorias, P2 parcial por ring de SurfaceFlinger; profile y release no son comparaciones A/B; sin atribución GPU/driver definitiva ni nueva sesión sostenida de Phase 16. Ahora existe corroboración perceptual humana de los dos scrolls señalados, sin universalizarla. Evidencia cruda en build/phase17 no se versiona.

Git: main, HEAD 637082dca27d399556e2eca07623db06246dbcdb conservado. Cambios: tres archivos de producción, test/widgets/slider_semantic_precision_test.dart, test/view_models/catalog_consistency_test.dart y este reporte. Sin staging ni acciones de historial.

Sin nuevas dependencias, SDK, signing, identidad, servicios, frameworks ni estado. No se declara preparación para publicación pública. No commit, tag, push ni inicio de Phase 18.

## 12. Final assessment

**PASS WITH LIMITATIONS.** T1–T7 del owner están registrados. El defecto ACCESSIBILITY MINOR de precisión excesiva queda corregido en el valor semántico del slider y en las etiquetas/resúmenes visuales compartidos; la primera corrección incompleta y la captura que la evidenció se conservan en §9.1. Todos los gates actuales pasaron, la APK final está instalada en el Xiaomi con identidad SHA-256 comprobada, y el owner respondió «perfecto» a la re-verificación agrupada de precisión visual/audible, unidades, escena y foco en Learn visually y Explore interactively.

No se reprodujo un defecto de rendimiento visible dentro del alcance ejercitado; la limitación técnica de tiempos de presentación permanece documentada. Las presentaciones ~33 ms y Draw/Submit medidos no se borran ni se convierten en garantía de FPS. No existe causa aislada atribuida a widget, dominio o ViewModel ni optimización de producción justificada en Phase 17. El cierre no depende de atribuir exactamente GPU/driver.

Límites: un Xiaomi/API/ABI, alcance humano declarado y mediciones exploratorias con las restricciones de §4/§11; no nueva sesión sostenida completa ni distribución del AAB. Search parcial y English + Spanish quedan como roadmap sin implementación. Engineering Toolkit no se declara lista para publicación pública. Se continúa y cierra esta evaluación de Phase 17, sin iniciar Phase 18 ni realizar commit, tag, push, staging o cambios de historial.
