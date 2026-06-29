extends Node2D
class_name DemoBaseHandoffAssetArtPass

const RESTORE_OUTPOST_QUEST_ID := "quest.restore_outpost"
const STAGE_BASE_RECEIVING := "base_receiving"
const STAGE_REACTOR_FEED := "reactor_feed"
const STAGE_REACTOR_PROCESSING := "reactor_processing"
const STAGE_STORAGE_OUTPUT := "storage_output"
const STAGE_OUTFITTING_READY := "outfitting_ready"

const HANDOFF_FOCUS_MIN_X := -360.0
const HANDOFF_FOCUS_MAX_X := 42.0
const HANDOFF_WORKFACE_RECT := Rect2(Vector2(-352.0, -206.0), Vector2(392.0, 304.0))

const ASSET_FLOOR_ID := "base_handoff_asset.workface_floor"
const ASSET_PIPE_BUNDLE_ID := "base_handoff_asset.pipe_bundle"
const ASSET_REACTOR_ID := "base_handoff_asset.reactor_module"
const ASSET_STORAGE_ID := "base_handoff_asset.storage_bank"
const ASSET_OUTFITTING_ID := "base_handoff_asset.outfitting_station"

const ASSET_FLOOR := preload("res://assets/sprites/demo_first_screen/terrain_outpost_floor.svg")
const ASSET_PIPE_BUNDLE := preload("res://assets/sprites/demo_first_screen/pipe_bundle.svg")
const ASSET_REACTOR := preload("res://assets/sprites/demo_first_screen/basic_reactor_module.svg")
const ASSET_STORAGE := preload("res://assets/sprites/demo_first_screen/storage_crate_bank.svg")
const ASSET_OUTFITTING := preload("res://assets/sprites/demo_first_screen/outfitting_station_rack.svg")

const HANDOFF_ASSET_MANIFEST := {
	ASSET_FLOOR_ID: {
		"path": "res://assets/sprites/demo_first_screen/terrain_outpost_floor.svg",
		"role": "local_workface_floor",
		"render": "sprite"
	},
	ASSET_PIPE_BUNDLE_ID: {
		"path": "res://assets/sprites/demo_first_screen/pipe_bundle.svg",
		"role": "short_material_conduit",
		"render": "sprite"
	},
	ASSET_REACTOR_ID: {
		"path": "res://assets/sprites/demo_first_screen/basic_reactor_module.svg",
		"role": "processing_device",
		"render": "sprite"
	},
	ASSET_STORAGE_ID: {
		"path": "res://assets/sprites/demo_first_screen/storage_crate_bank.svg",
		"role": "storage_device",
		"render": "sprite"
	},
	ASSET_OUTFITTING_ID: {
		"path": "res://assets/sprites/demo_first_screen/outfitting_station_rack.svg",
		"role": "outfitting_device",
		"render": "sprite"
	},
}

const HANDOFF_SHAPES := {
	"base_handoff_asset.old_route_suppression": true,
	"base_handoff_asset.local_backdrop": true,
	"base_handoff_asset.workface_floor": true,
	"base_handoff_asset.sprite_manifest": true,
	"base_handoff_asset.reactor_asset": true,
	"base_handoff_asset.storage_asset": true,
	"base_handoff_asset.outfitting_asset": true,
	"base_handoff_asset.short_pipe_bundle": true,
	"base_handoff_asset.return_tray_subject": true,
	"base_handoff_asset.reactor_hopper_subject": true,
	"base_handoff_asset.storage_supply_subject": true,
	"base_handoff_asset.outfitting_latch_subject": true,
	"base_handoff_asset.short_stage_packets": true,
	"base_handoff_asset.device_port_tokens": true,
	"base_handoff_asset.material_receipt_slots": true,
}

var handoff_state_shape_ids: Array[String] = []
var handoff_state: Dictionary = {}
var handoff_available := false


func _ready() -> void:
	process_priority = 92
	visible = false
	queue_redraw()


func _process(_delta: float) -> void:
	refresh_focus_visibility(_get_player_position())


