extends Node

const GAME_ROOT_SCENE := "res://scenes/game/GameRoot.tscn"
const SLICE_BASE_SCENE := "res://scenes/slice/SliceWorld.tscn"
const STARTUP_MENU_SCENE := "res://scenes/ui/StartupMenu.tscn"
const FACTORY_SCENE := preload("res://scenes/factory/FactoryWorld.tscn")
const FACTORY_MENU := preload("res://scripts/factory/world_menu.gd")

var data_registry: DataRegistry
var slice_save_catalog := SliceSaveCatalog.new()
var slice_save_service: SliceSaveService
var slice_world: SliceWorld
var startup_menu: StartupMenu
var factory_save_root := "user://saves/factory/worlds"
var factory_menu: Control
var factory_world: Control


func _ready() -> void:
	data_registry = DataRegistry.new()
	data_registry.name = "DataRegistry"
	add_child(data_registry)

	if not data_registry.load_all():
		push_error("Boot failed because static data could not be loaded.")
		return

	var migration_result := slice_save_catalog.migrate_legacy_single_world()
	var migration_notice := ""
	if not bool(migration_result.get("success", false)):
		migration_notice = String(
			migration_result.get("message", "旧存档迁移失败。")
		)
	else:
		var migration_data: Dictionary = migration_result.get("data", {})
		if bool(migration_data.get("migrated", false)):
			migration_notice = "已将旧单档无损导入“前哨 01”。"
	_show_startup_menu(migration_notice)


func _show_startup_menu(notice: String = "") -> void:
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

	startup_menu.configure_save_catalog(slice_save_catalog, notice)
	startup_menu.world_created.connect(_on_startup_world_created)
	startup_menu.world_load_requested.connect(_on_startup_world_load_requested)
	startup_menu.quit_requested.connect(_on_startup_quit_requested)
	startup_menu.factory_requested.connect(_show_factory_menu)


func _show_factory_menu() -> void:
	if startup_menu != null:
		startup_menu.queue_free()
		startup_menu = null
	factory_menu = FACTORY_MENU.new()
	factory_menu.save_root = factory_save_root
	factory_menu.back_requested.connect(func():
		factory_menu.queue_free()
		factory_menu = null
		_show_startup_menu())
	factory_menu.world_ready.connect(_start_factory)
	add_child(factory_menu)


func _start_factory(store: RefCounted, model: RefCounted, candidate: Dictionary) -> void:
	factory_menu.hide()
	factory_world = FACTORY_SCENE.instantiate()
	factory_world.store = store
	factory_world.model = model
	factory_world.candidate = candidate
	factory_world.return_requested.connect(func():
		factory_world.queue_free()
		factory_world = null
		factory_menu.show()
		factory_menu.refresh())
	factory_world.load_failed.connect(func(reason: String):
		factory_world.queue_free()
		factory_world = null
		factory_menu.show()
		factory_menu.notice.text = reason)
	add_child(factory_world)


func _on_startup_world_created(world_id: String) -> void:
	_start_slice(world_id, false)


func _on_startup_world_load_requested(world_id: String) -> void:
	_start_slice(world_id, true)


func _on_startup_quit_requested() -> void:
	get_tree().quit()


func _start_slice(world_id: String, startup_load: bool) -> void:
	slice_save_service = slice_save_catalog.service_for_world(world_id)
	if slice_save_service == null:
		if startup_menu != null:
			startup_menu.show_catalog_message(
				"无法打开所选世界，请刷新列表后重试。"
			)
		return
	var slice_scene := load(SLICE_BASE_SCENE) as PackedScene
	if slice_scene == null:
		push_error("Missing slice base scene: %s" % SLICE_BASE_SCENE)
		return

	slice_world = slice_scene.instantiate() as SliceWorld
	if slice_world == null:
		push_error("Slice base scene does not instantiate as SliceWorld.")
		return
	slice_world.save_service = slice_save_service
	slice_world.startup_load = startup_load
	slice_world.return_to_startup_requested.connect(
		_on_slice_return_to_startup_requested
	)

	if startup_menu != null:
		startup_menu.queue_free()
		startup_menu = null
	add_child(slice_world)


func _on_slice_return_to_startup_requested() -> void:
	if slice_world == null:
		return
	slice_world.queue_free()
	slice_world = null
	slice_save_service = null
	_show_startup_menu("当前世界已保存，可选择其他世界。")


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
