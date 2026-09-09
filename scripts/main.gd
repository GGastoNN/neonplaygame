extends Node3D

var car: ArcadeCar
var hud: CanvasLayer
var hud_overlay: ProHUD
var mobile_controls: MobileControls
var camera: Camera3D
var spring_arm: SpringArm3D
var camera_pivot: Node3D
var checkpoints: Array[Area3D] = []
var checkpoint_index := 0
var race_started := false
var race_time := 0.0
var best_time := 0.0
var pickup_count := 0
var mobile := OS.has_feature("mobile")
var rng := RandomNumberGenerator.new()
var world_ready := false

const ROAD_COORDS := [-120.0, 0.0, 120.0]
const WORLD_SIZE := 520.0

func _ready() -> void:
	rng.seed = 884211

	# Arranque seguro: primero jugador, cámara y HUD. De esta forma el usuario
	# nunca queda frente a una pantalla negra mientras se construye la ciudad.
	_spawn_player()
	car.set_physics_process(false)
	_build_camera()
	_build_hud()
	_set_loading_message("BOOT // INICIANDO MOTOR VISUAL")
	await get_tree().process_frame

	_build_environment()
	_build_ground()
	_set_loading_message("BOOT // TRAZANDO AUTOPISTAS")
	await get_tree().process_frame
	await _build_roads()

	_set_loading_message("BOOT // LEVANTANDO NIGHT CITY")
	await _build_city()

	_set_loading_message("BOOT // ILUMINANDO DISTRITOS")
	await _build_street_details()

	_build_stars_and_moon()
	_build_route()
	_build_pickups()
	_spawn_traffic()

	world_ready = true
	car.set_physics_process(true)
	if hud_overlay != null:
		hud_overlay.flash("CITY ONLINE // DRIVE", 2.8)

func _process(delta: float) -> void:
	if race_started:
		race_time += delta
	if hud_overlay != null and car != null:
		hud_overlay.set_race(checkpoint_index, checkpoints.size(), race_time, race_started)
		hud_overlay.set_world_position(car.global_position)
	if camera != null and car != null:
		var speed_ratio := clampf(absf(car.speed) / 82.0, 0.0, 1.0)
		var nitro_extra := 5.0 if car.nitro_input and car.nitro_amount > 0.0 and car.speed > 8.0 else 0.0
		camera.fov = lerpf(camera.fov, 70.0 + speed_ratio*13.0 + nitro_extra, minf(1.0,delta*4.0))
		camera.position.x = sin(Time.get_ticks_msec()*0.035) * speed_ratio * 0.025
		camera.position.y = sin(Time.get_ticks_msec()*0.051) * speed_ratio * 0.018
		camera_pivot.rotation.z = lerpf(camera_pivot.rotation.z, -car.current_steer*speed_ratio*0.025, minf(1.0,delta*5.0))

func _build_environment() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("020714")
	sky_mat.sky_horizon_color = Color("1a4388")
	sky_mat.ground_horizon_color = Color("102a58")
	sky_mat.ground_bottom_color = Color("030814")
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("7795e8")
	env.ambient_light_energy = 0.78
	env.fog_enabled = true
	env.fog_light_color = Color("172d62")
	env.fog_density = 0.0012
	env.fog_sky_affect = 0.28
	# Glow se deja desactivado en GL Compatibility para priorizar estabilidad móvil.
	# Los materiales emisivos siguen dando el aspecto neón sin bloquear el arranque.
	env.glow_enabled = false
	env_node.environment = env
	add_child(env_node)

	var moon_light := DirectionalLight3D.new()
	moon_light.rotation_degrees = Vector3(-48,-32,0)
	moon_light.light_color = Color("a6bfff")
	moon_light.light_energy = 1.05
	moon_light.shadow_enabled = true
	add_child(moon_light)

func _build_ground() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(WORLD_SIZE,1.0,WORLD_SIZE)
	shape.shape = ground_shape
	shape.position.y = -0.5
	ground.add_child(shape)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(WORLD_SIZE,1.0,WORLD_SIZE)
	visual.mesh = mesh
	visual.position.y = -0.5
	visual.material_override = _material(Color("071923"),0.0,0.0,0.92)
	ground.add_child(visual)
	add_child(ground)

