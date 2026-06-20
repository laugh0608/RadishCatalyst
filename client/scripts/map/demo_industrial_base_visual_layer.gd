extends Node2D
class_name DemoIndustrialBaseVisualLayer

const GENERATED_PREFIX := "DemoIndustrialBaseVisual"
const ROLE_DECK := "deck"
const ROLE_DEVICE := "device"
const ROLE_FLOW := "flow"
const ROLE_STATUS := "status"
const ROLE_CHAIN := "chain"

const DECK_LINE := Color(0.38, 0.64, 0.66, 0.34)
const DECK_FILL := Color(0.08, 0.16, 0.17, 0.18)
const DEVICE_FRAME := Color(0.72, 0.92, 0.88, 0.86)
const DEVICE_DIM := Color(0.36, 0.5, 0.48, 0.38)
const CORE_LIGHT := Color(0.28, 0.92, 0.96, 0.88)
const REACTOR_LIGHT := Color(0.98, 0.58, 0.2, 0.9)
const STORAGE_LIGHT := Color(0.58, 0.9, 0.68, 0.84)
const OUTFITTING_LIGHT := Color(0.94, 0.76, 0.28, 0.9)
const FILTER_LIGHT := Color(0.86, 0.92, 0.26, 0.82)
const PIPE_CRYSTAL := Color(0.3, 0.84, 0.94, 0.76)
const PIPE_PRODUCT := Color(0.58, 0.84, 0.52, 0.72)
const PIPE_OUTFITTING := Color(0.92, 0.72, 0.28, 0.78)
const PIPE_POLLUTION := Color(0.76, 0.72, 0.26, 0.74)
const CHAIN_DIM := Color(0.24, 0.32, 0.3, 0.42)
const CHAIN_READY := Color(0.92, 0.9, 0.42, 0.92)
const CHAIN_INPUT := Color(0.28, 0.84, 0.96, 0.94)
const CHAIN_PRODUCT := Color(0.64, 0.92, 0.56, 0.9)

const DEVICE_ANCHORS := {
	"device.outpost_core": "Interactables/OutpostCore",
	"device.basic_reactor": "Interactables/BasicReactor",
	"device.basic_storage": "Interactables/BasicStorageBuildSite",
	"device.field_outfitting_station": "Interactables/FieldOutfittingStation",
	"device.pollution_filter": "Interactables/PollutionFilter"
}

const LEGACY_DEVICE_BLOCKS := [
	"BaseCorePad",
	"BaseCoreObjectMarker",
	"BaseCoreToReactorFlowLine",
	"BaseReactorPad",
	"BaseReactorObjectMarker",
	"BaseReactorToExitFlowLine",
	"BaseOutfittingPad",
	"BaseOutfittingObjectMarker",
	"BaseOutfittingToExitFlowLine",
	"BaseStoragePad",
	"BaseStorageObjectMarker",
	"BaseSlurryBufferPad",
	"BaseSlurryBufferObjectMarker",
	"BaseSlurryBufferFlowLine",
	"BaseSupplyPad",
	"BaseSupplyObjectRail",
	"BaseSupplyReturnFlowLine"
]

const LEGACY_BASE_PANELS := [
	"BaseUpperServiceApron",
	"BaseCentralWorkYard",
	"BaseLowerLogisticsYard",
	"BaseDepartureCauseway",
	"BaseExitLane"
]

var applied_device_count := 0
var applied_flow_count := 0
var applied_chain_state_count := 0
var device_shape_ids: Array[String] = []
var flow_shape_ids: Array[String] = []
var chain_shape_ids: Array[String] = []
var chain_state: Dictionary = {}


func _ready() -> void:
	apply_visuals()


func apply_visuals() -> void:
	_clear_generated_nodes()
	_deemphasize_legacy_base_blocks()
	_mute_device_identity_blocks()
	_register_device_shapes()
	_register_flow_shapes()
	_tag_device_anchors()
	_tone_down_core_interactable_markers()
	queue_redraw()


