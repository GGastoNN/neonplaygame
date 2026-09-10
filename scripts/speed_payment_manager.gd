extends Node

signal status_changed(text: String)
signal products_changed
signal entitlement_changed(product_id: String, owned: bool)
signal wallet_opened(product_id: String)

const LIGHTNING_ADDRESS := "gastonc@speed.app"
const PRICE_SATS := 50
const PRICE_MSATS := PRICE_SATS * 1000
const SPEED_ANDROID_PACKAGE := "com.app.speedwallet"
const SPEED_PLAY_STORE_URL := "https://play.google.com/store/apps/details?id=com.app.speedwallet"
const SAVE_PATH := "user://speed_wallet_entitlements.cfg"

var product_ids: PackedStringArray = PackedStringArray([
	"neon_engine_stage1",
	"neon_steering_pro",
	"neon_nitro_tank",
	"neon_aero_kit",
	"neon_lighting_pack"
])

var owned: Dictionary = {}
var status := "Speed Wallet // listo"
var pending_product_id := ""
var pending_invoice := ""
var pending_verify_url := ""
var pending_created_at := 0

var _http: HTTPRequest
var _request_kind := ""
var _lnurl_callback := ""
var _comment_allowed := 0

func _ready() -> void:
	for product_id in product_ids:
		owned[String(product_id)] = false
	_load_local_entitlements()
	_load_pending_payment()
	_http = HTTPRequest.new()
	_http.timeout = 18.0
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)
	_set_status("Speed Wallet // 50 sats por mejora")

func purchase(product_id: String) -> void:
	if product_id not in product_ids:
		_set_status("Producto no válido")
		return
	if is_owned(product_id):
		_set_status("Mejora ya comprada")
		return
	if _http == null:
		_set_status("Servicio de pago no disponible")
		return

	pending_product_id = product_id
	pending_invoice = ""
	pending_verify_url = ""
	pending_created_at = int(Time.get_unix_time_from_system())
	_save_pending_payment()
	products_changed.emit()

	var parts := LIGHTNING_ADDRESS.split("@", false, 1)
	if parts.size() != 2:
		_set_status("Lightning Address inválida")
		return
	var user := String(parts[0]).uri_encode()
	var domain := String(parts[1])
	var lnurlp_url := "https://%s/.well-known/lnurlp/%s" % [domain, user]
	_request_kind = "lnurlp"
	_set_status("Creando invoice de %d sats..." % PRICE_SATS)
	var err := _http.request(lnurlp_url)
	if err != OK:
		_set_status("No se pudo consultar Speed Wallet (%d)" % err)

func verify_pending_payment() -> void:
	if pending_product_id == "":
		_set_status("No hay un pago pendiente")
		return
	if pending_verify_url == "":
		_set_status("Speed no entregó verificación pública para esta invoice")
		return
	_request_kind = "verify"
	_set_status("Verificando pago Lightning...")
	var err := _http.request(pending_verify_url)
	if err != OK:
		_set_status("No se pudo verificar el pago (%d)" % err)

func is_owned(product_id: String) -> bool:
	return bool(owned.get(product_id, false))

func is_pending(product_id: String) -> bool:
	return pending_product_id == product_id and not is_owned(product_id)

func get_price(_product_id: String) -> String:
	return "%d SATS" % PRICE_SATS

func get_lightning_address() -> String:
	return LIGHTNING_ADDRESS

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		_set_status("Error de red Lightning (%d)" % result)
		return
	if response_code < 200 or response_code >= 300:
		_set_status("Speed respondió HTTP %d" % response_code)
		return

	var data := _parse_json_dict(body)
	if data.is_empty():
		_set_status("Respuesta Lightning inválida")
		return
	if String(data.get("status", "")).to_upper() == "ERROR":
		_set_status(String(data.get("reason", "Error Lightning")))
		return

	match _request_kind:
		"lnurlp":
			_handle_lnurlp(data)
		"invoice":
			_handle_invoice(data)
		"verify":
			_handle_verify(data)
		_:
			_set_status("Respuesta de pago inesperada")

func _handle_lnurlp(data: Dictionary) -> void:
	var callback := String(data.get("callback", ""))
	if not callback.begins_with("https://"):
		_set_status("Callback Lightning no seguro")
		return
	var min_sendable := int(data.get("minSendable", 0))
	var max_sendable := int(data.get("maxSendable", 0))
	if min_sendable > PRICE_MSATS or (max_sendable > 0 and max_sendable < PRICE_MSATS):
		_set_status("La dirección no acepta exactamente %d sats" % PRICE_SATS)
		return

	_lnurl_callback = callback
	_comment_allowed = int(data.get("commentAllowed", 0))
	var separator := "&" if callback.contains("?") else "?"
	var invoice_url := callback + separator + "amount=%d" % PRICE_MSATS
	var comment := "Neon Apex %s" % pending_product_id
	if _comment_allowed >= comment.length():
		invoice_url += "&comment=" + comment.uri_encode()
	_request_kind = "invoice"
	_set_status("Solicitando invoice de %d sats..." % PRICE_SATS)
	var err := _http.request(invoice_url)
	if err != OK:
		_set_status("No se pudo crear la invoice (%d)" % err)