func _build_stars_and_moon() -> void:
	var star_mat := StandardMaterial3D.new()
	star_mat.albedo_color = Color("b9dcff")
	star_mat.emission_enabled = true
	star_mat.emission = Color("8bbcff")
	star_mat.emission_energy_multiplier = 3.4
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.18
	star_mesh.height = 0.36
	star_mesh.material = star_mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = star_mesh
	mm.instance_count = 160
	for i in range(mm.instance_count):
		var angle := rng.randf_range(0.0,TAU)
		var radius := rng.randf_range(210.0,380.0)
		var pos := Vector3(cos(angle)*radius,rng.randf_range(65.0,155.0),sin(angle)*radius)
		var scale_value := rng.randf_range(0.45,1.45)
		mm.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale_value),pos))
	var stars := MultiMeshInstance3D.new()
	stars.multimesh = mm
	add_child(stars)

	var moon_mat := StandardMaterial3D.new()
	moon_mat.albedo_color = Color("dbe8ff")
	moon_mat.emission_enabled = true
	moon_mat.emission = Color("b9cfff")
	moon_mat.emission_energy_multiplier = 1.7
	var moon := MeshInstance3D.new()
	var moon_mesh := SphereMesh.new()
	moon_mesh.radius = 11.0
	moon_mesh.height = 22.0
	moon.mesh = moon_mesh
	moon.position = Vector3(-185,112,-235)
	moon.material_override = moon_mat
	add_child(moon)

func _build_roads() -> void:
	for coord in ROAD_COORDS:
		_build_road(Vector3(coord,0.035,0),Vector3(30.0,0.07,WORLD_SIZE-20.0),true)
		_build_road(Vector3(0,0.04,coord),Vector3(WORLD_SIZE-20.0,0.07,30.0),false)
		await get_tree().process_frame
	for x in ROAD_COORDS:
		for z in ROAD_COORDS:
			_build_crosswalk(Vector3(x,0.105,z))
		await get_tree().process_frame

func _build_road(pos: Vector3, road_size: Vector3, vertical: bool) -> void:
	var road_mat := _material(Color("111824"),0.0,0.05,0.78)
	_make_visual_box(road_size,pos,road_mat)
	var sidewalk_mat := _material(Color("202a39"),0.0,0.08,0.83)
	if vertical:
		_make_visual_box(Vector3(3.2,0.22,road_size.z),pos+Vector3(-16.6,0.09,0),sidewalk_mat)
		_make_visual_box(Vector3(3.2,0.22,road_size.z),pos+Vector3(16.6,0.09,0),sidewalk_mat)
	else:
		_make_visual_box(Vector3(road_size.x,0.22,3.2),pos+Vector3(0,0.09,-16.6),sidewalk_mat)
		_make_visual_box(Vector3(road_size.x,0.22,3.2),pos+Vector3(0,0.09,16.6),sidewalk_mat)

	var white := _emissive_material(Color("b9eaff"),1.25)
	var cyan := _emissive_material(Color("19d7ff"),2.0)
	var pink := _emissive_material(Color("ff2bd6"),1.8)
	for lane in [-7.3,7.3]:
		for p in range(-240,241,18):
			if vertical:
				_make_visual_box(Vector3(0.18,0.025,8.0),Vector3(pos.x+lane,0.092,float(p)),white)
			else:
				_make_visual_box(Vector3(8.0,0.025,0.18),Vector3(float(p),0.092,pos.z+lane),white)
	if vertical:
		_make_visual_box(Vector3(0.12,0.028,road_size.z-8.0),pos+Vector3(-14.0,0.094,0),cyan)
		_make_visual_box(Vector3(0.12,0.028,road_size.z-8.0),pos+Vector3(14.0,0.094,0),pink)
	else:
		_make_visual_box(Vector3(road_size.x-8.0,0.028,0.12),pos+Vector3(0,0.094,-14.0),pink)
		_make_visual_box(Vector3(road_size.x-8.0,0.028,0.12),pos+Vector3(0,0.094,14.0),cyan)

func _build_crosswalk(pos: Vector3) -> void:
	var mat := _material(Color("8aa1b6"),0.0,0.0,0.8)
	for i in range(-5,6):
		_make_visual_box(Vector3(1.4,0.025,10.0),pos+Vector3(float(i)*2.25,0,0),mat)

