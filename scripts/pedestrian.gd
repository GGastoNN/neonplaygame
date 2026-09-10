extends Node3D

var route: Array[Vector3] = []
var route_index := 0
var walk_speed := 2.4
var body_color := Color("ffd166")
var clothing_color := Color("19d7ff")
var visual_root: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var walk_phase := 0.0

func setup(points: Array[Vector3], start_index: int, speed_value: float, skin_color: Color, cloth_color: Color) -> void:
	route = points
	route_index = posmod(start_index, max(1, route.size()))
	walk_speed = speed_value
	body_color = skin_color
	clothing_color = cloth_color

func _ready() -> void:
	_build_visual()

func _process(delta: float) -> void:
	if route.size() < 2:
		return
	var target: Vector3 = route[route_index]
	var to_target := target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.8:
		route_index = (route_index + 1) % route.size()
		target = route[route_index]
		to_target = target - global_position
		to_target.y = 0.0
	if to_target.length() > 0.05:
		var dir := to_target.normalized()
		global_position += dir * walk_speed * delta
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, delta * 4.5))
	walk_phase += delta * walk_speed * 5.5
	_animate_walk()

func _build_visual() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)

	var skin := StandardMaterial3D.new()
	skin.albedo_color = body_color
	skin.roughness = 0.78
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = clothing_color
	cloth.roughness = 0.72
	cloth.metallic = 0.08
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color("111318")
	dark.roughness = 0.92

	_make_box(Vector3(0.48, 0.64, 0.24), Vector3(0, 1.38, 0), cloth)
	_make_box(Vector3(0.42, 0.42, 0.3), Vector3(0, 1.92, 0.02), skin)
	_make_box(Vector3(0.54, 0.12, 0.2), Vector3(0, 2.16, 0.02), dark)
	left_arm = _make_box(Vector3(0.12, 0.58, 0.12), Vector3(-0.34, 1.42, 0), skin)
	right_arm = _make_box(Vector3(0.12, 0.58, 0.12), Vector3(0.34, 1.42, 0), skin)
	left_leg = _make_box(Vector3(0.14, 0.7, 0.14), Vector3(-0.12, 0.68, 0), dark)
	right_leg = _make_box(Vector3(0.14, 0.7, 0.14), Vector3(0.12, 0.68, 0), dark)

func _animate_walk() -> void:
	if left_arm != null:
		left_arm.rotation.x = sin(walk_phase) * 0.55
	if right_arm != null:
		right_arm.rotation.x = sin(walk_phase + PI) * 0.55
	if left_leg != null:
		left_leg.rotation.x = sin(walk_phase + PI) * 0.45
	if right_leg != null:
		right_leg.rotation.x = sin(walk_phase) * 0.45
	if visual_root != null:
		visual_root.position.y = sin(walk_phase * 2.0) * 0.025

func _make_box(box_size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = material
	visual_root.add_child(mi)
	return mi
