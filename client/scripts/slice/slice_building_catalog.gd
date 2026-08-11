class_name SliceBuildingCatalog
extends RefCounted

## Player-buildable registry. Fixed-front facilities expose immutable sprite,
## logistics and power geometry; only conveyors retain cardinal rotation.

const FLOOR_ID := "building.floor"
const COLLECTOR_ID := "building.collector"
const REACTOR_ID := "building.reactor"
const POWER_RELAY_ID := "building.power_relay"
const CONVEYOR_ID := "building.conveyor"
const STORAGE_ID := "building.storage"


static func find(building_id: String) -> SliceBuildingDefinition:
	match building_id:
		FLOOR_ID:
			return _with_device_model(
				SliceBuildingDefinition.new(
					FLOOR_ID,
					FLOOR_ID,
					"工业地板",
					Vector2i.ONE,
					false,
					SliceBuildingDefinition.SURFACE_BUILDABLE_ROCK,
					false,
					true,
					"",
					["res://assets/tiles/slice/industrial_floor_terrain.png"],
					Vector2.ZERO,
					Rect2(0, 0, 32, 32)
				),
				SliceBuildingDefinition.ORIENTATION_FIXED_FRONT,
				SliceBuildingDefinition.VISUAL_SINGLE_FRAME,
				_no_ports(),
				SliceBuildingDefinition.POWER_PROBE_FOOTPRINT_CENTER,
				Vector2i(-1, -1),
				SliceBuildingDefinition.POWER_VISUAL_ANCHOR_NONE,
				Vector2.ZERO
			)
		COLLECTOR_ID:
			return _with_device_model(
				SliceBuildingDefinition.new(
					COLLECTOR_ID,
					COLLECTOR_ID,
					"晶体采集器",
					Vector2i(2, 2),
					false,
					SliceBuildingDefinition.SURFACE_CRYSTAL,
					true,
					false,
					"res://scenes/slice/SliceCollector.tscn",
					["res://assets/sprites/slice/collector.png"],
					Vector2(0, -24),
					Rect2(),
					["buffer", "production_progress"],
					SliceBuildingDefinition.POWER_CONSUMER,
					Vector2i(0, 1),
					"",
					Vector2(4, -12)
				),
				SliceBuildingDefinition.ORIENTATION_FIXED_FRONT,
				SliceBuildingDefinition.VISUAL_SINGLE_FRAME,
				_collector_ports(),
				SliceBuildingDefinition.POWER_PROBE_FOOTPRINT_CENTER,
				Vector2i(-1, -1),
				SliceBuildingDefinition.POWER_VISUAL_ANCHOR_BLOCK_CENTER_OFFSET,
				Vector2(0, -78)
			)
		REACTOR_ID:
			return _with_device_model(
				SliceBuildingDefinition.new(
					REACTOR_ID,
					REACTOR_ID,
					"基础反应器",
					Vector2i(3, 3),
					false,
					SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR,
					true,
					false,
					"res://scenes/slice/SliceReactor.tscn",
					["res://assets/sprites/slice/reactor.png"],
					Vector2(0, 4),
					Rect2(),
					[
						"input_inventory",
						"output_inventory",
						"processing",
						"production_progress",
					],
					SliceBuildingDefinition.POWER_CONSUMER,
					Vector2i(1, 2),
					"",
					Vector2(-8, -8)
				),
				SliceBuildingDefinition.ORIENTATION_FIXED_FRONT,
				SliceBuildingDefinition.VISUAL_SINGLE_FRAME,
				_reactor_ports(),
				SliceBuildingDefinition.POWER_PROBE_FOOTPRINT_CENTER,
				Vector2i(-1, -1),
				SliceBuildingDefinition.POWER_VISUAL_ANCHOR_BLOCK_CENTER_OFFSET,
				Vector2(0, -18)
			).configure_icon_region(Rect2(28, 0, 120, 88))
		POWER_RELAY_ID:
			return _with_device_model(
				SliceBuildingDefinition.new(
					POWER_RELAY_ID,
					POWER_RELAY_ID,
					"电力中继",
					Vector2i.ONE,
					false,
					SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR,
					true,
					false,
					"",
					["res://assets/sprites/slice/power_relay.png"],
					Vector2(0, -22),
					Rect2(),
					[],
					SliceBuildingDefinition.POWER_RELAY,
					Vector2i(-1, -1),
					"",
					Vector2(-16, -32)
				),
				SliceBuildingDefinition.ORIENTATION_FIXED_FRONT,
				SliceBuildingDefinition.VISUAL_SINGLE_FRAME,
				_no_ports(),
				SliceBuildingDefinition.POWER_PROBE_FOOTPRINT_CENTER,
				Vector2i(-1, -1),
				SliceBuildingDefinition.POWER_VISUAL_ANCHOR_BLOCK_CENTER_OFFSET,
				Vector2(0, -44)
			).configure_power_visual_terminals({
				SliceBuildingDefinition.POWER_TERMINAL_WEST: Vector2(-20, -46),
				SliceBuildingDefinition.POWER_TERMINAL_NORTH: Vector2(0, -57),
				SliceBuildingDefinition.POWER_TERMINAL_EAST: Vector2(19, -46),
				SliceBuildingDefinition.POWER_TERMINAL_FRONT: Vector2(0, -37),
			})
		CONVEYOR_ID:
			return _with_device_model(
				SliceBuildingDefinition.new(
					CONVEYOR_ID,
					CONVEYOR_ID,
					"传送带",
					Vector2i.ONE,
					true,
					SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR,
					true,
					false,
					"res://scenes/slice/SliceConveyor.tscn",
					_cardinal_textures("conveyor"),
					Vector2.ZERO,
					Rect2(),
					["cargo", "merge_cursor"]
				),
				SliceBuildingDefinition.ORIENTATION_CARDINAL,
				SliceBuildingDefinition.VISUAL_CARDINAL_FRAMES,
				_no_ports(),
				SliceBuildingDefinition.POWER_PROBE_FOOTPRINT_CENTER,
				Vector2i(-1, -1),
				SliceBuildingDefinition.POWER_VISUAL_ANCHOR_NONE,
				Vector2.ZERO
			)
		STORAGE_ID:
			return _with_device_model(
				SliceBuildingDefinition.new(
					STORAGE_ID,
					STORAGE_ID,
					"储物箱",
					Vector2i(2, 2),
					false,
					SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR,
					true,
					false,
					"res://scenes/slice/SliceStorage.tscn",
					["res://assets/sprites/slice/storage.png"],
					Vector2(0, -8),
					Rect2(),
					[
						"inventory",
						"mode",
						"output_item_id",
						"transfer_cursor",
						"transfer_progress",
					],
					SliceBuildingDefinition.POWER_CONSUMER,
					Vector2i(-1, -1),
					"",
					Vector2(-8, -8)
				),
				SliceBuildingDefinition.ORIENTATION_FIXED_FRONT,
				SliceBuildingDefinition.VISUAL_SINGLE_FRAME,
				_storage_ports(),
				SliceBuildingDefinition.POWER_PROBE_FOOTPRINT_CENTER,
				Vector2i(-1, -1),
				SliceBuildingDefinition.POWER_VISUAL_ANCHOR_BLOCK_CENTER_OFFSET,
				Vector2(0, -30)
			)
	return null


