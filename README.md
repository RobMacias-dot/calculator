# Engineering Toolkit

Una caja de herramientas de ingeniería, offline y extensible, para estudiantes y profesionales. **Calculate. Understand. Build.**

## Estado: Phase 5 — Visual Learning Foundation

**30 calculadoras determinísticas y cuatro visualizaciones educativas opcionales.** Phase 4 añadió 25 herramientas a las cinco originales. Phase 5 incorpora Voltage Divider, Vector Magnitude, Reynolds e IPv4/CIDR como pilotos visuales; no añade calculadoras ni modifica sus motores matemáticos. Phase 6 no está implementada.

| Categoría | Nuevas herramientas | Total |
| --- | --- | ---: |
| Electrical | DC Power (P/V/I), Electrical Energy, Series Resistance, Parallel Resistance, Voltage Divider | 6 |
| Mechanical | Torque, Work, Mechanical Power, Kinetic Energy, Momentum | 6 |
| Fluids | Volumetric Flow, Circular Pipe Flow, Hydrostatic Pressure, Bernoulli (P2) | 5 |
| Thermodynamics | Sensible Heat, Thermal Efficiency, Temperature Converter, Linear Thermal Expansion | 5 |
| Networking | Binary/Decimal IPv4, Subnet Mask ↔ CIDR, Wildcard Mask | 4 |
| Mathematics | Percentage (tres modos), Pythagorean (a/b/c), Quadratic Equation, Vector Magnitude (2D/3D) | 4 |

Todas usan el formulario existente con validación inline, unidades, fórmula, sustitución, explicación, reset, favorito y copia. Las condiciones físicas se muestran antes de las entradas. Series y Parallel permiten añadir resistencias y quitar la última, con mínimo dos y sin máximo artificial. Favoritos, apariencia System/Light/Dark y las últimas cinco herramientas abiertas se conservan localmente. Búsqueda, filtros y conteos usan el único registro de producción.

## Ejecutar

Entorno usado: Flutter **3.47.2 stable**, Dart **3.13.2**. Se versiona `pubspec.lock` para fijar la resolución de dependencias.

```sh
flutter pub get
flutter run
# Vista previa web
flutter run -d chrome
# APK local de depuración
flutter build apk --debug
```

iOS requiere macOS y Xcode; no se puede compilar desde Windows. La aplicación móvil no requiere red en ejecución. La vista web necesita un servidor para cargar los assets y no incluye instalación/PWA offline en esta fase.

## Arquitectura

MVVM pragmática, organizada por feature. `EngineeringToolkitApp` construye e inyecta dependencias. Home y formularios usan `ChangeNotifier` con `ListenableBuilder`. El catálogo, los parsers, las conversiones y los motores son Dart puro. `CalculatorViewModel` coordina operaciones registradas por composición; no contiene fórmulas ni ramas por calculadora.

```text
lib/
  main.dart
  app/
    app.dart
    router/app_router.dart
  core/design_system/
    app_tokens.dart, app_theme.dart
    app_scaffold.dart, glass_card.dart
    glass_bottom_navigation.dart, detail_page.dart
  core/formatting/number_formatting.dart
  features/
    calculators/
      domain/
        engines/      # Funciones puras y parser IPv4
        definitions/  # Modos: parsing → SI → motor → reporte
      presentation/   # Formulario, ViewModel y ResultCard
    home/presentation/
    settings/presentation/
test/
  domain/
  view_models/
  widgets/
docs/architecture.md
tool/test_domain.dart
```

`features/preferences` contiene un único repositorio de preferencias y un controlador pequeño. No hay backend, cuentas, sincronización, SQL ni historial de resultados. Decisiones y límites en [architecture.md](docs/architecture.md).

## Calidad

```sh
dart format .
flutter analyze
flutter test
# Los mismos casos matemáticos, sin importar Flutter
dart run tool/test_domain.dart
# Verificar también el destino web (requiere Chrome)
flutter test --platform chrome test/domain/calculation_test.dart
# Alternativa si el bootstrap del runner Chrome no carga:
dart compile js tool/test_domain_web.dart -o build/domain_checks.js
node build/domain_checks.js
# Opcional
flutter test --coverage
```

