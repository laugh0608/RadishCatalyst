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
const DEVICE_PANEL := Color(0.28, 0.46, 0.44, 0.48)
const DEVICE_DARK := Color(0.04, 0.08, 0.085, 0.72)
const FLOOR_GRATE := Color(0.36, 0.54, 0.52, 0.2)
const MAINTENANCE_LINE := Color(0.76, 0.72, 0.34, 0.48)
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
const CHAIN_WINDOW := Color(1.0, 0.62, 0.24, 0.86)
const CHAIN_POLLUTION := Color(0.82, 0.78, 0.25, 0.88)
const CHAIN_SOLVENT := Color(0.36, 0.74, 0.86, 0.84)
const CHAIN_SLURRY := Color(0.78, 0.42, 0.18, 0.82)
const CHAIN_VIAL := Color(0.72, 0.92, 0.38, 0.9)
const CHAIN_CORE_PREP := Color(0.74, 0.58, 0.9, 0.88)
const CHAIN_ROUTE_DARK := Color(0.02, 0.04, 0.035, 0.72)

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
var detail_shape_ids: Array[String] = []
var pollution_chain_shape_ids: Array[String] = []
var chain_state: Dictionary = {}
var pollution_chain_state: Dictionary = {}
var applied_pollution_chain_state_count := 0


func _ready() -> void:
	apply_visuals()


func apply_visuals() -> void:
	_clear_generated_nodes()
	_deemphasize_legacy_base_blocks()
	_mute_device_identity_blocks()
	_register_device_shapes()
	_register_device_detail_shapes()
	_register_flow_shapes()
	_tag_device_anchors()
	_tone_down_core_interactable_markers()
	queue_redraw()


func refresh_chain_state(world_state: WorldState, character_state: CharacterState) -> void:
	chain_shape_ids.clear()
	pollution_chain_shape_ids.clear()
	applied_chain_state_count = 0
	applied_pollution_chain_state_count = 0
	_tone_down_core_interactable_markers()
	if world_state == null or character_state == null:
		chain_state.clear()
		pollution_chain_state.clear()
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
	_register_chain_shape("chain.input_crystal_bin.%s" % _state_suffix(bool(chain_state["crystal_ready"])))
	_register_chain_shape("chain.input_salvage_bin.%s" % _state_suffix(bool(chain_state["salvage_ready"])))
	_register_chain_shape("chain.reactor_feed_lane.%s" % _state_suffix(bool(chain_state["crystal_ready"]) or bool(chain_state["salvage_ready"])))
	_register_chain_shape("chain.reactor_process_core.%s" % _state_suffix(reactor_active))
	_register_chain_shape("chain.parts_output_tray.%s" % _state_suffix(bool(chain_state["parts_ready"])))
	_register_chain_shape("chain.repair_gel_cylinder.%s" % _state_suffix(bool(chain_state["gel_ready"])))
	_register_chain_shape("chain.outfitting_launch_bus.%s" % _state_suffix(bool(chain_state["station_ready"]) and bool(chain_state["gel_ready"])))
	_refresh_pollution_chain_visual_state(world_state, character_state)
	queue_redraw()


func refresh_pollution_chain_state(world_state: WorldState, character_state: CharacterState) -> void:
	pollution_chain_shape_ids.clear()
	applied_pollution_chain_state_count = 0
	_refresh_pollution_chain_visual_state(world_state, character_state)
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


func get_detail_shape_count() -> int:
	return detail_shape_ids.size()


func has_detail_shape(shape_id: String) -> bool:
	return detail_shape_ids.has(shape_id)


func get_chain_state_shape_count() -> int:
	return applied_chain_state_count


func has_chain_shape(shape_id: String) -> bool:
	return chain_shape_ids.has(shape_id)


func get_pollution_chain_state_shape_count() -> int:
	return applied_pollution_chain_state_count


func has_pollution_chain_shape(shape_id: String) -> bool:
	return pollution_chain_shape_ids.has(shape_id)


func _draw() -> void:
	_draw_base_deck()
	_draw_base_detail()
	_draw_flow_network()
	_draw_outpost_core()
	_draw_basic_reactor()
	_draw_basic_storage()
	_draw_field_outfitting_station()
	_draw_departure_gate()
	_draw_pollution_filter()
	_draw_chain_state()
	_draw_pollution_chain_state()


