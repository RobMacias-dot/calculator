# Phase 10 — Android Compatibility & Distribution Hardening

Fecha: 2026-09-26. Continuación de Phase 9; validación local, sin publicación.

## Dictamen

**Sí: técnicamente creíble para avanzar hacia una beta Android interna más amplia**, con límites explícitos. El mismo APK release funciona en Android 7/API 24, Android 11/API 30 y Android 17/API 37. Se ejercitaron los tres Playgrounds, cálculo, navegación, visualización, errores, lifecycle y persistencia. El AAB también se convirtió en splits, se instaló y calculó correctamente en API 37. No se reprodujeron blockers funcionales pendientes.

Esto no aprueba publicación, firma pública, rendimiento en hardware físico ni aceptación hablada de accesibilidad. La firma sigue siendo debug y la identidad sigue pendiente de aprobación del propietario. Hay metadatos de rutas del anfitrión en los artefactos y avisos de tooling documentados abajo.

## 1. Baseline

Árbol de trabajo inicialmente limpio, sin cambios de usuario que preservar ni descartar. Se ejecutó antes de cualquier modificación de producción:

| Gate | Resultado inicial |
| --- | --- |
| `flutter test` | 491/491 |
| `flutter analyze` | 0 incidencias |
| `dart format --output=none --set-exit-if-changed lib test tool` | 130 archivos, 0 cambios |
| `dart run tool/test_domain.dart` | 247/247 |
| `dart compile js tool/test_domain_web.dart -o build/phase10-domain.js` | Correcto |
| `node build/phase10-domain.js` | Exit 0, runner de los mismos 247 casos |
| `git diff --check` | Sin errores de whitespace |

Flutter 3.47.2 stable, Dart 3.13.2, Windows; Emulator 36.5.11. Java del Android Studio instalado; compile/target SDK 36, min SDK 24. Se conserva `0.2.0+2`. El primer intento de Flutter dentro del sandbox no produjo salida; las ejecuciones efectivas usaron acceso autorizado al SDK/cache. La restricción del sandbox no se atribuye a la app.

## 2. Cambios de producción

**Ninguno.** Solo se añade este informe al repositorio. Sin cambios de arquitectura, fórmulas, unidades, IDs, rutas, dependencias, permisos, backup, firma, versión o branding. Se conservan 30 calculadoras, ocho escenas y tres Playgrounds. `go_router` 18.0.1 y `shared_preferences` 2.5.5 continúan en el lockfile.

Permanece intacto el registro de Recents de Playground de Phase 9: `PreferencesController.recordOpened` después del primer frame, con protección `mounted`. No se añadió otro repositorio, motor o ViewModel. Las utilidades de inspección, AVDs y evidencias de esta fase están en `build/`, ignorado por Git.

## 3. Defectos y hallazgos nuevos

No se reprodujo defecto funcional del producto. Tres hallazgos de distribución/runtime merecen conservarse:

1. **Rutas locales en artefactos:** `libapp.so`, en las tres ABIs del APK/AAB, contiene la URI absoluta del archivo generado `.dart_tool/flutter_build/dart_plugin_registrant.dart`. El AAB además contiene rutas de recursos de la cache Gradle en `base/resources.pb` y rutas en símbolos de depuración. No son literals escritos en `lib/`, claves ni entradas del usuario. No se declara que los artefactos estén libres de rutas locales. No se parchean binarios, archivos generados o el SDK para ocultarlas. Antes de distribución externa conviene acordar un entorno de build con rutas neutras y verificar nuevamente el contenido; no se afirma haber validado esa mitigación.
2. **Avisos JAR del AAB:** `jarsigner` verifica la firma, pero avisa sobre certificado autofirmado/no confiable, ausencia de timestamp, atributos POSIX y diferencias de lectura JarFile/JarInputStream. El manifiesto de firma está en la entrada ZIP 380 de 381, no al principio; el lector streaming informa que no lo encuentra. Se registra el aviso, sin rehacer arbitrariamente el empaquetado. `bundletool validate`, generación de splits e instalación real pasan. No equivale a aprobación de Play.
3. **Diagnóstico EGL en API 30:** al arrancar procesos aparecen pares de mensajes `E flutter: EGL Error: Success (12288)` en `impeller/toolkit/egl/display.cc:161`. El código del engine instalado sitúa el mensaje en la selección de configuración `eglChooseConfig`; después se registra Impeller/OpenGLES y la app renderiza los flujos/escenas verificados. No hubo crash ni fallo visual reproducido asociado. Se mantiene como diagnóstico ambiental con impacto no demostrado, sin desactivar Impeller o cambiar producción para ocultarlo. No se declara un logcat completamente libre de errores.