func _build_city() -> void:
	var built := 0
	for gx in range(-7,8):
		for gz in range(-7,8):
			var wx := float(gx)*32.0
			var wz := float(gz)*32.0
			if _near_road(wx) or _near_road(wz):
				continue
			var seed_value: int = absi(gx*92821 + gz*68917 + gx*gz*113)
			var height := 12.0 + float(seed_value % 46)
			var width := 18.0 + float(seed_value % 6)
			var depth := 18.0 + float(int(seed_value / 3) % 6)
			var hue := fmod(float(seed_value%100)/100.0 + 0.52,1.0)
			var base_color := Color.from_hsv(hue,0.42,0.24)
			_build_building(Vector3(wx,height*0.5,wz),Vector3(width,height,depth),base_color,seed_value)
			built += 1
			if built % 8 == 0:
				await get_tree().process_frame

func _near_road(value: float) -> bool:
	for road in ROAD_COORDS:
		if absf(value-road) < 25.0:
			return true
	return false

func _build_building(pos: Vector3, building_size: Vector3, color: Color, seed_value: int) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = building_size
	col.shape = shape
	body.add_child(col)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = building_size
	mesh_instance.mesh = mesh
	var mat := _material(color,0.18,0.28,0.32)
	mat.emission = Color(color.r*0.32,color.g*0.32,color.b*0.42)
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.55
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)
	add_child(body)

	var accent := Color("19d7ff") if seed_value%2==0 else Color("ff2bd6")
	var band_mat := _emissive_material(accent,2.4)
	for ratio in [0.32,0.68]:
		var y: float = pos.y - building_size.y * 0.5 + building_size.y * float(ratio)
		_make_visual_box(Vector3(building_size.x+0.05,0.18,0.08),Vector3(pos.x,y,pos.z-building_size.z*0.5-0.05),band_mat)
		_make_visual_box(Vector3(0.08,0.18,building_size.z+0.05),Vector3(pos.x+building_size.x*0.5+0.05,y,pos.z),band_mat)
	if seed_value%4==0:
		var roof_mat := _emissive_material(Color("43f6a6"),2.2)
		_make_visual_box(Vector3(0.12,4.0,0.12),Vector3(pos.x,pos.y+building_size.y*0.5+2.0,pos.z),roof_mat)

func _build_street_details() -> void:
	var pole_mat := _material(Color("202938"),0.0,0.62,0.4)
	var lamp_mat := _emissive_material(Color("8cecff"),3.5)
	for road in ROAD_COORDS:
		for p in range(-220,221,44):
			for side in [-1.0,1.0]:
				_make_visual_box(Vector3(0.15,4.8,0.15),Vector3(road+side*18.1,2.4,float(p)),pole_mat)
				_make_visual_box(Vector3(0.9,0.16,0.28),Vector3(road+side*17.65,4.76,float(p)),lamp_mat)
				_make_visual_box(Vector3(0.15,4.8,0.15),Vector3(float(p),2.4,road+side*18.1),pole_mat)
				_make_visual_box(Vector3(0.28,0.16,0.9),Vector3(float(p),4.76,road+side*17.65),lamp_mat)
		await get_tree().process_frame

	var signs: Array[Dictionary] = [
		{"text":"NEON APEX", "pos":Vector3(45,12,-88), "rot":0.0, "color":Color("19d7ff")},
		{"text":"BOOST DISTRICT", "pos":Vector3(88,10,43), "rot":90.0, "color":Color("ff2bd6")},
		{"text":"OPEN ROADS", "pos":Vector3(-82,14,78), "rot":90.0, "color":Color("43f6a6")},
		{"text":"MIDNIGHT GRID", "pos":Vector3(-42,11,-86), "rot":0.0, "color":Color("a855f7")}
	]
	for data in signs:
		var label := Label3D.new()
		label.text = String(data["text"])
		label.position = Vector3(data["pos"])
		label.rotation_degrees.y = float(data["rot"])
		label.font_size = 64
		label.pixel_size = 0.025
		label.modulate = Color(data["color"])
		label.outline_size = 10
		label.outline_modulate = Color(0.01,0.02,0.06,0.9)
		add_child(label)

	for x in ROAD_COORDS:
		for z in ROAD_COORDS:
			var light := OmniLight3D.new()
			light.position = Vector3(x,7,z)
			light.light_color = Color("19d7ff") if int(x+z)%240==0 else Color("ff2bd6")
			light.light_energy = 0.65
			light.omni_range = 18.0
			light.shadow_enabled = false
			add_child(light)

