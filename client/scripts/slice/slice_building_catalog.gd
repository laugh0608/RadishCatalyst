class_name SliceBuildingCatalog
extends RefCounted

## L3 building registry. All six player-buildable types share these definitions
## instead of branching the world controller by device.

const FLOOR_ID := "building.floor"
const COLLECTOR_ID := "building.collector"
const REACTOR_ID := "building.reactor"
const POWER_RELAY_ID := "building.power_relay"
const CONVEYOR_ID := "building.conveyor"
const STORAGE_ID := "building.storage"


static func find(building_id: String) -> SliceBuildingDefinition:
	match building_id:
		FLOOR_ID:
			return SliceBuildingDefinition.new(
				FLOOR_ID,
				FLOOR_ID,
				"工业地板",
				Vector2i.ONE,
				true,
				SliceBuildingDefinition.SURFACE_BUILDABLE_ROCK,
				false,
				true,
				"",
				["res://assets/tiles/slice/industrial_floor_terrain.png"],
				Vector2.ZERO,
				Rect2(0, 0, 32, 32)
			)
		COLLECTOR_ID:
			return SliceBuildingDefinition.new(
				COLLECTOR_ID,
				COLLECTOR_ID,
				"晶体采集器",
				Vector2i(2, 2),
				true,
				SliceBuildingDefinition.SURFACE_CRYSTAL,
				true,
				false,
				"res://scenes/slice/SliceCollector.tscn",
				["res://assets/sprites/slice/collector.png"],
				Vector2(0, -22),
				Rect2(),
				["buffer", "production_progress"],
				SliceBuildingDefinition.POWER_CONSUMER,
				Vector2i(0, 1),
				"",
				Vector2(4, -12)
			)
		REACTOR_ID:
			return SliceBuildingDefinition.new(
				REACTOR_ID,
				REACTOR_ID,
				"基础反应器",
				Vector2i(3, 3),
				true,
				SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR,
				true,
				false,
				"res://scenes/slice/SliceReactor.tscn",
				_cardinal_textures("reactor"),
				Vector2(0, -16),
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
				Vector2(-8, -8),
				Vector2i(-1, -1),
				Vector2i.ZERO,
				Vector2i(1, 2),
				Vector2i.DOWN,
				Vector2i(1, 0),
				Vector2i.UP
			)
		POWER_RELAY_ID:
			return SliceBuildingDefinition.new(
				POWER_RELAY_ID,
				POWER_RELAY_ID,
				"电力中继",
				Vector2i.ONE,
				true,
				SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR,
				true,
				false,
				"",
				["res://assets/sprites/slice/power_relay_unpowered.png"],
				Vector2(0, -16),
				Rect2(),
				[],
				SliceBuildingDefinition.POWER_RELAY,
				Vector2i(-1, -1),
				"res://assets/sprites/slice/power_relay_powered.png"
			)
		CONVEYOR_ID:
			return SliceBuildingDefinition.new(
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
			)
		STORAGE_ID:
			return SliceBuildingDefinition.new(
				STORAGE_ID,
				STORAGE_ID,
				"储物箱",
				Vector2i(2, 2),
				true,
				SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR,
				true,
				false,
				"res://scenes/slice/SliceStorage.tscn",
				_cardinal_textures("storage"),
				Vector2(0, -16),
				Rect2(),
				["inventory"],
				SliceBuildingDefinition.POWER_PASSIVE,
				Vector2i(-1, -1),
				"",
				Vector2(-8, -8),
				Vector2i(1, 0),
				Vector2i.UP
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
