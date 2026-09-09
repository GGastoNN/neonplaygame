
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