func _build_route() -> void:
	var route_data: Array[Dictionary] = [
		{"p":Vector3(0,1,48),"h":false},
		{"p":Vector3(0,1,-92),"h":false},
		{"p":Vector3(92,1,-120),"h":true},
		{"p":Vector3(120,1,-22),"h":false},
		{"p":Vector3(120,1,92),"h":false},
		{"p":Vector3(22,1,120),"h":true},
		{"p":Vector3(-92,1,120),"h":true},
		{"p":Vector3(-120,1,22),"h":false},
		{"p":Vector3(-82,1,0),"h":true},
		{"p":Vector3(-18,1,0),"h":true}
	]
	for i in range(route_data.size()):
		var data: Dictionary = route_data[i]
		var area := Area3D.new()
		area.position = Vector3(data["p"])
		area.set_meta("index",i)
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(5,5,24) if bool(data["h"]) else Vector3(24,5,5)
		col.shape = box
		area.add_child(col)
		_build_checkpoint_gate(area,bool(data["h"]),i)
		area.body_entered.connect(_checkpoint_entered.bind(area))
		add_child(area)
		checkpoints.append(area)

func _build_checkpoint_gate(area: Area3D, horizontal: bool, index: int) -> void:
	var color := Color("43f6a6") if index==0 else (Color("ff2bd6") if index % 2 == 1 else Color("19d7ff"))
	var mat := _emissive_material(color,3.2)
	if horizontal:
		_make_child_box(area,Vector3(0.28,5.8,0.28),Vector3(0,2.9,-10.0),mat)
		_make_child_box(area,Vector3(0.28,5.8,0.28),Vector3(0,2.9,10.0),mat)
		_make_child_box(area,Vector3(0.28,0.28,20.0),Vector3(0,5.7,0),mat)
	else:
		_make_child_box(area,Vector3(0.28,5.8,0.28),Vector3(-10.0,2.9,0),mat)
		_make_child_box(area,Vector3(0.28,5.8,0.28),Vector3(10.0,2.9,0),mat)
		_make_child_box(area,Vector3(20.0,0.28,0.28),Vector3(0,5.7,0),mat)
	var label := Label3D.new()
	label.text = "START" if index==0 else "CP %02d" % index
	label.position = Vector3(0,6.45,0)
	label.font_size = 52
	label.pixel_size = 0.02
	label.modulate = color
	area.add_child(label)

func _checkpoint_entered(body: Node, area: Area3D) -> void:
	if body != car or int(area.get_meta("index")) != checkpoint_index:
		return
	if checkpoint_index == 0:
		race_started = true
		race_time = 0.0
		if hud_overlay != null:
			hud_overlay.flash("RACE START // GO!",1.4)
	checkpoint_index += 1
	area.visible = false
	area.monitoring = false
	if checkpoint_index >= checkpoints.size():
		race_started = false
		if best_time <= 0.0 or race_time < best_time:
			best_time = race_time
		if hud_overlay != null:
			hud_overlay.flash("FINISH // %.2f SEC" % race_time,4.0)
		await get_tree().create_timer(5.0).timeout
		checkpoint_index = 0
		for cp in checkpoints:
			cp.visible = true
			cp.monitoring = true

func _build_pickups() -> void:
	var positions: Array[Vector3] = [Vector3(7,1.0,-58),Vector3(112,1.0,-72),Vector3(112,1.0,60),Vector3(62,1.0,112),Vector3(-62,1.0,112),Vector3(-112,1.0,62),Vector3(-72,1.0,-8),Vector3(58,1.0,8)]
	for pos in positions:
		var area := Area3D.new()
		area.position = pos
		var col := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 1.25
		col.shape = sphere
		area.add_child(col)
		var orb := MeshInstance3D.new()
		var orb_mesh := SphereMesh.new()
		orb_mesh.radius = 0.58
		orb_mesh.height = 1.16
		orb.mesh = orb_mesh
		orb.material_override = _emissive_material(Color("a855f7"),5.0)
		area.add_child(orb)
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.85
		torus.outer_radius = 1.0
		ring.mesh = torus
		ring.rotation_degrees.x = 90
		ring.material_override = _emissive_material(Color("19d7ff"),3.5)
		area.add_child(ring)
		area.body_entered.connect(_pickup_entered.bind(area))
		add_child(area)