func _draw_base_deck() -> void:
	var base_rect := Rect2(Vector2(-336.0, -258.0), Vector2(282.0, 500.0))
	draw_rect(base_rect, DECK_FILL, true)
	draw_rect(base_rect, DECK_LINE, false, 2.0, true)
	for y in [-156.0, -24.0, 92.0, 184.0]:
		draw_line(Vector2(-326.0, y), Vector2(-64.0, y), Color(0.28, 0.48, 0.5, 0.24), 1.5, true)
	draw_line(Vector2(-70.0, -196.0), Vector2(-70.0, 172.0), Color(0.42, 0.62, 0.58, 0.42), 3.0, true)


func _draw_base_detail() -> void:
	for x in [-314.0, -282.0, -250.0, -218.0, -186.0, -154.0, -122.0, -90.0]:
		draw_line(Vector2(x, -244.0), Vector2(x, 226.0), FLOOR_GRATE, 1.0, true)
	for y in [-226.0, -194.0, -120.0, 44.0, 132.0, 220.0]:
		draw_line(Vector2(-326.0, y), Vector2(-82.0, y), FLOOR_GRATE, 1.0, true)
	_draw_hazard_stripe(Vector2(-88.0, -210.0), Vector2(-88.0, 180.0))
	_draw_hazard_stripe(Vector2(-72.0, -210.0), Vector2(-72.0, 180.0))
	draw_rect(Rect2(Vector2(-318.0, -138.0), Vector2(42.0, 18.0)), DEVICE_PANEL, true)
	draw_rect(Rect2(Vector2(-304.0, 116.0), Vector2(78.0, 16.0)), DEVICE_PANEL, true)


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
	draw_arc(center, 34.0, PI * 0.15, PI * 1.85, 36, Color(0.56, 0.92, 0.9, 0.34), 3.0, true)
	draw_arc(center, 26.0, 0.0, TAU, 36, CORE_LIGHT, 2.8, true)
	draw_arc(center, 14.0, 0.0, TAU, 28, Color(0.7, 1.0, 0.96, 0.72), 2.0, true)
	draw_line(center + Vector2(0.0, -34.0), center + Vector2(0.0, -18.0), CORE_LIGHT, 3.0, true)
	draw_line(center + Vector2(-12.0, -32.0), center + Vector2(12.0, -32.0), CORE_LIGHT, 2.0, true)
	draw_rect(Rect2(center + Vector2(-44.0, 18.0), Vector2(28.0, 18.0)), DEVICE_PANEL, true)
	draw_rect(Rect2(center + Vector2(-44.0, 18.0), Vector2(28.0, 18.0)), CORE_LIGHT, false, 1.4, true)
	draw_line(center + Vector2(26.0, 0.0), center + Vector2(52.0, 0.0), PIPE_CRYSTAL, 4.0, true)


func _draw_basic_reactor() -> void:
	var body := Rect2(Vector2(-190.0, -108.0), Vector2(54.0, 82.0))
	draw_rect(body, Color(0.16, 0.13, 0.08, 0.48), true)
	draw_rect(body, REACTOR_LIGHT, false, 2.5, true)
	draw_rect(Rect2(Vector2(-184.0, -102.0), Vector2(42.0, 70.0)), DEVICE_DARK, true)
	draw_rect(Rect2(Vector2(-178.0, -94.0), Vector2(28.0, 56.0)), Color(0.96, 0.58, 0.22, 0.48), true)
	draw_rect(Rect2(Vector2(-178.0, -94.0), Vector2(28.0, 56.0)), Color(1.0, 0.78, 0.34, 0.82), false, 2.0, true)
	draw_rect(Rect2(Vector2(-212.0, -88.0), Vector2(16.0, 42.0)), DEVICE_FRAME, false, 2.0, true)
	draw_rect(Rect2(Vector2(-130.0, -82.0), Vector2(14.0, 36.0)), DEVICE_FRAME, false, 2.0, true)
	draw_line(Vector2(-176.0, -124.0), Vector2(-158.0, -124.0), Color(0.76, 0.62, 0.36, 0.8), 5.0, true)
	for y in [-88.0, -76.0, -64.0, -52.0]:
		draw_line(Vector2(-176.0, y), Vector2(-150.0, y + 8.0), Color(1.0, 0.78, 0.34, 0.34), 1.3, true)
	draw_rect(Rect2(Vector2(-208.0, -118.0), Vector2(28.0, 14.0)), Color(0.3, 0.72, 0.84, 0.42), true)
	draw_rect(Rect2(Vector2(-142.0, -40.0), Vector2(28.0, 14.0)), Color(0.64, 0.9, 0.56, 0.42), true)


