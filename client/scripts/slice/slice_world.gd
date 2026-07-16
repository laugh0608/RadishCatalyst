class_name SliceWorld
extends Node2D

## Slice world root: owns the single player instance and swaps area scenes
## (base <-> crystal expedition). Area scenes declare their edge exits as
## Area2D nodes under an "Exits" node, carrying `target_area` and
## `spawn_point` metadata; the player node survives every switch.

const AREA_SCENES := {
	"base": "res://scenes/slice/BaseFirstScreen.tscn",
	"crystal": "res://scenes/slice/CrystalExpedition.tscn",
}
const PLAYER_SCENE := "res://scenes/slice/SlicePlayer.tscn"
const START_AREA := "base"
const START_SPAWN := Vector2(400, 576)

var player: SlicePlayer
var current_area: Node2D
var _switching := false


func _ready() -> void:
	player = (load(PLAYER_SCENE) as PackedScene).instantiate() as SlicePlayer
	_enter_area(START_AREA, START_SPAWN)


func _enter_area(area_id: String, spawn_point: Vector2) -> void:
	if current_area != null:
		if player.get_parent() != null:
			player.get_parent().remove_child(player)
		current_area.queue_free()

	var area_scene := load(AREA_SCENES[area_id]) as PackedScene
	if area_scene == null:
		push_error("Missing slice area scene: %s" % AREA_SCENES[area_id])
		return

	current_area = area_scene.instantiate()
	add_child(current_area)
	current_area.get_node("World").add_child(player)
	player.position = spawn_point

	for exit_area in current_area.get_node("Exits").get_children():
		exit_area.body_entered.connect(_on_exit_entered.bind(exit_area))
	_switching = false


func _on_exit_entered(body: Node2D, exit_area: Area2D) -> void:
	if body != player or _switching:
		return
	_switching = true
	_enter_area.call_deferred(
		exit_area.get_meta("target_area"), exit_area.get_meta("spawn_point")
	)
