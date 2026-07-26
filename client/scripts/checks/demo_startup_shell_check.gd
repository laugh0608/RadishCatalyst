extends SceneTree

const BootScene := preload("res://scenes/boot/Boot.tscn")
const StartupMenuScene := preload("res://scenes/ui/StartupMenu.tscn")
const TEST_ROOT := "/private/tmp/radishcatalyst-startup-world-list-check"
const PAUSE_TEST_ROOT := "/private/tmp/radishcatalyst-slice-pause-return-check"

var failures: Array[String] = []
var created_world_id := ""
var requested_load_world_id := ""


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_remove_tree(TEST_ROOT)
	_remove_tree(PAUSE_TEST_ROOT)
	await _run_checks()
	paused = false

	if failures.is_empty():
		print("Demo startup shell checks passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _run_checks() -> void:
	await _check_startup_menu_structure()
	await _check_startup_menu_save_state()
	await _check_world_catalog_ui()
	await _check_boot_starts_on_menu()
	await _check_boot_uses_selected_world()
	await _check_pause_return_to_startup()


func _check_startup_menu_structure() -> void:
	var menu := StartupMenuScene.instantiate() as StartupMenu
	root.add_child(menu)
	await process_frame
	_expect_equal(menu != null, true, "startup menu instantiates as StartupMenu")
	if menu == null:
		return
	_expect_text_contains(menu.title_label.text, "异星催化", "startup menu shows game title")
	_expect_text_contains(menu.subtitle_label.text, "受损前哨", "startup menu anchors industrial sci-fi premise")
	_expect_equal(menu.new_game_button.text, "新游戏", "startup menu has new game action")
	_expect_equal(menu.load_game_button.text, "载入存档", "startup menu has load action")
	_expect_text_contains(menu.multiplayer_button.text, "暂不开放", "startup menu marks multiplayer unavailable")
	_expect_equal(menu.multiplayer_button.disabled, true, "startup menu keeps multiplayer disabled")
	_expect_equal(menu.settings_button.text, "设置", "startup menu has settings entry")
	_expect_equal(menu.quit_button.text, "退出", "startup menu has quit action")
	_expect_equal(menu.settings_panel.visible, false, "settings panel starts hidden")
	_expect_equal(menu.world_panel.visible, false, "world panel starts hidden")
	menu.settings_button.pressed.emit()
	_expect_equal(menu.settings_panel.visible, true, "settings button opens lightweight settings panel")
	menu.settings_back_button.pressed.emit()
	_expect_equal(menu.settings_panel.visible, false, "settings back button closes settings panel")
	menu.free()


func _check_startup_menu_save_state() -> void:
	var menu := StartupMenuScene.instantiate() as StartupMenu
	root.add_child(menu)
	await process_frame
	menu.configure_save_summary({
		"display_name": "槽位 01",
		"status": "空槽位",
		"details": "尚未保存原型进度。",
		"has_loadable_save": false
	})
	_expect_equal(menu.load_game_button.disabled, true, "load button is disabled for empty default slot")
	menu.configure_save_summary({
		"display_name": "槽位 01",
		"status": "可读取",
		"details": "前哨核心已恢复。",
		"has_loadable_save": true
	})
	_expect_equal(menu.load_game_button.disabled, false, "load button is enabled for loadable default slot")
	_expect_text_contains(menu.slot_summary_label.text, "前哨核心已恢复", "slot summary keeps save context")
	menu.free()


func _check_world_catalog_ui() -> void:
	var catalog := SliceSaveCatalog.new(TEST_ROOT)
	var menu := StartupMenuScene.instantiate() as StartupMenu
	root.add_child(menu)
	await process_frame
	menu.configure_save_catalog(catalog)
	menu.world_created.connect(_capture_created_world)
	menu.world_load_requested.connect(_capture_requested_load)

	menu.new_game_button.pressed.emit()
	_expect_equal(menu.world_panel.visible, true, "new game opens world panel")
	_expect_equal(
		menu.world_name_input.has_focus(),
		true,
		"new game focuses world naming input"
	)
	menu.world_name_input.text = "L5 完整产线"
	menu.create_world_button.pressed.emit()
	_expect(not created_world_id.is_empty(), "create emits stable world id")
	_expect_equal(catalog.list_worlds().size(), 1, "create adds one world")

	var service := catalog.service_for_world(created_world_id)
	_expect(service != null, "created world exposes single-world service")
	if service != null:
		_expect_success(
			service.save_state(_state(11, 2)),
			"created world receives initial autosave"
		)
	menu.configure_save_catalog(catalog)
	_expect_equal(
		menu.load_game_button.disabled,
		false,
		"saved world enables load-world entry"
	)

	menu.load_game_button.pressed.emit()
	_expect_equal(menu.world_item_list.item_count, 1, "world list has one row")
	_expect_equal(
		menu.create_world_button.disabled,
		false,
		"world list allows creating when no existing world is selected"
	)
	menu.world_item_list.select(0)
	menu.world_item_list.item_selected.emit(0)
	_expect_equal(
		menu.create_world_button.disabled,
		true,
		"selecting an existing world disables create-and-enter"
	)
	var world_count_before_disabled_create := catalog.list_worlds().size()
	menu.create_world_button.pressed.emit()
	_expect_equal(
		catalog.list_worlds().size(),
		world_count_before_disabled_create,
		"disabled create action cannot create a duplicate world"
	)
	_expect_text_contains(
		menu.world_details_label.text,
		"建筑：2",
		"selected world shows progress summary"
	)
	menu.load_world_button.pressed.emit()
	_expect_equal(
		requested_load_world_id,
		created_world_id,
		"load action emits selected stable id"
	)

	menu.world_name_input.text = "L5 人工复核"
	menu.rename_world_button.pressed.emit()
	var renamed := catalog.list_worlds()[0]
	_expect_equal(
		String(renamed.get("world_id", "")),
		created_world_id,
		"UI rename preserves world id"
	)
	_expect_equal(
		String(renamed.get("display_name", "")),
		"L5 人工复核",
		"UI rename updates display name"
	)

	menu.world_item_list.select(0)
	menu.world_item_list.item_selected.emit(0)
	menu.trash_world_button.pressed.emit()
	_expect_equal(
		menu.trash_confirm_panel.visible,
		true,
		"move to trash requires confirmation"
	)
	menu.trash_confirm_button.pressed.emit()
	_expect_equal(catalog.list_worlds().size(), 0, "confirmed world leaves active list")
	_expect_equal(catalog.list_trash().size(), 1, "confirmed world enters trash")

	menu.trash_worlds_button.pressed.emit()
	menu.world_item_list.select(0)
	menu.world_item_list.item_selected.emit(0)
	menu.restore_world_button.pressed.emit()
	_expect_equal(catalog.list_worlds().size(), 1, "restore returns world to active list")
	_expect_equal(catalog.list_trash().size(), 0, "restore removes trash entry")
	menu.free()


func _check_boot_starts_on_menu() -> void:
	var catalog := SliceSaveCatalog.new(TEST_ROOT)
	var boot := BootScene.instantiate()
	boot.slice_save_catalog = catalog
	root.add_child(boot)
	await process_frame
	var menu := boot.get_node_or_null("StartupMenu") as StartupMenu
	_expect_equal(menu != null, true, "boot shows startup menu before game root")
	_expect_equal(boot.get_node_or_null("GameRoot") == null, true, "boot does not enter game before menu action")
	boot.free()


func _check_boot_uses_selected_world() -> void:
	var catalog := SliceSaveCatalog.new(TEST_ROOT)
	var worlds := catalog.list_worlds()
	if worlds.is_empty():
		failures.append("boot selected-world check needs preserved UI world")
		return
	var world_id := String(worlds[0].get("world_id", ""))
	var boot := BootScene.instantiate()
	boot.slice_save_catalog = catalog
	root.add_child(boot)
	await process_frame
	var menu := boot.get_node_or_null("StartupMenu") as StartupMenu
	_expect_equal(menu != null, true, "boot exposes configured world menu")
	if menu == null:
		boot.free()
		return
	menu.load_game_button.pressed.emit()
	_expect_equal(
		menu.world_item_list.item_count,
		1,
		"Boot menu lists the preserved review world"
	)
	if menu.world_item_list.item_count == 0:
		boot.free()
		return
	menu.world_item_list.select(0)
	menu.world_item_list.item_selected.emit(0)
	menu.load_world_button.pressed.emit()
	await process_frame
	await process_frame
	var world := boot.get_node_or_null("SliceWorld") as SliceWorld
	_expect_equal(world != null, true, "load selection enters slice world")
	if world != null:
		var expected_dir := catalog.worlds_directory().path_join(world_id)
		_expect_equal(
			world.save_service.save_directory(),
			expected_dir,
			"Boot injects the selected world's service"
		)
		_expect_equal(world.startup_load, true, "selected world starts in load mode")
	boot.free()


func _check_pause_return_to_startup() -> void:
	var catalog := SliceSaveCatalog.new(PAUSE_TEST_ROOT)
	var create_result := catalog.create_world("暂停返回复核")
	_expect_success(create_result, "pause check creates world")
	if not bool(create_result.get("success", false)):
		return
	var world_id := String(create_result.get("data", {}).get("world_id", ""))
	var service := catalog.service_for_world(world_id)
	_expect(service != null, "pause check receives world service")
	if service == null:
		return
	_expect_success(service.save_state(_state(11, 0)), "pause check seeds world")

	var boot := BootScene.instantiate()
	boot.slice_save_catalog = catalog
	root.add_child(boot)
	await process_frame
	var menu := boot.get_node_or_null("StartupMenu") as StartupMenu
	if menu == null:
		failures.append("pause check needs StartupMenu")
		boot.free()
		return
	menu.load_game_button.pressed.emit()
	menu.world_item_list.select(0)
	menu.world_item_list.item_selected.emit(0)
	menu.load_world_button.pressed.emit()
	await process_frame
	await process_frame
	var world := boot.get_node_or_null("SliceWorld") as SliceWorld
	_expect(world != null, "pause check enters SliceWorld")
	if world == null:
		boot.free()
		return
	world.core_energy = 27
	await _press_action("craft_menu")
	_expect(world._craft_panel.is_open(), "craft action opens foreground panel")
	await _press_action("ui_cancel")
	_expect(
		not world._craft_panel.is_open(),
		"first Escape closes foreground panel"
	)
	_expect(
		not world.pause_menu.is_open(),
		"closing foreground panel does not also pause"
	)
	await _press_action("ui_cancel")
	_expect(world.pause_menu.is_open(), "Escape opens pause menu")
	_expect(paused, "pause menu pauses world tree")
	world.pause_menu.settings_button.pressed.emit()
	_expect(
		world.pause_menu.settings_panel.visible,
		"pause settings button opens settings panel"
	)
	await _press_action("ui_cancel")
	_expect(
		not world.pause_menu.settings_panel.visible,
		"Escape returns from pause settings"
	)
	_expect(world.pause_menu.is_open(), "settings back keeps pause menu open")
	world.pause_menu.return_button.pressed.emit()
	_expect(
		world.pause_menu.confirm_panel.visible,
		"save-and-return requires confirmation"
	)
	world.pause_menu.confirm_button.pressed.emit()
	await process_frame
	await process_frame
	_expect(not paused, "return to startup unpauses tree")
	_expect(
		boot.get_node_or_null("SliceWorld") == null,
		"return removes the active SliceWorld"
	)
	var returned_menu := boot.get_node_or_null("StartupMenu") as StartupMenu
	_expect(returned_menu != null, "return rebuilds StartupMenu")
	var saved_result := service.load_state()
	_expect_success(saved_result, "return writes selected world")
	_expect_equal(
		int(saved_result.get("data", {}).get("core_energy", 0)),
		27,
		"return saves latest world state"
	)
	if returned_menu != null:
		returned_menu.load_game_button.pressed.emit()
		returned_menu.world_item_list.select(0)
		returned_menu.world_item_list.item_selected.emit(0)
		returned_menu.load_world_button.pressed.emit()
		await process_frame
		await process_frame
		var reloaded := boot.get_node_or_null("SliceWorld") as SliceWorld
		_expect(reloaded != null, "returned world can be loaded again")
		if reloaded != null:
			_expect_equal(
				reloaded.core_energy,
				27,
				"reloaded world keeps state saved during return"
			)
	boot.free()
	paused = false


func _press_action(action: StringName) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await process_frame
	var released := InputEventAction.new()
	released.action = action
	released.pressed = false
	Input.parse_input_event(released)
	await process_frame


func _capture_created_world(world_id: String) -> void:
	created_world_id = world_id


func _capture_requested_load(world_id: String) -> void:
	requested_load_world_id = world_id


func _state(core_energy: int, building_count: int) -> Dictionary:
	var buildings: Array[Dictionary] = []
	for index in range(building_count):
		buildings.append({
			"instance_id": "building-%06d" % (index + 1),
			"building_id": SliceBuildingCatalog.FLOOR_ID,
			"origin_cell": [4 + index, 4],
			"rotation": 0,
			"state": {},
		})
	return {
		"pocket": {"capacity": 20, "contents": {}},
		"core_storage": {
			"capacity": 120,
			"contents": {"catalyst": core_energy},
		},
		"core_repaired": true,
		"core_energy": core_energy,
		"harvested_clusters": [],
		"buildings": buildings,
		"next_building_serial": building_count + 1,
		"player_x": 480.0,
		"player_y": 270.0,
	}


func _expect_success(result: Dictionary, context: String) -> void:
	if bool(result.get("success", false)):
		return
	failures.append(
		"%s: %s" % [context, String(result.get("message", ""))]
	)


func _remove_tree(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	var dir := DirAccess.open(absolute_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		var child := absolute_path.path_join(entry)
		if dir.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(absolute_path)


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _expect(condition: bool, context: String) -> void:
	if not condition:
		failures.append(context)
