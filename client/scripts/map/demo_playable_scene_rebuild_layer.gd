extends Node2D
class_name DemoPlayableSceneRebuildLayer

const RESTORE_OUTPOST_QUEST_ID := "quest.restore_outpost"

const FOCUS_MIN_X := -420.0
const FOCUS_MAX_X := 260.0
const FOCUS_MIN_Y := -260.0
const FOCUS_MAX_Y := 220.0

const ASSET_TERRAIN_FLOOR_ID := "playable_scene.terrain_floor"
const ASSET_CORE_MACHINE_ID := "playable_scene.outpost_core_machine"
const ASSET_BASIC_REACTOR_ID := "playable_scene.basic_reactor_module"
const ASSET_STORAGE_BANK_ID := "playable_scene.storage_crate_bank"
const ASSET_OUTFITTING_STATION_ID := "playable_scene.outfitting_station_rack"
const ASSET_PIPE_BUNDLE_ID := "playable_scene.pipe_bundle"
const ASSET_CRYSTAL_ECOLOGY_ID := "playable_scene.crystal_ecology_cluster"
const ASSET_POLLUTION_EDGE_ID := "playable_scene.pollution_edge_pool"
const ASSET_PLAYER_REPAIR_POSE_ID := "playable_scene.player_repair_pose"

const ASSET_TERRAIN_FLOOR := preload("res://assets/sprites/demo_first_screen/playable_scene_compact_floor.svg")
const ASSET_CORE_MACHINE := preload("res://assets/sprites/demo_first_screen/outpost_core_machine.svg")
const ASSET_BASIC_REACTOR := preload("res://assets/sprites/demo_first_screen/basic_reactor_module.svg")
const ASSET_STORAGE_BANK := preload("res://assets/sprites/demo_first_screen/storage_crate_bank.svg")
const ASSET_OUTFITTING_STATION := preload("res://assets/sprites/demo_first_screen/outfitting_station_rack.svg")
const ASSET_PIPE_BUNDLE := preload("res://assets/sprites/demo_first_screen/pipe_bundle.svg")
const ASSET_CRYSTAL_ECOLOGY := preload("res://assets/sprites/demo_first_screen/crystal_ecology_cluster.svg")
const ASSET_POLLUTION_EDGE := preload("res://assets/sprites/demo_first_screen/pollution_edge_pool.svg")
const ASSET_PLAYER_REPAIR_POSE := preload("res://assets/sprites/demo_first_screen/player_repair_pose.svg")

const SCENE_ASSET_MANIFEST := {
	ASSET_TERRAIN_FLOOR_ID: {
		"path": "res://assets/sprites/demo_first_screen/playable_scene_compact_floor.svg",
		"role": "compact_walkable_floor",
		"render": "sprite"
	},
	ASSET_CORE_MACHINE_ID: {
		"path": "res://assets/sprites/demo_first_screen/outpost_core_machine.svg",
		"role": "first_objective_subject",
		"render": "sprite"
	},
	ASSET_BASIC_REACTOR_ID: {
		"path": "res://assets/sprites/demo_first_screen/basic_reactor_module.svg",
		"role": "processing_device",
		"render": "sprite"
	},
	ASSET_STORAGE_BANK_ID: {
		"path": "res://assets/sprites/demo_first_screen/storage_crate_bank.svg",
		"role": "storage_device",
		"render": "sprite"
	},
	ASSET_OUTFITTING_STATION_ID: {
		"path": "res://assets/sprites/demo_first_screen/outfitting_station_rack.svg",
		"role": "outfitting_device",
		"render": "sprite"
	},
	ASSET_PIPE_BUNDLE_ID: {
		"path": "res://assets/sprites/demo_first_screen/pipe_bundle.svg",
		"role": "short_service_pipes",
		"render": "sprite"
	},
	ASSET_CRYSTAL_ECOLOGY_ID: {
		"path": "res://assets/sprites/demo_first_screen/crystal_ecology_cluster.svg",
		"role": "resource_edge",
		"render": "sprite"
	},
	ASSET_POLLUTION_EDGE_ID: {
		"path": "res://assets/sprites/demo_first_screen/pollution_edge_pool.svg",
		"role": "hazard_edge",
		"render": "sprite"
	},
	ASSET_PLAYER_REPAIR_POSE_ID: {
		"path": "res://assets/sprites/demo_first_screen/player_repair_pose.svg",
		"role": "human_scale_action",
		"render": "sprite"
	},
}

