extends Node2D
class_name DemoBaseFirstScreenSceneLayer

const RESTORE_OUTPOST_QUEST_ID := "quest.restore_outpost"

const FOCUS_MIN_X := -390.0
const FOCUS_MAX_X := 180.0
const FOCUS_MIN_Y := -248.0
const FOCUS_MAX_Y := 208.0

const ROLE_FLOOR := "solid_floor"
const ROLE_BOUNDARY := "platform_boundary"
const ROLE_SHADOW := "grounding_shadow"
const ROLE_DEVICE := "solid_device_volume"
const ROLE_MATERIAL := "material_block"
const ROLE_CONTEXT := "right_crystal_edge_context"
const ROLE_SERVICE := "short_service_port"

const SCENE_SHAPES := {
	"base_first_screen_scene.independent_scene_layer": true,
	"base_first_screen_scene.solid_floor_mass": true,
	"base_first_screen_scene.platform_edge_boundaries": true,
	"base_first_screen_scene.player_spawn_service_pad": true,
	"base_first_screen_scene.outpost_core_volume": true,
	"base_first_screen_scene.reactor_volume": true,
	"base_first_screen_scene.storage_volume": true,
	"base_first_screen_scene.outfitting_volume": true,
	"base_first_screen_scene.grounding_shadows": true,
	"base_first_screen_scene.material_blocks": true,
	"base_first_screen_scene.short_service_ports": true,
	"base_first_screen_scene.right_crystal_edge_context": true,
	"base_first_screen_scene.old_rebuild_layer_deemphasized": true,
	"base_first_screen_scene.startup_stack_suppressed": true,
	"base_first_screen_scene.existing_interactions_preserved": true,
	"base_first_screen_scene.no_new_content_state": true,
	"base_first_screen_scene.far_core_station_excluded": true,
}

const DEVICE_VOLUME_IDS := [
	"base_first_screen_scene.part.outpost_core_hull",
	"base_first_screen_scene.part.basic_reactor_body",
	"base_first_screen_scene.part.storage_bank_body",
	"base_first_screen_scene.part.outfitting_rack_body",
]

const MATERIAL_BLOCK_IDS := [
	"base_first_screen_scene.part.floor_plate_west",
	"base_first_screen_scene.part.floor_plate_center",
	"base_first_screen_scene.part.floor_plate_east",
	"base_first_screen_scene.part.core_shell_block",
	"base_first_screen_scene.part.reactor_heat_chamber",
	"base_first_screen_scene.part.storage_cargo_block_a",
	"base_first_screen_scene.part.storage_cargo_block_b",
	"base_first_screen_scene.part.outfitting_suit_frame",
]

const SERVICE_PORT_IDS := [
	"base_first_screen_scene.part.core_repair_port",
	"base_first_screen_scene.part.reactor_feed_port",
	"base_first_screen_scene.part.storage_supply_port",
	"base_first_screen_scene.part.outfitting_lock_port",
]

const CONTEXT_LAYER_ALPHAS := [
	{"path": "OpeningSceneLayer", "alpha": 0.0},
	{"path": "DemoCoreSceneSpaceLayer", "alpha": 0.0},
	{"path": "DemoInitialArtIdentityLayer", "alpha": 0.0},
	{"path": "DemoIndustrialBaseVisualLayer", "alpha": 0.010},
	{"path": "DemoCrystalResourceVisualLayer", "alpha": 0.012},
	{"path": "DemoPollutionBoundaryVisualLayer", "alpha": 0.0},
	{"path": "DemoCoreStabilizationVisualLayer", "alpha": 0.0},
	{"path": "DemoSceneFocusDepthLayer", "alpha": 0.004},
	{"path": "PrototypeVisualPriorityLayer", "alpha": 0.002},
	{"path": "DemoRegionIndustrialValueLayer", "alpha": 0.0},
	{"path": "DemoRoutePresentationLayer", "alpha": 0.0},
	{"path": "DemoFirstIndustrialPathVisualLayer", "alpha": 0.0},
	{"path": "DemoBaseHandoffAssetArtPass", "alpha": 0.0},
	{"path": "DemoPlayableSceneRebuildLayer", "alpha": 0.0},
	{"path": "DemoBaseStartupPresentationLayer", "alpha": 0.0},
]

