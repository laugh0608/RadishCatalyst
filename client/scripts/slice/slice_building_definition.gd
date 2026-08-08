class_name SliceBuildingDefinition
extends RefCounted

## Immutable rules for one placeable slice building. Direction, sprite frames,
## logistics geometry, the logical power probe and the visual power anchor are
## explicit independent facts. None of these descriptors are persisted.

const SURFACE_BUILDABLE_ROCK := "buildable_rock"
const SURFACE_CRYSTAL := "crystal"
const SURFACE_INDUSTRIAL_FLOOR := "industrial_floor"
const POWER_PASSIVE := "passive"
const POWER_RELAY := "relay"
const POWER_CONSUMER := "consumer"
const ORIENTATION_CARDINAL := "cardinal"
const ORIENTATION_FIXED_FRONT := "fixed_front"
const VISUAL_SINGLE_FRAME := "single_frame"
const VISUAL_CARDINAL_FRAMES := "cardinal_frames"
const POWER_PROBE_FOOTPRINT_CENTER := "footprint_center"
const POWER_PROBE_FOLLOWS_ORIENTATION := "follows_orientation"
const POWER_PROBE_FIXED_LOCAL := "fixed_local"
const POWER_VISUAL_ANCHOR_NONE := "none"
const POWER_VISUAL_ANCHOR_BLOCK_CENTER_OFFSET := "block_center_offset"
const POWER_TERMINAL_WEST := "west"
const POWER_TERMINAL_NORTH := "north"
const POWER_TERMINAL_EAST := "east"
const POWER_TERMINAL_FRONT := "front"

var building_id: String
var kit_item_id: String
var display_name: String
var footprint: Vector2i
var orientation_mode: String
var allows_rotation: bool
var surface_rule: String
var blocks_movement: bool
var is_floor: bool
var scene_path: String
var texture_paths: Array[String]
var visual_mode: String
var sprite_offset: Vector2
var texture_region: Rect2
var icon_region: Rect2
var state_keys: Array[String]
var power_role: String
var logic_power_probe_policy: String
var logic_power_probe_cell: Vector2i
var power_port_cell: Vector2i
var powered_texture_path: String
var power_indicator_offset: Vector2
var power_visual_anchor_policy: String
var power_visual_anchor_offset: Vector2
var power_visual_terminal_offsets: Dictionary = {}
var logistics_ports: Array[SliceLogisticsPortDefinition] = []
var logistics_port_cell: Vector2i
var logistics_port_direction: Vector2i
var machine_input_port_cell: Vector2i
var machine_input_port_direction: Vector2i
var machine_output_port_cell: Vector2i
var machine_output_port_direction: Vector2i


func _init(
	id: String,
	kit_id: String,
	label: String,
	base_footprint: Vector2i,
	can_rotate: bool,
	required_surface: String,
	blocks: bool,
	floor_layer: bool,
	scene: String = "",
	textures: Array[String] = [],
	visual_offset: Vector2 = Vector2.ZERO,
	region: Rect2 = Rect2(),
	allowed_state_keys: Array[String] = [],
	role: String = POWER_PASSIVE,
	port_cell: Vector2i = Vector2i(-1, -1),
	powered_texture: String = "",
	indicator_offset: Vector2 = Vector2(-8, -8),
	logistics_cell: Vector2i = Vector2i(-1, -1),
	logistics_direction: Vector2i = Vector2i.ZERO,
	machine_input_cell: Vector2i = Vector2i(-1, -1),
	machine_input_direction: Vector2i = Vector2i.ZERO,
	machine_output_cell: Vector2i = Vector2i(-1, -1),
	machine_output_direction: Vector2i = Vector2i.ZERO
) -> void:
	building_id = id
	kit_item_id = kit_id
	display_name = label
	footprint = base_footprint
	orientation_mode = (
		ORIENTATION_CARDINAL if can_rotate else ORIENTATION_FIXED_FRONT
	)
	allows_rotation = can_rotate
	surface_rule = required_surface
	blocks_movement = blocks
	is_floor = floor_layer
	scene_path = scene
	texture_paths = textures.duplicate()
	visual_mode = (
		VISUAL_CARDINAL_FRAMES
		if texture_paths.size() > 1
		else VISUAL_SINGLE_FRAME
	)
	sprite_offset = visual_offset
	texture_region = region
	icon_region = region
	state_keys = allowed_state_keys.duplicate()
	power_role = role
	logic_power_probe_policy = (
		POWER_PROBE_FOLLOWS_ORIENTATION
		if _cell_is_defined(port_cell)
		else POWER_PROBE_FOOTPRINT_CENTER
	)
	logic_power_probe_cell = port_cell
	power_port_cell = port_cell
	powered_texture_path = powered_texture
	power_indicator_offset = indicator_offset
	power_visual_anchor_policy = POWER_VISUAL_ANCHOR_NONE
	power_visual_anchor_offset = Vector2.ZERO
	logistics_port_cell = logistics_cell
	logistics_port_direction = logistics_direction
	machine_input_port_cell = machine_input_cell
	machine_input_port_direction = machine_input_direction
	machine_output_port_cell = machine_output_cell
	machine_output_port_direction = machine_output_direction
	_replace_logistics_ports(_legacy_logistics_ports())


