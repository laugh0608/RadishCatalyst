extends Node

const GAME_ROOT_SCENE := "res://scenes/game/GameRoot.tscn"
const SLICE_BASE_SCENE := "res://scenes/slice/SliceWorld.tscn"
const STARTUP_MENU_SCENE := "res://scenes/ui/StartupMenu.tscn"

var data_registry: DataRegistry
var slice_save_service := SliceSaveService.new()
var startup_menu: StartupMenu


func _ready() -> void:
	data_registry = DataRegistry.new()
	data_registry.name = "DataRegistry"
	add_child(data_registry)

	if not data_registry.load_all():
		push_error("Boot failed because static data could not be loaded.")
		return

	_show_startup_menu()


func _show_startup_menu() -> void:
	startup_menu = get_node_or_null("StartupMenu") as StartupMenu
	if startup_menu == null:
		var startup_menu_scene := load(STARTUP_MENU_SCENE) as PackedScene
		if startup_menu_scene == null:
			push_error("Missing StartupMenu scene: %s" % STARTUP_MENU_SCENE)
			return

		startup_menu = startup_menu_scene.instantiate() as StartupMenu
		if startup_menu == null:
			push_error("StartupMenu scene does not instantiate as StartupMenu.")
			return
		add_child(startup_menu)

	startup_menu.configure_save_summary(slice_save_service.get_summary())
	startup_menu.new_game_requested.connect(_on_startup_new_game_requested)
	startup_menu.load_game_requested.connect(_on_startup_load_game_requested)
	startup_menu.quit_requested.connect(_on_startup_quit_requested)


func _on_startup_new_game_requested() -> void:
	_start_slice(false)


func _on_startup_load_game_requested() -> void:
	_start_slice(true)


func _on_startup_quit_requested() -> void:
	get_tree().quit()


func _start_slice(startup_load: bool) -> void:
	var slice_scene := load(SLICE_BASE_SCENE) as PackedScene
	if slice_scene == null:
		push_error("Missing slice base scene: %s" % SLICE_BASE_SCENE)
		return

	var slice_world := slice_scene.instantiate() as SliceWorld
	if slice_world == null:
		push_error("Slice base scene does not instantiate as SliceWorld.")
		return
	slice_world.save_service = slice_save_service
	slice_world.startup_load = startup_load

	if startup_menu != null:
		startup_menu.queue_free()
		startup_menu = null
	add_child(slice_world)


# Frozen legacy GameRoot entry, no longer reachable from the menu since the
# slice save topic rewired "载入存档" to the slice load path.
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