Los intentos de automatización con un label incorrecto (`Resume particles`, cuyo label real es `Play particles`), hints no expuestos por UiAutomator antiguo, y una ruta abreviada inexistente son limitaciones del script de prueba, no bugs de la app. Se corrigieron los selectores y se obtuvieron dumps nuevos. La ruta inválida se aprovechó para comprobar recuperación.

## 4. Matriz Android ejecutada

Solo estaba instalada API 37 al inicio. Se instalaron dos imágenes oficiales adicionales, sin actualizar/eliminar otras imágenes ni cambiar el AVD Pixel_7. Los AVDs temporales se crearon bajo `build/phase10-avd/`. Los tres arrancaron con `-no-snapshot -gpu host -no-boot-anim`.

| Tier | Runtime real | Imagen / revisión | AVD / serial | ABI ejecutada / páginas |
| --- | --- | --- | --- | --- |
| Mínimo | Android 7.0, API 24 | `system-images;android-24;default;x86_64`, rev. 8 | Phase10_API24 / emulator-5556 | x86_64 / 4 KiB |
| Intermedio | Android 11, API 30 | `system-images;android-30;default;x86_64`, rev. 10 instalada | Phase10_API30 / emulator-5558 | x86_64 / 4 KiB |
| Moderno | Android 17, API 37 | `system-images;android-37.0;google_apis_ps16k;x86_64`, rev. 4 | Pixel_7 / emulator-5554 | x86_64 / 16 KiB |

API 24/30: modelo `Android SDK built for x86_64`, fabricante reportado `unknown`. API 37: Google `sdk_gphone16k_x86_64`. Fingerprints:

```text
Android/sdk_phone_x86_64/generic_x86_64:7.0/NYC/4174735:userdebug/test-keys
Android/sdk_phone_x86_64/generic_x86_64:11/RSR1.210722.013.A2/10067904:userdebug/test-keys
google/sdk_gphone16k_x86_64/emu64xa16k:17/CP21.260330.005/15181570:userdebug/dev-keys
```

Los tres usaron 420 dpi y superficie de prueba 1080×2400. En API 24 el AVD tiene 1080×1920 y se aplicó `wm size 1080x2400` solo al AVD temporal. Los otros dos tienen 1080×2400 nativos. API 24 no dispone de `getconf`; se verificó `KernelPageSize: 4 kB` en `/proc/self/smaps`. API 30/37 se midieron con `getconf PAGE_SIZE`. API 37 expone traducción arm64 en su lista de ABIs, pero la app ejecutada fue x86_64: **no se cuenta como prueba ARM**.

El sdkmanager antiguo emitió aviso de XML SDK v4 frente a soporte v3; las instalaciones terminaron correctamente y las revisiones se leyeron de `source.properties`. Hubo avisos Qt `UpdateLayeredWindowIndirect` del anfitrión; los runtimes completaron el smoke. No se actualizó globalmente el SDK para silenciarlos.

## 5. Evidencia nativa

La tabla siguiente corresponde a ejecución real mediante ADB/UiAutomator y capturas, no a tests Flutter. Artefacto: APK universal release, salvo la columna adicional del AAB descrita en §8.

