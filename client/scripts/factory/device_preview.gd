extends SubViewportContainer

## A cached, isolated view of the existing asset; redraw only on device change/resize.
var viewport := SubViewport.new()
var scene := Node3D.new()
var camera := Camera3D.new()
var asset: Node3D
var shown_key := ""


func _ready() -> void:
	custom_minimum_size = Vector2(170, 150)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.gui_disable_input = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	viewport.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0, 0, 0, 0)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("bedcd0")
	environment.environment.ambient_light_energy = 0.65
	scene.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -35, 0)
	light.light_energy = 1.5
	scene.add_child(light)
	scene.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	resized.connect(func(): viewport.render_target_update_mode = SubViewport.UPDATE_ONCE)


func show_device(kind: String, direction := 0) -> void:
	var key := kind + str(direction)
	if key == shown_key:
		return
	shown_key = key
	if is_instance_valid(asset):
		scene.remove_child(asset)
		asset.queue_free()
	var path := "res://assets/factory/" + kind + ".glb"
	if kind in ["power_source", "power_junction"]:
		path = "res://assets/factory/power/" + kind.replace("_", "-") + ".glb"
	elif kind == "belt":
		path = "res://assets/factory/belt-2.glb"
	var packed := load(path) as PackedScene
	assert(packed != null, "Missing device preview: " + path)
	asset = packed.instantiate()
	scene.add_child(asset)
	if kind == "belt":
		asset.rotation.y = -direction * PI / 2
	var bounds := AABB()
	var first := true
	for part in asset.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = part.global_transform * part.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var center := bounds.get_center()
	camera.position = center + Vector3(6, 5, 7)
	camera.look_at(center)
	camera.size = maxf(bounds.size.length() * 1.12, 1.5)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
