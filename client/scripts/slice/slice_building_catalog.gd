class_name SliceBuildingCatalog
extends RefCounted

## Package-1 building registry. Later L3 packages add definitions here instead
## of branching the world controller for every new device.

const FLOOR_ID := "building.floor"
const COLLECTOR_ID := "building.collector"


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
				"res://assets/tiles/slice/industrial_floor_terrain.png",
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
				"res://assets/sprites/slice/collector.png",
				Vector2(0, -16),
				Rect2(),
				["buffer"]
			)
	return null


static func all() -> Array[SliceBuildingDefinition]:
	return [find(FLOOR_ID), find(COLLECTOR_ID)]