Pruebas de fórmulas, conversiones, parsing, límites físicos y numéricos, estados del ViewModel y flujos representativos de presentación. Todas las nuevas herramientas tienen casos de dominio; los widgets cubren estructuras compartidas, listas dinámicas, supuestos y resultados complejos. Se conservan registro inmutable, búsqueda, navegación/Atrás, enlaces directos, recuperación, temas, teclado y layouts de 320/430/1024 px. Los formularios originales y cinco flujos nuevos se prueban en 320 px al 200% en claro y oscuro. Son pruebas automatizadas; no sustituyen dispositivos físicos.

El baseline de **207 tests de Phase 3** pasó antes de modificar código. Phase 4 conserva esos casos y amplía la suite a **363 tests**, con **247 casos de dominio** ejecutables también en Dart puro y JavaScript/Node. Los tests históricos que dependen de un catálogo de cinco herramientas usan `test/support/phase3_catalog.dart`, compuesto por las mismas cinco definiciones originales; el catálogo completo tiene pruebas propias. Esa fixture no se importa desde producción.

Cierre verificado de Phase 4: `dart format .` sin cambios, `flutter analyze` sin incidencias, **363/363 tests**, **247/247 casos Dart puro** y verificación JavaScript/Node correcta. `flutter build apk --debug` genera `build/app/outputs/flutter-apk/app-debug.apk`. Ocho escenarios adicionales generan 16 capturas de revisión en ambos temas, fuera del conteo de la suite. Logs locales: `build/phase4-final-tests.log`, `build/phase4-final-domain.log`, `build/phase4-final-apk.log` y `build/phase4-captures.log`.

## Adding a new calculator

1. Escribir el motor en `domain/engines/`, con argumentos tipados en SI y `CalculationOutcome<T>`; probarlo en `test/domain/*_cases.dart`.
2. Crear la definición en `domain/definitions/`: ID estable, categoría, keywords, supuestos y modos con entradas/unidades y callback explícito. Usar `numericMode` para resultados escalares; IPv4 y quadratic muestran adaptadores pequeños para resultados estructurados. Añadir unidades al enum solo si faltan.
3. Registrar la definición en `initial_catalog.dart`. Búsqueda por nombre/categoría/keywords, conteos y ruta `/calculator/:calculatorId` se derivan del registro. No hay que modificar router ni ViewModel.
4. Añadir casos al ejecutor común de dominio: ejemplo independiente, límites, unidades y entradas inválidas/no finitas. Añadir pruebas de ViewModel/widget cuando aparezca una coordinación o presentación nueva. Ejecutar los checks anteriores.

El texto de `formula` **nunca se evalúa**. Los motores devuelven valores base sin redondear; el reporte convierte después a la unidad declarada y, cuando corresponde, muestra equivalencias (J/Wh/kWh, m³/s/L/s/L/min, K/°C/°F). No hay selector general de unidad de salida. Temperatura absoluta y diferencia de temperatura son dimensiones distintas: Δ1 °C = Δ1 K sin desplazamiento. Se aceptan punto o coma decimal y notación científica, sin separadores de miles. Cambiar unidad reinterpreta el valor escrito; cambiar objetivo limpia el formulario.

## Referencias y ejemplos comprobados

Los valores esperados se calcularon independientemente de los motores: 12 V × 2 A = **24 W**; 2 kW × 3 h = **6 kWh = 21600000 J**; 10 Ω y 20 Ω en paralelo = **6.666666… Ω**; masa 2 kg a 3 m/s = **9 J**; 0.02 m² × 3 m/s = **60 L/s**; agua con ρ = 1000 kg/m³ a 2 m = **19613.3 Pa** manométricos. Bernoulli con P1 = 100000 Pa, ρ = 1000, v1 = 2, v2 = 4 m/s, z1 = 3, z2 = 1 m da **P2 = 113613.3 Pa**.

