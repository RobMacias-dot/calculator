# Phase 18 — Android Backup, Restore y Device Transfer

Fecha: 2026-10-14 (America/Mexico_City).

**Veredicto: PASS WITH LIMITATIONS para esta configuración de privacidad. No equivale a aprobación para publicar.**

## Resultado y estado inicial

Se restringió Android Backup sin modificar la persistencia local de Flutter. Se verificaron por separado el código fuente, los manifests de release fusionado/empaquetado y el manifest y recursos binarios del APK recién compilado. No se realizaron pruebas físicas de restauración o transferencia.

- Rama inicial y final: `main`.
- HEAD inicial: `6f2a75ad49faffe65a2c33d716eee506f9a0d842`.
- Estado inicial: solamente `?? docs/phase18-release-readiness.md`. Ese documento preexistente no fue editado.
- No había atributos `allowBackup`, `fullBackupContent`, `dataExtractionRules`, reglas XML ni BackupAgent propio en el proyecto.
- Se revisaron los manifests `main`, `debug` y `profile`; no existe manifest específico de `release` ni flavors configurados. Debug/profile declaran INTERNET para desarrollo.
- Gradle usa los valores de Flutter: minSdk 24, targetSdk 36, compileSdk 36. Los dos primeros se confirmaron también en el manifest fusionado y en el APK.
- Herramientas: Flutter 3.47.2, Dart 3.13.2, Android Gradle Plugin 9.1.0; inspección binaria con Android build-tools 36.0.0.

## Archivos exactos de la entrega

1. Modificado: `android/app/src/main/AndroidManifest.xml` — tres atributos en application:
   - `android:allowBackup="false"`
   - `android:fullBackupContent="@xml/backup_rules"`
   - `android:dataExtractionRules="@xml/data_extraction_rules"`
2. Nuevo: `android/app/src/main/res/xml/backup_rules.xml` — nueve exclusiones legacy.
3. Nuevo: `android/app/src/main/res/xml/data_extraction_rules.xml` — nueve exclusiones en cloud-backup y otras nueve en device-transfer.
4. Nuevo: `docs/phase18-android-backup-verification.md` — este reporte.

No se modificaron Gradle, firma, versiones SDK, dependencias, repositorio de preferencias, calculadoras, navegación, web ni políticas públicas. La compilación y validación generaron archivos locales ignorados bajo `build/`, incluido el script `build/phase18-backup-validation/verify-backup.ps1` y sus logs. Estos no forman parte de los cambios de producto y pueden desaparecer al limpiar build.

## Cobertura y compatibilidad

Cada bloque excluye `path="."` en los nueve dominios: `root`, `file`, `database`, `sharedpref`, `device_root`, `device_file`, `device_database`, `device_sharedpref`, `external`. Esto cubre almacenamiento protegido por credenciales, protegido por dispositivo y archivos externos privados de la app. No depende de que root abarque otros dominios. Se excluyen también archivos DataStore bajo files; no se limita la protección a SharedPreferences XML.