const CONTEXT_RECT_ALPHAS := [
	{"path": "RegionBase", "alpha": 0.0},
	{"path": "RegionCrystal", "alpha": 0.0},
	{"path": "RegionPollution", "alpha": 0.0},
	{"path": "MainRouteSpine", "alpha": 0.0},
	{"path": "BaseToCrystalRouteBand", "alpha": 0.0},
	{"path": "CrystalToPollutionRouteBand", "alpha": 0.0},
	{"path": "RegionBoundaryCrystal", "alpha": 0.0},
	{"path": "RegionBoundaryPollution", "alpha": 0.0},
	{"path": "RegionBoundaryRuin", "alpha": 0.0},
]

const POLYGON_PARTS := [
	{
		"id": "base_first_screen_scene.part.floor_mass",
		"role": ROLE_FLOOR,
		"z": 0,
		"color": Color(0.105, 0.142, 0.126, 1.0),
		"points": [
			Vector2(-386.0, -214.0),
			Vector2(78.0, -214.0),
			Vector2(158.0, -132.0),
			Vector2(158.0, 132.0),
			Vector2(70.0, 198.0),
			Vector2(-352.0, 198.0),
			Vector2(-402.0, 134.0),
			Vector2(-416.0, -148.0),
		],
	},
	{
		"id": "base_first_screen_scene.part.floor_inner_platform",
		"role": ROLE_FLOOR,
		"z": 1,
		"color": Color(0.152, 0.194, 0.172, 1.0),
		"points": [
			Vector2(-342.0, -168.0),
			Vector2(20.0, -168.0),
			Vector2(96.0, -98.0),
			Vector2(94.0, 104.0),
			Vector2(18.0, 154.0),
			Vector2(-316.0, 154.0),
			Vector2(-362.0, 94.0),
			Vector2(-360.0, -112.0),
		],
	},
	{
		"id": "base_first_screen_scene.part.crystal_edge_ground",
		"role": ROLE_CONTEXT,
		"z": 1,
		"color": Color(0.046, 0.118, 0.136, 0.92),
		"points": [
			Vector2(92.0, -188.0),
			Vector2(218.0, -164.0),
			Vector2(236.0, 148.0),
			Vector2(142.0, 184.0),
			Vector2(94.0, 112.0),
			Vector2(104.0, -104.0),
		],
	},
]

