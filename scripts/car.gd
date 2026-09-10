extends CharacterBody3D

signal telemetry(speed_kph: float, nitro: float, drifting: bool)
signal collision_event(intensity: float)

@export var max_speed := 58.0
@export var reverse_speed := 14.0
@export var acceleration := 31.0
@export var brake_power := 46.0
@export var steering_speed := 2.25
@export var steering_response := 5.2
@export var grip := 8.5

var speed := 0.0
var nitro_amount := 100.0
var steer_input := 0.0
var throttle_input := 0.0
var brake_input := 0.0
var handbrake_input := false
var nitro_input := false
var current_steer := 0.0
var last_safe_transform: Transform3D
var visual_root: Node3D
var front_wheel_pivots: Array[Node3D] = []
var wheel_meshes: Array[Node3D] = []
var nitro_flames: Array[MeshInstance3D] = []
var brake_material: StandardMaterial3D
var underglow_material: StandardMaterial3D
var last_speed := 0.0
var nitro_capacity := 100.0
var base_max_speed := 58.0
var base_acceleration := 31.0
var base_steering_response := 5.2
var base_steering_speed := 2.25
var base_grip := 8.5

func _ready() -> void:
	collision_layer = 1
	collision_mask = 3
	floor_snap_length = 0.6
	last_safe_transform = global_transform
	_build_car()

func set_mobile_input(throttle: float, brake: float, steer: float, handbrake: bool, nitro: bool) -> void:
	throttle_input = clampf(throttle,0.0,1.0)
	brake_input = clampf(brake,0.0,1.0)
	steer_input = clampf(steer,-1.0,1.0)
	handbrake_input = handbrake
	nitro_input = nitro

func add_nitro(amount: float) -> void:
	nitro_amount = clampf(nitro_amount + amount, 0.0, nitro_capacity)

func apply_purchased_upgrades(owned: Dictionary) -> void:
	max_speed = base_max_speed * (1.18 if bool(owned.get("neon_engine_stage1", false)) else 1.0)
	acceleration = base_acceleration * (1.16 if bool(owned.get("neon_engine_stage1", false)) else 1.0)
	steering_response = base_steering_response * (1.22 if bool(owned.get("neon_steering_pro", false)) else 1.0)
	steering_speed = base_steering_speed
	grip = base_grip * (1.15 if bool(owned.get("neon_steering_pro", false)) else 1.0)
	if bool(owned.get("neon_aero_kit", false)):
		grip *= 1.10
		steering_speed = base_steering_speed * 1.06
	nitro_capacity = 140.0 if bool(owned.get("neon_nitro_tank", false)) else 100.0
	nitro_amount = minf(nitro_amount, nitro_capacity)
	if underglow_material != null and bool(owned.get("neon_lighting_pack", false)):
		underglow_material.albedo_color = Color("a855f7")
		underglow_material.emission = Color("a855f7")