func _draw_basic_storage() -> void:
	var body := Rect2(Vector2(-288.0, -20.0), Vector2(72.0, 72.0))
	draw_rect(body, Color(0.1, 0.22, 0.18, 0.42), true)
	draw_rect(body, STORAGE_LIGHT, false, 2.4, true)
	draw_line(Vector2(-282.0, 4.0), Vector2(-222.0, 4.0), STORAGE_LIGHT, 1.8, true)
	draw_line(Vector2(-282.0, 28.0), Vector2(-222.0, 28.0), STORAGE_LIGHT, 1.8, true)
	draw_rect(Rect2(Vector2(-276.0, -12.0), Vector2(20.0, 14.0)), Color(0.54, 0.86, 0.66, 0.54), true)
	draw_rect(Rect2(Vector2(-252.0, 10.0), Vector2(22.0, 14.0)), Color(0.54, 0.86, 0.66, 0.5), true)
	draw_rect(Rect2(Vector2(-276.0, 32.0), Vector2(18.0, 10.0)), Color(0.9, 0.76, 0.34, 0.48), true)
	draw_circle(Vector2(-232.0, 40.0), 5.0, Color(0.86, 0.96, 0.68, 0.56))
	draw_line(Vector2(-216.0, 12.0), Vector2(-196.0, 12.0), PIPE_PRODUCT, 3.0, true)


func _draw_field_outfitting_station() -> void:
	var left := Vector2(-116.0, -82.0)
	var right := Vector2(-44.0, -82.0)
	draw_line(left, right, OUTFITTING_LIGHT, 3.0, true)
	draw_line(left, Vector2(-116.0, -8.0), OUTFITTING_LIGHT, 3.0, true)
	draw_line(right, Vector2(-44.0, -8.0), OUTFITTING_LIGHT, 3.0, true)
	draw_rect(Rect2(Vector2(-108.0, -56.0), Vector2(56.0, 24.0)), Color(0.34, 0.28, 0.14, 0.44), true)
	draw_rect(Rect2(Vector2(-108.0, -56.0), Vector2(56.0, 24.0)), OUTFITTING_LIGHT, false, 2.0, true)
	draw_rect(Rect2(Vector2(-102.0, -78.0), Vector2(14.0, 20.0)), DEVICE_PANEL, true)
	draw_rect(Rect2(Vector2(-78.0, -78.0), Vector2(14.0, 20.0)), DEVICE_PANEL, true)
	draw_line(Vector2(-102.0, -22.0), Vector2(-58.0, -22.0), Color(0.72, 0.62, 0.36, 0.58), 3.0, true)
	draw_circle(Vector2(-94.0, -68.0), 4.5, OUTFITTING_LIGHT)
	draw_circle(Vector2(-66.0, -68.0), 4.5, Color(0.72, 0.9, 1.0, 0.76))