func refresh_chain_state(world_state: WorldState, character_state: CharacterState) -> void:
	chain_shape_ids.clear()
	applied_chain_state_count = 0
	_tone_down_core_interactable_markers()
	if world_state == null or character_state == null:
		chain_state.clear()
		queue_redraw()
		return
	var inventory := character_state.inventory
	var reactor_state := _get_base_structure_for_definition(world_state, "building.basic_reactor")
	var active_recipe_id := String(reactor_state.get("active_recipe_id", ""))
	var reactor_active := String(reactor_state.get("status", "")) == "in_progress"
	chain_state = {
		"crystal_ready": inventory.has_ref("item.crystal_ore", 3),
		"salvage_ready": inventory.has_ref("item.salvage_scrap", 1),
		"parts_ready": inventory.has_ref("item.basic_parts", 1),
		"gel_ready": inventory.has_ref("item.repair_gel", 1),
		"station_ready": world_state.has_base_structure_definition("building.field_outfitting_station"),
		"reactor_active": reactor_active,
		"active_recipe_id": active_recipe_id
	}
	_register_chain_shape("chain.crystal_input.%s" % _state_suffix(bool(chain_state["crystal_ready"])))
	_register_chain_shape("chain.salvage_input.%s" % _state_suffix(bool(chain_state["salvage_ready"])))
	_register_chain_shape("chain.reactor_work_window.%s" % _state_suffix(reactor_active))
	_register_chain_shape("chain.storage_parts_slot.%s" % _state_suffix(bool(chain_state["parts_ready"])))
	_register_chain_shape("chain.storage_repair_gel_slot.%s" % _state_suffix(bool(chain_state["gel_ready"])))
	_register_chain_shape("chain.outfitting_supply_state.%s" % _state_suffix(bool(chain_state["station_ready"]) and bool(chain_state["gel_ready"])))
	queue_redraw()


func get_generated_shape_count() -> int:
	return device_shape_ids.size() + flow_shape_ids.size()


func has_device(device_id: String) -> bool:
	for shape_id in device_shape_ids:
		if shape_id.begins_with(device_id):
			return true
	return false


func get_flow_count() -> int:
	return applied_flow_count


func get_chain_state_shape_count() -> int:
	return applied_chain_state_count


func has_chain_shape(shape_id: String) -> bool:
	return chain_shape_ids.has(shape_id)


func _draw() -> void:
	_draw_base_deck()
	_draw_flow_network()
	_draw_outpost_core()
	_draw_basic_reactor()
	_draw_basic_storage()
	_draw_field_outfitting_station()
	_draw_pollution_filter()
	_draw_chain_state()


func _draw_base_deck() -> void:
	var base_rect := Rect2(Vector2(-336.0, -258.0), Vector2(282.0, 500.0))
	draw_rect(base_rect, DECK_FILL, true)
	draw_rect(base_rect, DECK_LINE, false, 2.0, true)
	for y in [-156.0, -24.0, 92.0, 184.0]:
		draw_line(Vector2(-326.0, y), Vector2(-64.0, y), Color(0.28, 0.48, 0.5, 0.24), 1.5, true)
	draw_line(Vector2(-70.0, -196.0), Vector2(-70.0, 172.0), Color(0.42, 0.62, 0.58, 0.42), 3.0, true)


func _draw_flow_network() -> void:
	_draw_pipe([Vector2(-278.0, -92.0), Vector2(-206.0, -92.0)], PIPE_CRYSTAL, 4.0)
	_draw_pipe([Vector2(-166.0, -28.0), Vector2(-166.0, 18.0), Vector2(-250.0, 18.0)], PIPE_PRODUCT, 4.0)
	_draw_pipe([Vector2(-144.0, -54.0), Vector2(-112.0, -54.0), Vector2(-44.0, -44.0)], PIPE_OUTFITTING, 4.0)
	_draw_pipe([Vector2(-282.0, 66.0), Vector2(-118.0, 66.0)], PIPE_PRODUCT, 3.0)
	_draw_pipe([Vector2(238.0, -116.0), Vector2(278.0, -116.0), Vector2(340.0, -104.0)], PIPE_POLLUTION, 4.0)
	for point in [Vector2(-278.0, -92.0), Vector2(-206.0, -92.0), Vector2(-250.0, 18.0), Vector2(-44.0, -44.0)]:
		draw_circle(point, 4.0, Color(0.86, 0.96, 0.9, 0.66))


func _draw_outpost_core() -> void:
	var center := Vector2(-300.0, -92.0)
	draw_circle(center, 22.0, Color(0.08, 0.26, 0.28, 0.5))
	draw_arc(center, 26.0, 0.0, TAU, 36, CORE_LIGHT, 2.8, true)
	draw_arc(center, 14.0, 0.0, TAU, 28, Color(0.7, 1.0, 0.96, 0.72), 2.0, true)
	draw_line(center + Vector2(0.0, -34.0), center + Vector2(0.0, -18.0), CORE_LIGHT, 3.0, true)
	draw_line(center + Vector2(-12.0, -32.0), center + Vector2(12.0, -32.0), CORE_LIGHT, 2.0, true)


