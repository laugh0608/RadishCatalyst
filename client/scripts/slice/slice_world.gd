class_name SliceWorld
extends Node2D

## Slice world root: one seamless map (base zone west, crystal expedition
## zone east) plus the player. Owns the runtime loop state (crystal count,
## the core-repaired flag, harvested cluster names, placed collectors and the
## collector carry state) and an isolated SliceSaveService that auto-persists
## this state on every change and on quit. `startup_load` (set by Boot before
## the node enters the tree) decides whether _ready restores the saved slice
## or starts a fresh one. Collector placement is only valid on free crystal
## ground (docs/features/slice-harvest-and-build-v1.md).

const MAP_SCENE := "res://scenes/slice/SliceMap.tscn"
const PLAYER_SCENE := "res://scenes/slice/SlicePlayer.tscn"
const HUD_SCENE := "res://scenes/slice/SliceHud.tscn"
const COLLECTOR_SCENE := "res://scenes/slice/SliceCollector.tscn"
const COLLECTOR_TEXTURE := preload("res://assets/sprites/slice/collector.png")
const REPAIRED_CORE_TEXTURE := preload("res://assets/sprites/slice/outpost_core_repaired.png")
const MAP_PIXEL_SIZE := Vector2i(2560, 768)
const START_SPAWN := Vector2(400, 576)
const TILE_SIZE := 32.0
const COLLECTOR_COST := 5
const CRYSTAL_GROUND_SOURCE_ID := 2
const GHOST_VALID_COLOR := Color(0.45, 1.0, 0.9, 0.55)
const GHOST_INVALID_COLOR := Color(1.0, 0.4, 0.35, 0.55)

signal crystals_changed(count: int)
signal core_repair_completed

## Set by Boot before add_child: true loads the saved slice, false starts fresh.
var startup_load := false

var crystal_count := 0
var core_repaired := false
var harvested_clusters: Array[String] = []
var collectors: Array[Vector2i] = []
var carrying_collector := false

var player: SlicePlayer

var _save_service := SliceSaveService.new()
var _map: Node2D
var _ground: TileMapLayer
var _ghost: Sprite2D
var _place_query: PhysicsShapeQueryParameters2D
var _target_cell := Vector2i.ZERO
var _target_valid := false


func _ready() -> void:
	_map = (load(MAP_SCENE) as PackedScene).instantiate()
	add_child(_map)
	_ground = _map.get_node("GroundLayer")

	player = (load(PLAYER_SCENE) as PackedScene).instantiate() as SlicePlayer
	player.world = self
	_map.get_node("World").add_child(player)
	player.position = START_SPAWN

	var camera := player.get_node("Camera") as Camera2D
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = MAP_PIXEL_SIZE.x
	camera.limit_bottom = MAP_PIXEL_SIZE.y

	var hud := (load(HUD_SCENE) as PackedScene).instantiate() as SliceHud
	add_child(hud)
	hud.setup(self, player)

	# Placement preview ghost draws above the y-sorted world container.
	_ghost = Sprite2D.new()
	_ghost.texture = COLLECTOR_TEXTURE
	_ghost.offset = Vector2(0, -29)
	_ghost.visible = false
	_map.add_child(_ghost)

	var place_shape := RectangleShape2D.new()
	place_shape.size = Vector2(30, 30)
	_place_query = PhysicsShapeQueryParameters2D.new()
	_place_query.shape = place_shape
	_place_query.collide_with_areas = false

	if startup_load:
		_restore_from_save()


func _physics_process(_delta: float) -> void:
	if not carrying_collector or player == null:
		_target_valid = false
		return
	_target_cell = Vector2i(((player.position + player.facing * TILE_SIZE) / TILE_SIZE).floor())
	_target_valid = _can_place(_target_cell)


func _process(_delta: float) -> void:
	_ghost.visible = carrying_collector
	if not carrying_collector:
		return
	_ghost.position = _cell_center(_target_cell)
	_ghost.modulate = GHOST_VALID_COLOR if _target_valid else GHOST_INVALID_COLOR


