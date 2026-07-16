class_name SliceWorld
extends Node2D

## Slice world root: one seamless map (base zone west, crystal expedition
## zone east) plus the player. The player-mounted camera follows movement,
## clamped to the map bounds. Confirmed 2026-07-16: "单基地 + 单远征区" is
## two zones of one continuous map, not separate scenes.

const MAP_SCENE := "res://scenes/slice/SliceMap.tscn"
const PLAYER_SCENE := "res://scenes/slice/SlicePlayer.tscn"
const MAP_PIXEL_SIZE := Vector2i(2560, 768)
const START_SPAWN := Vector2(400, 576)

var player: SlicePlayer


func _ready() -> void:
	var map := (load(MAP_SCENE) as PackedScene).instantiate()
	add_child(map)

	player = (load(PLAYER_SCENE) as PackedScene).instantiate() as SlicePlayer
	map.get_node("World").add_child(player)
	player.position = START_SPAWN

	var camera := player.get_node("Camera") as Camera2D
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = MAP_PIXEL_SIZE.x
	camera.limit_bottom = MAP_PIXEL_SIZE.y