func _draw_basic_reactor() -> void:
	var body := Rect2(Vector2(-190.0, -108.0), Vector2(54.0, 82.0))
	draw_rect(body, Color(0.16, 0.13, 0.08, 0.48), true)
	draw_rect(body, REACTOR_LIGHT, false, 2.5, true)
	draw_rect(Rect2(Vector2(-178.0, -94.0), Vector2(28.0, 56.0)), Color(0.96, 0.58, 0.22, 0.48), true)
	draw_rect(Rect2(Vector2(-178.0, -94.0), Vector2(28.0, 56.0)), Color(1.0, 0.78, 0.34, 0.82), false, 2.0, true)
	draw_rect(Rect2(Vector2(-212.0, -88.0), Vector2(16.0, 42.0)), DEVICE_FRAME, false, 2.0, true)
	draw_rect(Rect2(Vector2(-130.0, -82.0), Vector2(14.0, 36.0)), DEVICE_FRAME, false, 2.0, true)
	draw_line(Vector2(-176.0, -124.0), Vector2(-158.0, -124.0), Color(0.76, 0.62, 0.36, 0.8), 5.0, true)


func _draw_basic_storage() -> void:
	var body := Rect2(Vector2(-288.0, -20.0), Vector2(72.0, 72.0))
	draw_rect(body, Color(0.1, 0.22, 0.18, 0.42), true)
	draw_rect(body, STORAGE_LIGHT, false, 2.4, true)
	draw_line(Vector2(-282.0, 4.0), Vector2(-222.0, 4.0), STORAGE_LIGHT, 1.8, true)
	draw_line(Vector2(-282.0, 28.0), Vector2(-222.0, 28.0), STORAGE_LIGHT, 1.8, true)
	draw_rect(Rect2(Vector2(-276.0, -12.0), Vector2(20.0, 14.0)), Color(0.54, 0.86, 0.66, 0.54), true)
	draw_rect(Rect2(Vector2(-252.0, 10.0), Vector2(22.0, 14.0)), Color(0.54, 0.86, 0.66, 0.5), true)


func _draw_field_outfitting_station() -> void:
	var left := Vector2(-116.0, -82.0)
	var right := Vector2(-44.0, -82.0)
	draw_line(left, right, OUTFITTING_LIGHT, 3.0, true)
	draw_line(left, Vector2(-116.0, -8.0), OUTFITTING_LIGHT, 3.0, true)
	draw_line(right, Vector2(-44.0, -8.0), OUTFITTING_LIGHT, 3.0, true)
	draw_rect(Rect2(Vector2(-108.0, -56.0), Vector2(56.0, 24.0)), Color(0.34, 0.28, 0.14, 0.44), true)
	draw_rect(Rect2(Vector2(-108.0, -56.0), Vector2(56.0, 24.0)), OUTFITTING_LIGHT, false, 2.0, true)
	draw_circle(Vector2(-94.0, -68.0), 4.5, OUTFITTING_LIGHT)
	draw_circle(Vector2(-66.0, -68.0), 4.5, Color(0.72, 0.9, 1.0, 0.76))


func _draw_pollution_filter() -> void:
	var body := Rect2(Vector2(276.0, -138.0), Vector2(40.0, 58.0))
	draw_rect(body, Color(0.24, 0.3, 0.1, 0.46), true)
	draw_rect(body, FILTER_LIGHT, false, 2.0, true)
	draw_line(Vector2(286.0, -128.0), Vector2(286.0, -88.0), FILTER_LIGHT, 4.0, true)
	draw_line(Vector2(306.0, -128.0), Vector2(306.0, -88.0), FILTER_LIGHT, 4.0, true)
	draw_circle(Vector2(326.0, -132.0), 5.0, REACTOR_LIGHT)