La documentación define exclusiones de directorios recursivas y deja cache, code cache y no-backup fuera del respaldo. Las secciones vacías no se usan como mecanismo de desactivación. [Sintaxis y dominios oficiales](https://developer.android.com/identity/data/autobackup#XMLSyntax).

| Android del dispositivo | Configuración esperada |
| --- | --- |
| 7–11, API 24–30 | allowBackup=false deshabilita participación; fullBackupContent aporta exclusiones legacy explícitas. dataExtractionRules no es el mecanismo de estas versiones. |
| 12+, API 31+ | allowBackup=false restringe cloud backup/restore; dataExtractionRules define por separado cloud-backup y device-transfer. Al usar este formato, fullBackupContent deja de controlar estos mecanismos en estas versiones. |

La configuración evita futuras copias mediante mecanismos estándar que la respetan y restringe restauración cloud; no demuestra eliminación de respaldos históricos. Las restricciones D2D no son garantía universal: Android documenta variaciones entre fabricantes. [Atributo application](https://developer.android.com/guide/topics/manifest/application-element#allowbackup) y [cambios de Android 12](https://developer.android.com/about/versions/12/behavior-changes-12#backup-restore).

Se evaluó cross-platform-transfer, disponible desde Android 16 QPR2/API 36.1. La documentación requiere plataforma iOS y parámetros bundleId/teamId/contentVersion. No existe correspondencia iOS de producción verificada en esta tarea: no se añadió esta sección ni se inventaron identificadores. Las reglas cloud/D2D no prueban control de otro modo de transferencia. Reevaluar si el producto incorpora esa integración. [Transferencias entre plataformas](https://developer.android.com/identity/data/autobackup#configure-cross-platform-transfers).

## Validación ejecutada y salidas

Comandos ejecutados desde la raíz del repositorio en PowerShell. Los comandos Flutter se completaron con acceso autorizado a SDK/cachés externos al workspace. Los primeros intentos restringidos no produjeron salida y terminaron con código 1; no se tomaron como validación ni se usaron manifests antiguos para concluir éxito.

| Comando | Resultado relevante |
| --- | --- |
| `git status --short`; `git branch --show-current`; `git rev-parse HEAD` | Estado y rama indicados arriba; sin commits. |
| `flutter --version` | Flutter 3.47.2; Dart 3.13.2. |
| `flutter build apk --release --no-pub` | Exit 0: `Running Gradle task 'assembleRelease'... 64.4s`; `Built build\app\outputs\flutter-apk\app-release.apk (50.2MB)`. |
| `flutter test --no-pub` | Exit 0: `00:49 +575: All tests passed!`. |
| `flutter analyze --no-pub` | Exit 0: `No issues found! (ran in 9.9s)`. |
| `& ./build/phase18-backup-validation/verify-backup.ps1` | Exit 0: tres SOURCE PASS, dos MERGED/PACKAGED PASS, tres ARTIFACT PASS. Comprueba XML con parser .NET, dominios/path por bloque, referencias y ausencia de INTERNET. |
| `& 'C:/Users/macia/AppData/Local/Android/sdk/platform-tools/adb.exe' devices -l` | Exit 0: `List of devices attached`, sin dispositivos. El intento restringido inicial no pudo iniciar daemon; se repitió con acceso autorizado. |
| `& 'C:/Users/macia/AppData/Local/Android/sdk/build-tools/36.0.0/apksigner.bat' verify --print-certs build/app/outputs/flutter-apk/app-release.apk` | Exit 0; `Signer #1 certificate DN: C=US, O=Android, CN=Android Debug`. |
| `git diff --check` | Exit 0; sin errores de whitespace. Git avisa conversión futura LF a CRLF para el manifest. |

Logs: `build/phase18-backup-validation/build-release.log`, `flutter-test.log`, `flutter-analyze.log`, `verification.log`, `apk-manifest.txt`, `apk-resources.txt`, `apk-backup-rules.txt`, `apk-extraction-rules.txt`, `apk-badging.txt`, `apk-signature.txt`.

### Fuente

El script parsea los dos XML, exige exactamente nueve exclusiones por sección, comprueba cada dominio con path=. y rechaza includes. No es una ejecución del motor de respaldo Android.

### Manifest fusionado y empaquetado

Se inspeccionaron los resultados generados durante esta compilación:

- `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`
- `build/app/intermediates/packaged_manifests/release/processReleaseManifestForPackage/AndroidManifest.xml`
- `build/app/outputs/logs/manifest-merger-release-report.txt`

En ambos manifests: allowBackup=false, fullBackupContent=@xml/backup_rules, dataExtractionRules=@xml/data_extraction_rules; minSdk=24 y targetSdk=36. El reporte de merging atribuye los tres atributos al manifest main, sin override. INTERNET ausente. El permiso de firma `com.engineeringtoolkit.engineering_toolkit.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` procede de AndroidX existente; no se agregó un permiso de plataforma nuevo.

### APK compilado

Comandos de inspección ejecutados con `aapt2.exe` de build-tools 36.0.0 (el script resuelve las rutas optimizadas a partir de la tabla de recursos):

```powershell
$aapt2 = 'C:/Users/macia/AppData/Local/Android/sdk/build-tools/36.0.0/aapt2.exe'
$apk = 'build/app/outputs/flutter-apk/app-release.apk'
& $aapt2 dump xmltree $apk --file AndroidManifest.xml
& $aapt2 dump resources $apk
& $aapt2 dump xmltree $apk --file res/Qq.xml
& $aapt2 dump xmltree $apk --file res/4j.xml
& $aapt2 dump badging $apk
Get-FileHash $apk -Algorithm SHA256
```

Salidas confirmadas:

```text
allowBackup(0x01010280)=false
fullBackupContent(0x010104eb)=@0x7f100000
dataExtractionRules(0x0101063e)=@0x7f100001
0x7f100000 xml/backup_rules -> res/Qq.xml
0x7f100001 xml/data_extraction_rules -> res/4j.xml
```

Se verificaron nuevamente los nueve dominios con path=. en cada sección binaria: nueve exclusiones legacy y dieciocho modernas. INTERNET ausente en el APK. Una primera consulta con nombres originales res/xml no encontró archivo: la optimización de recursos los renombra; se resolvieron los nombres mediante dump resources, sin modificar configuración.

APK: `build/app/outputs/flutter-apk/app-release.apk`.
SHA-256: `70604E0E77984597846B8BD6C452D7FA10E4F553F960E439C198EBF8BC23319F`.

## Persistencia, regresiones y privacidad

`LocalPreferencesRepository` conserva SharedPreferencesAsync, su clave `engineering_toolkit.preferences.v1` y los únicos campos persistidos: theme/favorites/recents. La versión instalada shared_preferences_android 2.4.28 implementa también DataStore; la exclusión file cubre ese almacenamiento. No se borran datos, cambian rutas ni se altera lectura/escritura local.

Las 575 pruebas existentes incluyen round-trip del adaptador de preferencias con almacenamiento simulado, restauración de controladores, temas, favoritos, orden de recientes, remount de widgets, cálculos, navegación y Copy result con clipboard simulado. La inspección del adaptador confirma que no persiste entradas ni resultados de cálculo. Esto confirma preservación del comportamiento a nivel código/pruebas; no equivale a probar reinicio de proceso y disco Android real.

No se añadieron dependencias ni código de red, analytics, publicidad, crash reporting, backend o sincronización. La ausencia de INTERNET se comprobó tanto en release fusionado como en el APK; debug/profile permanecen como estaban. Esta es una verificación del cambio y sus artefactos, no una auditoría exhaustiva de todos los binarios de terceros.

## Limitaciones y pendientes

- Sin dispositivo/emulador conectado: no se probaron backup/restore, migración D2D, reinicio real o combinaciones Android/fabricante. Se requieren pruebas en dispositivos representativos para evidencia de comportamiento.
- No se garantiza exclusión de cualquier transferencia propietaria, herramientas con privilegios o mecanismos que no respeten estas reglas. No se probó transferencia entre plataformas ni se configuró una app iOS.
- No se afirma que copias históricas externas hayan sido borradas o que esta configuración nueva cambie artefactos ya distribuidos.
- No hubo bloqueo de compilación por firma. Release ya usaba signingConfigs.debug y el APK confirma Android Debug. Se conservó exactamente; requiere trabajo de firma de producción antes de publicar. No se debilitó seguridad ni se editaron claves para pasar validaciones.
- Se compiló e inspeccionó APK release; no se generó AAB ni se verificó una entrega de Google Play. Este PASS WITH LIMITATIONS se refiere a la tarea de backup.

## Resumen propuesto para la futura política de privacidad

Engineering Toolkit guarda localmente las preferencias de apariencia, favoritos y calculadoras recientes. Las entradas y resultados de cálculo se mantienen durante la sesión; copiar un resultado requiere una acción del usuario. La app Android está configurada para desactivar el respaldo y la restauración en la nube de Android y excluir sus datos de las transferencias configurables entre dispositivos. El comportamiento de migración puede depender del sistema operativo y del fabricante. Esta configuración no implica borrar copias históricas que pudieran existir fuera del dispositivo. No se publicaron ni modificaron políticas en esta tarea.

## Estado final

Cambios de esta tarea: un manifest modificado, dos XML nuevos y este reporte nuevo. El documento previo `docs/phase18-release-readiness.md` permanece sin seguimiento y sin editar. No se realizaron commits, pushes, publicaciones ni cambios en Google Play Console. Trabajo detenido después del reporte.