func _draw_departure_gate() -> void:
	var gate := Rect2(Vector2(-44.0, -202.0), Vector2(18.0, 380.0))
	draw_rect(gate, Color(0.08, 0.18, 0.16, 0.32), true)
	draw_rect(gate, Color(0.62, 0.84, 0.66, 0.58), false, 2.0, true)
	for y in [-164.0, -98.0, -32.0, 34.0, 100.0, 156.0]:
		draw_line(Vector2(-42.0, y), Vector2(-28.0, y), Color(0.82, 0.76, 0.38, 0.52), 2.0, true)
	draw_line(Vector2(-54.0, -44.0), Vector2(-30.0, -44.0), PIPE_OUTFITTING, 4.0, true)


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
	var crystal_ready := bool(chain_state.get("crystal_ready", false))
	var salvage_ready := bool(chain_state.get("salvage_ready", false))
	var reactor_active := bool(chain_state.get("reactor_active", false))
	var parts_ready := bool(chain_state.get("parts_ready", false))
	var gel_ready := bool(chain_state.get("gel_ready", false))
	var outfitting_ready := bool(chain_state.get("station_ready", false)) and gel_ready
	_draw_chain_input_slots(crystal_ready, salvage_ready)
	_draw_chain_flow_band([Vector2(-214.0, -112.0), Vector2(-196.0, -112.0), Vector2(-184.0, -92.0)], crystal_ready, CHAIN_INPUT, 5.0)
	_draw_chain_flow_band([Vector2(-214.0, -84.0), Vector2(-196.0, -84.0), Vector2(-184.0, -72.0)], salvage_ready, CHAIN_READY, 4.0)
	_draw_reactor_process_core(reactor_active)
	_draw_chain_flow_band([Vector2(-148.0, -38.0), Vector2(-170.0, 10.0), Vector2(-222.0, 18.0)], parts_ready or gel_ready, CHAIN_PRODUCT, 5.0)
	_draw_storage_outputs(parts_ready, gel_ready)
	_draw_chain_flow_band([Vector2(-220.0, 54.0), Vector2(-128.0, 54.0), Vector2(-74.0, -12.0), Vector2(-44.0, -40.0)], outfitting_ready, CHAIN_READY, 4.0)
	_draw_outfitting_supply_state(outfitting_ready)
	_draw_status_pip(Vector2(-224.0, -108.0), crystal_ready, CHAIN_INPUT)
	_draw_status_pip(Vector2(-224.0, -92.0), salvage_ready, CHAIN_READY)
	_draw_status_pip(Vector2(-166.0, -66.0), reactor_active, _reactor_state_color())
	_draw_status_pip(Vector2(-276.0, 58.0), parts_ready, CHAIN_PRODUCT)
	_draw_status_pip(Vector2(-244.0, 58.0), gel_ready, CHAIN_READY)
	_draw_status_pip(Vector2(-80.0, -20.0), outfitting_ready, CHAIN_READY)


func _draw_chain_input_slots(crystal_ready: bool, salvage_ready: bool) -> void:
	var crystal_slot := Rect2(Vector2(-228.0, -124.0), Vector2(28.0, 18.0))
	var salvage_slot := Rect2(Vector2(-228.0, -94.0), Vector2(28.0, 18.0))
	_draw_chain_slot(crystal_slot, crystal_ready, CHAIN_INPUT)
	_draw_chain_slot(salvage_slot, salvage_ready, CHAIN_READY)
	draw_line(Vector2(-220.0, -120.0), Vector2(-208.0, -110.0), _state_color(CHAIN_INPUT, crystal_ready, 0.78, 0.18), 2.0, true)
	draw_line(Vector2(-216.0, -90.0), Vector2(-204.0, -82.0), _state_color(CHAIN_READY, salvage_ready, 0.72, 0.18), 2.0, true)
	draw_rect(Rect2(Vector2(-242.0, -116.0), Vector2(10.0, 8.0)), _state_color(CHAIN_INPUT, crystal_ready, 0.52, 0.14), true)
	draw_rect(Rect2(Vector2(-242.0, -88.0), Vector2(10.0, 8.0)), _state_color(CHAIN_READY, salvage_ready, 0.52, 0.14), true)


func _draw_reactor_process_core(is_active: bool) -> void:
	var color := _reactor_state_color()
	var window := Rect2(Vector2(-176.0, -88.0), Vector2(24.0, 44.0))
	draw_rect(window.grow(4.0), _state_color(color, is_active, 0.18, 0.06), true)
	draw_rect(window, _state_color(CHAIN_WINDOW, is_active, 0.52, 0.16), true)
	draw_rect(window, _state_color(color, is_active, 0.86, 0.26), false, 2.0, true)
	for y in [-80.0, -68.0, -56.0]:
		draw_line(Vector2(-172.0, y), Vector2(-156.0, y + 7.0), _state_color(color, is_active, 0.74, 0.2), 1.8, true)
	draw_arc(Vector2(-164.0, -66.0), 19.0, PI * 0.1, PI * 1.65, 32, _state_color(color, is_active, 0.44, 0.12), 2.0, true)


func _draw_storage_outputs(parts_ready: bool, gel_ready: bool) -> void:
	var parts_tray := Rect2(Vector2(-282.0, 48.0), Vector2(24.0, 16.0))
	var gel_tube := Rect2(Vector2(-250.0, 46.0), Vector2(16.0, 22.0))
	_draw_chain_slot(parts_tray, parts_ready, CHAIN_PRODUCT)
	draw_rect(Rect2(Vector2(-276.0, 52.0), Vector2(6.0, 6.0)), _state_color(CHAIN_PRODUCT, parts_ready, 0.84, 0.2), true)
	draw_rect(Rect2(Vector2(-268.0, 52.0), Vector2(6.0, 6.0)), _state_color(CHAIN_PRODUCT, parts_ready, 0.72, 0.18), true)
	draw_rect(gel_tube, _state_color(CHAIN_READY, gel_ready, 0.22, 0.08), true)
	draw_rect(gel_tube, _state_color(CHAIN_READY, gel_ready, 0.84, 0.22), false, 1.6, true)
	draw_line(gel_tube.position + Vector2(3.0, 5.0), gel_tube.position + Vector2(13.0, 5.0), _state_color(CHAIN_READY, gel_ready, 0.86, 0.16), 2.0, true)
	draw_line(gel_tube.position + Vector2(3.0, 15.0), gel_tube.position + Vector2(13.0, 15.0), _state_color(CHAIN_READY, gel_ready, 0.66, 0.12), 2.0, true)