const SCENE_SHAPES := {
	"playable_scene.sprite_node_layout": true,
	"playable_scene.walkable_floor_subject": true,
	"playable_scene.first_objective_core_subject": true,
	"playable_scene.human_scale_repair_pose": true,
	"playable_scene.short_service_pipe_subject": true,
	"playable_scene.base_devices_as_scene_objects": true,
	"playable_scene.crystal_edge_as_ecology": true,
	"playable_scene.pollution_edge_as_hazard": true,
	"playable_scene.old_planning_layers_muted": true,
	"playable_scene.startup_presentation_suppressed": true,
	"playable_scene.compact_floor_not_fullscreen_overlay": true,
	"playable_scene.no_fullscreen_backdrop": true,
	"playable_scene.floor_islands_not_planning_grid": true,
	"playable_scene.far_core_station_excluded": true,
}

const SCENE_SPRITE_LAYOUT := [
	{
		"id": ASSET_TERRAIN_FLOOR_ID,
		"texture": ASSET_TERRAIN_FLOOR,
		"position": Vector2(-128.0, -6.0),
		"scale": Vector2(1.08, 0.94),
		"modulate": Color(1.0, 1.0, 1.0, 0.96),
		"z": 1,
	},
	{
		"id": ASSET_PIPE_BUNDLE_ID,
		"texture": ASSET_PIPE_BUNDLE,
		"position": Vector2(-222.0, -20.0),
		"scale": Vector2(0.86, 0.72),
		"modulate": Color(0.84, 0.96, 0.88, 0.58),
		"z": 3,
	},
	{
		"id": ASSET_CORE_MACHINE_ID,
		"texture": ASSET_CORE_MACHINE,
		"position": Vector2(-300.0, -92.0),
		"scale": Vector2(0.70, 0.70),
		"modulate": Color(1.0, 1.0, 1.0, 0.94),
		"z": 8,
	},
	{
		"id": ASSET_BASIC_REACTOR_ID,
		"texture": ASSET_BASIC_REACTOR,
		"position": Vector2(-156.0, -82.0),
		"scale": Vector2(0.64, 0.64),
		"modulate": Color(1.0, 0.98, 0.92, 0.90),
		"z": 7,
	},
	{
		"id": ASSET_STORAGE_BANK_ID,
		"texture": ASSET_STORAGE_BANK,
		"position": Vector2(-252.0, 70.0),
		"scale": Vector2(0.66, 0.62),
		"modulate": Color(0.94, 1.0, 0.94, 0.82),
		"z": 7,
	},
	{
		"id": ASSET_OUTFITTING_STATION_ID,
		"texture": ASSET_OUTFITTING_STATION,
		"position": Vector2(-78.0, 28.0),
		"scale": Vector2(0.58, 0.60),
		"modulate": Color(0.92, 1.0, 0.96, 0.78),
		"z": 7,
	},
	{
		"id": ASSET_CRYSTAL_ECOLOGY_ID,
		"texture": ASSET_CRYSTAL_ECOLOGY,
		"position": Vector2(96.0, -88.0),
		"scale": Vector2(0.74, 0.72),
		"modulate": Color(0.84, 0.98, 1.0, 0.72),
		"z": 5,
	},
	{
		"id": ASSET_POLLUTION_EDGE_ID,
		"texture": ASSET_POLLUTION_EDGE,
		"position": Vector2(242.0, 92.0),
		"scale": Vector2(0.74, 0.70),
		"modulate": Color(1.0, 0.98, 0.76, 0.46),
		"z": 2,
	},
	{
		"id": ASSET_PLAYER_REPAIR_POSE_ID,
		"texture": ASSET_PLAYER_REPAIR_POSE,
		"position": Vector2(-218.0, -58.0),
		"scale": Vector2(0.42, 0.42),
		"modulate": Color(1.0, 1.0, 1.0, 0.32),
		"z": 9,
	},
]

