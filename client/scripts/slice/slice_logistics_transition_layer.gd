class_name SliceLogisticsTransitionLayer
extends Node2D

## Non-persistent ground sprites for explicit multi-cell device approaches.
## Port geometry remains authoritative; this layer only makes a connected
## transition readable without moving simulated conveyor cells into Y sort.

const DIRECTION_TEXTURES := {
	Vector2i.UP: preload("res://assets/sprites/slice/conveyor_up.png"),
	Vector2i.RIGHT: preload("res://assets/sprites/slice/conveyor_right.png"),
	Vector2i.DOWN: preload("res://assets/sprites/slice/conveyor_down.png"),
	Vector2i.LEFT: preload("res://assets/sprites/slice/conveyor_left.png"),
}

var _transition_cells: Array[Vector2i] = []


func set_transitions(ports: Array[Dictionary], tile_size: float) -> void:
	for child in get_children():
		child.free()
	_transition_cells.clear()
	for port in ports:
		if (
			not bool(port.get("connected", false))
			or int(port.get("connection_distance", 1)) <= 1
		):
			continue
		var outward := Vector2i(port["outward_direction"])
		var flow := (
			-outward
			if String(port.get("role", ""))
			== SliceLogisticsPortDefinition.ROLE_INPUT
			else outward
		)
		var texture := DIRECTION_TEXTURES.get(flow) as Texture2D
		for step in range(1, int(port["connection_distance"])):
			var cell := Vector2i(port["port_cell"]) + outward * step
			var sprite := Sprite2D.new()
			sprite.name = "Transition_%d_%d" % [cell.x, cell.y]
			sprite.position = (Vector2(cell) + Vector2(0.5, 0.5)) * tile_size
			sprite.texture = texture
			sprite.z_index = 0
			add_child(sprite)
			_transition_cells.append(cell)


func transition_count() -> int:
	return _transition_cells.size()


func has_transition_at(cell: Vector2i) -> bool:
	return _transition_cells.has(cell)