func _draw_outfitting_supply_state(is_ready: bool) -> void:
	var color := _state_color(CHAIN_READY, is_ready, 0.86, 0.18)
	draw_rect(Rect2(Vector2(-98.0, -18.0), Vector2(36.0, 12.0)), _state_color(CHAIN_READY, is_ready, 0.28, 0.08), true)
	draw_rect(Rect2(Vector2(-98.0, -18.0), Vector2(36.0, 12.0)), color, false, 1.6, true)
	for x in [-92.0, -80.0, -68.0]:
		draw_line(Vector2(x, -18.0), Vector2(x + 7.0, -6.0), color, 1.4, true)
	draw_line(Vector2(-46.0, -40.0), Vector2(-30.0, -40.0), color, 3.0, true)


func _draw_chain_slot(rect: Rect2, is_ready: bool, color: Color) -> void:
	draw_rect(rect, Color(0.02, 0.04, 0.035, 0.56), true)
	draw_rect(rect, _state_color(color, is_ready, 0.26, 0.08), true)
	draw_rect(rect, _state_color(color, is_ready, 0.86, 0.22), false, 1.5, true)


func _draw_chain_flow_band(points: Array[Vector2], is_ready: bool, color: Color, width: float) -> void:
	draw_polyline(PackedVector2Array(points), CHAIN_ROUTE_DARK, width + 3.0, true)
	draw_polyline(PackedVector2Array(points), _state_color(color, is_ready, 0.68, 0.14), width, true)
	for point in points:
		draw_circle(point, width * 0.55, _state_color(color, is_ready, 0.74, 0.14))


func _refresh_pollution_chain_visual_state(world_state: WorldState, character_state: CharacterState) -> void:
	if world_state == null or character_state == null:
		pollution_chain_state.clear()
		return
	var inventory := character_state.inventory
	if not _has_pollution_chain_context(world_state, inventory):
		pollution_chain_state.clear()
		return
	var filter_state := _get_base_structure_for_definition(world_state, "building.pollution_filter")
	var reactor_state := _get_base_structure_for_definition(world_state, "building.basic_reactor")
	var filter_active := (
		String(filter_state.get("status", "")) == "in_progress"
		and String(filter_state.get("active_recipe_id", "")) == "recipe.cleanse_residue"
	)
	var reclaim_active := (
		String(reactor_state.get("status", "")) == "in_progress"
		and String(reactor_state.get("active_recipe_id", "")) == "recipe.reclaim_basic_parts"
	)
	var core_prep_active := (
		String(reactor_state.get("status", "")) == "in_progress"
		and String(reactor_state.get("active_recipe_id", "")) == "recipe.core_stabilization_buffer"
	)
	var residue_ready := inventory.has_ref("item.polluted_residue", 2)
	var solvent_ready := inventory.has_ref("fluid.basic_solvent", 1.0)
	var vial_ready := inventory.has_ref("item.resistance_vial_t1", 1)
	var slurry_ready := inventory.has_ref("fluid.polluted_slurry", 1.0)
	var core_prep_ready := (
		inventory.has_ref("item.repair_gel", 1)
		and inventory.has_ref("item.resistance_vial_t1", 1)
		and inventory.has_ref("fluid.polluted_slurry", 1.0)
		and inventory.has_ref("item.basic_parts", 2)
	)
	pollution_chain_state = {
		"residue_ready": residue_ready,
		"solvent_ready": solvent_ready,
		"filter_ready": world_state.has_base_structure_definition("building.pollution_filter") and residue_ready and solvent_ready,
		"filter_active": filter_active,
		"vial_ready": vial_ready,
		"slurry_ready": slurry_ready,
		"slurry_buffer_ready": world_state.has_base_structure_definition("building.slurry_buffer_tank"),
		"recycle_ready": slurry_ready and world_state.has_base_structure_definition("building.basic_reactor"),
		"reclaim_active": reclaim_active,
		"core_prep_ready": core_prep_ready,
		"core_prep_active": core_prep_active
	}
	_register_pollution_chain_shape("pollution_chain.residue_input_slot.%s" % _state_suffix(residue_ready))
	_register_pollution_chain_shape("pollution_chain.solvent_input_slot.%s" % _state_suffix(solvent_ready))
	_register_pollution_chain_shape("pollution_chain.filter_process_window.%s" % _state_suffix(filter_active))
	_register_pollution_chain_shape("pollution_chain.vial_output_slot.%s" % _state_suffix(vial_ready))
	_register_pollution_chain_shape("pollution_chain.slurry_byproduct_slot.%s" % _state_suffix(slurry_ready))
	_register_pollution_chain_shape("pollution_chain.vial_to_outfitting_route.%s" % _state_suffix(vial_ready or filter_active))
	_register_pollution_chain_shape("pollution_chain.slurry_return_route.%s" % _state_suffix(slurry_ready or filter_active))
	_register_pollution_chain_shape("pollution_chain.slurry_recycle_route.%s" % _state_suffix(bool(pollution_chain_state["recycle_ready"]) or reclaim_active))
	_register_pollution_chain_shape("pollution_chain.core_prep_route.%s" % _state_suffix(core_prep_ready or core_prep_active))


