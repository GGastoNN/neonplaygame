extends Control

signal closed
signal purchase_requested(product_id: String)
signal verify_requested

const CATALOG: Array[Dictionary] = [
	{"id":"neon_engine_stage1", "name":"MOTOR STAGE 1", "desc":"+18% velocidad máxima y mejor aceleración"},
	{"id":"neon_steering_pro", "name":"DIRECCIÓN PRO", "desc":"Respuesta más rápida y mayor agarre"},
	{"id":"neon_nitro_tank", "name":"TANQUE NITRO XL", "desc":"Más capacidad y recarga de nitro"},
	{"id":"neon_aero_kit", "name":"AERO TRACK KIT", "desc":"Más estabilidad en curvas rápidas"},
	{"id":"neon_lighting_pack", "name":"NEON SIGNATURE", "desc":"Underglow violeta premium para el coche"}
]

var payment_manager
var list_box: VBoxContainer
var status_label: Label
var title_label: Label
var cards: Dictionary = {}
var wallet_label: Label
var owned_label: Label
var upgrade_progress: ProgressBar

func setup(manager) -> void:
	payment_manager = manager
	if is_inside_tree():
		_bind_manager()
		_refresh()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()
	if payment_manager != null:
		_bind_manager()
		_refresh()

func open_menu() -> void:
	visible = true
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.97, 0.97)
	_refresh()
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.22)
	tween.tween_property(self, "scale", Vector2.ONE, 0.28)

func close_menu() -> void:
	visible = false
	closed.emit()

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.003,0.008,0.025,0.965)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-500,-315)
	panel.size = Vector2(1000,630)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018,0.03,0.09,0.99)
	style.border_color = Color("19d7ff")
	style.set_border_width_all(2)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.0,0.65,1.0,0.22)
	style.shadow_size = 24
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation",10)
	panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	title_label = Label.new()
	title_label.text = "NEON PERFORMANCE LAB"
	title_label.add_theme_font_size_override("font_size",28)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.modulate = Color("19d7ff")
	header.add_child(title_label)
	var close_btn := Button.new()
	close_btn.text = "CERRAR"
	close_btn.pressed.connect(close_menu)
	header.add_child(close_btn)

	var sub := Label.new()
	sub.text = "VEHICLE DEVELOPMENT // STREET & TRACK DIVISION"
	sub.modulate = Color(0.80,0.88,1.0)
	root.add_child(sub)

	wallet_label = Label.new()
	wallet_label.text = "Destino protegido • pago seguro vía Lightning"
	wallet_label.modulate = Color(0.55, 0.95, 0.75)
	root.add_child(wallet_label)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	root.add_child(content)
	_build_showroom(content)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation",8)
	scroll.add_child(list_box)

	for item in CATALOG:
		_add_card(item)

	var footer := HBoxContainer.new()
	root.add_child(footer)
	status_label = Label.new()
	status_label.text = "Lightning listo"
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(status_label)
	var verify := Button.new()
	verify.text = "VERIFICAR PAGO ⚡"
	verify.custom_minimum_size = Vector2(190,48)
	verify.pressed.connect(func(): verify_requested.emit())
	footer.add_child(verify)

func _build_showroom(parent: HBoxContainer) -> void:
	var showcase := PanelContainer.new()
	showcase.custom_minimum_size = Vector2(315, 0)
	var showroom_style := StyleBoxFlat.new()
	showroom_style.bg_color = Color(0.012, 0.028, 0.065, 0.98)
	showroom_style.border_color = Color(0.12, 0.45, 0.65, 0.72)
	showroom_style.set_border_width_all(1)
	showroom_style.set_corner_radius_all(16)
	showcase.add_theme_stylebox_override("panel", showroom_style)
	parent.add_child(showcase)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 9)
	showcase.add_child(box)
	var bay := Label.new()
	bay.text = "SHOWROOM // BAY 01"
	bay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bay.modulate = Color(0.48, 0.72, 0.9)
	box.add_child(bay)
	var model := Label.new()
	model.text = "NEON APEX R"
	model.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	model.add_theme_font_size_override("font_size", 30)
	model.modulate = Color("19d7ff")
	box.add_child(model)
	var silhouette := Label.new()
	silhouette.text = "◢━━━━ VEHICLE ━━━━◣"
	silhouette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	silhouette.add_theme_font_size_override("font_size", 18)
	silhouette.modulate = Color("ff2bd6")
	box.add_child(silhouette)
	_add_spec(box, "POWER", 86.0, Color("ff365e"))
	_add_spec(box, "GRIP", 78.0, Color("19d7ff"))
	_add_spec(box, "NITRO", 72.0, Color("a855f7"))
	_add_spec(box, "AERO", 68.0, Color("43f6a6"))
	owned_label = Label.new()
	owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owned_label.modulate = Color("f6c945")
	box.add_child(owned_label)
	upgrade_progress = ProgressBar.new()
	upgrade_progress.max_value = float(CATALOG.size())
	upgrade_progress.show_percentage = false
	upgrade_progress.custom_minimum_size = Vector2(270, 10)
	box.add_child(upgrade_progress)

func _add_spec(parent: VBoxContainer, title: String, value: float, color: Color) -> void:
	var label := Label.new()
	label.text = "%s  %03d" % [title, int(value)]
	label.modulate = Color(0.78, 0.87, 1.0)
	parent.add_child(label)
	var bar := ProgressBar.new()
	bar.max_value = 100.0
	bar.value = value
	bar.show_percentage = false
	bar.modulate = color
	bar.custom_minimum_size = Vector2(270, 8)
	parent.add_child(bar)

func _add_card(item: Dictionary) -> void:
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.025,0.045,0.105,0.98)
	card_style.border_color = Color(0.12,0.55,0.78,0.68)
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
	buy.custom_minimum_size = Vector2(200,64)
	buy.add_theme_font_size_override("font_size", 14)
	var product_id := String(item["id"])
	buy.pressed.connect(func(): purchase_requested.emit(product_id))
	row.add_child(buy)
	cards[product_id] = buy

func _bind_manager() -> void:
	if not payment_manager.products_changed.is_connected(_refresh):
		payment_manager.products_changed.connect(_refresh)
	if not payment_manager.status_changed.is_connected(_on_status):
		payment_manager.status_changed.connect(_on_status)

func _on_status(text: String) -> void:
	if status_label != null:
		status_label.text = text

func _refresh() -> void:
	if payment_manager == null:
		return
	if wallet_label != null:
		wallet_label.text = "Destino protegido • pago seguro vía Lightning"
	var owned_count := 0
	for item in CATALOG:
		var product_id := String(item["id"])
		var button: Button = cards.get(product_id)
		if button == null:
			continue
		if payment_manager.is_owned(product_id):
			owned_count += 1
			button.text = "COMPRADO ✓"
			button.disabled = true
		elif payment_manager.is_pending(product_id):
			button.text = "REINTENTAR PAGO ⚡\n50 SATS"
			button.disabled = false
		else:
			button.text = "PAGAR CON SPEED ⚡\n%s" % payment_manager.get_price(product_id)
			button.disabled = false
	if status_label != null:
		status_label.text = payment_manager.status
	if owned_label != null:
		owned_label.text = "DEVELOPMENT  %d / %d" % [owned_count, CATALOG.size()]
	if upgrade_progress != null:
		upgrade_progress.value = float(owned_count)