const RECT_PARTS := [
	{"id": "base_first_screen_scene.part.north_boundary", "role": ROLE_BOUNDARY, "z": 3, "rect": Rect2(Vector2(-374.0, -218.0), Vector2(468.0, 24.0)), "color": Color(0.052, 0.070, 0.064, 1.0)},
	{"id": "base_first_screen_scene.part.south_boundary", "role": ROLE_BOUNDARY, "z": 3, "rect": Rect2(Vector2(-356.0, 172.0), Vector2(430.0, 28.0)), "color": Color(0.046, 0.062, 0.056, 1.0)},
	{"id": "base_first_screen_scene.part.west_boundary", "role": ROLE_BOUNDARY, "z": 3, "rect": Rect2(Vector2(-410.0, -164.0), Vector2(28.0, 292.0)), "color": Color(0.044, 0.058, 0.052, 1.0)},
	{"id": "base_first_screen_scene.part.floor_plate_west", "role": ROLE_MATERIAL, "z": 4, "rect": Rect2(Vector2(-342.0, -136.0), Vector2(132.0, 96.0)), "color": Color(0.184, 0.224, 0.198, 0.94)},
	{"id": "base_first_screen_scene.part.floor_plate_center", "role": ROLE_MATERIAL, "z": 4, "rect": Rect2(Vector2(-196.0, -132.0), Vector2(132.0, 116.0)), "color": Color(0.170, 0.214, 0.190, 0.94)},
	{"id": "base_first_screen_scene.part.floor_plate_east", "role": ROLE_MATERIAL, "z": 4, "rect": Rect2(Vector2(-78.0, -96.0), Vector2(130.0, 134.0)), "color": Color(0.156, 0.198, 0.178, 0.92)},
	{"id": "base_first_screen_scene.part.player_service_pad", "role": ROLE_FLOOR, "z": 6, "rect": Rect2(Vector2(-246.0, -76.0), Vector2(74.0, 48.0)), "color": Color(0.102, 0.142, 0.136, 1.0)},
	{"id": "base_first_screen_scene.part.outpost_core_plinth", "role": ROLE_DEVICE, "z": 10, "rect": Rect2(Vector2(-348.0, -130.0), Vector2(96.0, 76.0)), "color": Color(0.070, 0.108, 0.104, 1.0)},
	{"id": "base_first_screen_scene.part.outpost_core_hull", "role": ROLE_DEVICE, "z": 11, "rect": Rect2(Vector2(-332.0, -150.0), Vector2(64.0, 82.0)), "color": Color(0.132, 0.236, 0.226, 1.0)},
	{"id": "base_first_screen_scene.part.core_shell_block", "role": ROLE_MATERIAL, "z": 12, "rect": Rect2(Vector2(-318.0, -136.0), Vector2(36.0, 54.0)), "color": Color(0.236, 0.430, 0.400, 0.96)},
	{"id": "base_first_screen_scene.part.basic_reactor_body", "role": ROLE_DEVICE, "z": 10, "rect": Rect2(Vector2(-204.0, -126.0), Vector2(92.0, 74.0)), "color": Color(0.160, 0.128, 0.090, 1.0)},
	{"id": "base_first_screen_scene.part.reactor_heat_chamber", "role": ROLE_MATERIAL, "z": 12, "rect": Rect2(Vector2(-184.0, -112.0), Vector2(44.0, 44.0)), "color": Color(0.520, 0.268, 0.106, 1.0)},
	{"id": "base_first_screen_scene.part.reactor_feed_port", "role": ROLE_SERVICE, "z": 13, "rect": Rect2(Vector2(-214.0, -106.0), Vector2(24.0, 22.0)), "color": Color(0.820, 0.598, 0.280, 1.0)},
	{"id": "base_first_screen_scene.part.storage_bank_body", "role": ROLE_DEVICE, "z": 10, "rect": Rect2(Vector2(-306.0, 44.0), Vector2(108.0, 62.0)), "color": Color(0.100, 0.176, 0.142, 1.0)},
	{"id": "base_first_screen_scene.part.storage_cargo_block_a", "role": ROLE_MATERIAL, "z": 12, "rect": Rect2(Vector2(-292.0, 54.0), Vector2(36.0, 42.0)), "color": Color(0.248, 0.414, 0.318, 1.0)},
	{"id": "base_first_screen_scene.part.storage_cargo_block_b", "role": ROLE_MATERIAL, "z": 12, "rect": Rect2(Vector2(-248.0, 54.0), Vector2(34.0, 42.0)), "color": Color(0.206, 0.344, 0.282, 1.0)},
	{"id": "base_first_screen_scene.part.storage_supply_port", "role": ROLE_SERVICE, "z": 13, "rect": Rect2(Vector2(-228.0, 24.0), Vector2(30.0, 18.0)), "color": Color(0.506, 0.790, 0.432, 1.0)},
	{"id": "base_first_screen_scene.part.outfitting_rack_body", "role": ROLE_DEVICE, "z": 10, "rect": Rect2(Vector2(-102.0, -76.0), Vector2(74.0, 96.0)), "color": Color(0.130, 0.148, 0.120, 1.0)},
	{"id": "base_first_screen_scene.part.outfitting_suit_frame", "role": ROLE_MATERIAL, "z": 12, "rect": Rect2(Vector2(-82.0, -62.0), Vector2(34.0, 66.0)), "color": Color(0.392, 0.344, 0.162, 1.0)},
	{"id": "base_first_screen_scene.part.outfitting_lock_port", "role": ROLE_SERVICE, "z": 13, "rect": Rect2(Vector2(-106.0, -28.0), Vector2(22.0, 20.0)), "color": Color(0.880, 0.730, 0.320, 1.0)},
	{"id": "base_first_screen_scene.part.core_repair_port", "role": ROLE_SERVICE, "z": 13, "rect": Rect2(Vector2(-278.0, -74.0), Vector2(24.0, 20.0)), "color": Color(0.770, 0.898, 0.662, 1.0)},
]

