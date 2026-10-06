# Phase 16 — Physical Android & Runtime Readiness Audit

Primera ejecución: 2026-10-03. Reanudación física: 2026-10-05, America/Mexico_City.

**PASS WITH LIMITATIONS — ready for technical review**

El Xiaomi físico ARM64 ejecutó la APK release actual y completó los escenarios representativos, incluida la ruta integrada Newton, persistencia, configuración y 12 ciclos sostenidos sobre el mismo proceso. Los bloqueos originales de detección y permisos están resueltos. Quedan límites de evidencia: TalkBack audible requiere confirmación humana; los contadores Android de frames no equivalen a un benchmark de FPS de Flutter; se auditó un dispositivo y un conjunto representativo de rutas. No se declara preparación para publicación pública.

Las secciones 1–11 conservan la evidencia legítima de la primera ejecución bloqueada, fechada 2026-10-03; sus estados de ausencia de dispositivo son históricos. La sección 12 documenta el smoke físico y el bloqueo intermedio, ya resuelto. **La sección 13 contiene la aceptación física completada y prevalece para la evaluación final.**

## 1. Baseline y alcance

- Rama inicial: `main`.
- HEAD y `origin/main`: `d2a3e38fcd597bfe29227a88eff8604221e21895`.
- Working tree inicial limpio: `git status --short` sin entradas; hubo advertencias de acceso al archivo global de ignore de Git, sin fallo del comando.
- Historial verificado: Phase 14 en `4cfec2b`; Phase 15 en `d2a3e38`.
- El reporte histórico de Phase 15 describe su baseline anterior a esos commits. Para esta fase se usa el estado real actual de Git indicado arriba.
- Catálogo conservado: 30 calculators, 44 modes, 8 Learn visually scenes, 6 Playgrounds, 6 categories. La prueba existente `registry alone enables exactly six Playgrounds and preserves catalog` verifica estos totales y pasó en la ejecución actual.
- Sin cambios de producción, tests, dependencias, arquitectura, matemáticas, tolerancias, parsers, conversiones, result models o CalculatorViewModel. Sin commit, tag, push, amend, reset ni reescritura del historial.

Se leyó el reporte de Phase 15 como antecedente. Sus 12 escenarios Android 11/API 30/x86_64 pertenecen a un **emulador**, no a un dispositivo físico ni a ejecución ARM. No se repitieron ni se contabilizaron como aceptación física de Phase 16.

## 2. Entorno y detección de dispositivos

SDK localizado mediante `android/local.properties`. ADB no estaba en PATH; se utilizó `C:\Users\macia\AppData\Local\Android\Sdk\platform-tools\adb.exe`.

- ADB: 1.0.41, platform-tools 37.0.0-14910828.
- Host informado por ADB: Windows 10.0.26300.
- Flutter: 3.47.2 stable, framework `d3b14c8769`, engine revision `a804b26164`.
- Dart: 3.13.2, host `windows_x64`.
- Node: v24.15.0.

El primer intento restringido no pudo ejecutar ADB (Access is denied). Se repitió con acceso autorizado al SDK: el daemon se inició correctamente en tcp:5037 y `adb devices -l` terminó con exit 0. Su única salida de inventario fue `List of devices attached`, sin filas. Esto no es un dispositivo offline ni unauthorized; no existe un transporte enumerado. Una invocación restringida de Flutter que no produjo resultados se interrumpió; los gates se ejecutaron con acceso autorizado a las cachés existentes, sin actualizar el SDK.

| Categoría | Evidencia de esta fase |
|---|---|
| Android físico | Ningún transporte ADB accesible |
| Emulador | Ningún transporte enumerado; no se inició uno |
| Android ARM/ARM64 | Sin ejecución; inclusión de bibliotecas en APK no equivale a ejecución |
| Android x86/x86_64 | Sin ejecución en esta fase |
| Host Windows x64 | Ejecución de tests y herramientas locales |

Serial, modelo, fabricante, fingerprint, Android, API, ABI/ABI list, resolución y densidad: **no disponibles**, porque no existe un dispositivo consultable. No se intentaron instalación ni lanzamiento sin un destino válido.

Evidencia local: `build/phase16/adb-version.log`, `adb-devices-start.log`, `adb-devices-final.log` y los logs de versiones del SDK. Los archivos bajo `build/` están ignorados por Git; son evidencia local, no anexos versionados. El reporte resume sus resultados para revisión.

## 3. Matriz de aceptación física

Todos los escenarios siguientes tienen estado **BLOCKED / no ejecutado en hardware físico**. El motivo común es la ausencia de dispositivo, no un defecto reproducido de la app.

| Escenario requerido | Evidencia que falta |
|---|---|
| Cold launch y relaunch | Instalación release, arranque tras force-stop y reapertura real |
| Home, Tools y navegación | Interacción y capturas del dispositivo |
| Search | Consulta exacta/conceptual, vacío y retorno con query conservada |
| Categories | Acceso y navegación entre categorías reales |
| Favorites | Agregar/quitar y persistencia tras reinicio del proceso |
| Recents | Orden, promoción sin duplicados y persistencia física |
| Input, validation, result | Teclado real, error recuperable y resultado coherente |
| Back | Back del sistema y controles internos desde rutas y modal |
| Background/resume | Salida a Home de Android y retorno al mismo proceso |
| Process restart | Reinicio y restauración de preferencias/Recents, diferenciados del estado efímero del formulario |
| Learn visually | Apertura, interacción, cierre y coherencia con el resultado |
| Explore interactively | Edición, actualización y retorno al formulario |
| Ruta integrada Newton | Calculator → cálculo válido → Learn → return → Explore → return |
| Texto 200% | Ajuste real, scroll, controles y ausencia de clipping/overflow |
| Light/dark | Uso en ambos temas sobre el dispositivo |
| Rotación/configuración | Cambios permitidos por el dispositivo, continuidad y diagnóstico |
| Teclado/focus | IME del dispositivo, dismiss, scroll y orden de controles |
| Uso sostenido | Sesión sobre la misma instancia, navegación/cálculos/escenas/Playgrounds repetidos |

