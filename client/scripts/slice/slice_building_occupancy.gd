class_name SliceBuildingOccupancy
extends RefCounted

## Separate floor and blocking occupancy layers. Facilities may stand on floor
## cells, but two floors or two blocking facilities may never claim one cell.

var _floor_cells: Dictionary = {}
var _blocking_cells: Dictionary = {}


func can_occupy(cells: Array[Vector2i], is_floor: bool) -> bool:
	for cell in cells:
		var key := _cell_key(cell)
		if is_floor:
			if _floor_cells.has(key) or _blocking_cells.has(key):
				return false
		elif _blocking_cells.has(key):
			return false
	return true


func occupy(instance_id: String, cells: Array[Vector2i], is_floor: bool) -> void:
	if instance_id.is_empty():
		push_error("Building occupancy requires a non-empty instance id.")
		return
	var target := _floor_cells if is_floor else _blocking_cells
	for cell in cells:
		target[_cell_key(cell)] = instance_id


func release(instance_id: String) -> void:
	_release_from(_floor_cells, instance_id)
	_release_from(_blocking_cells, instance_id)


func has_floor(cell: Vector2i) -> bool:
	return _floor_cells.has(_cell_key(cell))


func blocking_instance_at(cell: Vector2i) -> String:
	return String(_blocking_cells.get(_cell_key(cell), ""))


func floor_instance_at(cell: Vector2i) -> String:
	return String(_floor_cells.get(_cell_key(cell), ""))


func clear() -> void:
	_floor_cells.clear()
	_blocking_cells.clear()


func _release_from(layer: Dictionary, instance_id: String) -> void:
	var keys_to_remove: Array[String] = []
	for key in layer:
		if String(layer[key]) == instance_id:
			keys_to_remove.append(String(key))
	for key in keys_to_remove:
		layer.erase(key)


func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