func refresh_handoff_state(world_state: WorldState, character_state: CharacterState) -> void:
	handoff_state_shape_ids.clear()
	handoff_available = _is_handoff_available(world_state)
	if world_state == null or character_state == null or not handoff_available:
		handoff_state.clear()
		refresh_focus_visibility(_get_player_position())
		queue_redraw()
		return

	var inventory := character_state.inventory
	var reactor_state := _get_base_structure_for_definition(world_state, "building.basic_reactor")
	var reactor_active := (
		String(reactor_state.get("status", "")) == "in_progress"
		and String(reactor_state.get("active_recipe_id", "")) in ["recipe.process_crystal_ore", "recipe.repair_gel"]
	)
	var inputs_ready := inventory.has_ref("item.crystal_ore", 3) or inventory.has_ref("item.salvage_scrap", 1)
	var storage_ready := (
		(inventory.has_ref("item.basic_parts", 1) or inventory.has_ref("item.repair_gel", 1))
		and _has_first_path_output_context(world_state)
	)
	var outfitting_ready := (
		world_state.has_base_structure_definition("building.field_outfitting_station")
		and inventory.has_ref("item.repair_gel", 1)
		and _has_repair_gel_output_context(world_state)
	)
	var active_stage := _resolve_active_stage(character_state, inputs_ready, reactor_active, storage_ready, outfitting_ready)
	handoff_state = {
		"inputs_ready": inputs_ready,
		"reactor_active": reactor_active,
		"storage_ready": storage_ready,
		"outfitting_ready": outfitting_ready,
		"active_stage": active_stage
	}
	_register_state_shape("base_handoff_asset.state.base_receiving.%s" % _state_suffix(inputs_ready))
	_register_state_shape("base_handoff_asset.state.reactor_feed.%s" % _state_suffix(inputs_ready or reactor_active))
	_register_state_shape("base_handoff_asset.state.reactor_processing.%s" % _state_suffix(reactor_active))
	_register_state_shape("base_handoff_asset.state.storage_ready.%s" % _state_suffix(storage_ready))
	_register_state_shape("base_handoff_asset.state.outfitting_ready.%s" % _state_suffix(outfitting_ready))
	_register_state_shape("base_handoff_asset.stage.%s" % active_stage)
	if inputs_ready:
		_register_state_shape("base_handoff_asset.return_tray.loaded")
		_register_state_shape("base_handoff_asset.reactor_hopper.armed")
	if reactor_active:
		_register_state_shape("base_handoff_asset.reactor_hopper.processing")
		_register_state_shape("base_handoff_asset.reactor_core.active")
	if storage_ready:
		_register_state_shape("base_handoff_asset.storage_supply.ready")
	if outfitting_ready:
		_register_state_shape("base_handoff_asset.outfitting_latch.locked")
		_register_state_shape("base_handoff_asset.short_stage_packets.ready")
	refresh_focus_visibility(character_state.position)
	queue_redraw()


func refresh_focus_visibility(player_position: Vector2) -> void:
	visible = is_handoff_visible_at(player_position)


func is_handoff_visible_at(player_position: Vector2) -> bool:
	return handoff_available and player_position.x >= HANDOFF_FOCUS_MIN_X and player_position.x <= HANDOFF_FOCUS_MAX_X


func is_handoff_available() -> bool:
	return handoff_available


func get_active_stage() -> String:
	return String(handoff_state.get("active_stage", STAGE_BASE_RECEIVING))


func has_handoff_asset_shape(shape_id: String) -> bool:
	return HANDOFF_SHAPES.has(shape_id)


func get_handoff_asset_shape_count() -> int:
	return HANDOFF_SHAPES.size()


func has_handoff_state_shape(shape_id: String) -> bool:
	return handoff_state_shape_ids.has(shape_id)


func get_handoff_state_shape_count() -> int:
	return handoff_state_shape_ids.size()


func has_handoff_asset(asset_id: String) -> bool:
	return HANDOFF_ASSET_MANIFEST.has(asset_id)


func get_handoff_asset_count() -> int:
	return HANDOFF_ASSET_MANIFEST.size()


func get_handoff_asset_path(asset_id: String) -> String:
	if not HANDOFF_ASSET_MANIFEST.has(asset_id):
		return ""
	return String(HANDOFF_ASSET_MANIFEST[asset_id].get("path", ""))


