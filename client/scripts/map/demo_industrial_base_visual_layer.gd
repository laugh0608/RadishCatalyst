extends Node2D
class_name DemoIndustrialBaseVisualLayer

const GENERATED_PREFIX := "DemoIndustrialBaseVisual"
const ROLE_DECK := "deck"
const ROLE_DEVICE := "device"
const ROLE_FLOW := "flow"
const ROLE_STATUS := "status"
const ROLE_PIPE := "pipe"

const METAL_DECK := Color(0.082, 0.12, 0.125, 1.0)
const METAL_RIM := Color(0.18, 0.28, 0.3, 1.0)
const ALLOY_BODY := Color(0.18, 0.36, 0.38, 1.0)
const ALLOY_LIGHT := Color(0.62, 0.92, 0.88, 1.0)
const REACTOR_BODY := Color(0.34, 0.31, 0.18, 1.0)
const REACTOR_HEAT := Color(0.96, 0.62, 0.2, 1.0)
const STORAGE_BODY := Color(0.22, 0.45, 0.38, 1.0)
const STORAGE_LIGHT := Color(0.58, 0.86, 0.68, 1.0)
const OUTFITTING_BODY := Color(0.42, 0.36, 0.21, 1.0)
const OUTFITTING_LIGHT := Color(0.84, 0.74, 0.34, 1.0)
const FILTER_BODY := Color(0.42, 0.5, 0.2, 1.0)
const FILTER_LIGHT := Color(0.86, 0.9, 0.3, 1.0)
const PIPE_CRYSTAL := Color(0.28, 0.72, 0.84, 0.86)
const PIPE_PRODUCT := Color(0.56, 0.74, 0.5, 0.86)
const PIPE_OUTFITTING := Color(0.82, 0.7, 0.32, 0.9)
const PIPE_POLLUTION := Color(0.74, 0.68, 0.24, 0.9)

const DEVICE_ANCHORS := {
	"device.outpost_core": "Interactables/OutpostCore",
	"device.basic_reactor": "Interactables/BasicReactor",
	"device.basic_storage": "Interactables/BasicStorageBuildSite",
	"device.field_outfitting_station": "Interactables/FieldOutfittingStation",
	"device.pollution_filter": "Interactables/PollutionFilter"
}

var applied_device_count := 0
var applied_flow_count := 0


func _ready() -> void:
	apply_visuals()


func apply_visuals() -> void:
	_clear_generated_nodes()
	applied_device_count = 0
	applied_flow_count = 0
	_create_base_deck_detail()
	_create_outpost_core()
	_create_basic_reactor()
	_create_basic_storage()
	_create_field_outfitting_station()
	_create_pollution_filter()
	_create_flow_network()
	_tag_device_anchors()


func get_generated_shape_count() -> int:
	var count := 0
	for child in get_children():
		if String(child.name).begins_with(GENERATED_PREFIX):
			count += 1
	return count


func has_device(device_id: String) -> bool:
	for child in get_children():
		if not child.has_meta("industrial_base_shape_id"):
			continue
		if String(child.get_meta("industrial_base_shape_id", "")).begins_with(device_id):
			return true
	return false


func get_flow_count() -> int:
	return applied_flow_count


func _create_base_deck_detail() -> void:
	_add_rect("deck.base_rim_top", ROLE_DECK, Rect2(Vector2(-338.0, -264.0), Vector2(284.0, 8.0)), METAL_RIM)
	_add_rect("deck.base_rim_left", ROLE_DECK, Rect2(Vector2(-338.0, -264.0), Vector2(8.0, 512.0)), METAL_RIM)
	_add_rect("deck.base_rim_bottom", ROLE_DECK, Rect2(Vector2(-338.0, 240.0), Vector2(284.0, 8.0)), METAL_RIM)
	_add_rect("deck.work_yard_panel_a", ROLE_DECK, Rect2(Vector2(-318.0, -146.0), Vector2(64.0, 72.0)), METAL_DECK)
	_add_rect("deck.work_yard_panel_b", ROLE_DECK, Rect2(Vector2(-238.0, -126.0), Vector2(78.0, 86.0)), Color(0.098, 0.15, 0.152, 1.0))
	_add_rect("deck.work_yard_panel_c", ROLE_DECK, Rect2(Vector2(-150.0, -110.0), Vector2(86.0, 92.0)), Color(0.108, 0.143, 0.13, 1.0))
	_add_rect("deck.logistics_panel", ROLE_DECK, Rect2(Vector2(-316.0, 86.0), Vector2(204.0, 126.0)), Color(0.07, 0.102, 0.11, 1.0))
	_add_rect("deck.departure_threshold", ROLE_DECK, Rect2(Vector2(-70.0, -198.0), Vector2(24.0, 372.0)), Color(0.24, 0.32, 0.3, 1.0))