func _draw_pollution_chain_state() -> void:
	if pollution_chain_state.is_empty():
		return
	var residue_ready := bool(pollution_chain_state.get("residue_ready", false))
	var solvent_ready := bool(pollution_chain_state.get("solvent_ready", false))
	var filter_ready := bool(pollution_chain_state.get("filter_ready", false))
	var filter_active := bool(pollution_chain_state.get("filter_active", false))
	var vial_ready := bool(pollution_chain_state.get("vial_ready", false))
	var slurry_ready := bool(pollution_chain_state.get("slurry_ready", false))
	var slurry_buffer_ready := bool(pollution_chain_state.get("slurry_buffer_ready", false))
	var recycle_ready := bool(pollution_chain_state.get("recycle_ready", false))
	var reclaim_active := bool(pollution_chain_state.get("reclaim_active", false))
	var core_prep_ready := bool(pollution_chain_state.get("core_prep_ready", false))
	var core_prep_active := bool(pollution_chain_state.get("core_prep_active", false))
	_draw_pollution_input_slots(residue_ready, solvent_ready)
	_draw_chain_flow_band([Vector2(258.0, 34.0), Vector2(278.0, -18.0), Vector2(288.0, -84.0)], residue_ready or filter_ready or filter_active, CHAIN_POLLUTION, 4.0)
	_draw_chain_flow_band([Vector2(-250.0, 18.0), Vector2(-88.0, 18.0), Vector2(160.0, -58.0), Vector2(288.0, -104.0)], solvent_ready, CHAIN_SOLVENT, 3.2)
	_draw_filter_process_window(filter_ready, filter_active)
	_draw_pollution_outputs(vial_ready, slurry_ready)
	_draw_chain_flow_band([Vector2(334.0, -124.0), Vector2(222.0, -108.0), Vector2(106.0, -84.0), Vector2(-44.0, -44.0)], vial_ready or filter_active, CHAIN_VIAL, 4.0)
	_draw_chain_flow_band([Vector2(334.0, -96.0), Vector2(240.0, 44.0), Vector2(72.0, 98.0), Vector2(-130.0, 120.0)], slurry_ready or filter_active, CHAIN_SLURRY, 3.8)
	_draw_pollution_slurry_buffer_state(slurry_ready, slurry_buffer_ready)
	_draw_chain_flow_band([Vector2(-130.0, 120.0), Vector2(-166.0, 42.0), Vector2(-166.0, -26.0)], recycle_ready or reclaim_active, CHAIN_PRODUCT, 3.6)
	_draw_chain_flow_band([Vector2(-130.0, 120.0), Vector2(-98.0, 78.0), Vector2(-74.0, -12.0), Vector2(-44.0, -40.0)], core_prep_ready or core_prep_active, CHAIN_CORE_PREP, 3.6)
	_draw_status_pip(Vector2(256.0, -102.0), residue_ready, CHAIN_POLLUTION)
	_draw_status_pip(Vector2(256.0, -78.0), solvent_ready, CHAIN_SOLVENT)
	_draw_status_pip(Vector2(300.0, -110.0), filter_active, FILTER_LIGHT)
	_draw_status_pip(Vector2(348.0, -124.0), vial_ready, CHAIN_VIAL)
	_draw_status_pip(Vector2(348.0, -96.0), slurry_ready, CHAIN_SLURRY)
	_draw_status_pip(Vector2(-130.0, 120.0), slurry_ready, CHAIN_SLURRY)
	_draw_status_pip(Vector2(-166.0, -26.0), recycle_ready or reclaim_active, CHAIN_PRODUCT)
	_draw_status_pip(Vector2(-52.0, -40.0), core_prep_ready or core_prep_active, CHAIN_CORE_PREP)


