# Neon Apex: Open Roads PRO — Diseño 0.4

## Objetivo
Arcade de conducción nocturna para Android con controles táctiles multitouch, sensación de velocidad, circuito urbano y estética cyber-neon.

## Pilares
1. **Control inmediato**: aceleración y dirección simultáneas, drift accesible y nitro independiente.
2. **Lectura visual clara**: avenidas anchas, checkpoint gates, minimapa y HUD de carrera.
3. **Estética neon**: ciudad oscura, bandas emisivas, faros, underglow, carteles, estrellas y luna.
4. **Rendimiento móvil**: renderer GL Compatibility, geometría procedural simple y estrellas con MultiMesh.

## Mundo
- Malla urbana 3x3 de avenidas principales en X/Z = -120, 0, 120.
- Edificios procedurales de distintas alturas y colores.
- Veredas, líneas discontinuas, cruces peatonales, alumbrado, carteles 3D y neón lateral.
- Tráfico IA recorriendo loops urbanos.
- Pickups de nitro con respawn.

## Jugador
- CharacterBody3D arcade.
- Dirección suavizada y progresiva.
- Grip normal y grip reducido durante drift.
- Nitro con recarga pasiva y pickups.
- Carrocería procedural multicapa con animación visual de balanceo.
- Luces delanteras, freno, underglow y llamas de nitro.

## Cámara
- SpringArm3D para evitar clipping.
- FOV dinámico según velocidad y nitro.
- Inclinación por dirección y micro shake a alta velocidad.

## HUD
- Velocímetro analógico/digital.
- Nitro segmentado.
- Minimapa de la cuadrícula urbana.
- Cronómetro y checkpoints.
- Mensajes de carrera/pickups.
- Speed streaks a alta velocidad.

## Mobile Input
El HUD táctil no usa Button. Registra InputEventScreenTouch e InputEventScreenDrag por índice de dedo, permitiendo múltiples acciones simultáneas.
