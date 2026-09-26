# Phase 9 Release Candidate Validation

## Dictamen y alcance

**Viable como RC Android interna en el entorno validado; no preparada para tienda.** No se reprodujeron blockers de producto pendientes. Se conservan 30 calculadoras, ocho escenas Learn visually y tres Playgrounds. Sin cambios de motores, fórmulas, unidades, IDs o dependencias; sin publicación. La firma sigue siendo la debug existente, no una firma de distribución.

La fase parte del árbol de trabajo de Phase 8, que ya contenía modificaciones y archivos sin commit de fases anteriores. No se descartaron ni se atribuyen a Phase 9. Los únicos cambios de producción de esta fase son la inyección de PreferencesController en Playground y el registro de apertura; además se añaden pruebas, una utilidad de capturas y documentación.

## Baseline y entorno

Antes de modificar código: **482/482 tests Flutter**, **247/247 casos Dart**, los mismos **247 casos compilados a JavaScript y ejecutados en Node con exit 0**, analyzer sin incidencias, formatter sin cambios, `git diff --check` limpio y APK debug compilado.

- Windows 11, build 26200.9457; Flutter 3.47.2 stable, Dart 3.13.2.
- Android Emulator 36.5.11, AVD existente Pixel_7, Android 17/API 37, x86_64, imagen `google_apis_ps16k`, 1080×2400, 420 dpi, 2 GB de RAM configurada.
- Runtime estable: `-no-snapshot -gpu host`, GPU anfitriona NVIDIA RTX 4050 Laptop; Flutter usó Impeller/OpenGLES. No se borraron datos del AVD ni se modificó su configuración guardada.
- Tres intentos con frontend headless/renderizado software terminaron en fallos del proceso QEMU anfitrión, excepción Windows `0xc0000005`. El cambio de parámetros de ejecución permitió completar smoke debug/release/profile. No se corrigió código de la app para eludir esos fallos.
- El sandbox bloqueaba SDK/ADB; las validaciones se ejecutaron con el acceso autorizado al entorno local. No es una falla de producto.
- No había dispositivo físico ni runtime Apple. Chrome conserva la incidencia conocida de bootstrap; no se reabrió la investigación, al no aparecer una causa pequeña y evidente.

## Defecto reproducido y corregido

**Aperturas directas de Playground ausentes de Recents.** La prueba abrió los tres `/playground/:id` directamente y obtuvo `null` como primer recent, en lugar del ID recién abierto. Solo CalculatorScreen registraba aperturas.

PlaygroundScreen recibe ahora el mismo PreferencesController y llama `recordOpened` después del primer frame, con guardia `mounted`. Conserva el filtro de IDs, orden, límite de cinco y persistencia existentes; no añade almacenamiento, estado de cálculo ni cambios al ViewModel. Una entrada desde formulario sigue siendo idempotente. La regresión abre los tres pilotos, comprueba orden y restaura el repositorio; los tests anteriores conservan propiedad/disposición del VM prestado y local.

No se detectaron otras fallas de producto que justificaran refactor o cambios de arquitectura. Los ajustes de automatización para scroll lazy, foco/teclado y capturas nativas no son defectos de la aplicación. Los dumps UiAutomator que no producen árbol nuevo no cuentan como evidencia nueva.

## Matriz del producto

“Automatizado” significa tests de widgets/repositorio/VM ejecutados en esta fase, no prueba nativa ni escucha de audio.