func _draw_pollution_input_slots(residue_ready: bool, solvent_ready: bool) -> void:
	var residue_slot := Rect2(Vector2(244.0, -112.0), Vector2(28.0, 18.0))
	var solvent_slot := Rect2(Vector2(244.0, -88.0), Vector2(28.0, 18.0))
	_draw_chain_slot(residue_slot, residue_ready, CHAIN_POLLUTION)
	_draw_chain_slot(solvent_slot, solvent_ready, CHAIN_SOLVENT)
	draw_circle(Vector2(252.0, -103.0), 3.2, _state_color(CHAIN_POLLUTION, residue_ready, 0.84, 0.16))
	draw_circle(Vector2(264.0, -103.0), 3.2, _state_color(CHAIN_POLLUTION, residue_ready, 0.66, 0.14))
	draw_line(Vector2(250.0, -80.0), Vector2(266.0, -80.0), _state_color(CHAIN_SOLVENT, solvent_ready, 0.86, 0.16), 2.2, true)
	draw_line(Vector2(258.0, -86.0), Vector2(258.0, -74.0), _state_color(CHAIN_SOLVENT, solvent_ready, 0.7, 0.12), 2.0, true)


func _draw_filter_process_window(filter_ready: bool, filter_active: bool) -> void:
	var process_color := FILTER_LIGHT if filter_active else CHAIN_POLLUTION
	var window := Rect2(Vector2(286.0, -130.0), Vector2(24.0, 44.0))
	draw_rect(window.grow(4.0), _state_color(process_color, filter_ready or filter_active, 0.18, 0.06), true)
	draw_rect(window, _state_color(CHAIN_WINDOW, filter_active, 0.5, 0.12), true)
	draw_rect(window, _state_color(process_color, filter_active, 0.86, 0.28), false, 1.8, true)
	for y in [-122.0, -110.0, -98.0]:
		draw_line(Vector2(290.0, y), Vector2(306.0, y + 6.0), _state_color(process_color, filter_active, 0.72, 0.18), 1.6, true)


func _draw_pollution_outputs(vial_ready: bool, slurry_ready: bool) -> void:
	var vial_slot := Rect2(Vector2(322.0, -132.0), Vector2(26.0, 18.0))
	var slurry_slot := Rect2(Vector2(322.0, -104.0), Vector2(26.0, 18.0))
	_draw_chain_slot(vial_slot, vial_ready, CHAIN_VIAL)
	draw_line(Vector2(328.0, -128.0), Vector2(342.0, -118.0), _state_color(CHAIN_VIAL, vial_ready, 0.82, 0.16), 2.0, true)
	draw_line(Vector2(342.0, -128.0), Vector2(328.0, -118.0), _state_color(CHAIN_VIAL, vial_ready, 0.64, 0.12), 2.0, true)
	_draw_chain_slot(slurry_slot, slurry_ready, CHAIN_SLURRY)
	draw_circle(Vector2(330.0, -95.0), 3.0, _state_color(CHAIN_SLURRY, slurry_ready, 0.86, 0.16))
	draw_circle(Vector2(340.0, -95.0), 3.0, _state_color(CHAIN_SLURRY, slurry_ready, 0.66, 0.12))


