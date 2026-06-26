extends SceneTree

const BootScene := preload("res://scenes/boot/Boot.tscn")
const StartupMenuScene := preload("res://scenes/ui/StartupMenu.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	await _run_checks()

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
	await _check_boot_starts_on_menu()


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


func _check_boot_starts_on_menu() -> void:
	var boot := BootScene.instantiate()
	root.add_child(boot)
	await process_frame
	var menu := boot.get_node_or_null("StartupMenu") as StartupMenu
	_expect_equal(menu != null, true, "boot shows startup menu before game root")
	_expect_equal(boot.get_node_or_null("GameRoot") == null, true, "boot does not enter game before menu action")
	boot.free()


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])
