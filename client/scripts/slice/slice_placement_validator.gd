class_name SlicePlacementValidator
extends RefCounted

## Authoritative placement query assembled from the existing ground, occupancy,
## collision and power models. It returns preview detail without owning state.

var _world: Node2D
var _ground: TileMapLayer
var _occupancy: SliceBuildingOccupancy
var _power_grid: SlicePowerGrid
var _player: SlicePlayer
var _map_pixel_size := Vector2i.ZERO
var _tile_size := 32.0
var _rock_source_id := -1
var _crystal_source_id := -1


func setup(
	world: Node2D,
	ground: TileMapLayer,
	occupancy: SliceBuildingOccupancy,
	power_grid: SlicePowerGrid,
	player: SlicePlayer,
	map_pixel_size: Vector2i,
	tile_size: float,
	rock_source_id: int,
	crystal_source_id: int
) -> void:
	_world = world
	_ground = ground
	_occupancy = occupancy
	_power_grid = power_grid
	_player = player
	_map_pixel_size = map_pixel_size
	_tile_size = tile_size
	_rock_source_id = rock_source_id
	_crystal_source_id = crystal_source_id


func validate(
	definition: SliceBuildingDefinition,
	origin_cell: Vector2i,
	rotation: int,
	available_floor_kits: int = 0,
	reserved_approach_cells: Array[Vector2i] = []
) -> Dictionary:
	var cells := definition.occupied_cells(origin_cell, rotation)
	for cell in cells:
		if cell.x < 0 or cell.y < 0:
			return _result(false, "越界", cells)
		if cell.x >= _map_pixel_size.x / int(_tile_size):
			return _result(false, "越界", cells)
		if cell.y >= _map_pixel_size.y / int(_tile_size):
			return _result(false, "越界", cells)
	if not definition.is_floor:
		for cell in cells:
			if reserved_approach_cells.has(cell):
				return _result(false, "设备接口接驳区需留空", cells)
		var approach_cells := definition.logistics_approach_cells(
			origin_cell, rotation
		)
		if not _occupancy.can_occupy(approach_cells, false):
			return _result(false, "设备接口接驳区需留空", cells)

	var missing_floor_cells: Array[Vector2i] = []
	var missing_floor_has_invalid_surface := false
	for cell in cells:
		var source_id := _ground.get_cell_source_id(cell)
		if (
			definition.surface_rule
			== SliceBuildingDefinition.SURFACE_BUILDABLE_ROCK
			and source_id != _rock_source_id
		):
			return _result(false, "需可建岩地", cells)
		if (
			definition.surface_rule == SliceBuildingDefinition.SURFACE_CRYSTAL
			and source_id != _crystal_source_id
		):
			return _result(false, "需晶体地", cells)
		if (
			definition.surface_rule
			== SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR
			and not _occupancy.has_floor(cell)
		):
			missing_floor_cells.append(cell)
			if source_id != _rock_source_id:
				missing_floor_has_invalid_surface = true

	if not _occupancy.can_occupy(cells, definition.is_floor):
		return _result(false, "已有占用", cells, missing_floor_cells)

	var query := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new()
	var footprint := (
		Vector2(definition.rotated_footprint(rotation)) * _tile_size
	)
	shape.size = footprint - Vector2(2, 2)
	query.shape = shape
	query.collide_with_areas = false
	query.transform = Transform2D(
		0.0,
		definition.block_center(origin_cell, _tile_size, rotation)
	)
	var collisions := (
		_world.get_world_2d().direct_space_state.intersect_shape(query, 8)
	)
	for collision in collisions:
		if collision.get("collider") == _player:
			return _result(false, "玩家阻挡", cells, missing_floor_cells)
	if not collisions.is_empty():
		return _result(false, "已有占用", cells, missing_floor_cells)
	if (
		definition.power_role == SliceBuildingDefinition.POWER_RELAY
		and not _power_grid.can_connect_relay_at(
			definition.block_center(origin_cell, _tile_size, rotation)
		)
	):
		return _result(
			false,
			"超出电网连接距离",
			cells,
			missing_floor_cells
		)
	if missing_floor_has_invalid_surface:
		return _result(
			false,
			"此处无法自动铺设工业地板",
			cells,
			missing_floor_cells
		)
	if missing_floor_cells.size() > available_floor_kits:
		return _result(
			false,
			"工业地板不足：需%d，有%d" % [
				missing_floor_cells.size(),
				available_floor_kits,
			],
			cells,
			missing_floor_cells
		)
	return _result(true, "", cells, missing_floor_cells)


func _result(
	valid: bool,
	reason: String,
	cells: Array[Vector2i],
	missing_floor_cells: Array[Vector2i] = []
) -> Dictionary:
	return {
		"valid": valid,
		"reason": reason,
		"cells": cells,
		"missing_floor_cells": missing_floor_cells,
		"required_floor_kits": missing_floor_cells.size(),
	}
