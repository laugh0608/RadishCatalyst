extends Node3D

## Imported review geometry only. Anchors never hold logistics or game state.
const MODEL_PATH := "res://assets/prototypes/base_core_outline/core-outline.glb"
const MANIFEST_PATH := "res://assets/prototypes/base_core_outline/source-manifest.json"
var prepared := false
var resource_error := ""
var tier := 1
var names_visible := false
var asset: Node3D
var variants: Array[Node3D] = []
var parts: Array[MeshInstance3D] = []
var faces := {}
var ports: Array[Dictionary] = []
var labels: Array[Label3D] = []


func _ready() -> void:
	var resource = load(MODEL_PATH)
	if not resource is PackedScene:
		fail("R1-B 缺少已导入的核心轮廓 GLB")
		return
	asset = resource.instantiate()
	add_child(asset)
	var modules := asset.find_child("TierModules", true, false)
	var anchors := asset.find_child("Ports", true, false)
	if modules == null or anchors == null or modules.get_child_count() != 2 or anchors.get_child_count() != 16:
		fail("核心节点 / 端口数量不符合轮廓合同")
		return
	for id in ["I", "II"]:
		var variant := modules.get_node_or_null(id) as Node3D
		if variant == null:
			fail("核心缺少结构等级：" + id)
			return
		variants.append(variant)
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not manifest is Dictionary or not manifest.get("ports") is Array or manifest.ports.size() != anchors.get_child_count():
		fail("核心来源清单不可读")
		return
	for port in manifest.ports:
		var anchor := anchors.get_node_or_null("Port_" + port.id) as Node3D
		var expected := Vector3(port.point[0], port.point[1], port.point[2])
		if anchor == null or not anchor.global_position.is_equal_approx(expected):
			fail("核心端口锚点不匹配：" + port.id)
			return
		ports.append({"id": port.id, "role": port.role, "anchor": anchor, "point": expected,
			"normal": Vector2(port.normal[0], port.normal[1]),
			"probe": Vector3(port.probe[0], port.probe[1], port.probe[2]), "samples": port.probe_samples})
		var label := Label3D.new()
		label.text = port.id
		label.font = preload("res://assets/fonts/NotoSansSC-wght.ttf")
		label.font_size = 20
		label.pixel_size = 0.012
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = false
		label.position = Vector3(port.probe[0], 0.64, port.probe[2])
		add_child(label)
		label.visible = false
		labels.append(label)
	for node in asset.find_children("*", "MeshInstance3D", true, false):
		parts.append(node)
		faces[node.mesh.get_instance_id()] = node.mesh.get_faces()
	set_tier(1)
	prepared = true


func fail(message: String) -> void:
	resource_error = message
	push_error(message)


func set_tier(value: int) -> void:
	assert(value in [1, 2])
	tier = value
	for i in variants.size(): variants[i].visible = value == i + 1


func toggle_names() -> void:
	names_visible = not names_visible
	for label in labels: label.visible = names_visible


func visual() -> Dictionary:
	var visible_parts: Array[MeshInstance3D] = []
	for part in parts:
		if part.is_visible_in_tree(): visible_parts.append(part)
	return {"root": asset, "focus_parts": visible_parts}


func ray_distance(meshes: Array, origin: Vector3, direction: Vector3) -> float:
	var distance := INF
	for part: MeshInstance3D in meshes:
		if not part.is_visible_in_tree(): continue
		var inverse := part.global_transform.affine_inverse()
		var local_origin: Vector3 = inverse * origin
		var local_direction: Vector3 = inverse.basis * direction
		if part.get_aabb().intersects_ray(local_origin, local_direction) == null: continue
		var key: int = part.mesh.get_instance_id()
		if not faces.has(key): faces[key] = part.mesh.get_faces()
		var triangles: PackedVector3Array = faces[key]
		for index in range(0, triangles.size(), 3):
			var at: Variant = Geometry3D.ray_intersects_triangle(local_origin, local_direction,
				triangles[index], triangles[index + 1], triangles[index + 2])
			if at != null: distance = minf(distance, origin.distance_to(part.global_transform * at))
	return distance


func blocks_point(camera: Camera3D, point: Vector3) -> bool:
	var origin := camera.project_ray_origin(camera.unproject_position(point))
	var direction := (point - origin).normalized()
	return ray_distance(parts, origin, direction) < origin.distance_to(point) - 0.035


func port_at(camera: Camera3D, screen: Vector2, radius: float) -> String:
	var result := ""
	var nearest := radius
	for port in ports:
		var distance := camera.unproject_position(port.probe).distance_to(screen)
		if distance < nearest and not blocks_point(camera, port.probe):
			result = port.id
			nearest = distance
	return result


func review(camera: Camera3D, actor: Dictionary) -> Dictionary:
	var port_results := {}
	for port in ports:
		var point: Vector3 = port.anchor.global_position
		var blocked_samples := 0
		for sample in port.samples:
			if blocks_point(camera, Vector3(sample[0], sample[1], sample[2])): blocked_samples += 1
		port_results[port.id] = {"anchor": [point.x, point.y, point.z], "role": port.role,
			"probe_blocked_by_core": blocked_samples > 0, "blocked_samples": blocked_samples, "sample_count": port.samples.size()}
	var actor_results := {}
	for probe in [["feet", 0.08], ["torso", 0.8], ["head", 1.5]]:
		actor_results[probe[0]] = blocks_point(camera, Vector3(actor.x, probe[1], actor.z))
	return {"model": MODEL_PATH, "tier": tier, "ports": port_results,
		"actor_probes_blocked_by_core": actor_results, "names_depth_tested": true,
		"probe_scope": "core geometry only; sampled points, not whole-body visible percentage",
		"gameplay_connected": false}
