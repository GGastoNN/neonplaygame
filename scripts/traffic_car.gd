extends CharacterBody3D

var route: Array[Vector3] = []
var route_index := 0
var drive_speed := 18.0
var body_color := Color("ff365e")
var lane_bias := 0.0
var cruise_phase := 0.0
var visual_root: Node3D
var wheel_nodes: Array[Node3D] = []

func setup(points: Array, start_index: int, speed_value: float, color_value: Color) -> void:
	# Las rutas se crean como arreglos literales en main.gd. Godot los trata como
	# Array sin tipo y no permite asignarlos directamente a Array[Vector3].
	route.clear()
	for point in points:
		route.append(Vector3(point))
	route_index = posmod(start_index, max(1, route.size()))
	drive_speed = speed_value
	body_color = color_value
	lane_bias = randf_range(0.0, TAU)

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_build_visual()

func _physics_process(delta: float) -> void:
	if route.size() < 2:
		return
	cruise_phase += delta
	var target := route[route_index]
	var flat_delta := target - global_position
	flat_delta.y = 0.0
	if flat_delta.length() < 4.0:
		route_index = (route_index + 1) % route.size()
		target = route[route_index]
		flat_delta = target - global_position
		flat_delta.y = 0.0
	if flat_delta.length() > 0.1:
		var dir := flat_delta.normalized()
		var target_yaw := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, delta*3.4))
		var speed_scale := 0.92 + sin(cruise_phase * 0.7 + lane_bias) * 0.06
		velocity.x = dir.x * drive_speed * speed_scale
		velocity.z = dir.z * drive_speed * speed_scale
	if not is_on_floor():
		velocity.y -= 18.0*delta
	else:
		velocity.y = -0.4
	move_and_slide()
	for wheel in wheel_nodes:
		wheel.rotate_x(drive_speed*delta*0.8)

func _build_visual() -> void:
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8,0.8,3.8)
	collider.shape = box
	collider.position.y = 0.55
	add_child(collider)
	visual_root = Node3D.new()
	add_child(visual_root)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = body_color
	paint.metallic = 0.65
	paint.roughness = 0.24
	_make_box(Vector3(1.75,0.55,3.75),Vector3(0,0.62,0),paint)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color("07152d")
	glass.metallic = 0.45
	glass.roughness = 0.1
	_make_box(Vector3(1.45,0.48,1.55),Vector3(0,1.05,0.05),glass)
	var light_mat := StandardMaterial3D.new()
	light_mat.albedo_color = Color("fff1b3")
	light_mat.emission_enabled = true
	light_mat.emission = Color("fff1b3")
	light_mat.emission_energy_multiplier = 2.5
	for x in [-0.56,0.56]:
		_make_box(Vector3(0.35,0.16,0.08),Vector3(x,0.66,-1.9),light_mat)
	var tire := StandardMaterial3D.new()
	tire.albedo_color = Color("08090d")
	tire.roughness = 0.9
	for x in [-0.96,0.96]:
		for z in [-1.22,1.22]:
			var wheel := MeshInstance3D.new()
			var wm := CylinderMesh.new()
			wm.top_radius = 0.34
			wm.bottom_radius = 0.34
			wm.height = 0.24
			wheel.mesh = wm
			wheel.material_override = tire
			wheel.rotation_degrees.z = 90
			wheel.position = Vector3(x,0.38,z)
			visual_root.add_child(wheel)
			wheel_nodes.append(wheel)

func _make_box(box_size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = material
	visual_root.add_child(mi)
	return mi