## 4. Runtime, uso sostenido y mediciones

Tiempo de sesión física: **ninguno**. No se capturaron logcat, crash buffer, exit-info, ANRs ni excepciones Flutter/Dart de una app instalada en esta fase. No se afirma «cero crashes», «sin ANRs» ni estabilidad sostenida. Los tests locales finalizaron correctamente, pero su duración no representa una sesión release de usuario.

- Memoria: sin muestras PSS/RSS/heap ni serie temporal antes/durante/después. No se puede evaluar crecimiento, recuperación o leak; no se clasifica memory leak.
- Rendimiento: sin gfxinfo/framestats ni medición de frames de un dispositivo. No se afirman FPS, fluidez sostenida ni ausencia de degradación.
- Batería y temperatura: sin lecturas. No se hace ninguna inferencia energética o térmica.
- Rotación/configuración: las pruebas Flutter simulan tamaños y cambios de plataforma; no verifican callbacks ni comportamiento real de Android físico.

## 5. Accesibilidad estructural y evidencia automatizada

Se inspeccionaron navegación inferior, Home/Search, favoritos, formulario, resultado, router, Playground, sheet visual y controles de visualización, junto con sus regresiones existentes.

- Navegación inferior: Semantics con label Home/Favorites/Tools/Settings, button, selected y onTap. ExcludeSemantics evita duplicar el contenido visual, incluso cuando el modo compacto oculta texto. Orden estructural de los cuatro destinos estable.
- Back, Back to calculator, Close visualization, Clear search y Copy result tienen tooltips; favoritos incluyen nombre del calculator y acción Add/Remove.
- Inputs y selectores usan labels de formulario; unidades tienen labels específicos. TextInputAction.next en inputs; Calculate y cambios de ruta eliminan focus; scroll dismiss del teclado en Home, formulario y Playground.
- Search no solicita autofocus; conteo, errores y resultados incluyen live regions donde corresponde.
- Playground declara ReadingOrderTraversalPolicy. Controles de sliders incluyen label y semanticFormatterCallback con valor/unidad. VisualScene aporta descripción semántica en lugar de depender únicamente del canvas.
- Theme define targets mínimos de 48×48 para IconButton y 48×52 para FilledButton. Son constraints estructurales; la evidencia de tamaño/contraste ejecutada corresponde a las superficies cubiertas por los tests, no a todos los controles físicos.

La suite actual incluye Tab/Enter real dentro del widget harness para Clear/result, semántica de capacidades, guías de targets Android/etiquetas/contraste en discovery y catálogo, ambos temas con texto al 200%, y travesía de accesibilidad simulada que excluye la navegación del modal visual. También verifica inputs, selectores, teclado simulado y layouts de Playgrounds. Todas estas pruebas pasaron; no certifican un orden de lectura completo en TalkBack sobre hardware.

**TalkBack audible/manual: no ejecutado, sin verificación auditiva humana.** No se usa XML, UIAutomator ni Semantics para declarar lectura audible PASS.

Secuencia manual corta para el owner, una vez conectado el dispositivo:

1. Activar TalkBack y confirmar que Home, Tools, Favorites y Settings se leen una vez, con estado seleccionado y acción correcta.
2. Buscar `F=ma`; escuchar label de Search, Clear, conteo, Newton y acción de favorito. Navegar mediante swipes y activar mediante doble tap.
3. Abrir Newton; recorrer mass, unidad, acceleration, unidad y Calculate. Probar mass inválida y escuchar el error; luego mass 2 kg y acceleration 3 m/s², escuchando 6 N con unidad.
4. Abrir Learn visually, confirmar descripción/cantidad y controles; comprobar que el modal no lleva focus a Home. Cerrar y confirmar retorno útil de focus.
5. Abrir Explore interactively, recorrer campos/resultado/escena, editar acceleration a 4 y escuchar 8 N; volver y confirmar coherencia del formulario.
6. Repetir navegación esencial con texto al 200%; registrar etiquetas duplicadas, controles omitidos y cualquier problema de lectura/focus. Restaurar ajustes originales.

Esta secuencia está preparada, no completada.

## 6. Coherencia de Newton y arquitectura

Router entrega el CalculatorViewModel del formulario mediante `extra` a Playground cuando corresponde a la misma definición. Playground lo toma prestado y no lo dispone; solo crea y dispone una instancia propia para entrada directa. Learn visually recibe el mismo VM, y los modelos visuales derivan del reporte calculado.

Las regresiones existentes ejecutadas comprueban identidad del VM/reporte, conservación de edición al volver/reabrir, aprendizaje visual y Back para Newton y los otros Playgrounds; también cubren fuerza con signo, unidades y mass inválida. Esto sustenta coherencia en el harness local, pero no completa la ruta física exacta solicitada.

Para aceptación física pendiente: introducir 2 kg y 3 m/s², calcular 6 N, abrir Learn sin editar y volver; abrir Explore sin editar y confirmar 6 N, editar acceleration a 4, confirmar 8 N y volver al formulario con esos mismos valores. Verificar que escenas y resultado siguen el reporte único. Capturar cada transición y logcat sobre el mismo proceso.

## 7. Defectos y decisiones

