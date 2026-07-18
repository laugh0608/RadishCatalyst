class_name SliceWorld
extends Node2D

## Slice world root: one seamless map (base zone west, crystal expedition
## zone east) plus the player. Owns the runtime loop state (crystal count,
## the core-repaired flag, and the set of harvested cluster names) and an
## isolated SliceSaveService that auto-persists this state on every change and
## on quit. `startup_load` (set by Boot before the node enters the tree)
## decides whether _ready restores the saved slice or starts a fresh one.

const MAP_SCENE := "res://scenes/slice/SliceMap.tscn"
const PLAYER_SCENE := "res://scenes/slice/SlicePlayer.tscn"
const HUD_SCENE := "res://scenes/slice/SliceHud.tscn"
const MAP_PIXEL_SIZE := Vector2i(2560, 768)
const START_SPAWN := Vector2(400, 576)
const REPAIRED_CORE_TEXTURE := preload("res://assets/sprites/slice/outpost_core_repaired.png")

signal crystals_changed(count: int)
signal core_repair_completed

## Set by Boot before add_child: true loads the saved slice, false starts fresh.
var startup_load := false

var crystal_count := 0
var core_repaired := false
var harvested_clusters: Array[String] = []

var player: SlicePlayer

var _save_service := SliceSaveService.new()
var _map: Node2D


func _ready() -> void:
	_map = (load(MAP_SCENE) as PackedScene).instantiate()
	add_child(_map)

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

	if startup_load:
		_restore_from_save()


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
	var result := _save_service.save_state({
		"crystal_count": crystal_count,
		"core_repaired": core_repaired,
		"harvested_clusters": harvested_clusters,
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
