class_name SliceWorld
extends Node2D

## Slice world root: one seamless map (base zone west, crystal expedition
## zone east) plus the player. Owns the runtime loop state (crystal count and
## the core-repaired flag) that the HUD and interactables read; this state is
## in-memory only, save integration is a later topic.

const MAP_SCENE := "res://scenes/slice/SliceMap.tscn"
const PLAYER_SCENE := "res://scenes/slice/SlicePlayer.tscn"
const HUD_SCENE := "res://scenes/slice/SliceHud.tscn"
const MAP_PIXEL_SIZE := Vector2i(2560, 768)
const START_SPAWN := Vector2(400, 576)

signal crystals_changed(count: int)
signal core_repair_completed

var crystal_count := 0
var core_repaired := false

var player: SlicePlayer


func _ready() -> void:
	var map := (load(MAP_SCENE) as PackedScene).instantiate()
	add_child(map)

	player = (load(PLAYER_SCENE) as PackedScene).instantiate() as SlicePlayer
	player.world = self
	map.get_node("World").add_child(player)
	player.position = START_SPAWN

	var camera := player.get_node("Camera") as Camera2D
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = MAP_PIXEL_SIZE.x
	camera.limit_bottom = MAP_PIXEL_SIZE.y

	var hud := (load(HUD_SCENE) as PackedScene).instantiate() as SliceHud
	add_child(hud)
	hud.setup(self, player)


func add_crystals(amount: int) -> void:
	crystal_count += amount
	crystals_changed.emit(crystal_count)


func spend_crystals(amount: int) -> bool:
	if crystal_count < amount:
		return false
	crystal_count -= amount
	crystals_changed.emit(crystal_count)
	return true


func mark_core_repaired() -> void:
	core_repaired = true
	core_repair_completed.emit()