| Clasificación | Reproducción/evidencia | Impacto y decisión |
|---|---|---|
| ENVIRONMENT / INVALID TEST ASSUMPTION | ADB inicialmente denegado por sandbox; ejecución autorizada posterior exit 0 | Resuelto para inventario; no se modifica producción |
| ENVIRONMENT / INVALID TEST ASSUMPTION | `adb devices -l` sin filas | Bloquea toda aceptación física; no simular PASS ni sustituir con emulador |

No se reprodujo defecto de producto en los gates locales. No hay base para clasificar BLOCKER, MAJOR, MINOR, UX, ACCESSIBILITY o PERFORMANCE de producto, ni para aplicar correcciones preventivas. La falta de dispositivo es un bloqueo de evidencia, no un fallo demostrado de Engineering Toolkit.

## 8. Regression gates actuales

Todos se ejecutaron sobre HEAD actual, sin editar producción ni añadir tests.

| Gate | Resultado | Evidencia en `build/phase16/` |
|---|---|---|
| `flutter test --reporter expanded` | 572/572, exit 0 | `flutter-test.log` |
| `flutter analyze` | No issues found, exit 0 | `flutter-analyze.log` |
| `dart format --output=none --set-exit-if-changed lib test tool` | 145 archivos, 0 cambios, exit 0 | `format.log` |
| `dart run tool/test_domain.dart` | 283/283, exit 0 | `domain.log` |
| `dart compile js tool/test_domain_web.dart -o build/phase16/domain.js` | Exit 0 | `js-compile.log` |
| `node build/phase16/domain.js` | Exit 0, éxito silencioso | `node-domain.log` |
| `git diff --check` | Exit 0 | `diff-check.log` |

El runner JS recorre las mismas 283 closures de allCalculationCases y falla ante cualquier excepción; no imprime un conteo. Su éxito es exit 0 junto con compilación exit 0, no un conteo inventado de salida. `gate-exits.log` registra los códigos de salida de gates y builds.

## 9. Builds release

| Build desde HEAD actual | Resultado | Artefacto |
|---|---|---|
| `flutter build apk --release` | Exit 0; assembleRelease 30.0 s; 52,672,577 bytes | `build/app/outputs/flutter-apk/app-release.apk` |
| `flutter build appbundle --release` | Exit 0; bundleRelease 3.3 s; 51,381,587 bytes | `build/app/outputs/bundle/release/app-release.aab` |

APK SHA-256: `BB58A8EEC4E6C3AAC7AE12F17F4304369451939E6C0CBB4B89EDA2656A43958B`.

AAB SHA-256: `0C29AE64181DFCFA4EC027BD8F62A3F7B9E48F79BF5BE4CD82AA909BF600D741`.

La APK se obtuvo de la invocación release actual desde HEAD y tiene timestamp de salida 2026-10-04 05:00:47 UTC (2026-10-03 23:00:47 America/Mexico_City). Se usó el build incremental normal, sin clean ni cambios de fuente. El AAB conserva timestamp 2026-10-01 20:17:32 UTC: Gradle reutilizó la salida existente en la invocación exit 0; no se afirma regeneración completa del AAB. Ambos hashes coinciden con los de Phase 15, coherente con producción sin cambios; esa coincidencia no demuestra ejecución física.

Se inspeccionó el contenido ZIP de ambos: `libapp.so` y `libflutter.so` para `armeabi-v7a`, `arm64-v8a` y `x86_64` (prefijo `base/` en AAB). Esto verifica presencia de payload ARM/ARM64/x86_64, sin validar instalación o ejecución en ninguna ABI. Logs: `apk-build.log`, `aab-build.log`; tamaños, timestamps y hashes: `artifacts.json`.

No se altera signing, applicationId (`com.engineeringtoolkit.engineering_toolkit`), targets SDK ni configuración de publicación. La configuración existente conserva signing debug para release; esta fase no la cambia ni la presenta como production signing.

## 10. Trabajo pendiente para cerrar el gate físico

Conectar un Android físico ARM/ARM64 con depuración USB autorizada y transporte ADB en estado `device`. Registrar modelo, fingerprint, Android/API, `ro.product.cpu.abi`, `ro.product.cpu.abilist`, `ro.kernel.qemu`, resolución/densidad e identificación del transporte. Confirmar físicamente que es hardware real; ABI por sí sola no demuestra esa categoría.

Instalar la APK fresca documentada aquí mediante `adb -s <serial> install -r`; ejecutar la matriz y la ruta integrada. Registrar duración real y realizar una sesión sostenida sobre la misma instancia con ciclos de navegación/cálculo/escenas/Playgrounds. Capturar logcat con timestamps, crash buffer, ANR/exit-info cuando disponible, PID y muestras comparables de memoria al inicio, durante y al final; distinguir force-stop deliberado de crash. Anotar degradación observable separada de mediciones. Usar framestats únicamente si proporcionan información interpretable del renderer; no inferir 60 FPS de contadores inadecuados. Batería/temperatura antes/después, si expuestas, serán observaciones exploratorias. Registrar y restaurar theme/font_scale/rotation y otros ajustes alterados. Completar TalkBack audible con el owner y documentar exactamente su alcance.

No se conserva tooling nuevo: solo reporte; logs/artefactos de una ejecución permanecen fuera del producto en `build/phase16/`.

## 11. Git y evaluación final

Estado final: `?? docs/phase16-validation.md`, único archivo no ignorado modificado/agregado; sin cambios de producción. HEAD, rama y origin/main permanecen en el baseline. `git diff --check` exit 0; como el reporte está untracked, también se revisa directamente su whitespace antes de entregar. No se ejecutan acciones de historial. El inventario ADB final volvió a mostrar únicamente el encabezado, sin dispositivos.