func _handle_invoice(data: Dictionary) -> void:
	var invoice := String(data.get("pr", ""))
	if invoice == "":
		_set_status("Speed no devolvió una invoice Lightning")
		return

	pending_invoice = invoice
	pending_verify_url = _extract_verify_url(data)
	_save_pending_payment()
	products_changed.emit()

	_set_status("Abriendo Speed Wallet // %d sats" % PRICE_SATS)
	var opened := _open_speed_wallet(invoice)
	if opened:
		wallet_opened.emit(pending_product_id)
	else:
		_set_status("No se pudo abrir Speed Wallet")

func _handle_verify(data: Dictionary) -> void:
	if _response_says_paid(data):
		_grant(pending_product_id)
		_clear_pending_payment()
		products_changed.emit()
		_set_status("Pago confirmado ⚡ mejora desbloqueada")
	else:
		_set_status("Pago todavía no confirmado")

func _extract_verify_url(data: Dictionary) -> String:
	for key in ["verify", "verify_url", "verifyUrl", "payment_verify_url", "checking_url"]:
		var value := String(data.get(key, ""))
		if value.begins_with("https://"):
			return value
	return ""

func _response_says_paid(data: Dictionary) -> bool:
	for key in ["settled", "paid", "is_paid", "complete", "completed"]:
		if bool(data.get(key, false)):
			return true
	var state := String(data.get("status", data.get("state", ""))).to_upper()
	return state in ["PAID", "SETTLED", "COMPLETE", "COMPLETED", "SUCCEEDED", "SUCCESS"]

func _open_speed_wallet(invoice: String) -> bool:
	var lightning_uri := "lightning:" + invoice
	if OS.get_name() == "Android":
		var runtime := Engine.get_singleton("AndroidRuntime")
		var wrapper := Engine.get_singleton("JavaClassWrapper")
		if runtime != null and wrapper != null:
			var intent_class = wrapper.call("wrap", "android.content.Intent")
			var uri_class = wrapper.call("wrap", "android.net.Uri")
			if intent_class != null and uri_class != null:
				var intent = intent_class.call("Intent")
				var uri = uri_class.call("parse", lightning_uri)
				if intent != null and uri != null:
					intent.call("setAction", "android.intent.action.VIEW")
					intent.call("setData", uri)
					intent.call("setPackage", SPEED_ANDROID_PACKAGE)
					var activity = runtime.call("getActivity")
					if activity != null:
						activity.call("startActivity", intent)
						var exception = wrapper.call("get_exception")
						if exception == null:
							return true
						_set_status("Speed Wallet no está instalada")
						OS.shell_open(SPEED_PLAY_STORE_URL)
						return false

	# Fallback para escritorio u otros Android: abre el esquema Lightning con la wallet compatible.
	return OS.shell_open(lightning_uri) == OK

func _parse_json_dict(body: PackedByteArray) -> Dictionary:
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)

func _grant(product_id: String) -> void:
	if product_id == "" or is_owned(product_id):
		return
	owned[product_id] = true
	_save_local_entitlements()
	entitlement_changed.emit(product_id, true)

func _set_status(text: String) -> void:
	status = text
	status_changed.emit(text)

func _load_local_entitlements() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for product_id in product_ids:
		owned[String(product_id)] = bool(cfg.get_value("owned", String(product_id), false))

func _save_local_entitlements() -> void:
	var cfg := ConfigFile.new()
	for product_id in product_ids:
		cfg.set_value("owned", String(product_id), is_owned(String(product_id)))
	cfg.save(SAVE_PATH)

func _save_pending_payment() -> void:
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(SAVE_PATH):
		cfg.load(SAVE_PATH)
	cfg.set_value("pending", "product_id", pending_product_id)
	cfg.set_value("pending", "invoice", pending_invoice)
	cfg.set_value("pending", "verify_url", pending_verify_url)
	cfg.set_value("pending", "created_at", pending_created_at)
	cfg.save(SAVE_PATH)

func _load_pending_payment() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	pending_product_id = String(cfg.get_value("pending", "product_id", ""))
	pending_invoice = String(cfg.get_value("pending", "invoice", ""))
	pending_verify_url = String(cfg.get_value("pending", "verify_url", ""))
	pending_created_at = int(cfg.get_value("pending", "created_at", 0))

func _clear_pending_payment() -> void:
	pending_product_id = ""
	pending_invoice = ""
	pending_verify_url = ""
	pending_created_at = 0
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(SAVE_PATH):
		cfg.load(SAVE_PATH)
	cfg.erase_section("pending")
	cfg.save(SAVE_PATH)