func get_handoff_asset_role(asset_id: String) -> String:
	if not HANDOFF_ASSET_MANIFEST.has(asset_id):
		return ""
	return String(HANDOFF_ASSET_MANIFEST[asset_id].get("role", ""))


func get_handoff_asset_render_mode(asset_id: String) -> String:
	if not HANDOFF_ASSET_MANIFEST.has(asset_id):
		return ""
	return String(HANDOFF_ASSET_MANIFEST[asset_id].get("render", ""))


func is_handoff_asset_available(asset_id: String) -> bool:
	var asset_path := get_handoff_asset_path(asset_id)
	return not asset_path.is_empty() and ResourceLoader.exists(asset_path) and _get_handoff_asset_texture(asset_id) != null


func _draw() -> void:
	if not visible:
		return
	_draw_route_suppression()
	_draw_local_backdrop()
	_draw_asset_floor()
	_draw_short_pipe_bundle()
	_draw_device_assets()
	_draw_device_ports()
	_draw_return_tray()
	_draw_reactor_hopper()
	_draw_storage_supply()
	_draw_outfitting_latch()
	_draw_stage_packets()


func _draw_route_suppression() -> void:
	draw_rect(HANDOFF_WORKFACE_RECT.grow(28.0), Color(0.006, 0.012, 0.012, 0.78), true)
	draw_rect(Rect2(Vector2(-360.0, -276.0), Vector2(410.0, 76.0)), Color(0.004, 0.010, 0.010, 0.46), true)
	draw_rect(Rect2(Vector2(-360.0, 94.0), Vector2(410.0, 72.0)), Color(0.004, 0.010, 0.010, 0.42), true)


func _draw_local_backdrop() -> void:
	draw_rect(HANDOFF_WORKFACE_RECT, Color(0.030, 0.045, 0.040, 0.88), true)
	draw_rect(HANDOFF_WORKFACE_RECT, Color(0.36, 0.48, 0.42, 0.22), false, 2.0, true)
	draw_rect(Rect2(Vector2(-322.0, -184.0), Vector2(328.0, 22.0)), Color(0.46, 0.58, 0.50, 0.14), true)
	draw_rect(Rect2(Vector2(-330.0, 54.0), Vector2(340.0, 20.0)), Color(0.46, 0.58, 0.50, 0.12), true)


func _draw_asset_floor() -> void:
	_draw_handoff_asset(ASSET_FLOOR_ID, Rect2(Vector2(-340.0, -198.0), Vector2(370.0, 286.0)), Color(1.0, 1.0, 1.0, 0.56))


func _draw_short_pipe_bundle() -> void:
	_draw_handoff_asset(ASSET_PIPE_BUNDLE_ID, Rect2(Vector2(-306.0, -86.0), Vector2(244.0, 122.0)), Color(0.78, 0.92, 0.86, 0.52))
	_draw_lane([Vector2(-250.0, -112.0), Vector2(-202.0, -108.0), Vector2(-166.0, -72.0)], Color(0.82, 0.70, 0.36, 0.34), 7.0)
	_draw_lane([Vector2(-154.0, -22.0), Vector2(-214.0, 18.0), Vector2(-250.0, 18.0)], Color(0.54, 0.86, 0.52, 0.28), 6.0)
	_draw_lane([Vector2(-214.0, 18.0), Vector2(-140.0, 4.0), Vector2(-72.0, -42.0)], Color(0.92, 0.72, 0.34, 0.30), 6.0)


func _draw_device_assets() -> void:
	_draw_handoff_asset(ASSET_REACTOR_ID, Rect2(Vector2(-222.0, -146.0), Vector2(140.0, 118.0)), Color(1.0, 1.0, 1.0, 0.84))
	_draw_handoff_asset(ASSET_STORAGE_ID, Rect2(Vector2(-318.0, -34.0), Vector2(142.0, 116.0)), Color(1.0, 1.0, 1.0, 0.80))
	_draw_handoff_asset(ASSET_OUTFITTING_ID, Rect2(Vector2(-134.0, -94.0), Vector2(126.0, 116.0)), Color(1.0, 1.0, 1.0, 0.78))


