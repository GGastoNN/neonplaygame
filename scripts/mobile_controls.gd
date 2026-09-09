class_name MobileControls
extends Control

signal controls_changed(throttle: float, brake: float, steer: float, handbrake: bool, nitro: bool)

const ACTIONS := ["steer_left", "steer_right", "brake", "accelerate", "nitro", "handbrake"]

var touches: Dictionary = {}
var mouse_action := ""
var current_throttle := 0.0
var current_brake := 0.0
var current_steer := 0.0
var current_handbrake := false
var current_nitro := false
var accelerate_latched := false
var last_accelerate_tap_ms := -10000
const DOUBLE_TAP_MS := 360

func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	queue_redraw()


func _process(_delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	if size != viewport_size:
		size = viewport_size
		queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			var action := _action_at(touch.position)
			if action != "":
				_handle_action_tap(action)
				touches[touch.index] = action
			else:
				touches.erase(touch.index)
		else:
			touches.erase(touch.index)
		_sync_state()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		var action := _action_at(drag.position)
		if action != "":
			touches[drag.index] = action
		else:
			touches.erase(drag.index)
		_sync_state()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			mouse_action = _action_at(mb.position) if mb.pressed else ""
			_sync_state()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mm := event as InputEventMouseMotion
		mouse_action = _action_at(mm.position)
		_sync_state()

func clear_controls() -> void:
	touches.clear()
	mouse_action = ""
	_sync_state()

func _sync_state() -> void:
	var active: Dictionary = {}
	for action in ACTIONS:
		active[action] = false
	for action in touches.values():
		if active.has(action):
			active[action] = true
	if mouse_action != "" and active.has(mouse_action):
		active[mouse_action] = true

	if active["brake"]:
		accelerate_latched = false
	current_throttle = 1.0 if active["accelerate"] or accelerate_latched else 0.0
	current_brake = 1.0 if active["brake"] else 0.0
	current_steer = (1.0 if active["steer_right"] else 0.0) - (1.0 if active["steer_left"] else 0.0)
	current_handbrake = active["handbrake"]
	current_nitro = active["nitro"]
	controls_changed.emit(current_throttle, current_brake, current_steer, current_handbrake, current_nitro)
	queue_redraw()

func _handle_action_tap(action: String) -> void:
	if action == "brake":
		accelerate_latched = false
		return
	if action != "accelerate":
		return
	var now_ms := Time.get_ticks_msec()
	if accelerate_latched:
		accelerate_latched = false
		last_accelerate_tap_ms = -10000
	elif now_ms - last_accelerate_tap_ms <= DOUBLE_TAP_MS:
		accelerate_latched = true
		last_accelerate_tap_ms = -10000
	else:
		last_accelerate_tap_ms = now_ms

func _action_at(pos: Vector2) -> String:
	for zone in _zones():
		var rect: Rect2 = zone["rect"]
		if rect.has_point(pos):
			return String(zone["action"])
	return ""

func _zones() -> Array[Dictionary]:
	var s := size
	if s.x <= 10.0 or s.y <= 10.0:
		s = get_viewport_rect().size
	var bottom := s.y - 28.0
	var left_w := 132.0
	var left_h := 104.0
	var pedal_w := 150.0
	var pedal_h := 104.0
	return [
		{"action":"steer_left", "label":"◀", "rect":Rect2(Vector2(28.0, bottom-left_h), Vector2(left_w, left_h))},
		{"action":"steer_right", "label":"▶", "rect":Rect2(Vector2(172.0, bottom-left_h), Vector2(left_w, left_h))},
		{"action":"handbrake", "label":"DRIFT", "rect":Rect2(Vector2(s.x-360.0, bottom-196.0), Vector2(118.0, 78.0))},
		{"action":"nitro", "label":"NITRO", "rect":Rect2(Vector2(s.x-222.0, bottom-222.0), Vector2(132.0, 82.0))},
		{"action":"brake", "label":"FRENO", "rect":Rect2(Vector2(s.x-382.0, bottom-pedal_h), Vector2(pedal_w, pedal_h))},
		{"action":"accelerate", "label":"ACELERA", "rect":Rect2(Vector2(s.x-214.0, bottom-pedal_h-8.0), Vector2(176.0, pedal_h+8.0))}
	]

func _draw() -> void:
	for zone in _zones():
		var action := String(zone["action"])
		var rect: Rect2 = zone["rect"]
		var pressed := _is_action_active(action)
		if action == "accelerate" and accelerate_latched:
			pressed = true
		var accent := _accent_for(action)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(accent.r, accent.g, accent.b, 0.40 if pressed else 0.18)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.98 if pressed else 0.55)
		style.set_border_width_all(3 if pressed else 2)
		style.corner_radius_top_left = 22
		style.corner_radius_top_right = 22
		style.corner_radius_bottom_left = 22
		style.corner_radius_bottom_right = 22
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
		style.shadow_size = 8
		draw_style_box(style, rect)
		var center := rect.get_center()
		if action == "accelerate" or action == "brake":
			draw_arc(center, minf(rect.size.x, rect.size.y) * 0.35, -PI * 0.9, PI * 0.9, 24, Color(accent.r,accent.g,accent.b,0.72), 3.0, true)
		var font_size := 28 if action.begins_with("steer") else 18
		var baseline := Vector2(rect.position.x, center.y + float(font_size) * 0.32)
		var label_text := String(zone["label"])
		if action == "accelerate" and accelerate_latched:
			label_text = "AUTO ON"
		draw_string(ThemeDB.fallback_font, baseline, label_text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, Color.WHITE)

func _is_action_active(action: String) -> bool:
	if mouse_action == action:
		return true
	for pressed_action in touches.values():
		if pressed_action == action:
			return true
	return false

func _accent_for(action: String) -> Color:
	match action:
		"accelerate": return Color("19d7ff")
		"brake": return Color("ff365e")
		"nitro": return Color("a855f7")
		"handbrake": return Color("ff2bd6")
		_: return Color("43f6a6")