const ELLIPSE_PARTS := [
	{"id": "base_first_screen_scene.part.core_shadow", "role": ROLE_SHADOW, "z": 8, "center": Vector2(-300.0, -48.0), "radius": Vector2(72.0, 24.0), "color": Color(0.0, 0.0, 0.0, 0.46)},
	{"id": "base_first_screen_scene.part.reactor_shadow", "role": ROLE_SHADOW, "z": 8, "center": Vector2(-158.0, -48.0), "radius": Vector2(68.0, 22.0), "color": Color(0.0, 0.0, 0.0, 0.36)},
	{"id": "base_first_screen_scene.part.storage_shadow", "role": ROLE_SHADOW, "z": 8, "center": Vector2(-252.0, 108.0), "radius": Vector2(78.0, 20.0), "color": Color(0.0, 0.0, 0.0, 0.32)},
	{"id": "base_first_screen_scene.part.outfitting_shadow", "role": ROLE_SHADOW, "z": 8, "center": Vector2(-66.0, 24.0), "radius": Vector2(56.0, 20.0), "color": Color(0.0, 0.0, 0.0, 0.30)},
]

const CRYSTAL_PARTS := [
	{"id": "base_first_screen_scene.part.right_crystal_spire_a", "role": ROLE_CONTEXT, "z": 7, "points": [Vector2(132.0, -138.0), Vector2(170.0, -202.0), Vector2(196.0, -112.0), Vector2(162.0, -76.0)], "color": Color(0.238, 0.676, 0.790, 0.78)},
	{"id": "base_first_screen_scene.part.right_crystal_spire_b", "role": ROLE_CONTEXT, "z": 7, "points": [Vector2(104.0, -40.0), Vector2(142.0, -114.0), Vector2(174.0, -24.0), Vector2(134.0, 18.0)], "color": Color(0.176, 0.540, 0.690, 0.68)},
	{"id": "base_first_screen_scene.part.right_crystal_spire_c", "role": ROLE_CONTEXT, "z": 7, "points": [Vector2(130.0, 80.0), Vector2(184.0, 20.0), Vector2(216.0, 118.0), Vector2(160.0, 154.0)], "color": Color(0.236, 0.618, 0.722, 0.58)},
]

var scene_part_nodes: Dictionary = {}
var scene_part_roles: Dictionary = {}
var scene_state_shape_ids: Array[String] = []
var context_original_modulates: Dictionary = {}
var context_rect_original_colors: Dictionary = {}
var muted_context_layer_count := 0
var muted_context_rect_count := 0
var scene_active := false
var outpost_restored := false
var devices_online := false


func _ready() -> void:
	z_index = 18
	process_priority = 104
	_ensure_scene_nodes()
	refresh_scene_state(null, null)


func _process(_delta: float) -> void:
	refresh_focus_visibility(_get_player_position())


func refresh_scene_state(world_state: WorldState, character_state: CharacterState) -> void:
	_ensure_scene_nodes()
	scene_state_shape_ids.clear()
	outpost_restored = world_state != null and world_state.quest_state.has_completed_quest(RESTORE_OUTPOST_QUEST_ID)
	devices_online = _has_base_device_context(world_state)
	_register_state_shape("base_first_screen_scene.state.outpost.%s" % ("restored" if outpost_restored else "damaged"))
	_register_state_shape("base_first_screen_scene.state.devices.%s" % ("online" if devices_online else "dormant"))
	_apply_state_colors()
	refresh_focus_visibility(_get_position_for_refresh(character_state))
	queue_redraw()


func refresh_focus_visibility(player_position: Vector2) -> void:
	scene_active = is_scene_active_at(player_position)
	visible = scene_active
	_set_context_layers_muted(scene_active)
	_set_context_rects_muted(scene_active)


func is_scene_active_at(player_position: Vector2) -> bool:
	return (
		player_position.x >= FOCUS_MIN_X
		and player_position.x <= FOCUS_MAX_X
		and player_position.y >= FOCUS_MIN_Y
		and player_position.y <= FOCUS_MAX_Y
	)


func is_scene_active() -> bool:
	return scene_active