static func all() -> Array[SliceBuildingDefinition]:
	return [
		find(FLOOR_ID),
		find(COLLECTOR_ID),
		find(REACTOR_ID),
		find(POWER_RELAY_ID),
		find(CONVEYOR_ID),
		find(STORAGE_ID),
	]


static func _cardinal_textures(stem: String) -> Array[String]:
	return [
		"res://assets/sprites/slice/%s_up.png" % stem,
		"res://assets/sprites/slice/%s_right.png" % stem,
		"res://assets/sprites/slice/%s_down.png" % stem,
		"res://assets/sprites/slice/%s_left.png" % stem,
	]


static func _with_device_model(
	definition: SliceBuildingDefinition,
	orientation_mode: String,
	visual_mode: String,
	ports: Array[SliceLogisticsPortDefinition],
	logic_power_probe_policy: String,
	logic_power_probe_cell: Vector2i,
	power_visual_anchor_policy: String,
	power_visual_anchor_offset: Vector2
) -> SliceBuildingDefinition:
	return definition.configure_device_model(
		orientation_mode,
		visual_mode,
		ports,
		logic_power_probe_policy,
		logic_power_probe_cell,
		power_visual_anchor_policy,
		power_visual_anchor_offset
	)


static func _no_ports() -> Array[SliceLogisticsPortDefinition]:
	return []


static func _collector_ports() -> Array[SliceLogisticsPortDefinition]:
	return [
		SliceLogisticsPortDefinition.new(
			"output",
			SliceLogisticsPortDefinition.ROLE_OUTPUT,
			"OUT",
			Vector2i(1, 1),
			Vector2i.RIGHT,
			SliceLogisticsPortDefinition.ORIENTATION_FIXED_LOCAL,
			[],
			["crystal"],
			0
		),
	]


static func _storage_ports() -> Array[SliceLogisticsPortDefinition]:
	return [
		SliceLogisticsPortDefinition.new(
			"input",
			SliceLogisticsPortDefinition.ROLE_INPUT,
			"IN",
			Vector2i(0, 1),
			Vector2i.LEFT,
			SliceLogisticsPortDefinition.ORIENTATION_FIXED_LOCAL,
			["crystal", "catalyst"],
			[],
			0
		),
		SliceLogisticsPortDefinition.new(
			"output",
			SliceLogisticsPortDefinition.ROLE_OUTPUT,
			"OUT",
			Vector2i(1, 1),
			Vector2i.RIGHT,
			SliceLogisticsPortDefinition.ORIENTATION_FIXED_LOCAL,
			[],
			["crystal", "catalyst"],
			0
		),
	]


static func _reactor_ports() -> Array[SliceLogisticsPortDefinition]:
	return [
		SliceLogisticsPortDefinition.new(
			"input",
			SliceLogisticsPortDefinition.ROLE_INPUT,
			"IN",
			Vector2i(0, 1),
			Vector2i.LEFT,
			SliceLogisticsPortDefinition.ORIENTATION_FIXED_LOCAL,
			["crystal"],
			[],
			1,
			2
		),
		SliceLogisticsPortDefinition.new(
			"output",
			SliceLogisticsPortDefinition.ROLE_OUTPUT,
			"OUT",
			Vector2i(2, 1),
			Vector2i.RIGHT,
			SliceLogisticsPortDefinition.ORIENTATION_FIXED_LOCAL,
			[],
			["catalyst"],
			1,
			2
		),
	]
