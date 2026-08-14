class_name SlicePlacementSupportFloorTransaction
extends RefCounted

## Creates missing industrial support floors as one placement transaction.
## SliceWorld remains authoritative for instance IDs and spawning; this helper
## owns preflight, rollback and the exact supporting-floor material cost.

var _ground: TileMapLayer
var _occupancy: SliceBuildingOccupancy
var _industrial_floor: TileMapLayer
var _building_instances: Array[SliceBuildingInstance]


func setup(
	ground: TileMapLayer,
	occupancy: SliceBuildingOccupancy,
	industrial_floor: TileMapLayer,
	building_instances: Array[SliceBuildingInstance]
) -> void:
	_ground = ground
	_occupancy = occupancy
	_industrial_floor = industrial_floor
	_building_instances = building_instances


func create(
	definition: SliceBuildingDefinition,
	cells: Array[Vector2i],
	pocket: Inventory,
	spawn_building: Callable
) -> Dictionary:
	if cells.is_empty():
		return {"success": true, "instances": []}
	if (
		definition.surface_rule
		!= SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR
		or pocket.count(SliceBuildingCatalog.FLOOR_ID) < cells.size()
	):
		return {"success": false, "instances": []}
	for cell in cells:
		var target_cells: Array[Vector2i] = [cell]
		if (
			_ground.get_cell_source_id(cell) != SliceWorld.ROCK_GROUND_SOURCE_ID
			or not _occupancy.can_occupy(target_cells, true)
		):
			return {"success": false, "instances": []}

	var floor_definition := SliceBuildingCatalog.find(
		SliceBuildingCatalog.FLOOR_ID
	)
	var instances: Array[SliceBuildingInstance] = []
	for cell in cells:
		var floor := spawn_building.call(
			floor_definition,
			"",
			cell,
			0,
			{}
		) as SliceBuildingInstance
		if floor == null:
			rollback(instances)
			return {"success": false, "instances": []}
		instances.append(floor)
	return {"success": true, "instances": instances}


func commit_cost(pocket: Inventory, instances: Array[SliceBuildingInstance]) -> void:
	if instances.is_empty():
		return
	var removed := pocket.remove(
		SliceBuildingCatalog.FLOOR_ID,
		instances.size()
	)
	if removed != instances.size():
		push_error("Automatic support floor cost drifted after validation.")


func rollback(instances: Array[SliceBuildingInstance]) -> void:
	for instance in instances:
		_occupancy.release(instance.instance_id)
		_industrial_floor.erase_cell(instance.origin_cell)
		_building_instances.erase(instance)
		instance.free()