func _draw_chain_state() -> void:
	if chain_state.is_empty():
		return
	_draw_status_pip(Vector2(-224.0, -108.0), bool(chain_state.get("crystal_ready", false)), CHAIN_INPUT)
	_draw_status_pip(Vector2(-224.0, -92.0), bool(chain_state.get("salvage_ready", false)), CHAIN_READY)
	_draw_status_pip(Vector2(-166.0, -66.0), bool(chain_state.get("reactor_active", false)), _reactor_state_color())
	_draw_status_pip(Vector2(-276.0, 58.0), bool(chain_state.get("parts_ready", false)), CHAIN_PRODUCT)
	_draw_status_pip(Vector2(-244.0, 58.0), bool(chain_state.get("gel_ready", false)), CHAIN_READY)
	_draw_status_pip(Vector2(-80.0, -20.0), bool(chain_state.get("station_ready", false)) and bool(chain_state.get("gel_ready", false)), CHAIN_READY)


func _draw_status_pip(position: Vector2, is_ready: bool, color: Color) -> void:
	draw_circle(position, 5.0, color if is_ready else CHAIN_DIM)
	draw_arc(position, 8.0, 0.0, TAU, 20, Color(color.r, color.g, color.b, 0.36), 1.4, true)


func _draw_pipe(points: Array[Vector2], color: Color, width: float) -> void:
	draw_polyline(PackedVector2Array(points), Color(0.02, 0.05, 0.05, 0.62), width + 3.0, true)
	draw_polyline(PackedVector2Array(points), color, width, true)


func _register_device_shapes() -> void:
	device_shape_ids = [
		"device.outpost_core.outline",
		"device.basic_reactor.outline",
		"device.basic_storage.outline",
		"device.field_outfitting_station.outline",
		"device.pollution_filter.outline"
	]
	applied_device_count = device_shape_ids.size()


func _register_flow_shapes() -> void:
	flow_shape_ids = [
		"flow.core_to_reactor",
		"flow.reactor_to_storage",
		"flow.reactor_to_outfitting",
		"flow.storage_supply_lane",
		"flow.pollution_to_filter"
	]
	applied_flow_count = flow_shape_ids.size()


func _register_chain_shape(shape_id: String) -> void:
	if chain_shape_ids.has(shape_id):
		return
	chain_shape_ids.append(shape_id)
	applied_chain_state_count = chain_shape_ids.size()


func _get_base_structure_for_definition(world_state: WorldState, building_id: String) -> Dictionary:
	for structure in world_state.base_structures.values():
		if not structure is Dictionary:
			continue
		if String(structure.get("definition_id", "")) == building_id:
			return structure
	return {}


func _state_suffix(is_ready: bool) -> String:
	return "ready" if is_ready else "idle"


func _reactor_state_color() -> Color:
	return CHAIN_READY if String(chain_state.get("active_recipe_id", "")) == "recipe.repair_gel" else REACTOR_LIGHT


func _tag_device_anchors() -> void:
	for device_id in DEVICE_ANCHORS.keys():
		var node := _get_map_node(String(DEVICE_ANCHORS[device_id]))
		if node == null:
			continue
		node.set_meta("industrial_base_device_id", device_id)
		node.set_meta("industrial_base_visual_role", ROLE_DEVICE)


func _tone_down_core_interactable_markers() -> void:
	for path in DEVICE_ANCHORS.values():
		var interactable := _get_map_node(String(path)) as PrototypeInteractable
		if interactable == null:
			continue
		if interactable.marker != null:
			interactable.marker.color.a = 0.08


func _deemphasize_legacy_base_blocks() -> void:
	var layer := _get_map_node("OpeningSceneLayer")
	if layer == null:
		return
	for node_name in LEGACY_DEVICE_BLOCKS:
		var rect := layer.get_node_or_null(String(node_name)) as ColorRect
		if rect != null:
			rect.color.a = minf(rect.color.a, 0.045)
	for node_name in LEGACY_BASE_PANELS:
		var rect := layer.get_node_or_null(String(node_name)) as ColorRect
		if rect != null:
			rect.color.a = minf(rect.color.a, 0.14)


func _mute_device_identity_blocks() -> void:
	var identity_layer := _get_map_node("DemoInitialArtIdentityLayer")
	if identity_layer == null:
		return
	for child in identity_layer.get_children():
		if not child.has_meta("initial_art_role"):
			continue
		if String(child.get_meta("initial_art_role", "")) == DemoInitialArtIdentityProfile.ROLE_DEVICE:
			child.visible = false


func _get_map_node(path: String) -> Node:
	if path.is_empty() or get_parent() == null:
		return null
	return get_parent().get_node_or_null(path)


func _clear_generated_nodes() -> void:
	for child in get_children():
		if not String(child.name).begins_with(GENERATED_PREFIX):
			continue
		remove_child(child)
		child.free()
