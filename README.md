# Neon Apex: Open Roads PRO V13 — Speed Wallet

Juego arcade de conducción nocturna desarrollado en Godot para Android.

## V13

- Garage Lightning sin Google Play Billing.
- Cada mejora cuesta **50 sats**.
- Destino: **gastonc@speed.app**.
- El juego genera una invoice Lightning de 50 sats mediante LNURL-pay.
- En Android intenta abrir directamente **Speed Wallet** con la invoice preparada.
- Botón **VERIFICAR PAGO** para confirmar una compra pendiente cuando el proveedor ofrece verificación pública.
- Las mejoras no se desbloquean únicamente por abrir la wallet.
- Doble toque en **ACELERA** activa AUTO; otro toque o FRENO lo cancela.
- Landscape, multitouch, tráfico, nitro, drift, cámara dinámica, minimapa, checkpoints y ciudad neon se mantienen.

## Mejoras — 50 sats cada una

- `neon_engine_stage1` — Motor Stage 1.
- `neon_steering_pro` — Dirección PRO.
- `neon_nitro_tank` — Tanque Nitro XL.
- `neon_aero_kit` — Aero Track Kit.
- `neon_lighting_pack` — Neon Signature.

## Compilación

GitHub Actions usa Godot 4.7.2, Java 17 y Android API 36.

APK esperado:

`NeonApex-PRO-V13-SPEED-debug.apk`

Artifact:

`NeonApex-PRO-V13-SPEED-Android-Debug`

## Seguridad del pago

Una redirección a una wallet no demuestra que la invoice haya sido pagada. V13 solo concede la mejora cuando puede verificar settlement. Consulta `SPEED_WALLET_PAGOS.md` antes de publicar comercialmente.