func has_scene_shape(shape_id: String) -> bool:
	return SCENE_SHAPES.has(shape_id)


func get_scene_shape_count() -> int:
	return SCENE_SHAPES.size()


func has_scene_state_shape(shape_id: String) -> bool:
	return scene_state_shape_ids.has(shape_id)


func get_scene_state_shape_count() -> int:
	return scene_state_shape_ids.size()


func get_scene_part_count() -> int:
	return scene_part_nodes.size()


func has_scene_part(part_id: String) -> bool:
	return scene_part_nodes.has(part_id)


func get_scene_part_role(part_id: String) -> String:
	return String(scene_part_roles.get(part_id, ""))


func get_device_volume_count() -> int:
	return DEVICE_VOLUME_IDS.size()


func get_material_block_count() -> int:
	return MATERIAL_BLOCK_IDS.size()


func get_service_port_count() -> int:
	return SERVICE_PORT_IDS.size()


func get_muted_context_layer_count() -> int:
	return muted_context_layer_count


func get_muted_context_rect_count() -> int:
	return muted_context_rect_count


func _draw() -> void:
	if not visible:
		return
	_draw_short_service_links()
	_draw_status_feedback()


func _ensure_scene_nodes() -> void:
	if not scene_part_nodes.is_empty():
		return
	for part in POLYGON_PARTS:
		_create_polygon_part(part)
	for part in RECT_PARTS:
		_create_rect_part(part)
	for part in ELLIPSE_PARTS:
		_create_ellipse_part(part)
	for part in CRYSTAL_PARTS:
		_create_polygon_part(part)


func _create_polygon_part(part: Dictionary) -> void:
	var polygon := Polygon2D.new()
	var part_id := String(part["id"])
	polygon.name = part_id.replace(".", "_")
	polygon.polygon = _points_to_packed_array(part["points"] as Array)
	polygon.color = part["color"] as Color
	polygon.z_index = int(part["z"])
	polygon.set_meta("scene_part_id", part_id)
	polygon.set_meta("scene_role", String(part["role"]))
	add_child(polygon)
	scene_part_nodes[part_id] = polygon
	scene_part_roles[part_id] = String(part["role"])


func _create_rect_part(part: Dictionary) -> void:
	var part_copy := part.duplicate()
	part_copy["points"] = _rect_to_points(part["rect"] as Rect2)
	_create_polygon_part(part_copy)


func _create_ellipse_part(part: Dictionary) -> void:
	var points: Array[Vector2] = []
	var center := part["center"] as Vector2
	var radius := part["radius"] as Vector2
	for index in range(24):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	var part_copy := part.duplicate()
	part_copy["points"] = points
	_create_polygon_part(part_copy)


func _points_to_packed_array(points: Array) -> PackedVector2Array:
	var vector_points := PackedVector2Array()
	for point in points:
		vector_points.append(point as Vector2)
	return vector_points


func _rect_to_points(rect: Rect2) -> Array[Vector2]:
	return [
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	]


func _apply_state_colors() -> void:
	_set_part_color(
		"base_first_screen_scene.part.core_repair_port",
		Color(0.420, 0.980, 0.720, 1.0) if outpost_restored else Color(0.900, 0.650, 0.300, 1.0)
	)
	_set_part_color(
		"base_first_screen_scene.part.reactor_feed_port",
		Color(0.960, 0.620, 0.260, 1.0) if devices_online else Color(0.560, 0.376, 0.178, 1.0)
	)
	_set_part_color(
		"base_first_screen_scene.part.storage_supply_port",
		Color(0.560, 0.900, 0.480, 1.0) if devices_online else Color(0.310, 0.470, 0.290, 1.0)
	)
	_set_part_color(
		"base_first_screen_scene.part.outfitting_lock_port",
		Color(0.960, 0.800, 0.330, 1.0) if devices_online else Color(0.440, 0.374, 0.186, 1.0)
	)


func _set_part_color(part_id: String, color: Color) -> void:
	var polygon := scene_part_nodes.get(part_id) as Polygon2D
	if polygon == null:
		return
	polygon.color = color


