class_name SliceCoreLogistics
extends RefCounted

## Non-persistent logistics adapter for the fixed map core. The repaired core
## binds the existing core_storage inventory to one left input and one right
## output; the damaged core exposes neither endpoint.

const INSTANCE_ID := SlicePowerGrid.CORE_NODE_ID
const DISPLAY_NAME := "前哨核心"
const FOOTPRINT := Vector2i(2, 2)
const SOURCE_PHASE := 2
## The device-owned short docks do not span a full tile. The terminal belt
## therefore occupies the immediately adjacent cell and becomes their
## connected-state cover only after topology confirms a real connection.
const CONNECTION_DISTANCE := 1
const REPAIRED_SPRITE_OFFSET := Vector2(0, -32)
const POWER_VISUAL_ANCHOR_OFFSET := Vector2(8, -80)

var _core: Sprite2D
var _inventory: Inventory
var _online := false
var _tile_size := 32.0


static func apply_repaired_visual(
	core: Sprite2D,
	texture: Texture2D
) -> void:
	if core == null:
		return
	core.texture = texture
	core.offset = REPAIRED_SPRITE_OFFSET


func setup(
	core: Sprite2D,
	inventory: Inventory,
	online: bool,
	tile_size: float
) -> void:
	_core = core
	_inventory = inventory
	_online = online
	_tile_size = tile_size


func endpoints() -> Array[SliceLogisticsEndpoint]:
	var result: Array[SliceLogisticsEndpoint] = []
	if not _online or _core == null or _inventory == null:
		return result
	var origin := origin_cell()
	for port in port_definitions():
		result.append(SliceLogisticsEndpoint.bind_fixed(
			self,
			port,
			INSTANCE_ID,
			DISPLAY_NAME,
			origin,
			FOOTPRINT,
			0,
			Callable(self, "_accept_one"),
			Callable(self, "_peek_output"),
			Callable(self, "_take_output")
		))
	return result


func reserved_approach_cells(
	instances: Array[SliceBuildingInstance],
	excluded_instance: SliceBuildingInstance
) -> Array[Vector2i]:
	var result := approach_cells()
	for instance in instances:
		if instance == excluded_instance:
			continue
		result.append_array(instance.definition.logistics_approach_cells(
			instance.origin_cell, instance.building_rotation
		))
	return result


func approach_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not _online or _core == null:
		return result
	var origin := origin_cell()
	for port in port_definitions():
		var descriptor := port.resolved_descriptor(origin, FOOTPRINT, 0)
		var port_cell := Vector2i(descriptor["port_cell"])
		var outward := Vector2i(descriptor["outward_direction"])
		for step in range(1, int(descriptor["connection_distance"])):
			result.append(port_cell + outward * step)
	return result


func origin_cell() -> Vector2i:
	if _core == null:
		return Vector2i.ZERO
	var center := Vector2i(
		roundi(_core.global_position.x / _tile_size),
		roundi(_core.global_position.y / _tile_size)
	)
	return center - FOOTPRINT / 2


func port_definitions() -> Array[SliceLogisticsPortDefinition]:
	var transportable := SliceItemCatalog.transportable_ids()
	return [
		SliceLogisticsPortDefinition.new(
			"input",
			SliceLogisticsPortDefinition.ROLE_INPUT,
			"IN",
			Vector2i(0, 1),
			Vector2i.LEFT,
			SliceLogisticsPortDefinition.ORIENTATION_FIXED_LOCAL,
			transportable,
			[],
			SOURCE_PHASE,
			CONNECTION_DISTANCE
		),
		SliceLogisticsPortDefinition.new(
			"output",
			SliceLogisticsPortDefinition.ROLE_OUTPUT,
			"OUT",
			Vector2i(1, 1),
			Vector2i.RIGHT,
			SliceLogisticsPortDefinition.ORIENTATION_FIXED_LOCAL,
			[],
			transportable,
			SOURCE_PHASE,
			CONNECTION_DISTANCE
		),
	]


func _accept_one(item_id: String) -> int:
	if (
		not _online
		or _inventory == null
		or not SliceItemCatalog.is_transportable(item_id)
	):
		return 0
	return _inventory.add(item_id, 1)


func _peek_output() -> String:
	if not _online or _inventory == null:
		return ""
	for item_id in SliceItemCatalog.transportable_ids():
		if _inventory.count(item_id) > 0:
			return item_id
	return ""


func _take_output(item_id: String) -> int:
	if (
		not _online
		or _inventory == null
		or not SliceItemCatalog.is_transportable(item_id)
	):
		return 0
	return _inventory.remove(item_id, 1)