const CONTEXT_LAYER_ALPHAS := [
	{"path": "OpeningSceneLayer", "alpha": 0.0},
	{"path": "DemoCoreSceneSpaceLayer", "alpha": 0.0},
	{"path": "DemoInitialArtIdentityLayer", "alpha": 0.0},
	{"path": "DemoIndustrialBaseVisualLayer", "alpha": 0.08},
	{"path": "DemoCrystalResourceVisualLayer", "alpha": 0.08},
	{"path": "DemoPollutionBoundaryVisualLayer", "alpha": 0.006},
	{"path": "DemoSceneFocusDepthLayer", "alpha": 0.012},
	{"path": "PrototypeVisualPriorityLayer", "alpha": 0.002},
	{"path": "DemoRegionIndustrialValueLayer", "alpha": 0.001},
	{"path": "DemoRoutePresentationLayer", "alpha": 0.0},
	{"path": "DemoFirstIndustrialPathVisualLayer", "alpha": 0.0},
	{"path": "DemoBaseHandoffAssetArtPass", "alpha": 0.0},
	{"path": "DemoBaseStartupPresentationLayer", "alpha": 0.0},
]

const CONTEXT_RECT_ALPHAS := [
	{"path": "RegionBase", "alpha": 0.012},
	{"path": "RegionCrystal", "alpha": 0.012},
	{"path": "RegionPollution", "alpha": 0.008},
	{"path": "MainRouteSpine", "alpha": 0.0001},
	{"path": "BaseToCrystalRouteBand", "alpha": 0.0001},
	{"path": "CrystalToPollutionRouteBand", "alpha": 0.0001},
	{"path": "RegionBoundaryCrystal", "alpha": 0.0002},
	{"path": "RegionBoundaryPollution", "alpha": 0.0002},
	{"path": "DemoRoutePresentationLayer/DemoRouteBaseBand", "alpha": 0.0},
	{"path": "DemoRoutePresentationLayer/DemoRouteCrystalBand", "alpha": 0.0},
	{"path": "DemoRoutePresentationLayer/DemoRoutePollutionBand", "alpha": 0.0},
]

var scene_state_shape_ids: Array[String] = []
var scene_state: Dictionary = {}
var scene_active := false
var context_original_modulates: Dictionary = {}
var context_rect_original_colors: Dictionary = {}
var muted_planning_layer_count := 0
var muted_context_rect_count := 0
var scene_asset_nodes: Dictionary = {}


func _ready() -> void:
	z_index = 32
	process_priority = 86
	_ensure_scene_sprite_nodes()
	refresh_scene_state(null, null)


func _process(_delta: float) -> void:
	refresh_focus_visibility(_get_player_position())


func refresh_scene_state(world_state: WorldState, character_state: CharacterState) -> void:
	_ensure_scene_sprite_nodes()
	scene_state_shape_ids.clear()
	var restored := world_state != null and world_state.quest_state.has_completed_quest(RESTORE_OUTPOST_QUEST_ID)
	var has_processing_context := false
	if world_state != null:
		has_processing_context = (
			world_state.has_base_structure_definition("building.basic_reactor")
			or world_state.has_base_structure_definition("building.basic_storage")
			or world_state.has_base_structure_definition("building.field_outfitting_station")
		)
	scene_state = {
		"outpost_restored": restored,
		"processing_context": has_processing_context,
		"has_character": character_state != null,
	}
	_register_state_shape("playable_scene.state.outpost.%s" % ("restored" if restored else "damaged"))
	_register_state_shape("playable_scene.state.devices.%s" % ("online" if has_processing_context else "dormant"))
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


