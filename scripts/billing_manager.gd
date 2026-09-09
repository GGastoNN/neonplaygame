extends Node

signal status_changed(text: String)
signal products_changed
signal entitlement_changed(product_id: String, owned: bool)

const PRODUCT_IDS := PackedStringArray([
	"neon_engine_stage1",
	"neon_steering_pro",
	"neon_nitro_tank",
	"neon_aero_kit",
	"neon_lighting_pack"
])
const PRODUCT_TYPE_INAPP := 0
const PURCHASE_STATE_PURCHASED := 1
const RESPONSE_OK := 0
const SAVE_PATH := "user://iap_entitlements.cfg"

var billing_client: Object
var prices: Dictionary = {}
var owned: Dictionary = {}
var status := "Inicializando tienda..."

func _ready() -> void:
	for product_id in PRODUCT_IDS:
		prices[String(product_id)] = "USD 2.00"
		owned[String(product_id)] = false
	_load_local_entitlements()
	_initialize_billing()

func _initialize_billing() -> void:
	var billing_script_path := "res://addons/GodotGooglePlayBilling/BillingClient.gd"
	if not ResourceLoader.exists(billing_script_path):
		_set_status("Compras reales: disponible en build de Google Play")
		return
	var billing_script: Script = load(billing_script_path)
	billing_client = billing_script.new()
	if billing_client == null:
		_set_status("Google Play Billing no disponible")
		return
	add_child(billing_client)
	_connect_if_present("connected", _on_connected)
	_connect_if_present("disconnected", _on_disconnected)
	_connect_if_present("connect_error", _on_connect_error)
	_connect_if_present("query_product_details_response", _on_product_details)
	_connect_if_present("query_purchases_response", _on_purchases)
	_connect_if_present("on_purchase_updated", _on_purchase_updated)
	_connect_if_present("acknowledge_purchase_response", _on_acknowledged)
	billing_client.call("start_connection")

func _connect_if_present(signal_name: StringName, callable: Callable) -> void:
	if billing_client != null and billing_client.has_signal(signal_name):
		billing_client.connect(signal_name, callable)

func purchase(product_id: String) -> void:
	if is_owned(product_id):
		_set_status("Mejora ya comprada")
		return
	if billing_client == null or not bool(billing_client.call("is_ready")):
		_set_status("Instala la app desde Google Play para comprar")
		return
	var result: Dictionary = billing_client.call("purchase", product_id)
	if int(result.get("response_code", -999)) != RESPONSE_OK:
		_set_status("No se pudo abrir Google Play: %s" % String(result.get("debug_message", "error")))

func restore_purchases() -> void:
	if billing_client != null and bool(billing_client.call("is_ready")):
		billing_client.call("query_purchases", PRODUCT_TYPE_INAPP, false)
		_set_status("Restaurando compras...")
	else:
		_set_status("Google Play no conectado")

func is_owned(product_id: String) -> bool:
	return bool(owned.get(product_id, false))

func get_price(product_id: String) -> String:
	return String(prices.get(product_id, "USD 2.00"))

func _on_connected() -> void:
	_set_status("Google Play conectado")
	billing_client.call("query_product_details", PRODUCT_IDS, PRODUCT_TYPE_INAPP)
	billing_client.call("query_purchases", PRODUCT_TYPE_INAPP, false)

func _on_disconnected() -> void:
	_set_status("Google Play desconectado")

func _on_connect_error(response_code: int, debug_message: String) -> void:
	_set_status("Billing %d: %s" % [response_code, debug_message])

func _on_product_details(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != RESPONSE_OK:
		_set_status("No se pudieron consultar precios")
		return
	var details: Array = response.get("product_details", [])
	for detail_value in details:
		var detail: Dictionary = detail_value
		var product_id := String(detail.get("product_id", ""))
		var offers: Array = detail.get("one_time_purchase_offer_details_list", [])
		if product_id != "" and offers.size() > 0:
			var offer: Dictionary = offers[0]
			prices[product_id] = String(offer.get("formatted_price", prices.get(product_id, "USD 2.00")))
	products_changed.emit()

func _on_purchases(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != RESPONSE_OK:
		return
	var purchases: Array = response.get("purchases", [])
	for purchase_value in purchases:
		_process_purchase(Dictionary(purchase_value))

func _on_purchase_updated(response: Dictionary) -> void:
	var code := int(response.get("response_code", -1))
	if code == 1:
		_set_status("Compra cancelada")
		return
	if code != RESPONSE_OK:
		_set_status("Error de compra: %s" % String(response.get("debug_message", "")))
		return
	var purchases: Array = response.get("purchases", [])
	for purchase_value in purchases:
		_process_purchase(Dictionary(purchase_value))

func _process_purchase(purchase: Dictionary) -> void:
	if int(purchase.get("purchase_state", 0)) != PURCHASE_STATE_PURCHASED:
		_set_status("Compra pendiente en Google Play")
		return
	var ids: Array = purchase.get("product_ids", [])
	for product_value in ids:
		var product_id := String(product_value)
		if product_id in PRODUCT_IDS:
			_grant(product_id)
	if not bool(purchase.get("is_acknowledged", false)) and billing_client != null:
		var token := String(purchase.get("purchase_token", ""))
		if token != "":
			billing_client.call("acknowledge_purchase", token)

func _on_acknowledged(result: Dictionary) -> void:
	if int(result.get("response_code", -1)) == RESPONSE_OK:
		_set_status("Compra confirmada")

func _grant(product_id: String) -> void:
	if is_owned(product_id):
		return
	owned[product_id] = true
	_save_local_entitlements()
	entitlement_changed.emit(product_id, true)
	products_changed.emit()
	_set_status("Mejora desbloqueada")

func _set_status(text: String) -> void:
	status = text
	status_changed.emit(text)

func _load_local_entitlements() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for product_id in PRODUCT_IDS:
		owned[String(product_id)] = bool(cfg.get_value("owned", String(product_id), false))

func _save_local_entitlements() -> void:
	var cfg := ConfigFile.new()
	for product_id in PRODUCT_IDS:
		cfg.set_value("owned", String(product_id), is_owned(String(product_id)))
	cfg.save(SAVE_PATH)
