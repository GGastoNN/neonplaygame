class_name GarageMenu
extends Control

signal closed
signal purchase_requested(product_id: String)
signal restore_requested

const CATALOG: Array[Dictionary] = [
	{"id":"neon_engine_stage1", "name":"MOTOR STAGE 1", "desc":"+18% velocidad máxima y mejor aceleración"},
	{"id":"neon_steering_pro", "name":"DIRECCIÓN PRO", "desc":"Respuesta más rápida y mayor agarre"},
	{"id":"neon_nitro_tank", "name":"TANQUE NITRO XL", "desc":"Más capacidad y recarga de nitro"},
	{"id":"neon_aero_kit", "name":"AERO TRACK KIT", "desc":"Más estabilidad en curvas rápidas"},
	{"id":"neon_lighting_pack", "name":"NEON SIGNATURE", "desc":"Underglow violeta premium para el coche"}
]

var billing: BillingManager
var list_box: VBoxContainer
var status_label: Label
var title_label: Label
var cards: Dictionary = {}

func setup(manager: BillingManager) -> void:
	billing = manager
	if is_inside_tree():
		_bind_billing()
		_refresh()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()
	if billing != null:
		_bind_billing()
		_refresh()

func open_menu() -> void:
	visible = true
	_refresh()

func close_menu() -> void:
	visible = false
	closed.emit()

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.005,0.01,0.035,0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-440,-285)
	panel.size = Vector2(880,570)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018,0.03,0.09,0.98)
	style.border_color = Color("19d7ff")
	style.set_border_width_all(2)
	style.set_corner_radius_all(24)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation",10)
	panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	title_label = Label.new()
	title_label.text = "NEON GARAGE // PERFORMANCE STORE"
	title_label.add_theme_font_size_override("font_size",26)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	var close_btn := Button.new()
	close_btn.text = "CERRAR"
	close_btn.pressed.connect(close_menu)
	header.add_child(close_btn)

	var sub := Label.new()
	sub.text = "MEJORAS PERMANENTES • PRECIO BASE USD 2.00 • COBRO POR GOOGLE PLAY"
	sub.modulate = Color(0.75,0.84,1.0)
	root.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation",8)
	scroll.add_child(list_box)

	for item in CATALOG:
		_add_card(item)

	var footer := HBoxContainer.new()
	root.add_child(footer)
	status_label = Label.new()
	status_label.text = "Tienda lista"
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(status_label)
	var restore := Button.new()
	restore.text = "RESTAURAR COMPRAS"
	restore.pressed.connect(func(): restore_requested.emit())
	footer.add_child(restore)

func _add_card(item: Dictionary) -> void:
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.035,0.055,0.13,0.96)
	card_style.border_color = Color(0.25,0.55,0.85,0.65)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(14)
	card.add_theme_stylebox_override("panel",card_style)
	list_box.add_child(card)
	var row := HBoxContainer.new()
	card.add_child(row)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)
	var name_label := Label.new()
	name_label.text = String(item["name"])
	name_label.add_theme_font_size_override("font_size",20)
	name_label.modulate = Color("19d7ff")
	text_box.add_child(name_label)
	var desc := Label.new()
	desc.text = String(item["desc"])
	desc.modulate = Color(0.82,0.88,1.0)
	text_box.add_child(desc)
	var buy := Button.new()
	buy.custom_minimum_size = Vector2(190,64)
	var product_id := String(item["id"])
	buy.pressed.connect(func(): purchase_requested.emit(product_id))
	row.add_child(buy)
	cards[product_id] = buy

func _bind_billing() -> void:
	if not billing.products_changed.is_connected(_refresh):
		billing.products_changed.connect(_refresh)
	if not billing.status_changed.is_connected(_on_status):
		billing.status_changed.connect(_on_status)

func _on_status(text: String) -> void:
	if status_label != null:
		status_label.text = text

func _refresh() -> void:
	if billing == null:
		return
	for item in CATALOG:
		var product_id := String(item["id"])
		var button: Button = cards.get(product_id)
		if button == null:
			continue
		if billing.is_owned(product_id):
			button.text = "COMPRADO ✓"
			button.disabled = true
		else:
			button.text = "COMPRAR\n%s" % billing.get_price(product_id)
			button.disabled = false
	if status_label != null:
		status_label.text = billing.status
