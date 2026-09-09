extends Node3D

var car: ArcadeCar
var hud: CanvasLayer
var speed_label: Label
var nitro_bar: ProgressBar
var checkpoint_label: Label
var checkpoints: Array[Area3D] = []
var checkpoint_index := 0
var race_started := false
var race_time := 0.0
var mobile := OS.has_feature("mobile")

func _ready() -> void:
	_build_environment()
	_build_city()
	_build_route()
	car = ArcadeCar.new(); car.name = "PlayerCar"; car.position = Vector3(0, 1.2, 18); add_child(car)
	car.telemetry.connect(_on_telemetry)
	_build_camera()
	_build_hud()

func _process(delta: float) -> void:
	if race_started:
		race_time += delta
		checkpoint_label.text = "CHECKPOINT %d/%d   %02d:%05.2f" % [checkpoint_index, checkpoints.size(), int(race_time)/60, fmod(race_time,60.0)]

func _build_environment() -> void:
	var env_node := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color("061023")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color("7d9be8"); env.ambient_light_energy = 0.45
	env.fog_enabled = true; env.fog_light_color = Color("172a51"); env.fog_density = 0.0025
	env.glow_enabled = true; env_node.environment = env; add_child(env_node)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-52,-28,0); sun.light_color=Color("91aaff"); sun.light_energy=.75; sun.shadow_enabled=true; add_child(sun)
	var ground := StaticBody3D.new(); var shape:=CollisionShape3D.new(); var ground_shape:=BoxShape3D.new(); ground_shape.size=Vector3(420,1,420); shape.shape=ground_shape; shape.position.y=-.5; ground.add_child(shape)
	var visual:=MeshInstance3D.new(); var plane:=BoxMesh.new(); plane.size=Vector3(420,1,420); visual.mesh=plane; visual.position.y=-.5
	var mat:=StandardMaterial3D.new(); mat.albedo_color=Color("07121b"); mat.roughness=.92; visual.material_override=mat; ground.add_child(visual); add_child(ground)

func _build_city() -> void:
	for x in range(-9,10):
		for z in range(-9,10):
			if abs(x) < 2 or abs(z) < 2 or (x+z)%7==0: continue
			var height := 5.0 + float(abs((x*17+z*31)%18))
			var building:=StaticBody3D.new(); building.position=Vector3(x*19,height*.5,z*19)
			var col:=CollisionShape3D.new(); var bs:=BoxShape3D.new(); bs.size=Vector3(13,height,13); col.shape=bs; building.add_child(col)
			var mi:=MeshInstance3D.new(); var bm:=BoxMesh.new(); bm.size=Vector3(13,height,13); mi.mesh=bm
			var material:=StandardMaterial3D.new(); material.albedo_color=Color.from_hsv(fmod(absf(x*.07+z*.03),1.0),.35,.16); material.metallic=.25; material.emission_enabled=true; material.emission=Color("07132b"); material.emission_energy_multiplier=.35
			mi.material_override=material; building.add_child(mi); add_child(building)
	_build_road(Vector3(0,.03,0),Vector3(34,.06,390))
	_build_road(Vector3(0,.04,0),Vector3(390,.06,34))

func _build_road(pos:Vector3,size:Vector3) -> void:
	var road:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size; road.mesh=mesh; road.position=pos
	var mat:=StandardMaterial3D.new(); mat.albedo_color=Color("161a24"); mat.roughness=.76; road.material_override=mat; add_child(road)
	var along_z:=size.z>size.x
	for lane in [-8.0,0.0,8.0]:
		var stripe:=MeshInstance3D.new(); var sm:=BoxMesh.new(); sm.size=Vector3(.2,.03,size.z-4 if along_z else size.x-4) if along_z else Vector3(size.x-4,.03,.2)
		stripe.mesh=sm; stripe.position=pos+Vector3(lane,.07,0) if along_z else pos+Vector3(0,.07,lane)
		var glow:=StandardMaterial3D.new(); glow.albedo_color=Color("19d7ff"); glow.emission_enabled=true; glow.emission=Color("19d7ff"); glow.emission_energy_multiplier=2.; stripe.material_override=glow; add_child(stripe)