| Superficie | Automatizado | Android nativo de Phase 9 |
| --- | --- | --- |
| Home | Arranque, secciones, categorías, Back y layouts del catálogo completo | Release y profile: Home, Recents, navegación inferior y capturas |
| Search | Query normal/parcial, sin resultados, limpiar, navegación y teclado | Release: `voltage`, tres resultados, abrir divisor |
| Tools | 30 definiciones, búsqueda/filtros, seis categorías, listas lazy, IDs/rutas únicos | Release: catálogo de 30 herramientas y scrolling; todos los filtros se verificaron automatizados |
| Favorites | Añadir/quitar, idempotencia, restauración, IDs obsoletos | Release: añadir divisor, reiniciar proceso, comprobar favorito y quitarlo |
| Recents | Orden, promoción, máximo cinco, duplicados/obsoletos y restauración | Release: divisor primero tras reinicio; las entradas directas de gas/IPv4 se reflejan al volver a Home |
| Settings | System/Light/Dark, actualización, valores por defecto y fallos de guardado | Release: tres opciones; Dark persistió tras force-stop/relaunch; System restaurado al terminar |
| Calculadoras | Las 30 rutas se montan; flujos representativos de las seis categorías, errores, modos/unidades y dominio | Release: divisor 12/1000/2000 → 8 V; resultado, fórmula y explicación visibles |
| Learn visually | Las ocho conservan mapper/render/control, error/recuperación, semántica y layout | Release: divisor abre/cierra como modal; gas e IPv4 renderizan además dentro de Playground |
| Playground | Los tres: sincronización, VM prestado/local, rutas, entradas inválidas, unidades/modos, teclado, layouts | Release: los tres; profile: Ideal Gas, desplazamiento, resultado y resume |

Las ocho escenas automatizadas son Voltage Divider, Vector Magnitude, Reynolds, IPv4/CIDR, Newton, Torque, Bernoulli e Ideal Gas. No se afirma haber repetido las ocho manualmente en Android en esta fase.

### Evidencia nativa concreta

- **Divisor release:** formulario → favorito → cálculo 8 V → Learn visually → cerrar → Playground. Cambiar Vin de 12 a 6 produce 4 V; Back del sistema devuelve al mismo formulario con 4 V y sustitución actualizada.
- **IPv4 release:** ruta directa; 192.168.1.10 y /24 → 192.168.1.0/24, 256 direcciones, 254 utilizables y escena 24/8 bits. Entrada incompleta muestra validación antes de recuperar resultado.
- **Gas release:** ruta directa; 1 mol, 300 K, 0.025 m³ → 99773.551418 Pa. Cámara, datos, pausa/reanudación y background/resume. Dos capturas del canvas activo difieren; muestreo cada tres píxeles registra 1070 puntos cambiados. Las dos capturas pausadas registran cero. Esto demuestra la observación puntual de movimiento/pausa, no fps o ausencia de fugas.
- **Gas profile:** mismo resultado; Home, ruta directa, campos, scroll, background/resume. Activar `transition_animation_scale=0` muestra `Reduce Motion is on`; dos capturas completas tienen SHA-256 idéntico. Al restaurar 1.0 vuelve el control de pausa. Se comprobó en el SDK local que Flutter observa esa escala; cambiar solo `animator_duration_scale` no activó la señal y ese ensayo no se cuenta como validación.
- **Reinicio de proceso release:** PID 7668 → force-stop → PID 8729. Home recuperó divisor primero y favorito; Settings recuperó Dark. Es reinicio del proceso, no recreación de widget ni reinicio físico del teléfono. Se preservaron datos preexistentes; instalación fresca se cubre con tests de defaults, no con borrado nativo.
- Al finalizar queda instalado el APK release. Favorito de prueba eliminado, tema System; accesibilidad=0, servicios=null, transition=1.0, animator=null, como antes de las pruebas.

## Persistencia, startup y errores

`main` construye una sola vez el catálogo y restaura un único PreferencesController/LocalPreferencesRepository antes de `runApp`. La lectura tiene límite de dos segundos y fallback a preferencias por defecto. La UI comunica fallos de guardado en Settings. Los tests existentes verifican JSON ausente/malformado/incompatible, campos parciales, IDs desconocidos/duplicados, fallos de lectura/escritura y recuperación de la cola serial. No hay fórmulas ni resultados persistidos.

La búsqueda usa el registro; favoritos y recents resuelven IDs contra él. Modos y unidades invalidan el reporte anterior. Vacíos, números malformados/no finitos, límites y división por cero aplicable siguen la validación tipada. No se añadieron catch globales ni un manejador que oculte errores. Copiar conserva manejo del fallo de plataforma y guardia de montaje.

La lista de resultados es lazy. Las escenas se crean al abrir modal/Playground y contar con reporte válido; startup no crea animaciones. Favoritos/recents no notifican el observable de tema que reconstruye MaterialApp.

## Navegación, lifecycle y recursos