**BLOCKED — physical-device evidence unavailable/incomplete**. Los gates locales verifican el baseline y permiten preparar los binarios, pero faltan instalación y escenarios físicos ARM, sesión sostenida, diagnósticos runtime, mediciones comparables y verificación audible humana. No se declara Phase 16 PASS ni readiness para publicación pública.

## 12. Reanudación física — 2026-10-05

### Baseline y dispositivo

Git verificado nuevamente: `main`; HEAD/origin/main `d2a3e38fcd597bfe29227a88eff8604221e21895`; único cambio no ignorado `?? docs/phase16-validation.md`. Sin cambios de producción. Se conservan los gates anteriores sin repetir suites innecesariamente.

ADB explícito del SDK detectó un transporte en estado `device`. Se omite su serial del reporte por no ser necesario para la revisión. El owner confirma hardware físico Xiaomi; las propiedades concuerdan con ese destino y no con el emulador anterior.

| Propiedad | Evidencia física |
|---|---|
| Fabricante / modelo | Xiaomi / 23129RA5FL |
| Android / API | 15 / 35 |
| ABI primaria | arm64-v8a |
| ABI list | arm64-v8a, armeabi-v7a, armeabi |
| ro.kernel.qemu | Vacío |
| Resolución / densidad | 1080×2400 / 440 dpi |
| Font scale inicial y tras intento denegado | 1.0 / 1.0 |
| Rotación inicial | accelerometer_rotation=0, user_rotation=0 |
| Servicios de accesibilidad activos iniciales | null; TalkBack no activo |

Evidencia: `build/phase16/physical/device.txt`, `original-settings.txt`, `font-scale-after-denial.txt`. Estos datos son de hardware físico ARM64; la evidencia API 30/x86_64 de Phase 15 sigue siendo exclusivamente de emulador.

### Build, instalación y smoke físico ejecutado

`flutter build apk --release` desde HEAD actual: exit 0, assembleRelease 23.4 s, 52,672,577 bytes. APK SHA-256 `BB58A8EEC4E6C3AAC7AE12F17F4304369451939E6C0CBB4B89EDA2656A43958B`. `adb install -r` terminó `Success`. Package instalado: versionName 0.2.0, versionCode 2, minSdk 24, targetSdk 36. Sin cambios de identidad, signing, SDK o dependencias. Evidencia: `physical/apk-build.log`, `install.log`, `package.txt`.

| Escenario físico | Resultado y alcance |
|---|---|
| Cold launch | PASS acotado: `am start -W` Status ok, LaunchState COLD, TotalTime 3637 ms; Home visible en XML y PNG |
| Relaunch de instancia existente | PASS acotado: intent entregado a instancia top-most, Status ok; no segundo cold launch |
| Home | PASS acotado: Search, categorías y cuatro destinos presentes; screenshot inspeccionado en tema oscuro |
| Background → resume | PASS acotado: Android Home por intent y retorno; PID 29486 antes/después; Home conservado |
| Reinicio deliberado del proceso | PASS acotado: force-stop y cold launch, PID nuevo 32011, TotalTime 944 ms; Home visible |
| Tools / Search / Categories / Favorites / Recents / calculator / Back / Learn / Explore / teclado | Pendiente: el primer tap a Tools fue rechazado con SecurityException INJECT_EVENTS; no se contabiliza como navegación ejecutada |
| Newton integrado y uso sostenido | Pendiente: sin interacción permitida todavía |
| Texto 200% y restauración | Pendiente: intento de settings put font_scale 2.0 rechazado con WRITE_SETTINGS; intento de restaurar también denegado, readback confirma 1.0 sin modificación efectiva |
| Cambio de tema / rotación | Pendiente; solo tema oscuro inicial observado; ajustes de rotación no alterados |
| TalkBack audible | No ejecutado; requiere confirmación humana, checklist de §5 conservado |

Los tiempos de `am start -W` son mediciones de lanzamiento de Android de dos muestras, sin umbral universal ni equivalencia con tiempo hasta UI plenamente interactiva. La reapertura no comprueba persistencia de Favorites/Recents porque no se pudieron crear entradas aún.

Capturas: `cold-home`, `resumed-home`, `restarted-home` en `build/phase16/physical/` (pares XML/PNG). El helper temporal está en el directorio ignorado `physical/native.ps1`, adaptado del helper ya existente; no forma parte del producto ni del build.

### Diagnósticos parciales y límites

El smoke se realizó aproximadamente 22:26–22:28 America/Mexico_City. No es una sesión sostenida de navegación. Memoria inicial, PID 29486: TOTAL PSS 161,389 KB, TOTAL RSS 291,444 KB. Tras reinicio, PID 32011: PSS 156,474 KB, RSS 282,824 KB. Son procesos distintos; la diferencia no es evidencia de tendencia ni de leak.

`gfxinfo framestats` tras reinicio recoge únicamente tres frames de la tubería Android Skia/OpenGL, todos marcados janky, con percentiles 46–53 ms. Esta muestra de arranque no caracteriza las animaciones/rendering Flutter ni el uso sostenido; no se declara 60 FPS ni defecto PERFORMANCE a partir de ella. Evidencia: `memory-start.txt`, `memory-after-restart.txt`, `framestats-initial.txt`.

El crash buffer global contiene fallos históricos de init y com.miui.misightservice anteriores a esta sesión. No se atribuyen a Engineering Toolkit ni se describe ese buffer como vacío. Logcat del PID 32011 no contiene FATAL EXCEPTION, Fatal signal, E/flutter, Unhandled Exception o ANR. Hay un mensaje `FrameInsert open fail: No such file or directory` del proceso, sin fallo funcional asociado reproducido; no se aplica corrección especulativa. Exit-info muestra únicamente el force-stop deliberado (USER REQUESTED / FORCE STOP) de PID 29486. Evidencia: `app-logcat-after-smoke.txt`, `crash-buffer-after-smoke.txt`, `runtime-markers-after-smoke.txt`, `exit-after-smoke.txt`. Ausencia de markers en este smoke no acredita estabilidad sostenida.

