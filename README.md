# Neon Apex: Open Roads PRO V8

## Novedades V8

- **AUTO ACELERADOR:** doble toque rápido en ACELERA para dejarlo presionado. Un toque posterior o FRENO lo cancela.
- **GARAGE interactivo:** botón GARAGE en carrera, tienda de mejoras permanentes y restauración de compras.
- **Google Play Billing:** integración preparada con el plugin oficial GodotGooglePlayBilling 3.3.0.
- **5 mejoras:** Motor Stage 1, Dirección PRO, Nitro XL, Aero Track Kit y Neon Signature.
- Cada producto está pensado para precio base **USD 2.00** en Google Play Console.
- Se mantiene landscape, multitouch, HUD PRO, tráfico, ciudad, checkpoints y smoke test.

## Compra real

Para bienes digitales Android se usa **Google Play Billing**, no Google Pay SDK directo. El checkout real funciona cuando la app está configurada y distribuida mediante Google Play. Crea los productos indicados en `GOOGLE_PLAY_COMPRAS.md`.

## Compilación

El workflow instala automáticamente Godot 4.3, Android Gradle Build Template y el plugin oficial de Billing. Genera `NeonApex-PRO-V8-GARAGE-debug.apk`.

# Neon Apex: Open Roads PRO V7 — Landscape

## Cambio principal

Esta versión está diseñada específicamente para **smartphone en horizontal**.

- Orientación: **Sensor Landscape** (el teléfono puede girarse hacia cualquiera de los dos lados horizontales).
- Resolución base: **1280×720**.
- Stretch: **canvas_items + expand**, para aprovechar pantallas 16:9, 18:9, 19:9, 20:9 y similares.
- Refuerzo en tiempo de ejecución mediante `DisplayServer.SCREEN_SENSOR_LANDSCAPE`.
- Se mantienen el multitouch, HUD PRO, tráfico, nitro, drift, cámara dinámica y smoke test.

APK generado: `NeonApex-PRO-V8-GARAGE-debug.apk`.

Artifact: `NeonApex-PRO-V8-GARAGE-Android-Debug`.

---


## V5 - corrección de pantalla oscura en Android

Esta versión cambia el arranque para crear primero jugador, cámara y HUD, y luego construir la ciudad de forma progresiva. También excluye el auto del `SpringArm3D`, fuerza el tamaño del HUD al viewport y agrega un smoke test de ejecución en GitHub Actions antes de exportar el APK.

APK generado: `NeonApex-PRO-V5-debug.apk`.

# Neon Apex: Open Roads PRO

Juego arcade de conducción nocturna desarrollado en **Godot 4.3**, preparado para Android y escritorio.

## Cambios de la edición PRO 0.4

- Control móvil **multitáctil real**: permite acelerar y doblar al mismo tiempo, además de combinar NITRO y DRIFT.
- Dirección progresiva con asistencia a baja velocidad y menor sensibilidad a alta velocidad.
- Auto deportivo reconstruido con carrocería por capas, cabina, splitter, faldones, alerón, llantas, faros, luces de freno, underglow y llamas de nitro.
- Cámara con SpringArm, FOV dinámico, inclinación y vibración por velocidad.
- Ciudad ampliada con tres avenidas verticales y tres horizontales.
- Edificios de alturas y colores variados con bandas luminosas, antenas y neón.
- Cielo nocturno con estrellas, luna, niebla y luz ambiental.
- Calles con veredas, líneas de carril, bordes neon, cruces peatonales y alumbrado.
- Carteles 3D luminosos y luces de intersección.
- Tráfico controlado por IA con varios autos y rutas.
- Circuito coherente de 10 checkpoints dentro de la red de calles.
- Pickups de nitro que reaparecen.
- HUD gráfico nuevo con velocímetro analógico/digital, barra segmentada de nitro, minimapa, cronómetro, checkpoints, contador de pickups y efectos de velocidad.
- Mantiene ETC2/ASTC habilitado para exportación Android.
- Workflow de GitHub Actions actualizado para generar `NeonApex-PRO-debug.apk`.

## Controles Android

Los controles se dibujan sobre la pantalla y aceptan varios dedos simultáneamente:

- **◀ / ▶**: dirección
- **ACELERA**: acelerador
- **FRENO**: freno y marcha atrás a baja velocidad
- **NITRO**: turbo
- **DRIFT**: pérdida de grip controlada

Ejemplo: podés mantener **ACELERA + ▶ + NITRO** a la vez.

## Controles PC

- W / Flecha arriba: acelerar
- S / Flecha abajo: frenar / marcha atrás
- A / D o Flechas: dirección
- Espacio: drift
- N: nitro
- R: reposicionar auto

## Exportar APK con GitHub Actions

1. Subí el contenido de este paquete a la raíz del repositorio.
2. Entrá en **Actions**.
3. Elegí **Build Android APK**.
4. Ejecutá **Run workflow**.
5. Al finalizar, descargá el artifact **NeonApex-PRO-Android-Debug**.

El APK se llama `NeonApex-PRO-debug.apk`.

## V9 - corrección de clases en CI/Godot 4.3

Esta versión elimina la dependencia del caché global de `class_name` para el arranque. `main.gd` carga los scripts principales mediante `preload()` y el Garage ya no exige `BillingManager` como tipo estático. También se corrigió la ruta de activación del plugin a `res://addons/GodotGooglePlayBilling/plugin.cfg`.

APK esperado: `NeonApex-PRO-V9-GARAGE-debug.apk`.


## V10 - compatibilidad Godot 4.3 Billing

Se corrigió la creación de la lista de productos de Google Play. En Godot 4.3, `PackedStringArray(...)` no es una expresión válida para una constante GDScript. Ahora los IDs se crean en runtime como un `PackedStringArray` tipado. También se fuerza `--quit` al instalar el Android Gradle Build Template para evitar jobs de CI bloqueados.


## V11 — Gradle CI estable

La V11 reemplaza el comando aislado `--install-android-build-template` por la instalación directa del `android_source.zip` oficial de Godot 4.3 en `android/build`. También crea `android/.build_version` y valida el template antes del smoke test y la exportación. El artifact generado es `NeonApex-PRO-V11-GARAGE-Android-Debug`.


## V12 / Android 16

El pipeline Android usa Godot 4.7.2 con compileSdk/targetSdk 36, Build Tools 36.1.0 y Google Play Billing 3.3.0. Esto corrige el conflicto de AAR metadata de la V11 y alinea el proyecto con Android 16.