Las nuevas pruebas recorren las 30 rutas reales y las seis categorías, verifican identidades únicas y resolución de búsquedas. `/calculator/obsolete`, `/playground/obsolete`, Playground no soportado, categoría desconocida y ruta inexistente muestran el patrón not-found actual y permiten volver a Home.

Se retienen tests de Home/Search/Tools/Favorites → calculadora → Back, reapertura de modal y Playground, reemplazo de rutas y propiedad del VM. El modal y la ruta raíz impiden interacción con navegación inferior que podría disponer el formulario propietario. Solo el propietario dispone su CalculatorViewModel.

Reynolds e Ideal Gas mantienen un AnimationController por renderer. VisualAnimationLifecycle observa foreground, TickerMode, viewport, pausa y ambas señales Reduce Motion; quita observadores/listeners y dispone el controller. Los tests ejercitan background/resume, ruta cubierta, scroll fuera de viewport y disposición sin callbacks pendientes. Se inspeccionaron TextEditingController y ScrollController: tienen disposición; callbacks posframe/clipboard comprueban montaje. No se añadió framework de lifecycle ni detector de fugas.

## Responsive, consistencia y accesibilidad

Nueve pruebas nuevas: integridad de rutas (1), recuperación de rutas inválidas (1), recents directos (1), Home/Search/Tools/Favorites/Settings/calculadora con catálogo completo en tres tamaños × dos temas (6). Tamaños: 320×640, 430×932, 1024×768, texto 200%. Los tests previos de escenas y tres Playgrounds conservan escalado, ambos temas y controles accesibles. Sin overflow reproducido.

Revisión visual de Home, Search, Tools, Settings, resultado y modal en claro/oscuro; doce capturas regenerables mediante `tool/capture_phase9.dart`. Contraste, targets y labels se verifican también por guidelines Flutter existentes. Se conservaron nombres Result/Formula/Substitution/Explanation/Learn visually/Explore interactively/Reset/Copy y unidades. Sin rediseño ni efectos adicionales.

Semántica: datos cuantitativos, fórmula y explicación siguen disponibles en texto; canvas no es la única fuente. Campos Android exponen hints, incluyendo validación. Teclado automatizado conserva Tab, flechas, Enter, modos, unidades y controles visuales; se introdujeron valores con teclado Android durante smoke. No se afirma que una inspección semántica cubra todo el recorrido de lector de pantalla.

**TalkBack: intento acotado, no aprobado como recorrido hablado.** En profile se habilitó el servicio, se esperó su enlace (`touchExplorationEnabled=true`, servicio bound, sin servicio crashed), se intentaron gestos/control en gas y Back/Home. Se obtuvo foco verde visible en Home y logs Google TTS de solicitudes de síntesis en inglés. No se escuchó ni capturó audio verificable, ni se validó el recorrido completo Home → calculadora → resultado → escena → control → Back. UiAutomator puede interferir temporalmente con el servicio; la captura final de foco se tomó sin dump intermedio. Se restauraron ajustes originales. La activación fiable del control bajo TalkBack sigue sin confirmarse.

**VoiceOver:** no probado: no hay runtime/dispositivo Apple. **Rendimiento físico:** no medido.

## Android, distribución y privacidad

| Configuración | Resultado inspeccionado |
| --- | --- |
| applicationId / namespace | `com.engineeringtoolkit.engineering_toolkit`, conservado. El scaffold mantiene TODO de identidad definitiva; requiere decisión del propietario antes de tienda |
| Nombre | Engineering Toolkit |
| Versión | pubspec `0.2.0+2` → versionName 0.2.0 / versionCode 2, confirmado en APK |
| SDK | min 24, target 36, compile 36; derivados del SDK Flutter y confirmados en manifest/APK |
| Build | AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1, Java target 17, NDK 28.2.13676358 |
| Firma | Release usa `signingConfigs.debug` existente. APK verificado con certificado Android Debug. No claves, passwords o keystores creados/añadidos |
| Launcher/splash | Iconos Flutter del scaffold, LaunchTheme claro/oscuro y fondo de arranque blanco; sin splash personalizado |
| Orientación | Sin restricción; configChanges habitual de Flutter y adjustResize |
| Red | Main/release sin INTERNET. Debug/profile lo declaran para tooling. Código de producto sin cliente/red, backend, analytics o telemetría |
| Backup | Sin `allowBackup`, `fullBackupContent` ni `dataExtractionRules` explícitos: se conserva comportamiento Android por defecto; backup/transferencia entre dispositivos no probados |
| Cleartext/debug | Sin usesCleartextTraffic/networkSecurityConfig explícitos; APK release sin DEBUGGABLE, sin banner o herramientas debug requeridas |