func get_scene_asset_count() -> int:
	return SCENE_ASSET_MANIFEST.size()


func has_scene_asset(asset_id: String) -> bool:
	return SCENE_ASSET_MANIFEST.has(asset_id)


func get_scene_asset_path(asset_id: String) -> String:
	if not SCENE_ASSET_MANIFEST.has(asset_id):
		return ""
	return String(SCENE_ASSET_MANIFEST[asset_id].get("path", ""))


func get_scene_asset_role(asset_id: String) -> String:
	if not SCENE_ASSET_MANIFEST.has(asset_id):
		return ""
	return String(SCENE_ASSET_MANIFEST[asset_id].get("role", ""))


func get_scene_asset_render_mode(asset_id: String) -> String:
	if not SCENE_ASSET_MANIFEST.has(asset_id):
		return ""
	return String(SCENE_ASSET_MANIFEST[asset_id].get("render", ""))


func is_scene_asset_available(asset_id: String) -> bool:
	var asset_path := get_scene_asset_path(asset_id)
	return not asset_path.is_empty() and ResourceLoader.exists(asset_path) and _get_scene_asset_texture(asset_id) != null


func get_scene_sprite_node_count() -> int:
	return scene_asset_nodes.size()


func has_scene_shape(shape_id: String) -> bool:
	return SCENE_SHAPES.has(shape_id)


func get_scene_shape_count() -> int:
	return SCENE_SHAPES.size()


func has_scene_state_shape(shape_id: String) -> bool:
	return scene_state_shape_ids.has(shape_id)


func get_scene_state_shape_count() -> int:
	return scene_state_shape_ids.size()


func get_muted_planning_layer_count() -> int:
	return muted_planning_layer_count


func get_muted_context_rect_count() -> int:
	return muted_context_rect_count


func _draw() -> void:
	if not visible:
		return
	_draw_shadow_grounding()
	_draw_short_service_relations()
	_draw_scene_status_feedback()


func _ensure_scene_sprite_nodes() -> void:
	if not scene_asset_nodes.is_empty():
		return
	for item in SCENE_SPRITE_LAYOUT:
		var sprite := Sprite2D.new()
		var asset_id := String(item["id"])
		sprite.name = asset_id.replace(".", "_")
		sprite.texture = item["texture"] as Texture2D
		sprite.position = item["position"] as Vector2
		sprite.scale = item["scale"] as Vector2
		sprite.modulate = item["modulate"] as Color
		sprite.z_index = int(item["z"])
		sprite.centered = true
		add_child(sprite)
		scene_asset_nodes[asset_id] = sprite


func _draw_shadow_grounding() -> void:
	for shadow in [
		{"center": Vector2(-302.0, -46.0), "radius": Vector2(96.0, 30.0), "alpha": 0.40},
		{"center": Vector2(-156.0, -30.0), "radius": Vector2(82.0, 24.0), "alpha": 0.34},
		{"center": Vector2(-252.0, 112.0), "radius": Vector2(96.0, 26.0), "alpha": 0.28},
		{"center": Vector2(-82.0, 74.0), "radius": Vector2(88.0, 24.0), "alpha": 0.24},
		{"center": Vector2(92.0, -18.0), "radius": Vector2(132.0, 32.0), "alpha": 0.20},
	]:
		_draw_soft_shadow(shadow["center"] as Vector2, shadow["radius"] as Vector2, float(shadow["alpha"]))