func _draw_pollution_slurry_buffer_state(slurry_ready: bool, slurry_buffer_ready: bool) -> void:
	var tank := Rect2(Vector2(-148.0, 104.0), Vector2(36.0, 32.0))
	draw_rect(tank, Color(0.05, 0.06, 0.035, 0.5), true)
	draw_rect(tank, _state_color(CHAIN_SLURRY, slurry_ready or slurry_buffer_ready, 0.52, 0.16), false, 1.8, true)
	draw_line(Vector2(-140.0, 112.0), Vector2(-120.0, 112.0), _state_color(CHAIN_SLURRY, slurry_ready, 0.7, 0.12), 2.0, true)
	draw_line(Vector2(-140.0, 124.0), Vector2(-120.0, 124.0), _state_color(CHAIN_SLURRY, slurry_ready, 0.54, 0.1), 2.0, true)
	draw_circle(Vector2(-112.0, 120.0), 4.0, _state_color(CHAIN_SLURRY, slurry_ready, 0.76, 0.14))


func _draw_status_pip(position: Vector2, is_ready: bool, color: Color) -> void:
	draw_circle(position, 5.0, color if is_ready else CHAIN_DIM)
	draw_arc(position, 8.0, 0.0, TAU, 20, Color(color.r, color.g, color.b, 0.36), 1.4, true)


func _state_color(color: Color, is_ready: bool, ready_alpha: float, idle_alpha: float) -> Color:
	return Color(color.r, color.g, color.b, ready_alpha if is_ready else idle_alpha)


func _draw_pipe(points: Array[Vector2], color: Color, width: float) -> void:
	draw_polyline(PackedVector2Array(points), Color(0.02, 0.05, 0.05, 0.62), width + 3.0, true)
	draw_polyline(PackedVector2Array(points), color, width, true)


func _draw_hazard_stripe(start: Vector2, end: Vector2) -> void:
	draw_line(start, end, MAINTENANCE_LINE, 2.0, true)
	var segment_count := 12
	for index in range(segment_count):
		var y := lerpf(start.y, end.y, float(index) / float(segment_count))
		draw_line(Vector2(start.x - 5.0, y + 10.0), Vector2(start.x + 5.0, y - 2.0), Color(0.92, 0.72, 0.28, 0.34), 1.0, true)


func _register_device_shapes() -> void:
	device_shape_ids = [
		"device.outpost_core.outline",
		"device.basic_reactor.outline",
		"device.basic_storage.outline",
		"device.field_outfitting_station.outline",
		"device.pollution_filter.outline"
	]
	applied_device_count = device_shape_ids.size()


func _register_device_detail_shapes() -> void:
	detail_shape_ids = [
		"floor.service_grates",
		"floor.maintenance_stripes",
		"device.outpost_core.side_console",
		"device.basic_reactor.reaction_chamber",
		"device.basic_reactor.input_output_ports",
		"device.basic_storage.shelf_bins",
		"device.field_outfitting_station.module_rack",
		"device.departure_gate.pressure_door",
		"flow.material_port_nodes"
	]


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


func _register_pollution_chain_shape(shape_id: String) -> void:
	if pollution_chain_shape_ids.has(shape_id):
		return
	pollution_chain_shape_ids.append(shape_id)
	applied_pollution_chain_state_count = pollution_chain_shape_ids.size()


func _get_base_structure_for_definition(world_state: WorldState, building_id: String) -> Dictionary:
	for structure in world_state.base_structures.values():
		if not structure is Dictionary:
			continue
		if String(structure.get("definition_id", "")) == building_id:
			return structure
	return {}


func _has_pollution_chain_context(world_state: WorldState, inventory: InventoryState) -> bool:
	if world_state == null or inventory == null:
		return false
	if (
		inventory.has_ref("item.polluted_residue", 1)
		or inventory.has_ref("item.resistance_vial_t1", 1)
		or inventory.has_ref("fluid.polluted_slurry", 1.0)
		or _is_recipe_active(world_state, "building.pollution_filter", "recipe.cleanse_residue")
		or _is_recipe_active(world_state, "building.basic_reactor", "recipe.reclaim_basic_parts")
		or _is_recipe_active(world_state, "building.basic_reactor", "recipe.core_stabilization_buffer")
	):
		return true
	for quest_id in [
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge",
		"quest.unlock_ruin_signal",
		"quest.prepare_demo_stabilization_buffer",
		"quest.write_demo_stabilization_core"
	]:
		if world_state.quest_state.has_active_quest(quest_id):
			return true
	return false


func _is_recipe_active(world_state: WorldState, building_id: String, recipe_id: String) -> bool:
	var structure := _get_base_structure_for_definition(world_state, building_id)
	return (
		String(structure.get("status", "")) == "in_progress"
		and String(structure.get("active_recipe_id", "")) == recipe_id
	)


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