| Flujo | API 24 | API 30 | API 37 |
| --- | --- | --- | --- |
| Arranque/Home sin crash observado | Sí, instalación fresca | Sí, instalación fresca | Sí, datos previos preservados |
| Home/Favorites/Tools/Settings | Sí | Sí | Sí |
| Buscar divisor y abrir calculadora | `divider` | `divider` | `voltage`, tres resultados |
| Divisor 12 V / 1000 Ω / 2000 Ω | 8 V | 8 V | 8 V |
| Fórmula, sustitución, explicación | Visibles | Visibles | Visibles |
| Abrir/cerrar Learn visually, conservar 8 V | Sí | Sí | Sí |
| Voltage Divider Playground | Sí, 6 V → 4 V y recuperación a 8 V | Sí, 8 V y recuperación | Sí; además 8 V en splits |
| IPv4 Playground | Sí | Sí | Sí |
| Ideal Gas Playground | Sí | Sí | Sí |
| Entrada inválida elimina reporte/escena anteriores | Sí | Sí | Sí, en splits |
| Back | Modal y Playground → formulario | Modal y Playground → formulario | Cierre de modal; Back de ruta raíz vuelve al launcher |
| Ruta inexistente → Go to Home | Sí | Sí | Sí |
| Dark/Favorite/Recents tras force-stop | Sí | Sí | Sí |
| Ideal Gas background/resume y pause/play | Sí | Sí | Sí |

IPv4: `192.168.1.10`, prefijo `24` → `192.168.1.0/24`, 256 direcciones, 254 utilizables; visual de 24 bits de red y ocho de host. Prefijo vacío muestra validación y se recupera al completarlo.

Gas: `1 mol`, `300 K`, `0.025 m³` → **99773.551418 Pa** en los tres runtimes. El resultado y las cuatro variables se muestran junto a la escena. Home del sistema → relanzar Activity conserva el estado durante el resume. Se ejercitaron scroll y pausa/reproducción.

Divisor inválido: desde un resultado válido, vaciar Vin muestra `Enter a value` y `Waiting for valid inputs`; el resultado previo y la escena no quedan presentados como actuales. Restaurar 12 devuelve 8 V. La apertura directa de los Playgrounds aparece en Recents.

Capturas del canvas de gas: pares activos difieren en 7501 píxeles (API 24), 10241 (API 30) y 9856 (API 37); pares pausados, tras esperar que termine el feedback del botón, difieren en **cero** píxeles en los tres. Otro par tras Play en API 37 difiere en 10221. Los recortes se toman de los bounds del canvas en el dump correspondiente, excluyendo reloj y controles. Esto acredita movimiento/pausa puntual; no acredita fps, suspensión interna de todos los callbacks en background ni ausencia de fugas. Esa lógica también conserva su cobertura automatizada.

## 6. Instalación fresca, reinicio y reemplazo

API 24 y API 30 se instalaron en AVDs nuevos sin la aplicación: Home sin Recents y tema System. API 30 también verificó explícitamente Favorites vacío. Se crearon favorito del divisor, Recents y tema Dark desde UI. Tras force-stop y nuevo proceso se restauraron. `adb install -r app-release.apk` devolvió Success; después del reemplazo volvieron a comprobarse Home/Recents, Favorites y Dark.

API 37 conservó los datos existentes; no se desinstaló ni borró. Se verificó persistencia tras force-stop y después de sustituir universal → splits del AAB → universal. Todos usan el mismo package, certificado y versionCode 2. **Es reemplazo compatible de la misma versión, no prueba de migración de esquema ni actualización a una versión superior.** No se crearon migraciones, IDs alternativos ni bumps ficticios.

Se restauraron tema System y ausencia del favorito de prueba. Recents conserva las aperturas legítimas del smoke; no se borró el historial preexistente de Pixel_7. Los AVDs temporales conservan datos de prueba locales para reproducibilidad. Los emuladores iniciados por esta fase se cerraron sin borrar datos. No se cambiaron ajustes de accesibilidad/animación; API 37 terminó con accessibility=0, servicios=null y transition_animation_scale=1.0.

## 7. Inspección de APK/AAB

`aapt`, `apksigner`, `jarsigner`, `bundletool dump manifest`, listados ZIP y manifest-merger-release-report inspeccionados.