func _draw_device_ports() -> void:
	for port in [
		{"position": Vector2(-250.0, -112.0), "color": Color(0.70, 0.82, 0.62, 0.64)},
		{"position": Vector2(-174.0, -94.0), "color": Color(1.0, 0.64, 0.30, 0.62)},
		{"position": Vector2(-246.0, 18.0), "color": Color(0.58, 0.90, 0.52, 0.58)},
		{"position": Vector2(-72.0, -42.0), "color": Color(0.96, 0.78, 0.34, 0.62)}
	]:
		var center := port["position"] as Vector2
		var color := port["color"] as Color
		draw_circle(center, 6.2, color)
		draw_arc(center, 12.0, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.28), 1.3, true)


func _draw_return_tray() -> void:
	var loaded := bool(handoff_state.get("inputs_ready", false))
	var tray := Rect2(Vector2(-278.0, -132.0), Vector2(60.0, 34.0))
	_draw_subject_rect(tray, Color(0.80, 0.78, 0.46, 0.34 if loaded else 0.14), loaded)
	for index in range(3):
		var center := Vector2(-264.0 + float(index) * 17.0, -114.0)
		draw_circle(center, 4.4, Color(0.46, 0.86, 0.90, 0.62 if loaded else 0.18))


func _draw_reactor_hopper() -> void:
	var active := bool(handoff_state.get("reactor_active", false))
	var armed := bool(handoff_state.get("inputs_ready", false)) or active
	var hopper := Rect2(Vector2(-196.0, -124.0), Vector2(46.0, 42.0))
	_draw_subject_rect(hopper, Color(1.0, 0.60, 0.26, 0.36 if armed else 0.12), armed)
	draw_line(Vector2(-190.0, -92.0), Vector2(-166.0, -70.0), Color(1.0, 0.62, 0.26, 0.42 if armed else 0.14), 3.0, true)
	if active:
		draw_arc(Vector2(-166.0, -66.0), 24.0, 0.0, TAU, 36, Color(0.48, 0.96, 0.90, 0.48), 2.0, true)


func _draw_storage_supply() -> void:
	var ready := bool(handoff_state.get("storage_ready", false))
	var supply := Rect2(Vector2(-292.0, 52.0), Vector2(104.0, 24.0))
	_draw_subject_rect(supply, Color(0.56, 0.90, 0.52, 0.34 if ready else 0.12), ready)
	for index in range(4):
		var pack := Rect2(Vector2(-280.0 + float(index) * 22.0, 58.0), Vector2(14.0, 10.0))
		draw_rect(pack, Color(0.58, 0.92, 0.52, 0.52 if ready else 0.16), true)


func _draw_outfitting_latch() -> void:
	var locked := bool(handoff_state.get("outfitting_ready", false))
	var latch := Rect2(Vector2(-122.0, -26.0), Vector2(78.0, 24.0))
	_draw_subject_rect(latch, Color(0.96, 0.76, 0.34, 0.34 if locked else 0.12), locked)
	for x in [-108.0, -82.0, -56.0]:
		draw_line(Vector2(x, -28.0), Vector2(x + 10.0, -4.0), Color(0.96, 0.76, 0.34, 0.56 if locked else 0.16), 2.2, true)


func _draw_stage_packets() -> void:
	var active_stage := get_active_stage()
	var packet_color := Color(0.96, 0.74, 0.28, 0.68)
	var points := _get_stage_points(active_stage)
	for index in range(points.size()):
		var center := points[index] as Vector2
		draw_circle(center, 4.6, packet_color)
		draw_circle(center + Vector2(4.0, -3.0), 2.4, Color(0.46, 0.92, 0.88, 0.52))


func _draw_subject_rect(rect: Rect2, color: Color, is_ready: bool) -> void:
	draw_rect(rect, Color(0.006, 0.014, 0.014, 0.78), true)
	draw_rect(rect.grow(-3.0), color, true)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.44 if is_ready else 0.18), false, 1.6, true)


func _draw_lane(points: Array, color: Color, width: float) -> void:
	var vector_points := PackedVector2Array()
	for point in points:
		vector_points.append(point)
	draw_polyline(vector_points, Color(0.006, 0.014, 0.014, 0.68), width + 6.0, true)
	draw_polyline(vector_points, Color(color.r, color.g, color.b, color.a * 0.40), width, true)
	draw_polyline(vector_points, color, 1.8, true)