func _build_route() -> void:
	var points=[Vector3(0,1,65),Vector3(0,1,-90),Vector3(95,1,-90),Vector3(95,1,0),Vector3(0,1,0)]
	for i in points.size():
		var area:=Area3D.new(); area.position=points[i]; area.set_meta("index",i)
		var col:=CollisionShape3D.new(); var box:=BoxShape3D.new(); box.size=Vector3(22,5,4); col.shape=box; area.add_child(col)
		var marker:=MeshInstance3D.new(); var torus:=TorusMesh.new(); torus.inner_radius=3.8; torus.outer_radius=4.2; marker.mesh=torus; marker.rotation_degrees.x=90
		var mat:=StandardMaterial3D.new(); mat.albedo_color=Color("ff2bd6"); mat.emission_enabled=true; mat.emission=Color("ff2bd6"); mat.emission_energy_multiplier=3.; marker.material_override=mat; area.add_child(marker)
		area.body_entered.connect(_checkpoint_entered.bind(area)); add_child(area); checkpoints.append(area)

func _checkpoint_entered(body:Node, area:Area3D) -> void:
	if body != car or int(area.get_meta("index")) != checkpoint_index: return
	if checkpoint_index==0: race_started=true; race_time=0.0
	checkpoint_index += 1
	area.visible=false; area.monitoring=false
	if checkpoint_index>=checkpoints.size():
		race_started=false; checkpoint_label.text="META — TIEMPO %.2f s"%race_time
		await get_tree().create_timer(4.0).timeout
		checkpoint_index=0
		for cp in checkpoints: cp.visible=true; cp.monitoring=true

func _build_camera() -> void:
	var pivot:=Node3D.new(); pivot.position=Vector3(0,3.1,7.8); car.add_child(pivot)
	var camera:=Camera3D.new(); camera.current=true; camera.fov=72.; pivot.add_child(camera)

func _build_hud() -> void:
	hud=CanvasLayer.new(); add_child(hud)
	var title:=Label.new(); title.text="NEON APEX"; title.position=Vector2(28,22); title.add_theme_font_size_override("font_size",28); title.modulate=Color("19d7ff"); hud.add_child(title)
	speed_label=Label.new(); speed_label.text="000 km/h"; speed_label.position=Vector2(1020,38); speed_label.add_theme_font_size_override("font_size",34); hud.add_child(speed_label)
	nitro_bar=ProgressBar.new(); nitro_bar.position=Vector2(1020,85); nitro_bar.size=Vector2(220,15); nitro_bar.value=100; nitro_bar.show_percentage=false; hud.add_child(nitro_bar)
	checkpoint_label=Label.new(); checkpoint_label.text="ATRAVIESA EL ARCO PARA INICIAR"; checkpoint_label.position=Vector2(440,28); checkpoint_label.add_theme_font_size_override("font_size",20); hud.add_child(checkpoint_label)
	_build_touch_controls()

func _build_touch_controls() -> void:
	var controls=[{"t":"◀","p":Vector2(40,570),"a":"steer_left"},{"t":"▶","p":Vector2(155,570),"a":"steer_right"},{"t":"FRENO","p":Vector2(930,590),"a":"brake"},{"t":"ACELERA","p":Vector2(1080,565),"a":"accelerate"},{"t":"NITRO","p":Vector2(1080,475),"a":"nitro"},{"t":"DRIFT","p":Vector2(930,500),"a":"handbrake"}]
	for data in controls:
		var b:=Button.new(); b.text=data.t; b.position=data.p; b.size=Vector2(120,74); b.modulate=Color(1,1,1,.76)
		b.set_meta("action", data.a)
		b.button_down.connect(_touch_down.bind(b))
		b.button_up.connect(_touch_up.bind(b))
		hud.add_child(b)

func _touch_down(button: Button) -> void:
	Input.action_press(StringName(button.get_meta("action")))

func _touch_up(button: Button) -> void:
	Input.action_release(StringName(button.get_meta("action")))

func _on_telemetry(kph:float,nitro:float,drifting:bool) -> void:
	speed_label.text="%03d km/h"%int(kph); nitro_bar.value=nitro
	speed_label.modulate=Color("ff2bd6") if drifting else Color.WHITE
