extends Node

const GAME_ROOT_SCENE := "res://scenes/game/GameRoot.tscn"
const STARTUP_MENU_SCENE := "res://scenes/ui/StartupMenu.tscn"

var data_registry: DataRegistry
var save_service := SaveService.new()
var startup_menu: StartupMenu


func _ready() -> void:
	data_registry = DataRegistry.new()
	data_registry.name = "DataRegistry"
	add_child(data_registry)

	if not data_registry.load_all():
		push_error("Boot failed because static data could not be loaded.")
		return

	save_service.setup(data_registry)
	_show_startup_menu()


func _show_startup_menu() -> void:
	var startup_menu_scene := load(STARTUP_MENU_SCENE) as PackedScene
	if startup_menu_scene == null:
		push_error("Missing StartupMenu scene: %s" % STARTUP_MENU_SCENE)
		return

	startup_menu = startup_menu_scene.instantiate() as StartupMenu
	if startup_menu == null:
		push_error("StartupMenu scene does not instantiate as StartupMenu.")
		return

	startup_menu.configure_save_summary(save_service.get_save_slot_summary(SaveService.DEFAULT_SLOT_ID))
	startup_menu.new_game_requested.connect(_on_startup_new_game_requested)
	startup_menu.load_game_requested.connect(_on_startup_load_game_requested)
	startup_menu.quit_requested.connect(_on_startup_quit_requested)
	add_child(startup_menu)


func _on_startup_new_game_requested() -> void:
	_start_game("")


func _on_startup_load_game_requested() -> void:
	_start_game(SaveService.DEFAULT_SLOT_ID)


func _on_startup_quit_requested() -> void:
	get_tree().quit()


func _start_game(startup_load_slot_id: String) -> void:
	var game_root_scene := load(GAME_ROOT_SCENE) as PackedScene
	if game_root_scene == null:
		push_error("Missing GameRoot scene: %s" % GAME_ROOT_SCENE)
		return

	var game_root := game_root_scene.instantiate()
	game_root.data_registry = data_registry
	game_root.startup_load_slot_id = startup_load_slot_id
	if startup_menu != null:
		startup_menu.queue_free()
		startup_menu = null
	add_child(game_root)