func harvest_crystals(cluster_name: String, amount: int) -> void:
	if not harvested_clusters.has(cluster_name):
		harvested_clusters.append(cluster_name)
	crystal_count += amount
	crystals_changed.emit(crystal_count)
	_autosave()


func spend_crystals(amount: int) -> bool:
	if crystal_count < amount:
		return false
	crystal_count -= amount
	crystals_changed.emit(crystal_count)
	_autosave()
	return true


func mark_core_repaired() -> void:
	core_repaired = true
	core_repair_completed.emit()
	_autosave()


func try_craft_collector() -> bool:
	if carrying_collector or crystal_count < COLLECTOR_COST:
		return false
	# Set the carry flag before spending so the autosave inside
	# spend_crystals persists both together.
	carrying_collector = true
	spend_crystals(COLLECTOR_COST)
	return true


func try_place_collector() -> bool:
	if not carrying_collector or not _can_place(_target_cell):
		return false
	_spawn_collector(_target_cell)
	collectors.append(_target_cell)
	carrying_collector = false
	_autosave()
	return true


func is_place_target_valid() -> bool:
	return _target_valid


func _can_place(cell: Vector2i) -> bool:
	if _ground.get_cell_source_id(cell) != CRYSTAL_GROUND_SOURCE_ID:
		return false
	_place_query.transform = Transform2D(0.0, _cell_center(cell))
	return get_world_2d().direct_space_state.intersect_shape(_place_query, 1).is_empty()


func _spawn_collector(cell: Vector2i) -> void:
	var collector := (load(COLLECTOR_SCENE) as PackedScene).instantiate() as Node2D
	collector.position = _cell_center(cell)
	_map.get_node("World").add_child(collector)


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE_SIZE + Vector2(TILE_SIZE, TILE_SIZE) * 0.5


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_autosave()


func _restore_from_save() -> void:
	var result := _save_service.load_state()
	if not bool(result.get("success", false)):
		push_warning("切片读档失败，按新档继续：%s" % String(result.get("message", "")))
		return

	var data: Dictionary = result.get("data", {})
	crystal_count = int(data.get("crystal_count", 0))
	core_repaired = bool(data.get("core_repaired", false))
	harvested_clusters = _to_string_array(data.get("harvested_clusters", []))
	carrying_collector = bool(data.get("carrying_collector", false))
	collectors.clear()
	for cell_pair in data.get("collectors", []):
		var cell := Vector2i(int(cell_pair[0]), int(cell_pair[1]))
		collectors.append(cell)
		_spawn_collector(cell)

	var world_node := _map.get_node("World")
	for cluster_name in harvested_clusters:
		var cluster := world_node.get_node_or_null(NodePath(cluster_name))
		if cluster != null:
			cluster.queue_free()

	if core_repaired:
		var core := world_node.get_node_or_null("OutpostCoreDamaged") as Sprite2D
		if core != null:
			core.texture = REPAIRED_CORE_TEXTURE

	player.position = Vector2(
		float(data.get("player_x", START_SPAWN.x)),
		float(data.get("player_y", START_SPAWN.y))
	)

	crystals_changed.emit(crystal_count)
	if core_repaired:
		core_repair_completed.emit()


func _autosave() -> void:
	var player_position := player.position if player != null else START_SPAWN
	var serialized_collectors := []
	for cell in collectors:
		serialized_collectors.append([cell.x, cell.y])
	var result := _save_service.save_state({
		"crystal_count": crystal_count,
		"core_repaired": core_repaired,
		"harvested_clusters": harvested_clusters,
		"collectors": serialized_collectors,
		"carrying_collector": carrying_collector,
		"player_x": player_position.x,
		"player_y": player_position.y
	})
	if not bool(result.get("success", false)):
		push_warning("切片自动存档失败：%s" % String(result.get("message", "")))


func _to_string_array(value) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(String(item))
	return result