func configure_icon_region(next_icon_region: Rect2) -> SliceBuildingDefinition:
	icon_region = next_icon_region
	return self


func configure_power_visual_terminals(
	next_terminal_offsets: Dictionary
) -> SliceBuildingDefinition:
	power_visual_terminal_offsets = next_terminal_offsets.duplicate(true)
	return self


func configure_device_model(
	next_orientation_mode: String,
	next_visual_mode: String,
	next_logistics_ports: Array[SliceLogisticsPortDefinition],
	next_logic_power_probe_policy: String,
	next_logic_power_probe_cell: Vector2i,
	next_power_visual_anchor_policy: String,
	next_power_visual_anchor_offset: Vector2
) -> SliceBuildingDefinition:
	orientation_mode = next_orientation_mode
	allows_rotation = orientation_mode == ORIENTATION_CARDINAL
	visual_mode = next_visual_mode
	logic_power_probe_policy = next_logic_power_probe_policy
	logic_power_probe_cell = next_logic_power_probe_cell
	power_port_cell = logic_power_probe_cell
	power_visual_anchor_policy = next_power_visual_anchor_policy
	power_visual_anchor_offset = next_power_visual_anchor_offset
	_replace_logistics_ports(next_logistics_ports)
	return self


func normalized_rotation(rotation: int) -> int:
	return posmod(rotation, 4) if orientation_mode == ORIENTATION_CARDINAL else 0


func rotated_footprint(rotation: int) -> Vector2i:
	var normalized := normalized_rotation(rotation)
	if normalized % 2 == 1:
		return Vector2i(footprint.y, footprint.x)
	return footprint


func occupied_cells(origin_cell: Vector2i, rotation: int) -> Array[Vector2i]:
	var size := rotated_footprint(rotation)
	var result: Array[Vector2i] = []
	for y in range(size.y):
		for x in range(size.x):
			result.append(origin_cell + Vector2i(x, y))
	return result


func origin_for_target(target_position: Vector2, tile_size: float, rotation: int) -> Vector2i:
	var size := Vector2(rotated_footprint(rotation))
	return Vector2i(
		roundi(target_position.x / tile_size - size.x * 0.5),
		roundi(target_position.y / tile_size - size.y * 0.5)
	)


func block_center(origin_cell: Vector2i, tile_size: float, rotation: int) -> Vector2:
	var size := Vector2(rotated_footprint(rotation))
	return Vector2(origin_cell) * tile_size + size * tile_size * 0.5


func sort_anchor_world_position(
	origin_cell: Vector2i,
	tile_size: float,
	rotation: int
) -> Vector2:
	var size := Vector2(rotated_footprint(rotation))
	return Vector2(
		(float(origin_cell.x) + size.x * 0.5) * tile_size,
		(float(origin_cell.y) + size.y) * tile_size
	)


func local_footprint_center_offset(
	tile_size: float,
	rotation: int
) -> Vector2:
	var size := Vector2(rotated_footprint(rotation))
	return Vector2(0.0, -size.y * tile_size * 0.5)


func texture_path_for_rotation(rotation: int) -> String:
	if texture_paths.is_empty():
		return ""
	if visual_mode == VISUAL_SINGLE_FRAME or texture_paths.size() == 1:
		return texture_paths[0]
	return texture_paths[normalized_rotation(rotation) % texture_paths.size()]


func rotated_power_port_cell(rotation: int) -> Vector2i:
	if logic_power_probe_policy == POWER_PROBE_FIXED_LOCAL:
		return logic_power_probe_cell
	return _rotated_local_cell(logic_power_probe_cell, rotation)


func rotated_logistics_port_cell(rotation: int) -> Vector2i:
	var port := _port_with_role(
		SliceLogisticsPortDefinition.ROLE_BIDIRECTIONAL
	)
	return (
		Vector2i(-1, -1)
		if port == null
		else port.resolved_local_cell(footprint, normalized_rotation(rotation))
	)


func logistics_direction_for_rotation(rotation: int) -> Vector2i:
	var port := _port_with_role(
		SliceLogisticsPortDefinition.ROLE_BIDIRECTIONAL
	)
	return (
		Vector2i.ZERO
		if port == null
		else port.resolved_outward_direction(normalized_rotation(rotation))
	)