func _pickup_entered(body: Node, area: Area3D) -> void:
	if body != car or not area.monitoring:
		return
	car.add_nitro(34.0)
	pickup_count += 1
	if hud_overlay != null:
		hud_overlay.set_pickups(pickup_count)
		hud_overlay.flash("NITRO CORE +34",1.5)
	area.visible = false
	area.monitoring = false
	await get_tree().create_timer(9.0).timeout
	if is_instance_valid(area):
		area.visible = true
		area.monitoring = true

func _spawn_player() -> void:
	car = ArcadeCar.new()
	car.name = "PlayerCar"
	car.position = Vector3(0,1.2,86)
	add_child(car)
	car.telemetry.connect(_on_telemetry)

func _spawn_traffic() -> void:
	var loop_outer: Array[Vector3] = [Vector3(-120,1.0,-120),Vector3(-120,1.0,120),Vector3(120,1.0,120),Vector3(120,1.0,-120)]
	var loop_center: Array[Vector3] = [Vector3(0,1.0,-120),Vector3(0,1.0,0),Vector3(120,1.0,0),Vector3(120,1.0,-120)]
	var loop_west: Array[Vector3] = [Vector3(-120,1.0,0),Vector3(0,1.0,0),Vector3(0,1.0,120),Vector3(-120,1.0,120)]
	var colors: Array[Color] = [Color("ff365e"),Color("ffd166"),Color("43f6a6"),Color("a855f7"),Color("ff2bd6"),Color("19d7ff")]
	for i in range(9):
		var route: Array[Vector3]
		match i % 3:
			0: route = loop_outer
			1: route = loop_center
			_: route = loop_west
		var traffic := TrafficCar.new()
		traffic.setup(route,i%route.size(),14.0+float(i%4)*2.3,colors[i%colors.size()])
		traffic.position = route[i%route.size()] + Vector3(3.5 if i%2==0 else -3.5,0,3.5 if i%3==0 else -3.5)
		add_child(traffic)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0,2.35,0.85)
	camera_pivot.rotation_degrees.x = -9.0
	car.add_child(camera_pivot)

	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = 9.2
	spring_arm.margin = 0.22
	spring_arm.collision_mask = 1
	camera_pivot.add_child(spring_arm)
	# Evita que la cámara choque contra el propio auto y termine dentro de la carrocería.
	spring_arm.add_excluded_object(car.get_rid())

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 70.0
	camera.near = 0.08
	# Posición inicial segura hasta que SpringArm procese su primer frame físico.
	camera.position = Vector3(0,0,spring_arm.spring_length)
	spring_arm.add_child(camera)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 20
	add_child(hud)
	var viewport_size := get_viewport().get_visible_rect().size

	hud_overlay = ProHUD.new()
	hud_overlay.position = Vector2.ZERO
	hud_overlay.size = viewport_size
	hud.add_child(hud_overlay)
	hud_overlay.set_pickups(pickup_count)

	mobile_controls = MobileControls.new()
	mobile_controls.position = Vector2.ZERO
	mobile_controls.size = viewport_size
	mobile_controls.z_index = 50
	mobile_controls.visible = mobile or DisplayServer.is_touchscreen_available()
	mobile_controls.controls_changed.connect(_on_mobile_controls)
	hud.add_child(mobile_controls)

func _set_loading_message(text: String) -> void:
	if hud_overlay != null:
		hud_overlay.flash(text, 999.0)

func _on_mobile_controls(throttle: float, brake: float, steer: float, handbrake: bool, nitro: bool) -> void:
	if car != null:
		car.set_mobile_input(throttle,brake,steer,handbrake,nitro)

func _on_telemetry(kph: float, nitro_value: float, drifting: bool) -> void:
	if hud_overlay != null:
		hud_overlay.set_telemetry(kph,nitro_value,drifting)

func _material(color: Color, emission_energy := 0.0, metallic := 0.0, roughness := 0.8) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	return mat

func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	return _material(color,energy,0.2,0.28)

func _make_visual_box(box_size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = material
	add_child(mi)
	return mi

func _make_child_box(parent: Node3D, box_size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = material
	parent.add_child(mi)
	return mi