Manifest final release: solo usa `com.engineeringtoolkit.engineering_toolkit.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, de protección signature, introducido por **androidx.core 1.13.1**. No permisos peligrosos solicitados al usuario, Internet, almacenamiento externo, cámara, ubicación o micrófono. No se añadieron overrides para eliminar permisos de terceros sin justificación.

Componentes: MainActivity exportada para el launcher; AndroidX Startup InitializationProvider no exportado; ProfileInstallReceiver exportado por **androidx.profileinstaller 1.3.1**, protegido por `android.permission.DUMP`. El proveedor recibe inicializadores de lifecycle/profileinstaller; no se añadieron componentes propios. La query PROCESS_TEXT no es un permiso. Se inspeccionó el reporte de merge para atribuir cada componente.

La app opera sin red propia; no registra entradas del usuario. Sin prints/logs temporales en `lib`, sin credenciales ni rutas absolutas de desarrollador en producción. `local.properties` es configuración local ignorada; los reports de merge contienen rutas locales únicamente como evidencia generada. `.gitignore` cubre logs/build, keystores y key.properties. No se versionaron capturas, APKs/AABs ni logs. No se modificó pubspec/lock: go_router 18.0.1, shared_preferences 2.5.5 y dependencias SDK continúan usadas.

## Builds y tamaño

Todos producidos con éxito, sin cambiar firma ni publicar. APKs universales con armeabi-v7a, arm64-v8a y x86_64.

| Artefacto local | Bytes | MiB | Ejecución de Phase 9 |
| --- | ---: | ---: | --- |
| `build/app/outputs/flutter-apk/app-debug.apk` | 199967772 | 190.70 | Home nativo |
| `build/app/outputs/flutter-apk/app-profile.apk` | 72731422 | 69.36 | Instalación directa, Home, Ideal Gas Playground, resume y Reduce Motion |
| `build/app/outputs/flutter-apk/app-release.apk` | 52607041 | 50.17 | Smoke del producto descrito arriba; reinstalado al terminar |
| `build/app/outputs/bundle/release/app-release.aab` | 51334234 | 48.96 | Compilado; no subido ni instalado mediante Play |

Identidad del APK release validado, SHA-256: `50EC1C62577F6C6D2E0F925CC466FD442A47F555A3EF64BF695C2B294FAD0B1F`. El versionCode se conserva; este hash permite distinguir el artefacto interno de builds anteriores.

El intento inicial `flutter run --profile` no encontró dispositivo durante la caída del emulador; otro se interrumpió para no reemplazar release en mitad del smoke. La ejecución profile posteriormente verificada fue por instalación del APK profile, con VM service observado en log. No se confunden esos intentos con una sesión DevTools completada.

El tamaño debug proviene sobre todo del kernel Dart, tres bibliotecas Flutter y capas de validación; release incluye tres ABIs y AOT. Se inspeccionaron entradas ZIP grandes; las capturas/logs no son assets. No se introdujeron splits ni cambios de dependencias para reducir tamaño. Builds profile/AAB emitieron advertencia de fuente CupertinoIcons ausente: `lib` no usa CupertinoIcons, se comprobaron iconos Material en las pantallas; se conserva como aviso menor del build, sin añadir dependencia especulativa.

## Rendimiento: límites de las conclusiones

- **Código:** listas lazy; un catálogo/repositorio; un filtro de fondo en navegación, no uno por tarjeta; escenas bajo demanda y repaint aislado; ejecución síncrona de inputs intacta.
- **Tests:** ticks no recalculan ni notifican al VM, mantienen identidad de campos/reporte/detalles; animaciones suspendidas fuera de viewport/ruta/foreground y después de dispose. Los casos de ráfaga de Phase 8 siguen pasando.
- **Emulador:** navegación/cálculo/scroll, animación, pausa y resume observados. Una muestra `dumpsys meminfo` en gas profile: PSS 130451 KiB, RSS 240992 KiB, una Activity. Es una muestra puntual, no estudio de fugas ni presupuesto de memoria. No se midió una tasa de frames fiable ni se completó un trazado DevTools.
- **Dispositivo físico:** no disponible; sin medición de fps, temperatura, batería o carga sostenida. No se afirma “60 fps”.

## Gates y self-review

- Suite completa **491/491**: conserva los 482 anteriores y añade nueve pruebas de release. Dos escenarios de capturas fuera del conteo de la suite.
- Dominio **247/247 Dart**, **247/247 JS/Node** (runner Node silencioso, exit 0).
- Analyzer sin incidencias; formatter limpio; `git diff --check` limpio. Sin dependencias nuevas.
- Builds debug/profile/release/AAB exitosos; permisos/metadata/merge/firma revisados; sin credenciales ni artefactos generados versionados.
- Self-review: ningún cambio de fórmulas, unidades, validación o IDs. Conservadas propiedad del VM, lazy loading, disposición y pipeline único. El cambio de recents usa la abstracción existente y su guardia mounted; documentación de arquitectura actualizada solo para ese comportamiento.
- No se detectó excepción no controlada de producto en los logs recogidos durante el smoke. Esto no prueba ausencia absoluta de fallos. Automatización y pruebas nativas se documentan separadas.

## Pendientes clasificados

| Severidad | Pendiente |
| --- | --- |
| BLOCKER | Ninguno de producto reproducido pendiente para RC interna en el entorno validado |
| MAJOR | Antes de distribución pública: configurar firma de distribución bajo control del propietario y confirmar identidad/versionado para tienda; completar aceptación de accesibilidad hablada en Android objetivo |
| MINOR | Iconos/splash scaffold; advertencia de fuente Cupertino del build; decidir/documentar política de backup Android antes de producción |
| ENVIRONMENTAL / UNVERIFIED | Audio y recorrido TalkBack completo, VoiceOver sin Apple, rendimiento sostenido/dispositivos físicos, diversidad de API/hardware, backup/restauración entre dispositivos, runner/renderizado Chrome. Fallos de QEMU software documentados; smoke se completó con GPU host |

La aceptación interna puede continuar con estos límites explícitos. Una publicación pública requiere resolver distribución/identidad, completar accesibilidad hablada y QA en hardware objetivo. No se generaron claves, ficha de tienda, política de privacidad, cuentas ni uploads.

## Evidencia y repetición

Los logs/capturas son locales, regenerables y no se empaquetan. Referencias bajo `build/`: `phase9-baseline-tests-run.log`, `phase9-baseline-domain-run.log`, `phase9-baseline-analyze-run.log`, `phase9-baseline-debug.log`, `phase9-hardening-before.log`, `phase9-hardening.log`, `phase9-tests.log`, `phase9-analyze.log`, `phase9-domain-{dart,compile,node}.log`, `phase9-{debug-apk,release-apk,profile-build,aab}.log`, `phase9-captures.log`, `phase9-native-*.xml/png`, `phase9-restart-pids.log`, `phase9-talkback-*.txt/log/json`, `phase9-profile-meminfo.log`, `phase9-emulator-crashes.log` y `phase9-final-logcat.log`.

```sh
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed lib test tool
dart run tool/test_domain.dart
dart compile js tool/test_domain_web.dart -o build/phase9-domain.js
node build/phase9-domain.js
flutter build apk --debug
flutter build apk --profile
flutter build apk --release
flutter build appbundle --release
flutter test tool/capture_phase9.dart --update-goldens
git diff --check
```

Para repetir smoke nativo, instalar el APK del tipo elegido en un emulador compatible o dispositivo autorizado; ejecutar la matriz y registrar tipo, entorno, resultados y limitaciones de nuevo. No reutilizar capturas antiguas como prueba de una ejecución nueva. Phase 10 y toda expansión funcional quedan fuera de esta entrega.
