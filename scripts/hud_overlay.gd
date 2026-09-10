extends Control

var speed_kph := 0.0
var nitro := 100.0
var drifting := false
var checkpoint := 0
var checkpoint_total := 0
var race_time := 0.0
var race_active := false
var message := "OPEN ROADS // NIGHT RUN"
var message_time := 0.0
var player_world := Vector3.ZERO
var pickup_count := 0
var mission_title := "MISIÓN // LIBRE"
var mission_desc := "Explora la ciudad"
var mission_progress := 0.0
var mission_target := 1.0
var rep_points := 0
var missions_done := 0
var intro_backdrop: ColorRect
var intro_panel: PanelContainer
var intro_title: Label
var intro_subtitle: Label
var intro_line: ColorRect
var intro_tween: Tween

func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_circuit_intro()
	queue_redraw()

func _build_circuit_intro() -> void:
	intro_backdrop = ColorRect.new()
	intro_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_backdrop.color = Color(0.005, 0.01, 0.04, 0.72)
	intro_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_backdrop.visible = false
	add_child(intro_backdrop)
	intro_panel = PanelContainer.new()
	intro_panel.set_anchors_preset(Control.PRESET_CENTER)
	intro_panel.position = Vector2(-310, -92)
	intro_panel.size = Vector2(620, 184)
	intro_panel.pivot_offset = intro_panel.size * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.025, 0.075, 0.97)
	style.border_color = Color("19d7ff")
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.0, 0.75, 1.0, 0.28)
	style.shadow_size = 20
	intro_panel.add_theme_stylebox_override("panel", style)
	intro_backdrop.add_child(intro_panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	intro_panel.add_child(box)
	var eyebrow := Label.new()
	eyebrow.text = "NEON APEX // EVENT SYSTEM"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.modulate = Color(0.55, 0.82, 1.0)
	eyebrow.add_theme_font_size_override("font_size", 14)
	box.add_child(eyebrow)
	intro_title = Label.new()
	intro_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_title.add_theme_font_size_override("font_size", 38)
	box.add_child(intro_title)
	intro_subtitle = Label.new()
	intro_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_subtitle.add_theme_font_size_override("font_size", 17)
	intro_subtitle.modulate = Color(0.75, 0.86, 1.0)
	box.add_child(intro_subtitle)
	intro_line = ColorRect.new()
	intro_line.custom_minimum_size = Vector2(0, 5)
	box.add_child(intro_line)

func play_circuit_intro(circuit_name: String, circuit_desc: String, accent: Color) -> void:
	if intro_tween != null and intro_tween.is_valid():
		intro_tween.kill()
	intro_title.text = circuit_name
	intro_subtitle.text = circuit_desc
	intro_title.modulate = accent
	intro_line.color = accent
	intro_backdrop.visible = true
	intro_backdrop.modulate = Color(1, 1, 1, 0)
	intro_panel.scale = Vector2(0.78, 0.78)
	intro_line.scale.x = 0.02
	intro_tween = create_tween().set_parallel(false)
	intro_tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(intro_backdrop, "modulate:a", 1.0, 0.18)
	intro_tween.parallel().tween_property(intro_panel, "scale", Vector2.ONE, 0.42)
	intro_tween.parallel().tween_property(intro_line, "scale:x", 1.0, 0.62)
	intro_tween.tween_interval(1.15)
	intro_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	intro_tween.tween_property(intro_panel, "scale", Vector2(1.06, 1.06), 0.16)
	intro_tween.parallel().tween_property(intro_backdrop, "modulate:a", 0.0, 0.24)
	intro_tween.tween_callback(func(): intro_backdrop.visible = false)

func _process(delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	if size != viewport_size:
		size = viewport_size
	if message_time > 0.0:
		message_time = maxf(0.0, message_time - delta)
	queue_redraw()

func set_telemetry(kph: float, nitro_value: float, is_drifting: bool) -> void:
	speed_kph = kph
	nitro = nitro_value
	drifting = is_drifting

func set_race(cp: int, total: int, time_value: float, active: bool) -> void:
	checkpoint = cp
	checkpoint_total = total
	race_time = time_value
	race_active = active

func set_world_position(pos: Vector3) -> void:
	player_world = pos

func set_pickups(value: int) -> void:
	pickup_count = value

func flash(text: String, seconds: float = 2.0) -> void:
	message = text
	message_time = seconds

func set_mission(title: String, desc: String, progress_value: float, target_value: float, rep_value: int, completed_value: int) -> void:
	mission_title = title
	mission_desc = desc
	mission_progress = progress_value
	mission_target = target_value
	rep_points = rep_value
	missions_done = completed_value

func _panel(rect: Rect2, accent: Color, alpha := 0.18) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.025, 0.07, 0.78)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.55)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(0,0,0,0.35)
	style.shadow_size = 8
	draw_style_box(style, rect)
	draw_rect(Rect2(rect.position + Vector2(12,8), Vector2(rect.size.x-24,2)), Color(accent.r,accent.g,accent.b,alpha), true)

