# Neon Apex: Open Roads PRO — V13 Speed Wallet

## Objetivo
Arcade de conducción nocturna para Android con controles táctiles multitouch, ciudad cyber-neon, tráfico, carreras y mejoras permanentes del coche adquiridas mediante Bitcoin Lightning.

## Gameplay
- Control multitáctil real para acelerar, doblar, usar nitro y drift simultáneamente.
- Doble toque sobre ACELERA activa AUTO; otro toque o FRENO lo cancela.
- Cámara dinámica con SpringArm, FOV por velocidad e inclinación.
- Ciudad procedural 3x3, tráfico IA, checkpoints y pickups de nitro.
- HUD PRO con velocímetro, nitro, minimapa y cronómetro.

## Garage Lightning
Cinco mejoras permanentes, cada una con precio fijo de 50 sats:
- Motor Stage 1.
- Dirección PRO.
- Tanque Nitro XL.
- Aero Track Kit.
- Neon Signature.

El destino de cobro es la Lightning Address `gastonc@speed.app`.

### Flujo de pago
1. El jugador elige una mejora.
2. El juego resuelve la Lightning Address por LNURL-pay.
3. Solicita una invoice BOLT11 por exactamente 50 sats.
4. En Android intenta abrir Speed Wallet directamente con esa invoice.
5. La mejora solo se desbloquea cuando existe una confirmación verificable del pago.

Si el proveedor LNURL no entrega un endpoint de verificación de settlement, la versión de producción debe usar un backend/merchant API/webhook para confirmar el pago de manera segura.

## Android
- Godot 4.7.2 stable.
- GL Compatibility.
- Landscape sensor.
- Android API 36.
- Internet habilitado para LNURL/Lightning.
- Sin Google Play Billing en el código del juego.
