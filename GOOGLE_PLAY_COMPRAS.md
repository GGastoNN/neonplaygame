# Google Play Billing — preparación de Neon Apex PRO V8

La tienda del juego usa compras únicas (INAPP) mediante Google Play Billing.

## Productos a crear en Google Play Console

Crea estos 5 productos únicos **no consumibles** con precio base USD 2.00:

- `neon_engine_stage1` — Motor Stage 1
- `neon_steering_pro` — Dirección PRO
- `neon_nitro_tank` — Tanque Nitro XL
- `neon_aero_kit` — Aero Track Kit
- `neon_lighting_pack` — Neon Signature

Google Play puede localizar moneda, impuestos y precio final según país. La app consulta y muestra el precio que devuelve Play cuando está conectada.

## Importante

Google Play Billing funciona con una versión de la aplicación configurada y distribuida mediante Google Play. Un APK instalado manualmente puede mostrar el Garage, pero el checkout real requiere una build subida a una pista de prueba (Internal testing / Closed testing) y una cuenta de tester autorizada.

La V8 usa el plugin oficial `GodotGooglePlayBilling` 3.3.0 / Google Play Billing 9.1.0 durante el workflow de GitHub Actions.

Para producción debes usar un keystore de release estable, guardar las credenciales como GitHub Secrets y preferentemente generar un AAB para Play Console.

## V12 - Android 16

El pipeline V12 usa Godot 4.7.2, compileSdk 36, targetSdk 36, Build Tools 36.1.0 y GodotGooglePlayBilling 3.3.0 (Billing 9.1.0). Esto evita el conflicto de `androidx.core:core-ktx:1.15.0` que ocurría con el template Android de Godot 4.3.