func _draw_handoff_asset(asset_id: String, rect: Rect2, modulate: Color) -> void:
	var texture := _get_handoff_asset_texture(asset_id)
	if texture == null:
		return
	draw_texture_rect(texture, rect, false, modulate)


func _get_stage_points(active_stage: String) -> Array[Vector2]:
	match active_stage:
		STAGE_REACTOR_PROCESSING:
			return [Vector2(-184.0, -104.0), Vector2(-172.0, -86.0), Vector2(-166.0, -66.0)]
		STAGE_STORAGE_OUTPUT:
			return [Vector2(-154.0, -24.0), Vector2(-198.0, 8.0), Vector2(-250.0, 18.0)]
		STAGE_OUTFITTING_READY:
			return [Vector2(-214.0, 18.0), Vector2(-140.0, 4.0), Vector2(-72.0, -42.0)]
		STAGE_REACTOR_FEED:
			return [Vector2(-250.0, -112.0), Vector2(-202.0, -108.0), Vector2(-174.0, -94.0)]
		_:
			return [Vector2(-270.0, -118.0), Vector2(-250.0, -112.0), Vector2(-218.0, -104.0)]


func _get_handoff_asset_texture(asset_id: String) -> Texture2D:
	match asset_id:
		ASSET_FLOOR_ID:
			return ASSET_FLOOR
		ASSET_PIPE_BUNDLE_ID:
			return ASSET_PIPE_BUNDLE
		ASSET_REACTOR_ID:
			return ASSET_REACTOR
		ASSET_STORAGE_ID:
			return ASSET_STORAGE
		ASSET_OUTFITTING_ID:
			return ASSET_OUTFITTING
		_:
			return null


func _register_state_shape(shape_id: String) -> void:
	if handoff_state_shape_ids.has(shape_id):
		return
	handoff_state_shape_ids.append(shape_id)


func _is_handoff_available(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return world_state.quest_state.has_completed_quest(RESTORE_OUTPOST_QUEST_ID)


func _get_base_structure_for_definition(world_state: WorldState, building_id: String) -> Dictionary:
	if world_state == null:
		return {}
	for structure in world_state.base_structures.values():
		if not structure is Dictionary:
			continue
		if String(structure.get("definition_id", "")) == building_id:
			return structure
	return {}


func _has_first_path_output_context(world_state: WorldState) -> bool:
	var reactor_state := _get_base_structure_for_definition(world_state, "building.basic_reactor")
	var last_recipe_id := String(reactor_state.get("last_recipe_id", ""))
	return (
		last_recipe_id in ["recipe.process_crystal_ore", "recipe.repair_gel"]
		or _has_repair_gel_output_context(world_state)
	)


func _has_repair_gel_output_context(world_state: WorldState) -> bool:
	var reactor_state := _get_base_structure_for_definition(world_state, "building.basic_reactor")
	if String(reactor_state.get("last_recipe_id", "")) == "recipe.repair_gel":
		return true
	if world_state.quest_state.has_completed_quest("quest.prepare_treatment_supplies"):
		return true
	return world_state.quest_state.get_objective_progress(
		"quest.prepare_treatment_supplies",
		"craft_item",
		"item.repair_gel"
	) >= 1.0


func _resolve_active_stage(
	character_state: CharacterState,
	inputs_ready: bool,
	reactor_active: bool,
	storage_ready: bool,
	outfitting_ready: bool
) -> String:
	if outfitting_ready:
		return STAGE_OUTFITTING_READY
	if storage_ready:
		return STAGE_STORAGE_OUTPUT
	if reactor_active:
		return STAGE_REACTOR_PROCESSING
	if inputs_ready and character_state.position.distance_to(Vector2(-166.0, -66.0)) <= 96.0:
		return STAGE_REACTOR_FEED
	return STAGE_BASE_RECEIVING


func _state_suffix(is_ready: bool) -> String:
	return "ready" if is_ready else "idle"


func _get_player_position() -> Vector2:
	var parent_node := get_parent()
	if parent_node == null:
		return Vector2.ZERO
	var player := parent_node.get_node_or_null("Player") as Node2D
	if player == null:
		return Vector2.ZERO
	return player.position