Batería inicial: level 77/100, temperature 344 (34.4 °C según escala Android), AC powered true, status charging. Al final del smoke, level 77/100, temperature 348 (34.8 °C), todavía cargando. Solo observaciones exploratorias de una sesión corta conectada a alimentación; ninguna inferencia de consumo, eficiencia o seguridad térmica. Evidencia inicial y posterior en `battery-initial.txt`, `battery-after-smoke.txt`.

### Bloqueo intermedio y decisión en ese punto

**ENVIRONMENT / INVALID TEST ASSUMPTION:** transporte ADB autorizado no implicó autorización para `adb shell input` ni `settings put system`. Se reprodujeron ambos rechazos y se solicitó al owner habilitar «Depuración USB (ajustes de seguridad)» en el Xiaomi para volver a probar. No se intentó eludir la protección ni cambiar producción. Algunos intentos diagnósticos iniciales usaron un formato de fecha inválido para logcat; se corrigió la captura y no se cuentan esos intentos como evidencia runtime válida.

Conclusión intermedia antes de habilitar los permisos: **BLOCKED — physical-device evidence unavailable/incomplete**. El dispositivo y la instalación física estaban disponibles, pero faltaba autorización para interacción/configuración. El owner confirmó posteriormente la habilitación y los comandos de entrada y escritura volvieron a funcionar. Se preservan tests/builds locales anteriores. Sin commit, tag ni push.

## 13. Aceptación física completada tras habilitación del owner

### 13.1. Identidad del ensayo y autorización

El owner habilitó la autorización adicional de depuración del Xiaomi y pidió volver a intentar. `adb shell input` y escritura de ajustes funcionaron en la continuación. Se usó la APK fresca de §12, compilada desde el HEAD actual, ya instalada con `Success`; no se modificó producción entre build y ensayos. `dumpsys package` confirma **primaryCpuAbi=arm64-v8a**, secondaryCpuAbi=null (`package-abi.txt`). Esto identifica la ABI del paquete ejecutado, además de la ABI del dispositivo. No se expone serial, IMEI ni otro identificador innecesario.

Todo lo siguiente corresponde al **Xiaomi físico 23129RA5FL / Android 15 / API 35 / ARM64 / 1080×2400 / 440 dpi**. No se traslada a él la aceptación x86_64 del emulador anterior.

La evidencia está en `build/phase16/physical/`, ignorada por Git. En las tablas, los nombres sin extensión identifican pares XML/PNG; los logs indicados conservan sus extensiones. Se inspeccionaron visualmente capturas representativas de Home, resultados, Learn, ambos temas, IME, formulario al 200%, tarjeta con capacidades, Playground y no-results. XML corroboró valores/etiquetas y no se usó como evidencia audible.

### 13.2. Matriz física realmente ejecutada

| # | Escenario | Resultado físico y evidencia |
|---|---|---|
| 1 | Cold launch | PASS acotado: Status ok, COLD, Home visible. `cold-launch.log`, `cold-home`; el tiempo Android de 3637 ms es una muestra, no un umbral de aceptación universal. |
| 2 | Relaunch | PASS: instancia existente traída al frente; también HOT en el reintento posterior. `relaunch.log`, `permission-retry-home`. |
| 3 | Home | PASS: Search, categorías, Recents y destinos; Home final operativo. `cold-home`, `recents-newton`, `final-home`. |
| 4 | Tools | PASS: catálogo de 30 tools y controles de field/search. `tools`. |
| 5 | Search exact title | PASS: `Voltage Divider` produce una tarjeta con ambas capacidades. `search-exact`. |
| 6 | Search concept | PASS: `F=ma` produce Newton; `vector length` produce Vector en los ciclos. `search-concept`, `sustained-dump-recovery`. |
| 7 | Categories | PASS representativo: Mechanical y Electrical abren sus seis tools y permiten Back. `category-mechanical`, `category-electrical`. No se afirma recorrido físico exhaustivo de las seis categorías. |
| 8 | Favorites add/remove/persistence | PASS: Newton agregado, mostrado, restaurado tras force-stop/relaunch, eliminado y eliminación restaurada tras otro reinicio. `favorite-added`, `favorites`, `favorites-restored`, `favorite-removed`, `favorite-removal-restored`. |
| 9 | Recents order/persistence | PASS: tras los ciclos, Vector → Torque → Newton sin duplicados; ese orden se conserva tras reinicio. Abrir Newton después lo promueve: Newton → Vector → Torque en Home final. `recents-before-restart{,-lower}`, `recents-restored{,-lower}`, `final-home`. |
| 10 | Calculator input | PASS: edición real mediante eventos ADB en campos Flutter, valores con signo y edición live. `newton-input`, `newton-return-inputs`, capturas sustained. |
| 11 | Validation | PASS: mass=-1 produce `Mass must be zero or greater.` y guía de inputs; corregir a 2 permite calcular. `newton-invalid`, `newton-result`. |
| 12 | Calculation/result | PASS: Newton 2×3=6 N, edición 2×4=8 N; casos sostenidos de Newton con signo, Torque y Vector. `newton-result`, `newton-return-8N`, verificaciones exactas descritas en §13.4. |
| 13 | Back navigation | PASS: Back de Android desde Playground/calculator/category, cierre de Learn y retorno con query/valores coherentes; controles internos también ejercitados. `newton-return-8N`, `newton-return-inputs`, capturas sustained de retorno. |
| 14 | Background → resume | PASS: Home conservado con PID 29486 antes/después; luego formulario Light conserva 2 kg, 3 m/s² y 6 N con PID 23170 antes/después. `resumed-home`, `calculator-resumed-6N`, `config-pid-{before,after}-background.txt`. |
| 15 | App/process restart | PASS: PID cambia solo en force-stops deliberados; Home, Favorites y Recents restauran el estado persistente. `process-restart.log`, `persistence-restart.log`, `removal-persistence-restart.log`, `final-exit-info.txt`. No se exige persistir el resultado efímero del formulario. |
| 16 | Learn visually | PASS: Newton, Torque y Vector abren escenas cuya descripción coincide con el cálculo. Newton también tras rotación y al 200%. `newton-learn`, `sustained-*-learn`, `rotation-learn-retained`, `large-learn-*`. |
| 17 | Explore interactively | PASS: inputs y resultado heredados; edición live y retorno coherente en los tres calculators. `newton-playground*`, `sustained-*-{playground,edited,return}`, `large-playground-*`. |
| 18 | Keyboard/focus | PASS acotado: IME numérico visible, resize/scroll y dismiss al calcular; Tab/Tab/Enter con eventos separados abre Newton desde Search. `keyboard-numeric-visible`, `keyboard-tab{1,2}`, `keyboard-enter`, `light-newton-6N`. Eventos inyectados; no teclado físico externo ni auditoría humana exhaustiva de cada IME. |
| 19 | 200% system text | PASS en superficies ejercitadas: readback 2.0, formulario y cálculo, Learn, Playground, Search con capacidades y no-results; scroll expone contenido/acciones. `large-font-scale.txt`, `large-calculator-*`, `large-learn-*`, `large-playground-*`, `large-search-*`, `large-no-results-*`. |
| 20 | Original text scale restoration | PASS: finally y readback final 1.0. `restored-font-scale.txt`, `final-font-scale.txt`, `font-scale-restored-home`. |
| 21 | Theme/configuration | PASS acotado: Light y Dark aplicados; System original restaurado. Landscape 2400×1080 y retorno a portrait conservan 6 N y la descripción Learn. user_rotation=0 y accelerometer_rotation=0 restaurados/conservados. `settings-{light,dark,restored-system}`, `newton-landscape`, `newton-rotation-restored`, `rotation-learn-retained`, `final-theme-restored`, `final-*-rotation.txt`. |