func _physics_process(delta: float) -> void:
	var throttle := maxf(throttle_input, Input.get_action_strength("accelerate"))
	var brake := maxf(brake_input, Input.get_action_strength("brake"))
	var keyboard_steer := Input.get_axis("steer_left", "steer_right")
	var steer_target := clampf(steer_input + keyboard_steer, -1.0, 1.0)
	current_steer = move_toward(current_steer, steer_target, steering_response * delta)

	var drifting := handbrake_input or Input.is_action_pressed("handbrake")
	var using_nitro := (nitro_input or Input.is_action_pressed("nitro")) and nitro_amount > 0.0 and speed > 8.0 and throttle > 0.0
	var target_max := max_speed + (24.0 if using_nitro else 0.0)

	if using_nitro:
		nitro_amount = maxf(0.0, nitro_amount - 25.0 * delta)
	else:
		nitro_amount = minf(nitro_capacity, nitro_amount + (7.2 if nitro_capacity > 100.0 else 5.5) * delta)

	if throttle > 0.0:
		var accel_scale := lerpf(1.0, 0.48, clampf(maxf(speed,0.0) / maxf(target_max,1.0), 0.0, 1.0))
		speed = move_toward(speed, target_max, acceleration * accel_scale * throttle * delta)
	elif brake > 0.0:
		if speed > 1.0:
			speed = move_toward(speed, 0.0, brake_power * brake * delta)
		else:
			speed = move_toward(speed, -reverse_speed, acceleration * 0.55 * brake * delta)
	else:
		speed = move_toward(speed, 0.0, 6.5 * delta)

	var speed_ratio := clampf(absf(speed) / max_speed, 0.0, 1.35)
	var low_speed_help := lerpf(0.55, 1.0, clampf(absf(speed) / 12.0, 0.0, 1.0))
	var high_speed_limit := lerpf(1.0, 0.58, clampf((speed_ratio - 0.65) / 0.7, 0.0, 1.0))
	var steering_amount := steering_speed * low_speed_help * high_speed_limit
	if drifting:
		steering_amount *= 1.28
	var travel_sign := signf(speed) if absf(speed) > 0.2 else 1.0
	rotate_y(-current_steer * steering_amount * delta * travel_sign)

	var forward := -global_transform.basis.z
	var desired := forward * speed
	var current_grip := 2.2 if drifting else grip
	velocity.x = lerpf(velocity.x, desired.x, minf(1.0, current_grip * delta))
	velocity.z = lerpf(velocity.z, desired.z, minf(1.0, current_grip * delta))

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = -0.55
	move_and_slide()

	if get_slide_collision_count() > 0 and absf(speed) > 12.0:
		speed *= 0.965
		collision_event.emit(absf(speed))

	if is_on_floor() and global_position.y > -1.0 and absf(rotation.x) < 0.6 and absf(rotation.z) < 0.6:
		last_safe_transform = global_transform
	if Input.is_action_just_pressed("reset_car") or global_position.y < -12.0:
		global_transform = last_safe_transform.translated(Vector3.UP * 1.6)
		velocity = Vector3.ZERO
		speed = 0.0

	_update_visuals(delta, throttle, brake, drifting, using_nitro, speed_ratio)
	last_speed = speed
	telemetry.emit(absf(speed) * 3.6, nitro_amount, drifting and absf(speed) > 8.0)

func _update_visuals(delta: float, throttle: float, brake: float, drifting: bool, using_nitro: bool, speed_ratio: float) -> void:
	if visual_root == null:
		return
	var accel_delta := clampf((speed - last_speed) / maxf(delta,0.001), -30.0, 30.0) / 30.0
	var target_roll := -current_steer * clampf(speed_ratio,0.0,1.0) * (0.12 if drifting else 0.075)
	var target_pitch := accel_delta * 0.035
	visual_root.rotation.z = lerpf(visual_root.rotation.z, target_roll, minf(1.0,delta*7.0))
	visual_root.rotation.x = lerpf(visual_root.rotation.x, target_pitch, minf(1.0,delta*6.0))

	for pivot in front_wheel_pivots:
		pivot.rotation.y = lerpf(pivot.rotation.y, -current_steer*0.42, minf(1.0,delta*9.0))
	for wheel in wheel_meshes:
		wheel.rotate_x(speed * delta * 0.78)
	for flame in nitro_flames:
		flame.visible = using_nitro
		if using_nitro:
			flame.scale.z = 0.8 + sin(Time.get_ticks_msec()*0.035)*0.16
	if brake_material != null:
		brake_material.emission_energy_multiplier = 6.0 if brake > 0.05 and speed > 0.0 else 2.4
	if underglow_material != null:
		underglow_material.emission_energy_multiplier = 4.2 if using_nitro else (3.4 if drifting else 2.3)

