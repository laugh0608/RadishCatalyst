extends Node

const GAME_ROOT_SCENE := "res://scenes/game/GameRoot.tscn"


func _ready() -> void:
	var data_registry := DataRegistry.new()
	data_registry.name = "DataRegistry"
	add_child(data_registry)

	if not data_registry.load_all():
		push_error("Boot failed because static data could not be loaded.")
		return

	var game_root_scene := load(GAME_ROOT_SCENE) as PackedScene
	if game_root_scene == null:
		push_error("Missing GameRoot scene: %s" % GAME_ROOT_SCENE)
		return

	var game_root := game_root_scene.instantiate()
	game_root.data_registry = data_registry
	add_child(game_root)