2 kg × 4186 J/(kg·K) × Δ10 K = **83720 J**; 400 J / 1000 J = **40%**; 0 °C = **32 °F = 273.15 K**; x² + 2x + 5 = 0 tiene raíces **−1 ± 2i**. La gravedad estándar **g = 9.80665 m/s²** es explícita en código y en los supuestos de las herramientas que la usan.

Referencias: [NIST, conversiones y gravedad estándar](https://www.nist.gov/pml/special-publication-811/nist-guide-si-appendix-b-conversion-factors/nist-guide-si-appendix-b9), [OpenStax, Bernoulli y sus condiciones](https://openstax.org/books/university-physics-volume-1/pages/14-6-bernoullis-equation), [OpenStax, temperatura y expansión](https://openstax.org/books/university-physics-volume-2/pages/1-key-equations), [OpenStax, eficiencia térmica](https://openstax.org/books/university-physics-volume-2/pages/4-2-heat-engines).

IPv4 usa `BigInt` y bitwise, incluyendo `/0`. Para `/0–/30` cuenta `total − 2` hosts; `/31` permite ambos extremos punto a punto (RFC 3021); `/32` representa una dirección. `/31` y `/32` no muestran un broadcast dirigido ficticio. Los conteos no garantizan que una dirección reservada sea asignable.

## Dependencias

- `go_router ^18.0.1`: rutas declarativas y enlaces directos. Evita implementar manualmente el parser/delegado de Router.
- `shared_preferences ^2.5.5`: añadida en Phase 3. La [guía oficial de Flutter](https://docs.flutter.dev/cookbook/persistence/key-value) la recomienda para colecciones pequeñas de preferencias. Se usa `SharedPreferencesAsync`, API recomendada para integraciones nuevas, con DataStore Preferences por defecto en Android. Sus paquetes de plataforma son dependencias transitivas; no se añade otro sistema de storage. No es almacenamiento de datos críticos.
- `flutter_test` (SDK) y `flutter_lints ^6.0.0`: pruebas y análisis. Sin codegen.
- Sin `provider`: la inyección explícita y `ListenableBuilder` siguen siendo claras. El tema tiene un observable separado; cambiar favoritos no reconstruye `MaterialApp`.

Phase 4 añade **cero dependencias** y conserva `pubspec.yaml` y `pubspec.lock`.

## Preferencias locales

Se guarda un JSON pequeño bajo `engineering_toolkit.preferences.v1`: tema semántico y únicamente IDs de favoritos/recientes. El registro resuelve las definiciones y descarta IDs obsoletos. Recientes mantiene orden de apertura, sin duplicados y con máximo cinco; no guarda entradas ni resultados.

La lectura ocurre antes de `runApp`, con límite de dos segundos y defaults seguros (System, listas vacías). Campos incompatibles se ignoran; una lectura fallida no bloquea la aplicación. Los cambios se aplican al instante y se escriben en serie. Si falla el guardado, la sesión continúa y Settings informa discretamente; una escritura posterior vuelve a intentar guardar el estado completo. No hay garantía de durabilidad ante cierre abrupto del proceso o del dispositivo.

Los tests usan repositorios en memoria y un adaptador de storage simulado. Cubren restauración al reconstruir la app, corrupción, orden de escritura, favoritos, tema, recientes, búsqueda, filtros y clipboard, incluidos IDs nuevos. Las capturas de revisión se generan con `flutter test tool/capture_phase4.dart --update-goldens` en `build/phase4-*.png` usando las fuentes del SDK; no son baselines versionados. El script de Phase 3 conserva su fixture histórica.

## Límites de esta entrega

Iconos de instalación y firma de distribución siguen siendo los generados por Flutter; el build release utiliza la firma debug del scaffold y **no está preparado para tiendas**. Hace falta validación nativa con TalkBack/VoiceOver y dispositivos reales antes de una publicación. La restauración se verifica mediante tests con almacenamiento simulado; no sustituye un reinicio físico en Android/iOS. El motor físico usa `double`: valores o resultados intermedios fuera de rango se rechazan explícitamente. No incluye aritmética de precisión arbitraria. No se incluyen claves ni credenciales.

## Chrome runner

En Phase 3 se revisó el log anterior y se hizo un smoke limpio con salida verbose y timeout de casos de 45 s. Chrome inicia y expone DevTools, el servidor local sirve el runner, pero la carga no alcanza ningún caso; el timeout de casos no limita ese bootstrap. Se interrumpió el intento acotado. No se obtuvo una causa raíz concluyente; la evidencia apunta a la carga del runner/entorno, ya que esta suite no inicia la aplicación. El mismo dominio compilado con dart2js pasa bajo Node. Log local: `build/phase3-chrome-smoke.log`.

## Visual Learning Architecture

Después de calcular, **Learn visually** abre una superficie modal construida bajo demanda. Solo aparece en los cuatro pilotos y permanece deshabilitada sin un resultado válido. El formulario conserva resultado, fórmula, explicación y edición manual.

`CalculationResult + contexto validado → mapper de presentación → modelo inmutable → renderer`. Los controles vuelven al mismo `CalculatorViewModel`, que convierte sus entradas mediante las unidades existentes y ejecuta el motor habitual. La visualización no calcula el resultado principal ni es una fuente de verdad adicional.

| Piloto | Qué enseña | Interacción |
| --- | --- | --- |
| Voltage Divider | Circuito sin carga, nodo Vout y proporción de tensión; símbolos de resistores del mismo tamaño | Vin, R1 y R2; conserva las unidades elegidas en el formulario |
| Vector Magnitude | Componentes y dirección en 2D; proyección oblicua explícita en 3D | Componentes disponibles del modo actual, con escala gráfica automática |
| Reynolds | Trayectorias ilustrativas progresivamente irregulares; sin umbrales de régimen ni CFD | Velocidad y pausa/reanudación |
| IPv4/CIDR | 32 bits de dirección, separación red/host y tamaño de bloque en escala logarítmica | Prefijo completo /0–/32, incluidas las convenciones /31 y /32 |

Los rangos de sliders son exploratorios. Un valor manual fuera de rango permanece intacto hasta una edición explícita; solo se limita la posición del control. Los errores del motor ocultan la escena y permiten volver a las entradas.

Reynolds usa un `AnimationController`, `CustomPainter.repaint`, seis trayectorias en caché y 24 partículas. Los ticks no reconstruyen la pantalla ni ejecutan cálculos. Las demás escenas son estáticas. Se respeta tanto Remove animations como Reduce Motion, además de pausa manual, estado de la app y `TickerMode`. Las escenas ofrecen resúmenes semánticos, controles etiquetados, navegación por teclado y texto adaptable en claro/oscuro.

Para extender esta capa, véase [Visual Learning Architecture](docs/architecture.md#visual-learning-architecture): añadir datos tipados solo si faltan en el resultado, un mapper/modelo específico, un renderer y pruebas de interacción. No existe un framework universal de simulación. **Cero dependencias nuevas.**

Cuatro capturas estáticas de revisión: `flutter test tool/capture_phase5.dart --update-goldens` genera `build/phase5-*.png`. No son baselines pixel-perfect ni pruebas de animación por frame. La incidencia del runner Chrome sigue documentada arriba; Dart/JavaScript/Node continúa siendo la verificación alternativa del dominio.

Validación de Phase 5: **397 tests Flutter** (363 anteriores + 34 nuevos), **247 casos de dominio** en Dart puro y JavaScript/Node, analyzer sin incidencias, formato correcto y APK debug compilado. Los tests previos, motores y archivos de dependencias se conservaron. Se cubren límites numéricos, todos los prefijos, unidades, teclado, semántica, contraste, 320 px/200% en ambos temas, tablet y ciclo de vida de la animación.

Smoke Android: se instaló y abrió el APK en el emulador Pixel 7; se verificaron Home y su árbol de accesibilidad. El emulador perdió la conexión ADB durante la navegación y después dejó de aparecer entre dispositivos. **No se completó el recorrido nativo de los cuatro pilotos ni una medición de fps.** Quedan pendientes ese recorrido, TalkBack/VoiceOver y rendimiento sostenido en hardware físico. Evidencia local: `build/phase5-device-home.png`, `build/phase5-ui.xml` y `build/phase5-device-smoke.md`.