func _draw_short_service_links() -> void:
	_draw_grounded_line([Vector2(-278.0, -74.0), Vector2(-238.0, -78.0), Vector2(-214.0, -106.0)], Color(0.880, 0.700, 0.348, 0.46), 4.0)
	_draw_grounded_line([Vector2(-278.0, -74.0), Vector2(-254.0, -10.0), Vector2(-228.0, 24.0)], Color(0.420, 0.820, 0.520, 0.40), 3.8)
	_draw_grounded_line([Vector2(-228.0, 24.0), Vector2(-156.0, 12.0), Vector2(-106.0, -28.0)], Color(0.860, 0.720, 0.342, 0.38), 3.8)


func _draw_status_feedback() -> void:
	var core_color := Color(0.420, 0.980, 0.720, 0.56) if outpost_restored else Color(0.940, 0.650, 0.300, 0.50)
	var device_alpha := 0.46 if devices_online else 0.16
	draw_circle(Vector2(-298.0, -112.0), 5.5, core_color)
	draw_circle(Vector2(-154.0, -86.0), 4.8, Color(0.960, 0.610, 0.260, device_alpha))
	draw_circle(Vector2(-214.0, 76.0), 4.8, Color(0.560, 0.900, 0.500, device_alpha))
	draw_circle(Vector2(-62.0, -20.0), 4.8, Color(0.960, 0.800, 0.320, device_alpha))


func _draw_grounded_line(points: Array, color: Color, width: float) -> void:
	var vector_points := PackedVector2Array()
	for point in points:
		vector_points.append(point as Vector2)
	draw_polyline(vector_points, Color(0.0, 0.0, 0.0, 0.34), width + 4.0, true)
	draw_polyline(vector_points, color, width, true)


func _set_context_layers_muted(should_mute: bool) -> void:
	muted_context_layer_count = 0
	var map_root := get_parent()
	if map_root == null:
		return
	for config in CONTEXT_LAYER_ALPHAS:
		var node_path := String(config["path"])
		var canvas_item := map_root.get_node_or_null(node_path) as CanvasItem
		if canvas_item == null:
			continue
		if should_mute:
			if not context_original_modulates.has(node_path):
				context_original_modulates[node_path] = canvas_item.modulate
			var muted_modulate := context_original_modulates[node_path] as Color
			muted_modulate.a = float(config["alpha"])
			canvas_item.modulate = muted_modulate
			muted_context_layer_count += 1
			continue
		if context_original_modulates.has(node_path):
			canvas_item.modulate = context_original_modulates[node_path] as Color
	if should_mute:
		return
	context_original_modulates.clear()


func _set_context_rects_muted(should_mute: bool) -> void:
	muted_context_rect_count = 0
	var map_root := get_parent()
	if map_root == null:
		return
	for config in CONTEXT_RECT_ALPHAS:
		var node_path := String(config["path"])
		var rect := map_root.get_node_or_null(node_path) as ColorRect
		if rect == null:
			continue
		if should_mute:
			if not context_rect_original_colors.has(node_path):
				context_rect_original_colors[node_path] = rect.color
			var muted_color := context_rect_original_colors[node_path] as Color
			muted_color.a = float(config["alpha"])
			rect.color = muted_color
			muted_context_rect_count += 1
			continue
		if context_rect_original_colors.has(node_path):
			rect.color = context_rect_original_colors[node_path] as Color
	if should_mute:
		return
	context_rect_original_colors.clear()


func _has_base_device_context(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return (
		world_state.has_base_structure_definition("building.basic_reactor")
		or world_state.has_base_structure_definition("building.basic_storage")
		or world_state.has_base_structure_definition("building.field_outfitting_station")
	)


func _get_position_for_refresh(character_state: CharacterState) -> Vector2:
	if character_state != null:
		return character_state.position
	return _get_player_position()


func _get_player_position() -> Vector2:
	var parent_node := get_parent()
	if parent_node == null:
		return Vector2.ZERO
	var player := parent_node.get_node_or_null("Player") as Node2D
	if player == null:
		return Vector2.ZERO
	return player.position


func _register_state_shape(shape_id: String) -> void:
	if scene_state_shape_ids.has(shape_id):
		return
	scene_state_shape_ids.append(shape_id)