| Propiedad | Evidencia |
| --- | --- |
| Application ID / namespace | `com.engineeringtoolkit.engineering_toolkit`, sin cambios |
| Nombre / versión | Engineering Toolkit / versionName 0.2.0 / versionCode 2 |
| SDK | min 24, target 36, compile 36 en APK y AAB |
| Release debuggable | No: atributo ausente y flags instalados sin DEBUGGABLE |
| ABIs | armeabi-v7a, arm64-v8a, x86_64 |
| Permiso solicitado | Solo `com.engineeringtoolkit.engineering_toolkit.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, signature; procede de AndroidX Core 1.13.1 |
| Activity | MainActivity exportada para launcher |
| Provider | AndroidX Startup InitializationProvider no exportado |
| Receiver | ProfileInstallReceiver exportado, protegido por `android.permission.DUMP`; AndroidX ProfileInstaller 1.3.1 |
| Firma APK | Verifica APK Signature Scheme v2; C=US, O=Android, CN=Android Debug |
| Firma AAB | SHA256withRSA, clave RSA 2048; `jar verified`, con avisos de §3 |
| Alineación APK | `zipalign -c -P 16 -v 4`: Verification successful |

Certificado debug SHA-256: `5666861d7d4b201cdc93c4453fb7050784669e18cd688e51101b53a4f62ccfcb`. No se generó ni sustituyó la clave. `signingConfigs.debug` sigue siendo la configuración release interna.

Assets: fuentes Material reducidas a 5500 bytes, manifiestos Flutter, NOTICES, shaders del SDK y perfiles Android esperados. Bibliotecas por ABI: `libapp.so`, `libflutter.so`, `libdatastore_shared_counter.so`. No se encontraron capturas, logs de prueba, keystores, `key.properties` o artefactos de emulador empaquetados. El AAB incorpora metadatos/símbolos de build esperados; **sí hay rutas locales**, como se detalla en §3. Las referencias de runtime del SDK no equivalen a logging de inputs de la app.

## 8. Camino AAB / bundletool

La cache Gradle incluía bundletool como biblioteca, sin Main-Class ejecutable. Se descargó el JAR standalone oficial [bundletool 1.18.3](https://github.com/google/bundletool/releases/tag/1.18.3) a `build/`, sin añadir dependencias al producto. SHA-256 del JAR: `A099CFA1543F55593BC2ED16A70A7C67FE54B1747BB7301F37FDFD6D91028E29`.

Secuencia ejecutada:

```text
java -jar build/bundletool-all-1.18.3.jar validate --bundle=build/app/outputs/bundle/release/app-release.aab
java -jar build/bundletool-all-1.18.3.jar dump manifest --bundle=build/app/outputs/bundle/release/app-release.aab
java -jar build/bundletool-all-1.18.3.jar get-device-spec --device-id=emulator-5554 --output=build/phase10-api37-device.json --adb=<SDK>/platform-tools/adb.exe
java -jar build/bundletool-all-1.18.3.jar build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=build/phase10-api37.apks --device-spec=build/phase10-api37-device.json
java -jar build/bundletool-all-1.18.3.jar install-apks --apks=build/phase10-api37.apks --device-id=emulator-5554 --adb=<SDK>/platform-tools/adb.exe
```

Bundletool utilizó explícitamente la clave debug **ya existente**. `pm path` confirmó base.apk + split_config.en.apk + split_config.x86_64.apk + split_config.xxhdpi.apk. Home, Tools, Settings, Favorites, Recents, Dark y divisor 8 V funcionaron; también la invalidación/recuperación en Playground. Después se reinstaló el universal preservando datos. Es validación local de la estructura y ejecución de splits, según el [flujo oficial de bundletool](https://developer.android.com/tools/bundletool); no instalación desde Play, prueba de firma pública o aceptación de tienda.

## 9. ABIs y tamaños

MiB = bytes / 1048576. Estos son archivos locales, **no tamaños entregados por una tienda**.

| Artefacto | Bytes | MiB | versionCode |
| --- | ---: | ---: | ---: |
| APK debug universal | 199967772 | 190.70 | 2 |
| APK profile universal | 72731422 | 69.36 | 2 |
| APK release universal | 52607041 | 50.17 | 2 |
| AAB release | 51334234 | 48.96 | 2 |
| APK release armeabi-v7a | 15861814 | 15.13 | 1002 |
| APK release arm64-v8a | 18403952 | 17.55 | 2002 |
| APK release x86_64 | 19904107 | 18.98 | 4002 |

Splits generados por bundletool para API 37: base-master 1042202 bytes; base-en 8339; base-x86_64 19136822; base-xxhdpi 49836. Suma de APKs seleccionados: 20237199 bytes (19.30 MiB). No es una medición de descarga comprimida ni almacenamiento instalado; tampoco representa otros dispositivos/idiomas.

Los APKs `--split-per-abi` se produjeron para medición, no se instalaron como supuesto reemplazo de la versión 2. Flutter añade el offset ABI al versionCode, confirmado con aapt. Cambiar de uno de esos APKs al universal con código 2 puede ser un downgrade: no mezclar estas líneas de artefactos sin plan de versionado. No se forzó ningún downgrade.

SHA-256 release universal validado: `50EC1C62577F6C6D2E0F925CC466FD442A47F555A3EF64BF695C2B294FAD0B1F`. AAB: `7EF7C5D77E4272EC7FFAC4260CD0C8AE19759F9CCD2725C4EB49D4B250CF1F15`. Coinciden con el contenido de Phase 9 porque no cambió producción. Se conserva el empaquetado existente: los 50.17 MiB universales contienen tres arquitecturas, no evidencian por sí solos un problema de tamaño.

## 10. Investigación CupertinoIcons

`lib/` y pubspec no referencian CupertinoIcons ni `cupertino_icons`. El warning se reprodujo en build profile. Se ejecutó el mismo `const_finder.dart.snapshot` que usa `icon_tree_shaker.dart` contra el kernel de la app: detectó **un** IconData Cupertino, codePoint 62415 (`0xf3cf`), paquete `cupertino_icons`, matchTextDirection=true. Corresponde a `CupertinoIcons.back`/`chevron_back` del SDK. El SDK lo referencia en `cupertino/nav_bar.dart`; el kernel incluye ese código de framework.

El mensaje proviene de `IconTreeShaker._getIconData`: compara familias constantes retenidas con FontManifest, que solo declara MaterialIcons. `uses-material-design: true` ya es correcto. No se halló configuración obsoleta propia que eliminar. Añadir una fuente no usada en la UI Android, parchear el SDK, cambiar navegación o desactivar tree shaking solo para silenciarlo carece de justificación. Se conserva como **MINOR** del tooling. Los iconos Material de los flujos inspeccionados renderizaron; esta observación no certifica todos los caminos adaptativos de iOS.

## 11. Política de backup

Main y manifiestos finales no declaran allowBackup/fullBackupContent/dataExtractionRules. `dumpsys package` confirma **ALLOW_BACKUP**. `LocalPreferencesRepository` guarda un JSON bajo `engineering_toolkit.preferences.v1`, con theme/favorites/recents. Usa `SharedPreferencesAsync` con backend Android **DataStore**, no el XML legacy.

Se verificó la implementación instalada de shared_preferences_android 2.4.28 (`useDataStore=true` por defecto) y el almacenamiento real del AVD de prueba API 24: `files/datastore/FlutterSharedPreferences.preferences_pb`, 136 bytes al terminar, con tema System, lista de favoritos vacía y tres IDs recientes. Se leyó solo esa app sintética; no se modificó su archivo. No se guardan resultados, inputs de cálculo, cuentas o credenciales.

Auto Backup puede incluir archivos internos y preferencias; por ello una futura regla limitada al dominio `sharedpref` **no cubriría este DataStore**, que está en `file`. Android 12+ usa dataExtractionRules y las versiones anteriores fullBackupContent. El alcance y comportamiento de transporte dependen del sistema y fabricante. Véase [Auto Backup de Android](https://developer.android.com/identity/data/autobackup).

**Decisión:** mantener el comportamiento. Para estas preferencias pequeñas, descartables y tolerantes a IDs obsoletos, no se demostró un defecto que justifique excluirlas. El propietario debe decidir si favoritos/recientes deben viajar entre dispositivos. “Sin red de aplicación” no significa “Android nunca puede respaldar preferencias”. Backup cloud, restore tras desinstalación y transferencia real entre dispositivos quedan **sin verificar**; el reemplazo `-r` no los prueba.

## 12. Gate de identidad y firma pública

Antes de distribución pública el propietario debe resolver, sin decisiones automáticas en esta fase:

| Decisión | Cambio concreto posterior / efecto |
| --- | --- |
| Identidad final | Aprobar applicationId; no inferir dominio/empresa. Cambiarlo después de distribuir crea otra identidad de app y no actualiza los datos privados de la anterior |
| Namespace | Revisar namespace Gradle, package/ruta de MainActivity y referencias del manifiesto/automatización si se decide renombrar; namespace y applicationId son conceptos diferentes |
| Versionado | Mantener un versionCode creciente para cada release distribuida y coordinar offsets de APKs por ABI; versionName es la etiqueta visible |
| Firma y propiedad | Designar titular/custodios, estrategia de app signing key y upload key si se elige Play App Signing, recuperación y acceso de emergencia |
| Almacenamiento | Claves fuera de Git, copia protegida y política de acceso/rotación; no incluir passwords en archivos versionados o logs |
| Build local/CI | Configuración release explícita que lea secretos externos y falle si faltan; no fallback silencioso a debug en el canal público; verificar certificado y manifest del artefacto final |
| Continuidad de actualización | Mismo package y firma compatible para actualizaciones. No asumir que la futura firma pública podrá sustituir estas instalaciones debug conservando datos |

Referencias: [identidad de larga duración y preparación de release](https://developer.android.com/studio/publish/preparing), [firma Android](https://developer.android.com/studio/publish/app-signing), [versionado](https://developer.android.com/studio/publish/versioning). No se creó keystore, password, secreto, cuenta, CI, upload ni ficha de tienda. La beta interna debe identificarse como artefacto debug-signed y acotar su continuidad de actualización.

## 13. Launcher y splash

Los cinco PNG `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` son **idénticos por hash a la plantilla Flutter instalada**. No hay branding aprobado que sustituir. Tamaños del scaffold a reemplazar con arte aprobado: 48, 72, 96, 144 y 192 px respectivamente.

Faltan recursos adaptive-icon en mipmap-anydpi-v26: futuras capas foreground/background de 108×108 dp, manteniendo el contenido esencial dentro de la zona segura central de 66×66 dp; evaluar capa monocromática para iconos temáticos Android 13+. Conservar fallback legacy para API 24/25. Requisitos oficiales: [adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).

`drawable/launch_background.xml` y `drawable-v21/launch_background.xml` mantienen fondo blanco y comentarios scaffold. `values/styles.xml` y `values-night/styles.xml` usan LaunchTheme/NormalTheme de Flutter; no hay recursos values-v31 propios. Para Android 12+ se debe diseñar el splash del sistema con icono y fondo aprobados; para API 24–30, el drawable de LaunchTheme. El [splash de Android](https://developer.android.com/develop/ui/views/launch/splash-screen) tiene restricciones específicas de máscara/tamaño (icono sin fondo: 288 dp, contenido en círculo de 192 dp; con fondo: 240/160 dp). No se añadió una pantalla artificial ni delays para branding. Se debe revisar claro/oscuro y el primer frame cuando existan assets aprobados.

## 14. Accesibilidad

Se preserva la suite existente de semántica, labels, foco, teclado, targets, contraste, 200% texto y Reduce Motion. La navegación/input nativos se observó en las tres APIs, pero los dumps UiAutomator de API 24/30 no exponen los mismos hints que API 37. **Eso no prueba por sí solo ni ausencia de label para TalkBack ni aceptación hablada.**

No hubo captura/escucha fiable de audio ni recorrido hablado completo en esta fase. No se repitió una activación superficial del servicio para sumar una falsa aceptación. La evidencia de Phase 9 (servicio bound, foco, solicitudes TTS) permanece limitada a lo que demostró. TalkBack completo, incluyendo control/Back, sigue **ENVIRONMENTAL / UNVERIFIED** y es un gate de aceptación para público. VoiceOver sin runtime Apple también sigue sin verificar. No se cambiaron ajustes de accesibilidad ni se afirma un nuevo smoke nativo de Reduce Motion; su evidencia previa y los tests se conservan.

## 15. Dispositivo físico

**Ningún Android físico autorizado estuvo conectado.** `adb devices -l` solo mostró los tres emuladores iniciados para esta fase. No había runtime Apple. Esto no bloqueó las otras validaciones.

Checklist para un futuro run autorizado:

- Registrar fabricante/modelo, Android/API, ABI real, RAM, tamaño de página y hash/certificado del APK o splits.
- Instalación fresca: defaults/Home; Home/Search/Tools/Settings/Favorites; abrir divisor y Back.
- Calcular 12/1000/2000 → 8 V; fórmula/explicación; abrir/cerrar visual; invalidar y recuperar entrada.
- Gas: 1 mol/300 K/0.025 m³ → 99773.551418 Pa; scroll, pause/play, Home del sistema y resume.
- Dark, favorito y Recents; force-stop/relaunch; reemplazo firmado compatible sin limpiar datos; comprobar restauración.
- TalkBack audible: Home → calculadora → input → resultado → visual → control → Back; texto 200%, teclado y Reduce Motion.
- Si se mide rendimiento, guardar duración, carga, método y trazas; incluir escenario sostenido para memoria/temperatura/batería. No extrapolar de un smoke breve.
- Restaurar preferencias/ajustes de prueba, registrar incidencias con pasos y evidencia.

## 16. Límites de rendimiento

Las capturas prueban cambio de píxeles y pausa; no 60 fps. El smoke no es una prueba de fugas, consumo energético, temperatura, estabilidad sostenida ni rendimiento ARM. No se capturó una nueva sesión DevTools o benchmark. El backend OpenGLES/Impeller se observó en logs de API 30 y 37; no se extrapola a todos los dispositivos. Los diagnósticos EGL de API 30 se conservan en §3. El pipeline determinista y lifecycle mantienen cobertura automatizada, separada de las observaciones nativas.

## 17. Seguridad y privacidad

Release sigue sin INTERNET, almacenamiento externo, ubicación, cámara o micrófono. INTERNET existe únicamente en manifests debug/profile para tooling. Query PROCESS_TEXT es visibilidad de actividades, no permiso. Sin analytics, telemetry, backend, cuentas ni nuevos clientes de red/dependencias. La revisión de `lib/` no encontró `print`, `debugPrint`, logging de inputs o rutas absolutas locales. No se añadieron secretos.

No se observó crash de la app en los recorridos; buffers crash capturados vacíos y sin excepciones Flutter no controladas detectadas en los logs recogidos. Los buffers son acotados y contienen ruido del sistema: no se afirma ausencia absoluta de errores. Permanecen los logs de motor/Android esperados. Los metadatos de rutas del build se registran como exposición de información del entorno, no como permiso de red ni captura de datos del usuario.

## 18. Pruebas automatizadas y builds finales

Se repite al cierre la misma suite completa y los cuatro builds requeridos, sin sustituirlos por la evidencia inicial. No se añadieron tests por conteo: no cambió comportamiento de producción y no se descubrió una regresión que necesitara una prueba nueva.

```text
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed lib test tool
dart run tool/test_domain.dart
dart compile js tool/test_domain_web.dart -o build/phase10-domain.js
node build/phase10-domain.js
flutter build apk --debug
flutter build apk --profile
flutter build apk --release
flutter build appbundle --release
git diff --check
```

Resultados finales: **491/491 tests Flutter**, **247/247 Dart**, **247/247 JS/Node** (exit 0), analyzer sin incidencias, formatter 130 archivos/0 cambios; debug APK, profile APK, release APK y release AAB con exit 0. Los cuatro modos se reconstruyeron en el cierre. La matriz nativa utilizó release; debug/profile se compilaron, no se presentan como smokes adicionales de esta fase. Dart/Node valida dominio compilado a JS, **no Flutter Web rendering**; Chrome no se investigó.

El `git diff --check` al final de la cadena de builds encontró un contexto de directorio no válido para Git; se repitió por separado desde la raíz del repositorio y pasó. No fue un fallo de compilación o whitespace. Los accesos Git dentro del sandbox también emitieron advertencias de lectura del ignore global; no se modificó esa configuración.

## 19. Formatter, fuente y reproducibilidad

Sin archivos de producción modificados, ni APK/AAB, capturas, logs, keystores, SDKs o AVDs añadidos a Git. `build/` permanece ignorado. Sin código temporal en `lib/`. La única adición intencional versionable es `docs/phase10-validation.md`. Se ejecuta `git diff --check` al cierre. No se hace commit ni publicación.

Evidencia local regenerable bajo `build/`:

- `phase10-baseline-*`, `phase10-final-*`: suite, analyzer, formato, Dart/JS y builds.
- `phase10-sdk-{list,install}.log`, `phase10-environments.json`: disponibilidad y entornos realmente ejecutados.
- `phase10-{api24,api30,api37}-*.xml/.png`: UI fresca de cada paso; dumps fallidos no se cuentan como prueba nueva.
- `phase10-*-logcat.log`, `phase10-*-crash.log`, `phase10-*-package.txt`: ejecución y flags instalados.
- `phase10-apk-{badging,manifest,signing}.txt`, `phase10-aab-{manifest.xml,signing.txt}`, `phase10-zipalign.txt`.
- `phase10-artifacts.json`, `phase10-{apk,aab}-entries.json`, `phase10-inspection.json`, `phase10-path-details.txt`, `phase10-icon-constants.json`.
- `phase10-bundle-validate.log`, `phase10-build-apks.log`, `phase10-api37-device.json`, `phase10-api37.apks`.
- `phase10-native.ps1` y `phase10-inspect.py`: helpers locales de interacción/inspección; no son nuevos tests del producto ni dependencias runtime.

Las rutas del SDK en los comandos deben resolverse desde la instalación de quien repita el run. Para abrir una ruta en Android se usó `am force-stop <package>` seguido de `am start -n <package>/.MainActivity --es route <ruta>`; las rutas reales de Playground son `voltage-divider`, `ipv4-subnet`, `ideal-gas-law`. Las interacciones siguientes fueron mediante UI, no por inyectar resultados o preferencias.

## 20. Hallazgos restantes por severidad

| Severidad | Hallazgo / alcance |
| --- | --- |
| BLOCKER | Ninguno funcional reproducido pendiente para la beta interna en el rango emulado probado |
| MAJOR | Antes de distribución pública: aprobar identidad permanente y establecer firma/custodia/build del propietario; no distribuir estos artefactos como producción firmada |
| MINOR | Rutas del anfitrión en metadata/registrador generado; warning Cupertino del SDK; avisos JAR streaming del AAB; iconos/splash scaffold; decisión de política de backup pendiente |
| ENVIRONMENTAL / UNVERIFIED | Diagnósticos EGL API 30 sin impacto funcional reproducido; hardware físico y ejecución ARM, rendimiento sostenido/batería/temperatura/fugas, TalkBack hablado, VoiceOver, backup cloud/D2D, actualización real entre versiones/esquemas, entrega desde Play, Flutter Web/Chrome |

La evidencia amplía realmente la RC de una API a **24/30/37** y valida un camino local AAB → splits → instalación. Una beta interna controlada puede continuar con esos límites y con el origen debug de la firma explícito. No se implementó la fase siguiente.