func _build_car() -> void:
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.9, 0.82, 4.25)
	collider.shape = box
	collider.position.y = 0.66
	add_child(collider)

	visual_root = Node3D.new()
	visual_root.name = "Visual"
	add_child(visual_root)

	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color("12c8ff")
	paint.metallic = 0.82
	paint.roughness = 0.16

	var dark_paint := StandardMaterial3D.new()
	dark_paint.albedo_color = Color("091224")
	dark_paint.metallic = 0.68
	dark_paint.roughness = 0.2

	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color("06122c")
	glass.metallic = 0.55
	glass.roughness = 0.08

	var chrome := StandardMaterial3D.new()
	chrome.albedo_color = Color("7be7ff")
	chrome.metallic = 0.92
	chrome.roughness = 0.12

	_make_box(Vector3(1.84,0.52,4.05),Vector3(0,0.66,0),paint)
	_make_box(Vector3(1.68,0.22,2.65),Vector3(0,0.98,-0.22),paint)
	_make_box(Vector3(1.48,0.52,1.72),Vector3(0,1.28,0.12),glass)
	_make_box(Vector3(1.56,0.14,0.62),Vector3(0,1.48,0.96),dark_paint)
	_make_box(Vector3(1.62,0.12,0.48),Vector3(0,0.45,-1.94),dark_paint)
	_make_box(Vector3(1.72,0.13,0.38),Vector3(0,0.51,1.93),dark_paint)

	# Front splitter and side skirts.
	_make_box(Vector3(2.05,0.08,0.52),Vector3(0,0.38,-2.12),dark_paint)
	_make_box(Vector3(0.10,0.12,2.65),Vector3(-0.98,0.38,0.08),chrome)
	_make_box(Vector3(0.10,0.12,2.65),Vector3(0.98,0.38,0.08),chrome)

	# Rear wing.
	_make_box(Vector3(1.92,0.09,0.36),Vector3(0,1.25,1.82),dark_paint)
	_make_box(Vector3(0.09,0.42,0.09),Vector3(-0.72,1.05,1.72),dark_paint)
	_make_box(Vector3(0.09,0.42,0.09),Vector3(0.72,1.05,1.72),dark_paint)

	var headlight := StandardMaterial3D.new()
	headlight.albedo_color = Color("d8fbff")
	headlight.emission_enabled = true
	headlight.emission = Color("b8f5ff")
	headlight.emission_energy_multiplier = 4.0
	for x in [-0.58,0.58]:
		_make_box(Vector3(0.42,0.16,0.07),Vector3(x,0.72,-2.05),headlight)
		var spot := SpotLight3D.new()
		spot.position = Vector3(x,0.78,-2.05)
		spot.light_color = Color("b8f5ff")
		spot.light_energy = 2.0
		spot.spot_range = 26.0
		spot.spot_angle = 32.0
		spot.shadow_enabled = false
		visual_root.add_child(spot)

	brake_material = StandardMaterial3D.new()
	brake_material.albedo_color = Color("ff244f")
	brake_material.emission_enabled = true
	brake_material.emission = Color("ff123e")
	brake_material.emission_energy_multiplier = 2.4
	for x in [-0.62,0.62]:
		_make_box(Vector3(0.44,0.16,0.07),Vector3(x,0.72,2.04),brake_material)

	underglow_material = StandardMaterial3D.new()
	underglow_material.albedo_color = Color("19d7ff")
	underglow_material.emission_enabled = true
	underglow_material.emission = Color("19d7ff")
	underglow_material.emission_energy_multiplier = 2.3
	var under := _make_box(Vector3(1.65,0.035,3.35),Vector3(0,0.25,0.08),underglow_material)
	under.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var tire := StandardMaterial3D.new()
	tire.albedo_color = Color("050609")
	tire.roughness = 0.93
	var rim := StandardMaterial3D.new()
	rim.albedo_color = Color("62e8ff")
	rim.metallic = 0.9
	rim.roughness = 0.12
	for x in [-0.99,0.99]:
		for z in [-1.38,1.38]:
			var holder := Node3D.new()
			holder.position = Vector3(x,0.42,z)
			visual_root.add_child(holder)
			if z < 0.0:
				front_wheel_pivots.append(holder)
			var wheel := MeshInstance3D.new()
			var wm := CylinderMesh.new()
			wm.top_radius = 0.39
			wm.bottom_radius = 0.39
			wm.height = 0.29
			wheel.mesh = wm
			wheel.rotation_degrees.z = 90
			wheel.material_override = tire
			holder.add_child(wheel)
			wheel_meshes.append(wheel)
			var rim_mesh := MeshInstance3D.new()
			var rm := CylinderMesh.new()
			rm.top_radius = 0.22
			rm.bottom_radius = 0.22
			rm.height = 0.305
			rim_mesh.mesh = rm
			rim_mesh.rotation_degrees.z = 90
			rim_mesh.material_override = rim
			holder.add_child(rim_mesh)
			wheel_meshes.append(rim_mesh)

	var flame_mat := StandardMaterial3D.new()
	flame_mat.albedo_color = Color("a855f7")
	flame_mat.emission_enabled = true
	flame_mat.emission = Color("6f35ff")
	flame_mat.emission_energy_multiplier = 6.0
	for x in [-0.42,0.42]:
		var flame := MeshInstance3D.new()
		var fm := CylinderMesh.new()
		fm.top_radius = 0.05
		fm.bottom_radius = 0.16
		fm.height = 0.85
		flame.mesh = fm
		flame.rotation_degrees.x = 90
		flame.position = Vector3(x,0.52,2.38)
		flame.material_override = flame_mat
		flame.visible = false
		visual_root.add_child(flame)
		nitro_flames.append(flame)

func _make_box(box_size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = material
	visual_root.add_child(mi)
	return mi