func _create_outpost_core() -> void:
	var device_id := "device.outpost_core"
	_add_rect("%s.plate" % device_id, ROLE_DEVICE, Rect2(Vector2(-332.0, -134.0), Vector2(90.0, 82.0)), Color(0.086, 0.18, 0.19, 1.0))
	_add_rect("%s.body" % device_id, ROLE_DEVICE, Rect2(Vector2(-318.0, -116.0), Vector2(42.0, 44.0)), ALLOY_BODY)
	_add_rect("%s.tower" % device_id, ROLE_DEVICE, Rect2(Vector2(-304.0, -138.0), Vector2(14.0, 28.0)), Color(0.2, 0.46, 0.48, 1.0))
	_add_rect("%s.beacon" % device_id, ROLE_STATUS, Rect2(Vector2(-312.0, -144.0), Vector2(30.0, 6.0)), ALLOY_LIGHT)
	_add_rect("%s.left_port" % device_id, ROLE_PIPE, Rect2(Vector2(-330.0, -96.0), Vector2(12.0, 10.0)), Color(0.26, 0.56, 0.58, 1.0))
	_add_rect("%s.right_port" % device_id, ROLE_PIPE, Rect2(Vector2(-276.0, -92.0), Vector2(34.0, 8.0)), PIPE_CRYSTAL)
	applied_device_count += 1


func _create_basic_reactor() -> void:
	var device_id := "device.basic_reactor"
	_add_rect("%s.plate" % device_id, ROLE_DEVICE, Rect2(Vector2(-214.0, -116.0), Vector2(98.0, 96.0)), Color(0.155, 0.156, 0.106, 1.0))
	_add_rect("%s.left_tank" % device_id, ROLE_DEVICE, Rect2(Vector2(-208.0, -88.0), Vector2(18.0, 42.0)), Color(0.28, 0.26, 0.18, 1.0))
	_add_rect("%s.body" % device_id, ROLE_DEVICE, Rect2(Vector2(-186.0, -102.0), Vector2(42.0, 70.0)), REACTOR_BODY)
	_add_rect("%s.heat_window" % device_id, ROLE_STATUS, Rect2(Vector2(-176.0, -94.0), Vector2(20.0, 56.0)), REACTOR_HEAT)
	_add_rect("%s.right_tank" % device_id, ROLE_DEVICE, Rect2(Vector2(-140.0, -82.0), Vector2(20.0, 38.0)), Color(0.28, 0.26, 0.18, 1.0))
	_add_rect("%s.vent_stack" % device_id, ROLE_DEVICE, Rect2(Vector2(-174.0, -130.0), Vector2(18.0, 30.0)), Color(0.48, 0.42, 0.26, 1.0))
	_add_rect("%s.status_strip" % device_id, ROLE_STATUS, Rect2(Vector2(-186.0, -32.0), Vector2(42.0, 6.0)), Color(1.0, 0.78, 0.3, 0.92))
	applied_device_count += 1


func _create_basic_storage() -> void:
	var device_id := "device.basic_storage"
	_add_rect("%s.plate" % device_id, ROLE_DEVICE, Rect2(Vector2(-296.0, -28.0), Vector2(92.0, 88.0)), Color(0.085, 0.16, 0.14, 1.0))
	_add_rect("%s.body" % device_id, ROLE_DEVICE, Rect2(Vector2(-286.0, -18.0), Vector2(72.0, 64.0)), STORAGE_BODY)
	_add_rect("%s.crate_a" % device_id, ROLE_STATUS, Rect2(Vector2(-278.0, -10.0), Vector2(26.0, 24.0)), Color(0.36, 0.66, 0.54, 1.0))
	_add_rect("%s.crate_b" % device_id, ROLE_STATUS, Rect2(Vector2(-246.0, -8.0), Vector2(24.0, 22.0)), Color(0.46, 0.74, 0.6, 1.0))
	_add_rect("%s.crate_c" % device_id, ROLE_STATUS, Rect2(Vector2(-276.0, 20.0), Vector2(48.0, 18.0)), STORAGE_LIGHT)
	_add_rect("%s.capacity_bar" % device_id, ROLE_STATUS, Rect2(Vector2(-286.0, 46.0), Vector2(72.0, 6.0)), Color(0.66, 0.92, 0.74, 0.86))
	applied_device_count += 1


func _create_field_outfitting_station() -> void:
	var device_id := "device.field_outfitting_station"
	_add_rect("%s.plate" % device_id, ROLE_DEVICE, Rect2(Vector2(-122.0, -88.0), Vector2(86.0, 94.0)), Color(0.17, 0.15, 0.102, 1.0))
	_add_rect("%s.bench" % device_id, ROLE_DEVICE, Rect2(Vector2(-112.0, -58.0), Vector2(64.0, 28.0)), OUTFITTING_BODY)
	_add_rect("%s.left_gantry" % device_id, ROLE_DEVICE, Rect2(Vector2(-116.0, -82.0), Vector2(8.0, 78.0)), Color(0.5, 0.44, 0.26, 1.0))
	_add_rect("%s.right_gantry" % device_id, ROLE_DEVICE, Rect2(Vector2(-48.0, -82.0), Vector2(8.0, 78.0)), Color(0.5, 0.44, 0.26, 1.0))
	_add_rect("%s.top_rail" % device_id, ROLE_DEVICE, Rect2(Vector2(-116.0, -82.0), Vector2(76.0, 8.0)), Color(0.54, 0.46, 0.28, 1.0))
	_add_rect("%s.loadout_lamp" % device_id, ROLE_STATUS, Rect2(Vector2(-96.0, -70.0), Vector2(30.0, 8.0)), OUTFITTING_LIGHT)
	_add_rect("%s.exit_arrow" % device_id, ROLE_FLOW, Rect2(Vector2(-54.0, -46.0), Vector2(22.0, 10.0)), PIPE_OUTFITTING)
	applied_device_count += 1