func _draw() -> void:
	var s := size
	if s.x <= 10.0:
		s = get_viewport_rect().size
	_draw_speed_streaks(s)
	_draw_brand()
	_draw_minimap(Vector2(30,78))
	_draw_speedometer(Vector2(s.x-138,128))
	_draw_race_panel(Vector2(s.x*0.5-190,24))
	_draw_mission_panel(Vector2(30,280))
	_draw_nitro(Vector2(s.x-310,250))
	if drifting:
		draw_string(ThemeDB.fallback_font, Vector2(s.x*0.5-110, s.y-180), "DRIFT MODE", HORIZONTAL_ALIGNMENT_CENTER, 220, 28, Color("ff2bd6"))
	if message_time > 0.0:
		var rect := Rect2(Vector2(s.x*0.5-210, s.y*0.24), Vector2(420,58))
		_panel(rect, Color("19d7ff"), 0.4)
		draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y+38), message, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 22, Color.WHITE)

func _draw_speed_streaks(screen_size: Vector2) -> void:
	var intensity := clampf((speed_kph-105.0)/170.0,0.0,1.0)
	if intensity <= 0.0:
		return
	var center := screen_size*0.5
	for i in range(22):
		var a := float(i)/22.0*TAU + race_time*0.12
		var inner_r := lerpf(210.0,330.0,float((i*7)%10)/10.0)
		var length := 45.0 + float((i*13)%55)*intensity
		var dir := Vector2(cos(a),sin(a))
		var col := Color(0.45,0.88,1.0,0.08+0.22*intensity) if i%2==0 else Color(1.0,0.2,0.82,0.06+0.18*intensity)
		draw_line(center+dir*inner_r,center+dir*(inner_r+length),col,1.0+2.0*intensity,true)

func _draw_brand() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(30,42), "NEON APEX", HORIZONTAL_ALIGNMENT_LEFT, 260, 30, Color("19d7ff"))
	draw_string(ThemeDB.fallback_font, Vector2(31,65), "OPEN ROADS // PRO BUILD", HORIZONTAL_ALIGNMENT_LEFT, 300, 13, Color(0.7,0.82,1.0,0.9))

func _draw_minimap(origin: Vector2) -> void:
	var rect := Rect2(origin, Vector2(190,190))
	_panel(rect, Color("43f6a6"), 0.25)
	var center := rect.get_center()
	var road_color := Color(0.2,0.55,0.7,0.48)
	for x in [-120.0, 0.0, 120.0]:
		var px: float = center.x + float(x) * 0.55
		draw_line(Vector2(px,rect.position.y+15), Vector2(px,rect.end.y-15), road_color, 4.0)
	for z in [-120.0, 0.0, 120.0]:
		var py: float = center.y + float(z) * 0.55
		draw_line(Vector2(rect.position.x+15,py), Vector2(rect.end.x-15,py), road_color, 4.0)
	var player := center + Vector2(player_world.x, player_world.z) * 0.55
	player.x = clampf(player.x, rect.position.x+10, rect.end.x-10)
	player.y = clampf(player.y, rect.position.y+10, rect.end.y-10)
	draw_circle(player, 6.0, Color("ff2bd6"))
	draw_circle(player, 11.0, Color(1,0.2,0.8,0.16), false, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position+Vector2(14,20), "CITY GRID", HORIZONTAL_ALIGNMENT_LEFT, 100, 12, Color(0.8,0.9,1,0.9))