### 13.3. Ruta integrada Newton y coherencia

Se ejecutó en hardware: calculator → cálculo válido **2 kg / 3 m/s² / 6 N** → Learn visually con descripción `Mass 2 kg. Input acceleration 3 m/s². Calculated net force 6 N` → cierre y formulario todavía con 6 N → Explore interactively con inputs 2/3 y 6 N → edición de acceleration a 4 → retorno al formulario con inputs 2/4, resultado **8 N** y sustitución `F = 2 kg × 4 m/s²`.

Evidencia: `newton-result`, `newton-learn`, `newton-playground`, `newton-playground-result`, `newton-playground-edited`, `newton-return-8N`, `newton-return-inputs`. Los nodos exactos de resultado se comprobaron además de inspeccionar las capturas. Rotación y el ensayo al 200% conservaron otro cálculo 2/3/6, incluida la descripción del modelo visual.

Esto concuerda con el router/VM único inspeccionado en §6 y con los tests existentes de identidad del VM/reporte. No apareció un cálculo divergente en las rutas físicas ejercitadas. No se añadió motor, registry ni estado alternativo, ni se cambió dominio matemático.

### 13.4. Sesión sostenida

- Inicio: **2026-10-05 22:36:25**, America/Mexico_City.
- Fin: **2026-10-05 22:58:45**, misma zona.
- Tiempo transcurrido: **22 min 20.747 s**, incluyendo capturas, diagnósticos y pausas/correcciones del tooling. No se presenta como 22 minutos de interacción humana continua ni como duración mínima universal.
- **12 ciclos completos**, cuatro por calculator, alternando Newton, Torque y Vector. Todos sobre la misma instalación release y **PID 32011**; el helper comprobó PID al cierre de cada ciclo. Los reinicios para persistencia ocurrieron después de la sesión.

Cada ciclo hizo Search → calculator → inputs → Calculate → Learn y comprobación de descripción → return → Playground → edición live → return → Favorites add/remove → sección Favorites → Home/Clear → Recents → muestra de memoria. Los cambios temporales de favoritos se deshicieron dentro del ciclo; Newton, agregado para aceptación, se conservó hasta comprobar persistencia y después se eliminó.

| Calculator | Cálculo inicial por ciclo | Edición y retorno |
|---|---|---|
| Newton | 2 kg × -3 m/s² = -6 N | acceleration=-4 → -8 N |
| Torque | 10 N × 2 m = 20 N·m | lever arm=3 → 30 N·m |
| Vector 2D | x=3, y=4 → 5 | y=0 → 3 |

`sustained-cycles.log` contiene los 12 cierres con timestamps/PID/resultados. `sustained-<n>-{calculated,learn,playground,edited,return,favorites,recents}.{xml,png}` conserva los estados. La revisión posterior comprobó **un nodo exacto de resultado, excluyendo EditText, en los 12 cálculos y 12 retornos** (`sustained-exact-results.log`) y las 12 descripciones Learn. No se contó una coincidencia arbitraria de un número en bounds/XML como cálculo correcto.

No se observó navegación rota, resultado obsoleto, pantalla de error ni degradación progresiva en los estados capturados. La cadencia del helper incluye esperas de UIAutomator, ADB y screenshots; no se usa como medición de latencia perceptiva ni FPS. Una interrupción de captura ADB se recuperó con la app viva y el mismo PID; se documenta en §13.9.

### 13.5. Memoria: mediciones e interpretación