func _create_pollution_filter() -> void:
	var device_id := "device.pollution_filter"
	_add_rect("%s.plate" % device_id, ROLE_DEVICE, Rect2(Vector2(260.0, -148.0), Vector2(82.0, 74.0)), Color(0.18, 0.196, 0.095, 1.0))
	_add_rect("%s.body" % device_id, ROLE_DEVICE, Rect2(Vector2(278.0, -136.0), Vector2(34.0, 54.0)), FILTER_BODY)
	_add_rect("%s.media_stack" % device_id, ROLE_STATUS, Rect2(Vector2(286.0, -128.0), Vector2(18.0, 38.0)), FILTER_LIGHT)
	_add_rect("%s.inlet_tank" % device_id, ROLE_DEVICE, Rect2(Vector2(262.0, -124.0), Vector2(18.0, 34.0)), Color(0.44, 0.46, 0.18, 1.0))
	_add_rect("%s.clean_outlet" % device_id, ROLE_PIPE, Rect2(Vector2(312.0, -112.0), Vector2(30.0, 8.0)), Color(0.76, 0.84, 0.34, 1.0))
	_add_rect("%s.warning_pip" % device_id, ROLE_STATUS, Rect2(Vector2(320.0, -140.0), Vector2(14.0, 14.0)), Color(0.96, 0.62, 0.2, 0.92))
	applied_device_count += 1


func _create_flow_network() -> void:
	_create_flow("flow.core_to_reactor", Rect2(Vector2(-276.0, -92.0), Vector2(70.0, 8.0)), PIPE_CRYSTAL)
	_create_flow("flow.reactor_input_drop", Rect2(Vector2(-210.0, -92.0), Vector2(8.0, 30.0)), PIPE_CRYSTAL)
	_create_flow("flow.reactor_to_storage", Rect2(Vector2(-166.0, -26.0), Vector2(8.0, 42.0)), PIPE_PRODUCT)
	_create_flow("flow.storage_branch", Rect2(Vector2(-250.0, 16.0), Vector2(92.0, 8.0)), PIPE_PRODUCT)
	_create_flow("flow.reactor_to_outfitting", Rect2(Vector2(-144.0, -54.0), Vector2(32.0, 8.0)), PIPE_OUTFITTING)
	_create_flow("flow.outfitting_to_departure", Rect2(Vector2(-46.0, -46.0), Vector2(24.0, 8.0)), PIPE_OUTFITTING)
	_create_flow("flow.field_return_rail", Rect2(Vector2(-326.0, 66.0), Vector2(168.0, 8.0)), PIPE_PRODUCT)
	_create_flow("flow.pollution_to_filter", Rect2(Vector2(238.0, -116.0), Vector2(40.0, 8.0)), PIPE_POLLUTION)
	_create_flow("flow.filter_clean_output", Rect2(Vector2(312.0, -104.0), Vector2(54.0, 8.0)), FILTER_LIGHT)


func _create_flow(shape_id: String, rect: Rect2, color: Color) -> void:
	_add_rect(shape_id, ROLE_FLOW, rect, color)
	applied_flow_count += 1


func _tag_device_anchors() -> void:
	for device_id in DEVICE_ANCHORS.keys():
		var node := _get_map_node(String(DEVICE_ANCHORS[device_id]))
		if node == null:
			continue
		node.set_meta("industrial_base_device_id", device_id)
		node.set_meta("industrial_base_visual_role", ROLE_DEVICE)


func _add_rect(shape_id: String, role: String, rect: Rect2, color: Color) -> ColorRect:
	var shape := ColorRect.new()
	shape.name = _shape_name(shape_id, role)
	shape.offset_left = rect.position.x
	shape.offset_top = rect.position.y
	shape.offset_right = rect.position.x + rect.size.x
	shape.offset_bottom = rect.position.y + rect.size.y
	shape.color = color
	shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shape.set_meta("industrial_base_shape_id", shape_id)
	shape.set_meta("industrial_base_visual_role", role)
	shape.z_index = _role_z_index(role)
	add_child(shape)
	return shape


func _role_z_index(role: String) -> int:
	match role:
		ROLE_FLOW:
			return 1
		ROLE_DECK:
			return 2
		ROLE_DEVICE:
			return 3
		ROLE_PIPE:
			return 4
		ROLE_STATUS:
			return 5
	return 0


func _shape_name(shape_id: String, role: String, suffix: String = "") -> String:
	var safe_shape_id := shape_id.replace(".", "_")
	var raw_name := "%s_%s_%s" % [safe_shape_id, role, suffix]
	return "%s%s" % [GENERATED_PREFIX, raw_name.to_pascal_case()]


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