func logistics_port_world_cell(
	origin_cell: Vector2i,
	rotation: int
) -> Vector2i:
	var port := rotated_logistics_port_cell(rotation)
	return origin_cell + port


func logistics_connection_world_cell(
	origin_cell: Vector2i,
	rotation: int
) -> Vector2i:
	var port := _port_with_role(
		SliceLogisticsPortDefinition.ROLE_BIDIRECTIONAL
	)
	return _resolved_connection_cell(port, origin_cell, rotation)


func rotated_machine_input_port_cell(rotation: int) -> Vector2i:
	var port := _port_with_role(SliceLogisticsPortDefinition.ROLE_INPUT)
	return (
		Vector2i(-1, -1)
		if port == null
		else port.resolved_local_cell(footprint, normalized_rotation(rotation))
	)


func machine_input_direction_for_rotation(rotation: int) -> Vector2i:
	var port := _port_with_role(SliceLogisticsPortDefinition.ROLE_INPUT)
	return (
		Vector2i.ZERO
		if port == null
		else port.resolved_outward_direction(normalized_rotation(rotation))
	)


func machine_input_port_world_cell(
	origin_cell: Vector2i,
	rotation: int
) -> Vector2i:
	return origin_cell + rotated_machine_input_port_cell(rotation)


func machine_input_connection_world_cell(
	origin_cell: Vector2i,
	rotation: int
) -> Vector2i:
	var port := _port_with_role(SliceLogisticsPortDefinition.ROLE_INPUT)
	return _resolved_connection_cell(port, origin_cell, rotation)


func rotated_machine_output_port_cell(rotation: int) -> Vector2i:
	var port := _port_with_role(SliceLogisticsPortDefinition.ROLE_OUTPUT)
	return (
		Vector2i(-1, -1)
		if port == null
		else port.resolved_local_cell(footprint, normalized_rotation(rotation))
	)


func machine_output_direction_for_rotation(rotation: int) -> Vector2i:
	var port := _port_with_role(SliceLogisticsPortDefinition.ROLE_OUTPUT)
	return (
		Vector2i.ZERO
		if port == null
		else port.resolved_outward_direction(normalized_rotation(rotation))
	)


func machine_output_port_world_cell(
	origin_cell: Vector2i,
	rotation: int
) -> Vector2i:
	return origin_cell + rotated_machine_output_port_cell(rotation)


func machine_output_connection_world_cell(
	origin_cell: Vector2i,
	rotation: int
) -> Vector2i:
	var port := _port_with_role(SliceLogisticsPortDefinition.ROLE_OUTPUT)
	return _resolved_connection_cell(port, origin_cell, rotation)


func _resolved_connection_cell(
	port: SliceLogisticsPortDefinition,
	origin_cell: Vector2i,
	rotation: int
) -> Vector2i:
	if port == null:
		return Vector2i(-1, -1)
	return Vector2i(port.resolved_descriptor(
		origin_cell,
		footprint,
		normalized_rotation(rotation)
	)["connection_cell"])