func _draw_short_service_relations() -> void:
	_draw_service_line([Vector2(-256.0, -92.0), Vector2(-204.0, -102.0), Vector2(-156.0, -82.0)], Color(0.96, 0.70, 0.34, 0.34), 4.2)
	_draw_service_line([Vector2(-264.0, -46.0), Vector2(-278.0, 28.0), Vector2(-252.0, 70.0)], Color(0.52, 0.86, 0.58, 0.28), 4.0)
	_draw_service_line([Vector2(-222.0, -28.0), Vector2(-126.0, 12.0), Vector2(-78.0, 28.0)], Color(0.96, 0.76, 0.34, 0.30), 3.8)
	for point in [
		Vector2(-256.0, -92.0),
		Vector2(-156.0, -82.0),
		Vector2(-252.0, 70.0),
		Vector2(-78.0, 28.0),
	]:
		draw_circle(point, 5.2, Color(0.95, 0.76, 0.34, 0.50))
		draw_circle(point, 2.2, Color(0.40, 0.90, 0.84, 0.50))


func _draw_scene_status_feedback() -> void:
	var restored := bool(scene_state.get("outpost_restored", false))
	var device_online := bool(scene_state.get("processing_context", false))
	var core_status_color := Color(0.42, 0.96, 0.76, 0.44) if restored else Color(0.96, 0.72, 0.34, 0.50)
	draw_arc(Vector2(-300.0, -92.0), 58.0, PI * 0.06, PI * 1.72, 32, core_status_color, 2.6, true)
	draw_rect(Rect2(Vector2(-186.0, -120.0), Vector2(58.0, 14.0)), Color(0.96, 0.72, 0.34, 0.30 if device_online else 0.12), true)
	draw_rect(Rect2(Vector2(-282.0, 52.0), Vector2(70.0, 14.0)), Color(0.54, 0.90, 0.52, 0.26 if device_online else 0.10), true)


func _set_context_layers_muted(should_mute: bool) -> void:
	muted_planning_layer_count = 0
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
			muted_planning_layer_count += 1
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


func _get_scene_asset_texture(asset_id: String) -> Texture2D:
	match asset_id:
		ASSET_TERRAIN_FLOOR_ID:
			return ASSET_TERRAIN_FLOOR
		ASSET_CORE_MACHINE_ID:
			return ASSET_CORE_MACHINE
		ASSET_BASIC_REACTOR_ID:
			return ASSET_BASIC_REACTOR
		ASSET_STORAGE_BANK_ID:
			return ASSET_STORAGE_BANK
		ASSET_OUTFITTING_STATION_ID:
			return ASSET_OUTFITTING_STATION
		ASSET_PIPE_BUNDLE_ID:
			return ASSET_PIPE_BUNDLE
		ASSET_CRYSTAL_ECOLOGY_ID:
			return ASSET_CRYSTAL_ECOLOGY
		ASSET_POLLUTION_EDGE_ID:
			return ASSET_POLLUTION_EDGE
		ASSET_PLAYER_REPAIR_POSE_ID:
			return ASSET_PLAYER_REPAIR_POSE
		_:
			return null


func _register_state_shape(shape_id: String) -> void:
	if scene_state_shape_ids.has(shape_id):
		return
	scene_state_shape_ids.append(shape_id)


func _draw_service_line(points: Array, color: Color, width: float) -> void:
	var vector_points := PackedVector2Array()
	for point in points:
		vector_points.append(point)
	draw_polyline(vector_points, Color(0.006, 0.014, 0.014, 0.62), width + 4.5, true)
	draw_polyline(vector_points, Color(color.r, color.g, color.b, color.a * 0.50), width, true)
	draw_polyline(vector_points, color, 1.5, true)


func _draw_soft_shadow(center: Vector2, radius: Vector2, alpha: float) -> void:
	draw_set_transform(center, 0.0, radius)
	draw_circle(Vector2.ZERO, 1.0, Color(0.0, 0.0, 0.0, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_polyline_closed(points: Array, color: Color, width: float) -> void:
	if points.size() < 2:
		return
	var vector_points := PackedVector2Array()
	for point in points:
		vector_points.append(point)
	vector_points.append(points[0])
	draw_polyline(vector_points, color, width, true)
