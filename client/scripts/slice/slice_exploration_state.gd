class_name SliceExplorationState
extends RefCounted

## Compact schema-9 first-journey and exploration state. Objective stages,
## markers and labels remain derived presentation and are never persisted.

const MAP_PIXEL_SIZE := Vector2i(2560, 768)
const CELL_SIZE := 64
const GRID_SIZE := Vector2i(40, 12)
const BIT_COUNT := GRID_SIZE.x * GRID_SIZE.y
const BYTE_COUNT := BIT_COUNT >> 3
const BASE64_LENGTH := 80
const START_SPAWN := Vector2(400, 576)
const CORE_POSITION := Vector2(640, 320)

var terminal_opened := false
var part_recipe_inspected := false
var _bits := PackedByteArray()


func _init() -> void:
	_bits.resize(BYTE_COUNT)
	_bits.fill(0)


func configure_new_game() -> void:
	terminal_opened = false
	part_recipe_inspected = false
	_bits.fill(0)
	reveal_at(START_SPAWN, 3)
	reveal_at(CORE_POSITION, 3)


func restore(flags: Dictionary, encoded_bits: String) -> void:
	terminal_opened = bool(flags.get("terminal_opened", false))
	part_recipe_inspected = bool(
		flags.get("part_recipe_inspected", false)
	)
	var decoded := Marshalls.base64_to_raw(encoded_bits)
	if decoded.size() == BYTE_COUNT:
		_bits = decoded
	else:
		configure_new_game()


func mark_terminal_opened() -> bool:
	if terminal_opened:
		return false
	terminal_opened = true
	return true


func mark_part_recipe_inspected() -> bool:
	if part_recipe_inspected:
		return false
	part_recipe_inspected = true
	return true


func reveal_at(world_position: Vector2, radius_cells: int = 1) -> bool:
	var center := world_to_cell(world_position)
	var changed := false
	for y in range(center.y - radius_cells, center.y + radius_cells + 1):
		for x in range(center.x - radius_cells, center.x + radius_cells + 1):
			var cell := Vector2i(x, y)
			if not is_cell_valid(cell):
				continue
			if Vector2(cell - center).length() > float(radius_cells) + 0.35:
				continue
			changed = _set_revealed(cell) or changed
	return changed


func is_revealed(cell: Vector2i) -> bool:
	if not is_cell_valid(cell):
		return false
	var index := cell.y * GRID_SIZE.x + cell.x
	return (_bits[index >> 3] & (1 << (index % 8))) != 0


func explored_cell_count() -> int:
	var total := 0
	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x):
			if is_revealed(Vector2i(x, y)):
				total += 1
	return total


func flags_data() -> Dictionary:
	return {
		"terminal_opened": terminal_opened,
		"part_recipe_inspected": part_recipe_inspected,
	}


func encoded_bits() -> String:
	return Marshalls.raw_to_base64(_bits)


func bits_copy() -> PackedByteArray:
	return _bits.duplicate()


static func is_cell_valid(cell: Vector2i) -> bool:
	return (
		cell.x >= 0 and cell.y >= 0
		and cell.x < GRID_SIZE.x and cell.y < GRID_SIZE.y
	)


static func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(floor(world_position.x / CELL_SIZE)), 0, GRID_SIZE.x - 1),
		clampi(int(floor(world_position.y / CELL_SIZE)), 0, GRID_SIZE.y - 1)
	)


static func default_bits_for_position(world_position: Vector2) -> String:
	var state := SliceExplorationState.new()
	state.configure_new_game()
	state.reveal_at(world_position, 2)
	return state.encoded_bits()


func _set_revealed(cell: Vector2i) -> bool:
	var index := cell.y * GRID_SIZE.x + cell.x
	var byte_index := index >> 3
	var mask := 1 << (index % 8)
	if (_bits[byte_index] & mask) != 0:
		return false
	_bits[byte_index] |= mask
	return true