func resolved_logistics_port_descriptors(
	origin_cell: Vector2i,
	rotation: int
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var normalized := normalized_rotation(rotation)
	for port in logistics_ports:
		result.append(port.resolved_descriptor(
			origin_cell, footprint, normalized
		))
	return result


func logistics_approach_cells(
	origin_cell: Vector2i,
	rotation: int
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for descriptor in resolved_logistics_port_descriptors(
		origin_cell, rotation
	):
		var port_cell := Vector2i(descriptor["port_cell"])
		var outward := Vector2i(descriptor["outward_direction"])
		for step in range(1, int(descriptor["connection_distance"])):
			var cell := port_cell + outward * step
			if not result.has(cell):
				result.append(cell)
	return result


func logistics_port_definition(
	port_id: String
) -> SliceLogisticsPortDefinition:
	for port in logistics_ports:
		if port.id == port_id:
			return port
	return null


func _rotated_local_cell(cell: Vector2i, rotation: int) -> Vector2i:
	if cell.x < 0 or cell.y < 0:
		return cell
	var point := cell
	var size := footprint
	for _step in range(normalized_rotation(rotation)):
		point = Vector2i(size.y - 1 - point.y, point.x)
		size = Vector2i(size.y, size.x)
	return point


func power_port_world_position(
	origin_cell: Vector2i,
	tile_size: float,
	rotation: int
) -> Vector2:
	return logic_power_probe_world_position(
		origin_cell, tile_size, rotation
	)


func logic_power_probe_world_position(
	origin_cell: Vector2i,
	tile_size: float,
	rotation: int
) -> Vector2:
	if logic_power_probe_policy == POWER_PROBE_FOOTPRINT_CENTER:
		return block_center(origin_cell, tile_size, rotation)
	var port := rotated_power_port_cell(rotation)
	if port.x < 0 or port.y < 0:
		return block_center(origin_cell, tile_size, rotation)
	return (Vector2(origin_cell + port) + Vector2(0.5, 0.5)) * tile_size


func power_visual_anchor_world_position(
	origin_cell: Vector2i,
	tile_size: float,
	rotation: int
) -> Vector2:
	var center := block_center(origin_cell, tile_size, rotation)
	if (
		power_visual_anchor_policy
		== POWER_VISUAL_ANCHOR_BLOCK_CENTER_OFFSET
	):
		return center + power_visual_anchor_offset
	return center


func power_visual_terminal_toward(
	origin_cell: Vector2i,
	tile_size: float,
	rotation: int,
	toward_world_position: Vector2
) -> String:
	if power_visual_terminal_offsets.is_empty():
		return ""
	var center := block_center(origin_cell, tile_size, rotation)
	var delta := toward_world_position - center
	if absf(delta.x) > absf(delta.y):
		return POWER_TERMINAL_EAST if delta.x > 0.0 else POWER_TERMINAL_WEST
	return POWER_TERMINAL_FRONT if delta.y > 0.0 else POWER_TERMINAL_NORTH


func power_visual_anchor_toward_world_position(
	origin_cell: Vector2i,
	tile_size: float,
	rotation: int,
	toward_world_position: Vector2
) -> Vector2:
	var terminal := power_visual_terminal_toward(
		origin_cell, tile_size, rotation, toward_world_position
	)
	if terminal.is_empty():
		return power_visual_anchor_world_position(
			origin_cell, tile_size, rotation
		)
	return (
		block_center(origin_cell, tile_size, rotation)
		+ Vector2(power_visual_terminal_offsets[terminal])
	)


func _legacy_logistics_ports() -> Array[SliceLogisticsPortDefinition]:
	var result: Array[SliceLogisticsPortDefinition] = []
	if _cell_is_defined(logistics_port_cell):
		result.append(SliceLogisticsPortDefinition.new(
			"io",
			SliceLogisticsPortDefinition.ROLE_BIDIRECTIONAL,
			"IO",
			logistics_port_cell,
			logistics_port_direction,
			SliceLogisticsPortDefinition.ORIENTATION_FOLLOWS
		))
	if _cell_is_defined(machine_input_port_cell):
		result.append(SliceLogisticsPortDefinition.new(
			"input",
			SliceLogisticsPortDefinition.ROLE_INPUT,
			"IN",
			machine_input_port_cell,
			machine_input_port_direction,
			SliceLogisticsPortDefinition.ORIENTATION_FOLLOWS
		))
	if _cell_is_defined(machine_output_port_cell):
		result.append(SliceLogisticsPortDefinition.new(
			"output",
			SliceLogisticsPortDefinition.ROLE_OUTPUT,
			"OUT",
			machine_output_port_cell,
			machine_output_port_direction,
			SliceLogisticsPortDefinition.ORIENTATION_FOLLOWS
		))
	return result


func _replace_logistics_ports(
	next_ports: Array[SliceLogisticsPortDefinition]
) -> void:
	logistics_ports.clear()
	for port in next_ports:
		logistics_ports.append(port)
	_sync_legacy_port_fields()


func _sync_legacy_port_fields() -> void:
	var io_port := _port_with_role(
		SliceLogisticsPortDefinition.ROLE_BIDIRECTIONAL
	)
	logistics_port_cell = (
		Vector2i(-1, -1) if io_port == null else io_port.local_cell
	)
	logistics_port_direction = (
		Vector2i.ZERO if io_port == null else io_port.outward_direction
	)
	var input_port := _port_with_role(SliceLogisticsPortDefinition.ROLE_INPUT)
	machine_input_port_cell = (
		Vector2i(-1, -1) if input_port == null else input_port.local_cell
	)
	machine_input_port_direction = (
		Vector2i.ZERO if input_port == null else input_port.outward_direction
	)
	var output_port := _port_with_role(
		SliceLogisticsPortDefinition.ROLE_OUTPUT
	)
	machine_output_port_cell = (
		Vector2i(-1, -1) if output_port == null else output_port.local_cell
	)
	machine_output_port_direction = (
		Vector2i.ZERO if output_port == null else output_port.outward_direction
	)


func _port_with_role(flow_role: String) -> SliceLogisticsPortDefinition:
	for port in logistics_ports:
		if port.role == flow_role:
			return port
	return null


func _cell_is_defined(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0