Muestras `dumpsys meminfo` sobre PID 32011, tras volver a Home/Clear al cerrar cada ciclo. Los Recents se poblaron hasta tres entradas durante los primeros ciclos; no son snapshots de un heap idéntico. KB son los valores reportados por Android.

| Muestra | TOTAL PSS (KB) | TOTAL RSS (KB) | TOTAL SWAP PSS (KB) |
|---|---:|---:|---:|
| Inicio sostenido | 218172 | 342184 | 6809 |
| Ciclo 1 | 215657 | 340348 | 5865 |
| Ciclo 2 | 210178 | 338664 | 5758 |
| Ciclo 3 | 213212 | 338052 | 5734 |
| Ciclo 4 | 216327 | 338248 | 5740 |
| Ciclo 5 | 216974 | 339128 | 5744 |
| Ciclo 6 | 217881 | 339720 | 5757 |
| Ciclo 7 | 217213 | 339144 | 5758 |
| Ciclo 8 | 214234 | 339052 | 5758 |
| Ciclo 9 | 208119 | 333324 | 6230 |
| Ciclo 10 | 208064 | 333192 | 6233 |
| Ciclo 11 | 203610 | 330672 | 8502 |
| Ciclo 12 | 208504 | 328740 | 10915 |
| Fin sostenido, segunda lectura | 182522 | 299860 | 10915 |

Los cierres de ciclo oscilan entre 203610 y 217881 KB PSS; no hay crecimiento monotónico en esta serie. La lectura final es menor, pero swap PSS aumenta: **no se interpreta la caída como prueba de liberación completa ni de ausencia de leaks**. No hay evidencia reproducible suficiente para clasificar memory leak, OOM o defecto de memoria. Tampoco se garantiza comportamiento indefinido con cargas no ejercitadas.

La muestra fría 161389 KB PSS de §12 pertenece a PID 29486 y a un estado previo; no se mezcla con esta serie para calcular una supuesta tendencia. Evidencia: `sustained-memory-start.txt`, `sustained-memory-1.txt` a `-12.txt`, `sustained-memory-end.txt`, `sustained-memory-summary.json`.

### 13.6. Frames y rendimiento

`sustained-framestats-end.txt` de PID 32011 reportó en el contador Android: **4745 frames rendered; 626 janky (13.19%); legacy 2098 (44.21%); percentiles 50/90/95/99 de 20/32/38/53 ms**. Pipeline informado: Skia/OpenGL. Las dos definiciones de jank no son intercambiables ni se suman.

El contador abarca la vida de ese proceso desde aproximadamente 22:27, incluyendo preparación, IME, navegación, capturas y periodos sin interacción; no fue reseteado ni aislado a los 22 minutos sostenidos. Es evidencia de jank en esos contadores y se conserva para revisión. No determina por sí solo la causa o la contribución de Flutter frente a la ventana Android/IME y al trabajo de automatización. No se convierte en un promedio FPS ni en «60 FPS estable».

No se reprodujo un slowdown progresivo o un control que dejara de responder. **Limitación PERFORMANCE:** falta un benchmark de renderer/latencia sin el observador UIAutomator y sin mezclar escenarios. No se inventan thresholds ni se aplica una optimización sin defecto demostrado; los números anteriores no se esconden ni se reinterpretan como fluidez perfecta.

### 13.7. Runtime, crashes, ANRs y exits

- Capturas del PID durante la sesión (`sustained-logcat-{early,mid,end}.txt`) y del proceso final (`final-app-logcat.txt`): **0 coincidencias** para FATAL EXCEPTION, Fatal signal, Unhandled Exception, E/flutter, ANR in o am_anr.
- `sustained-last-anr-end.txt` y `final-last-anr.txt`: Android informa `<no ANR has occurred since boot>`.
- `sustained-exit-end.txt`: solo force-stop deliberado previo al ensayo. `final-exit-info.txt`: tres salidas USER REQUESTED / FORCE STOP, correspondientes a los reinicios intencionales de PID 29486, 32011 y 22479. No hay salida anormal de la app registrada en este historial.
- PID final **23170**, vivo en Home. Ese proceso también sobrevivió background/resume, rotation y font_scale sin cambio de PID.
- `final-crash-buffer.txt` contiene los fallos históricos de init y com.miui.misightservice descritos en §12, anteriores a la sesión. No es un buffer vacío ni evidencia de crashes de Engineering Toolkit.
- `runtime-critical-stream.log` capturó errores de forma continua **hacia el cierre del ensayo y durante configuración**, incluyendo contenido histórico del buffer al iniciar el collector. No se afirma captura continua de toda la sesión: para el tramo anterior se usaron snapshots. Se filtraron asociaciones de proceso y tiempo al interpretar errores globales. El collector temporal se detuvo deliberadamente al cerrar.

Se observó el mensaje no fatal `FrameInsert open fail: No such file or directory` en procesos de la app, también después de reinicios. No se reprodujo un fallo funcional asociado ni se demostró su causa; no se atribuye especulativamente a dominio/VM ni se modifica producción para suprimirlo. Las afirmaciones de estabilidad se limitan a las rutas, observaciones y diagnósticos disponibles, no a todas las posibles excepciones futuras.

### 13.8. Batería y temperatura exploratorias

Al inicio sostenido: **77/100**, temperature **341 = 34.1 °C**. Al final: **84/100**, temperature **335 = 33.5 °C**. Android reportó AC powered=true y status=2 (charging) en ambas lecturas. Evidencia: `sustained-battery-start.txt`, `sustained-battery-end.txt`; lectura intermedia en `sustained-battery-mid.txt`.

