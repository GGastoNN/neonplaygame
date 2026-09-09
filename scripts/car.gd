class_name ArcadeCar
extends CharacterBody3D

signal telemetry(speed_kph: float, nitro: float, drifting: bool)

@export var max_speed := 52.0
@export var reverse_speed := 14.0
@export var acceleration := 28.0
@export var brake_power := 42.0
@export var steering_speed := 2.1
@export var grip := 7.0
var speed := 0.0
var nitro_amount := 100.0
var steer_input := 0.0
var throttle_input := 0.0
var brake_input := 0.0
var handbrake_input := false
var nitro_input := false
var last_safe_transform: Transform3D

func _ready() -> void:
	last_safe_transform = global_transform
	_build_car()

func set_mobile_input(throttle: float, brake: float, steer: float, handbrake: bool, nitro: bool) -> void:
	throttle_input = throttle
	brake_input = brake
	steer_input = steer
	handbrake_input = handbrake
	nitro_input = nitro

func _physics_process(delta: float) -> void:
	var throttle := maxf(throttle_input, Input.get_action_strength("accelerate"))
	var brake := maxf(brake_input, Input.get_action_strength("brake"))
	var steer := clampf(steer_input + Input.get_axis("steer_left", "steer_right"), -1.0, 1.0)
	var drifting := handbrake_input or Input.is_action_pressed("handbrake")
	var using_nitro := (nitro_input or Input.is_action_pressed("nitro")) and nitro_amount > 0.0 and speed > 8.0
	var target_max := max_speed + (22.0 if using_nitro else 0.0)
	if using_nitro:
		nitro_amount = maxf(0.0, nitro_amount - 28.0 * delta)
	else:
		nitro_amount = minf(100.0, nitro_amount + 7.0 * delta)
	if throttle > 0.0:
		speed = move_toward(speed, target_max, acceleration * throttle * delta)
	elif brake > 0.0:
		if speed > 1.0:
			speed = move_toward(speed, 0.0, brake_power * brake * delta)
		else:
			speed = move_toward(speed, -reverse_speed, acceleration * 0.55 * brake * delta)
	else:
		speed = move_toward(speed, 0.0, 7.0 * delta)
	var steer_factor := clampf(absf(speed) / 8.0, 0.0, 1.0)
	rotate_y(-steer * steering_speed * steer_factor * delta * signf(speed))
	var forward := -global_transform.basis.z
	var desired := forward * speed
	var current_grip := 2.0 if drifting else grip
	velocity.x = lerpf(velocity.x, desired.x, current_grip * delta)
	velocity.z = lerpf(velocity.z, desired.z, current_grip * delta)
	if not is_on_floor(): velocity.y -= 18.0 * delta
	else: velocity.y = -0.5
	move_and_slide()
	if is_on_floor() and global_position.y > -1.0: last_safe_transform = global_transform
	if Input.is_action_just_pressed("reset_car") or global_position.y < -12.0:
		global_transform = last_safe_transform.translated(Vector3.UP * 1.5)
		velocity = Vector3.ZERO
		speed = 0.0
	telemetry.emit(absf(speed) * 3.6, nitro_amount, drifting and absf(speed) > 8.0)

func _build_car() -> void:
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = Vector3(1.9, 0.75, 4.2)
	collider.shape = box; collider.position.y = 0.65; add_child(collider)
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new(); mesh.size = Vector3(1.85, 0.65, 4.0)
	body.mesh = mesh; body.position.y = 0.7
	var paint := StandardMaterial3D.new(); paint.albedo_color = Color("19d7ff"); paint.metallic = 0.75; paint.roughness = 0.18
	body.material_override = paint; add_child(body)
	var cabin := MeshInstance3D.new(); var cabin_mesh := BoxMesh.new(); cabin_mesh.size = Vector3(1.55, 0.55, 1.75)
	cabin.mesh = cabin_mesh; cabin.position = Vector3(0, 1.25, 0.15)
	var glass := StandardMaterial3D.new(); glass.albedo_color = Color("07152d"); glass.metallic = 0.4; glass.roughness = 0.1
	cabin.material_override = glass; add_child(cabin)
	for x in [-1.0, 1.0]:
		for z in [-1.35, 1.35]:
			var wheel := MeshInstance3D.new(); var wm := CylinderMesh.new(); wm.top_radius=.38; wm.bottom_radius=.38; wm.height=.28
			wheel.mesh=wm; wheel.rotation_degrees.z=90; wheel.position=Vector3(x,.42,z); add_child(wheel)