func _draw_speedometer(center: Vector2) -> void:
	var radius := 92.0
	for i in range(22):
		var t := float(i)/21.0
		var a := lerpf(PI*0.75, PI*2.25, t)
		var inner := center + Vector2(cos(a),sin(a))*(radius-10)
		var outer := center + Vector2(cos(a),sin(a))*radius
		var col := Color("19d7ff") if t < 0.72 else Color("ff2bd6")
		draw_line(inner, outer, Color(col.r,col.g,col.b,0.75), 3.0)
	var speed_norm := clampf(speed_kph/280.0,0.0,1.0)
	var needle_a := lerpf(PI*0.75, PI*2.25, speed_norm)
	draw_line(center, center+Vector2(cos(needle_a),sin(needle_a))*(radius-19), Color("ff365e"), 4.0)
	draw_circle(center, 8.0, Color("ff365e"))
	draw_string(ThemeDB.fallback_font, Vector2(center.x-76, center.y+20), "%03d" % int(speed_kph), HORIZONTAL_ALIGNMENT_CENTER, 152, 34, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(center.x-55, center.y+42), "KM/H", HORIZONTAL_ALIGNMENT_CENTER, 110, 13, Color(0.7,0.82,1.0))

func _draw_race_panel(origin: Vector2) -> void:
	var rect := Rect2(origin, Vector2(380,72))
	_panel(rect, Color("ff2bd6"), 0.25)
	var status := "FREE RIDE"
	if race_active:
		status = "CHECKPOINT %d/%d" % [checkpoint, checkpoint_total]
	elif checkpoint_total > 0 and checkpoint > 0:
		status = "RACE COMPLETE"
	draw_string(ThemeDB.fallback_font, origin+Vector2(0,28), status, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 18, Color("ff2bd6"))
	draw_string(ThemeDB.fallback_font, origin+Vector2(0,53), "%02d:%05.2f" % [int(race_time)/60, fmod(race_time,60.0)], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 22, Color.WHITE)

func _draw_nitro(origin: Vector2) -> void:
	var rect := Rect2(origin, Vector2(270,58))
	_panel(rect, Color("a855f7"), 0.25)
	draw_string(ThemeDB.fallback_font, origin+Vector2(15,22), "NITRO", HORIZONTAL_ALIGNMENT_LEFT, 74, 14, Color(0.9,0.8,1.0))
	var segments := 12
	var active_segments := int(round(nitro/100.0*segments))
	for i in range(segments):
		var x := origin.x+82+i*14
		var col := Color("a855f7") if i < active_segments else Color(0.2,0.16,0.32,0.9)
		draw_rect(Rect2(Vector2(x,origin.y+15),Vector2(10,20)),col,true)
	draw_string(ThemeDB.fallback_font, origin+Vector2(184,45), "ORB %02d" % pickup_count, HORIZONTAL_ALIGNMENT_RIGHT, 70, 12, Color("43f6a6"))

func _draw_mission_panel(origin: Vector2) -> void:
	var rect := Rect2(origin, Vector2(270, 126))
	_panel(rect, Color("f6c945"), 0.24)
	draw_string(ThemeDB.fallback_font, origin + Vector2(14, 22), mission_title, HORIZONTAL_ALIGNMENT_LEFT, 236, 16, Color("f6c945"))
	draw_string(ThemeDB.fallback_font, origin + Vector2(14, 44), mission_desc, HORIZONTAL_ALIGNMENT_LEFT, 242, 13, Color(0.85, 0.92, 1.0))
	var bar_rect := Rect2(origin + Vector2(14, 64), Vector2(240, 16))
	draw_rect(bar_rect, Color(0.1, 0.13, 0.22, 0.92), true)
	var ratio := 0.0
	if mission_target > 0.0:
		ratio = clampf(mission_progress / mission_target, 0.0, 1.0)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * ratio, bar_rect.size.y)), Color("f6c945"), true)
	var progress_text := "%d / %d" % [int(round(mission_progress)), int(round(maxf(mission_target, 0.0)))]
	if mission_target > 10.0:
		progress_text = "%d / %d" % [int(mission_progress), int(maxf(mission_target, 0.0))]
	draw_string(ThemeDB.fallback_font, origin + Vector2(14, 100), progress_text, HORIZONTAL_ALIGNMENT_LEFT, 110, 13, Color.WHITE)
	draw_string(ThemeDB.fallback_font, origin + Vector2(124, 100), "REP %03d" % rep_points, HORIZONTAL_ALIGNMENT_LEFT, 70, 13, Color("43f6a6"))
	draw_string(ThemeDB.fallback_font, origin + Vector2(184, 100), "MIS %02d" % missions_done, HORIZONTAL_ALIGNMENT_LEFT, 70, 13, Color("19d7ff"))
