# Pagos con Speed Wallet / Bitcoin Lightning

## Configuración incluida

- Lightning Address receptora: configurada internamente y oculta en la interfaz.
- Precio por mejora: **50 sats**
- Red: Bitcoin Lightning
- Wallet Android preferida: Speed Wallet (`com.app.speedwallet`)

## Cómo funciona

El juego no almacena claves privadas ni credenciales de tu cuenta Speed.

Para iniciar una compra:

1. Convierte internamente la Lightning Address en un endpoint LNURL-pay seguro.
2. Consulta los límites admitidos y el callback de pago.
3. Solicita al callback una invoice de `50000` millisatoshis, equivalentes a 50 sats.
4. Recibe una invoice BOLT11 (`pr`).
5. En Android crea un Intent para `lightning:<invoice>` y lo dirige al paquete `com.app.speedwallet`.
6. Si el Intent específico no puede iniciarse, usa el esquema `lightning:` como fallback.

## Confirmación y desbloqueo

Abrir la wallet NO significa que el pago se haya realizado. Por seguridad, el juego nunca concede una mejora solo porque el usuario volvió desde Speed Wallet.

V13 busca un endpoint de verificación de settlement en la respuesta LNURL. Si existe, `VERIFICAR PAGO` consulta ese endpoint y solo desbloquea cuando el estado indica pago completado.

### Si no hay URL de verificación

Una Lightning Address normal no necesariamente expone al pagador una API pública para consultar el estado de una invoice. En ese caso, para una tienda comercial robusta hay que usar infraestructura de comerciante:

- backend propio + nodo Lightning; o
- Speed Merchant/Payment API + webhook; o
- otro procesador Lightning que entregue una referencia de pago verificable.

Ese backend debe asociar cada invoice a `product_id`, verificar settlement y devolver al juego un comprobante/entitlement. No se debe guardar una API key de comerciante dentro del APK.

## Productos

- `neon_engine_stage1` — Motor Stage 1 — 50 sats
- `neon_steering_pro` — Dirección PRO — 50 sats
- `neon_nitro_tank` — Tanque Nitro XL — 50 sats
- `neon_aero_kit` — Aero Track Kit — 50 sats
- `neon_lighting_pack` — Neon Signature — 50 sats

## Distribución

Si distribuyes el APK directamente desde tu web u otra tienda, no dependes de Google Play Billing. Si publicas el juego en Google Play y vendes mejoras digitales dentro del juego, revisa y cumple los programas/reglas de facturación alternativa aplicables al país del usuario antes de habilitar este flujo dentro de la versión de Play Store.