Son observaciones del servicio de batería mientras el teléfono estaba conectado a alimentación. La temperatura corresponde a esa lectura de batería, **no a una medición validada de CPU/GPU o de thermal throttling**. No se deriva consumo energético, eficiencia de carga, seguridad térmica ni garantía de batería de esta sesión.

### 13.9. Accesibilidad, limitaciones y defectos

La evidencia estructural y automatizada previa se conserva en §5. En el dispositivo se corroboraron labels de navegación/favoritos/Back/capacidades, descripciones de escena y resultados coherentes; Tab/Enter ejercitó una ruta real de foco. Al 200% la navegación compacta oculta texto visual de destinos, pero conserva labels Home/Favorites/Tools/Settings en XML. Se inspeccionaron wraps y scroll de las superficies enumeradas; no se observó overflow ni recorte horizontal de tarjetas/acciones en esas capturas. El campo Search sigue siendo de una línea y una consulta larga puede desplazarse horizontalmente mientras se edita; eso no se cuenta como truncación de la tarjeta o pérdida de la consulta.

**TalkBack audible: requiere confirmación manual humana; no PASS audible.** No se activó ni se fingió escuchar TalkBack. Servicios activos iniciales/finales: null. El checklist de §5 queda disponible para que el owner confirme lectura, duplicados y focus movement en este Xiaomi. XML/Semantics no sustituyen esa confirmación.

| Clasificación | Reproducción / impacto | Decisión |
|---|---|---|
| ENVIRONMENT / INVALID TEST ASSUMPTION | ADB autorizado inicialmente no permitía INJECT_EVENTS/WRITE_SETTINGS | Resuelto al habilitar la autorización de seguridad por el owner; se completaron los escenarios posteriores. |
| ENVIRONMENT / INVALID TEST ASSUMPTION | Primer reintento con coordenada antigua cuando otra app estaba al frente | No se cuenta como acción de Toolkit; capturas ajenas descartadas. App llevada al frente y guard de package añadido al helper antes de inputs posteriores. No se expone contenido ajeno en el reporte. |
| ENVIRONMENT / INVALID TEST ASSUMPTION | Query `Torque` coincidía con EditText y tarjeta | Helper temporal distingue acciones de campos; retomado desde ciclo 2, sin reiniciar app ni contar doble el ciclo 1. |
| ENVIRONMENT / INVALID TEST ASSUMPTION | Dump interrumpido durante ciclo 6; ADB daemon reiniciado | Window focus y PID confirmaron app viva; captura recuperada y ciclo completado desde interacciones pendientes. No es crash/ANR de la app. |
| ENVIRONMENT / INVALID TEST ASSUMPTION | Burst Tab/Tab/Enter no abrió tarjeta; foco aún en transición | Eventos separados con capturas abren Newton correctamente; no se aplica workaround en producción. |
| PERFORMANCE / limitación de diagnóstico | Jank en contador Android; sin causa aislada ni slowdown progresivo reproducido | Valores conservados en §13.6; no claim de FPS ni optimización especulativa. |

No se reprodujo defecto de producto que justifique corrección BLOCKER, MAJOR, MINOR, UX o ACCESSIBILITY. No se clasifica memory leak. Los límites anteriores se mantienen visibles para revisión técnica; no se convierten en garantías de rendimiento o accesibilidad audible.

### 13.10. Regression gates, builds, Git y restauración

Sin cambios de producción, se preservan los gates válidos de la primera ejecución: **572/572 Flutter tests; 283/283 Dart cases; 283 closures JS/Node con compilación/ejecución exit 0; analyzer limpio; 145 archivos, 0 cambios de formatter; APK/AAB release exit 0**. No se repitieron suites solo para incrementar evidencia. El AAB continúa con el alcance incremental y hash descritos en §9; la APK para la instalación física fue una nueva invocación release desde HEAD, exit 0, descrita en §12. Sus hashes coinciden porque la producción no cambió.

Git final: `main`, HEAD y origin/main `d2a3e38fcd597bfe29227a88eff8604221e21895`; único cambio no ignorado `?? docs/phase16-validation.md`. `git diff --check` y revisión directa de whitespace/conflict markers del reporte untracked pasan. Sin commit, tag, push, amend, reset, staging ni reescritura de historial.

Readbacks finales: **font_scale=1.0, user_rotation=0, accelerometer_rotation=0, theme=System, enabled_accessibility_services=null**. App dejada viva en Home con query despejada, Favorites vacío tras comprobar eliminación, y Recents de los calculators ejercitados. La autorización de depuración habilitada voluntariamente por el owner no se revierte. Helpers/collectors de una ejecución permanecen únicamente en `build/phase16/physical/` para revisión junto con sus logs; no se incorporan al producto ni crean infraestructura permanente. Screenshot temporal remoto eliminado; collector detenido.

### 13.11. Evaluación final

**PASS WITH LIMITATIONS — ready for technical review**.

La release actual ejecutó correctamente los flujos representativos y el uso sostenido descritos en el Xiaomi físico ARM64, con coherencia de cálculo/visualización/Playground, persistencia y configuración restaurada. Se retiraron los bloqueos físicos originales sin fabricar evidencia ni modificar producción.

Límites restantes: un dispositivo/API/ABI, tres calculators en los ciclos sostenidos, cobertura representativa y no los 30 calculators/44 modes íntegros en hardware; diagnóstico de frames con jank sin benchmark independiente ni garantía FPS; batería/temperatura exploratorias bajo carga; TalkBack audible pendiente del owner. Los gates locales cubren el catálogo completo dentro de su propio alcance y no se reinterpretan como una matriz física completa.

Engineering Toolkit **no se declara lista para publicación pública**, ni se inicia Phase 17. Todos los cambios de esta fase quedan disponibles para revisión técnica en el reporte existente.
