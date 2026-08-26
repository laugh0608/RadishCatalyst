extends SceneTree

const SliceWorldScene := preload("res://scenes/slice/SliceWorld.tscn")
const SliceHudScene := preload("res://scenes/slice/SliceHud.tscn")
const StartupMenuScene := preload("res://scenes/ui/StartupMenu.tscn")
const PauseMenuScene := preload("res://scenes/slice/SlicePauseMenu.tscn")

var failures: Array[String] = []
var _assertion_count := 0
var _test_root := ""


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_test_root = "user://slice-playtest-remediation-package4-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_test_root))
	await _check_user_settings_and_shared_panel()
	await _check_hud_safe_edges()
	await _check_power_link_contexts()
	if failures.is_empty():
		print(
			"Slice playtest remediation package 4 checks passed (%d assertions)."
			% _assertion_count
		)
		_cleanup()
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _check_user_settings_and_shared_panel() -> void:
	var settings := SliceUserSettings.new()
	settings.settings_path = _test_root.path_join("settings.cfg")
	root.add_child(settings)
	await process_frame
	_expect_equal(
		settings.settings_path,
		_test_root.path_join("settings.cfg"),
		"user settings use an isolated application file"
	)
	_expect(
		not settings.settings_path.contains("worlds/"),
		"user settings never enter a world directory"
	)
	settings.fullscreen = true
	settings.set_master_volume_percent(0, false)
	settings.set_sfx_volume_percent(37, false)
	_expect(settings.save_settings(), "validated user preferences persist")
	var config := ConfigFile.new()
	_expect_equal(config.load(settings.settings_path), OK, "settings config reloads")
	_expect_equal(
		config.get_value("window", "fullscreen"),
		true,
		"fullscreen preference uses the application config"
	)
	_expect_equal(
		config.get_value("audio", "master_volume_percent"),
		0,
		"master mute persists as zero percent"
	)
	_expect_equal(
		config.get_value("audio", "sfx_volume_percent"),
		37,
		"SFX percentage persists independently"
	)
	_expect(
		not config.has_section_key("world", "schema_version"),
		"application settings do not copy gameplay schema"
	)
	var master_index := AudioServer.get_bus_index(&"Master")
	var sfx_index := AudioServer.get_bus_index(&"SFX")
	_expect(master_index >= 0, "Master audio bus exists")
	_expect(sfx_index >= 0, "SFX audio bus exists")
	if master_index >= 0:
		_expect(AudioServer.is_bus_mute(master_index), "zero master volume mutes its bus")
	if sfx_index >= 0:
		_expect(
			absf(AudioServer.get_bus_volume_db(sfx_index) - linear_to_db(0.37)) < 0.01,
			"SFX percentage applies to the SFX bus"
		)

	var startup := StartupMenuScene.instantiate() as StartupMenu
	root.add_child(startup)
	await process_frame
	startup.settings_panel.setup(settings)
	_expect(
		startup.settings_panel is SliceSettingsPanel,
		"startup uses the shared settings panel"
	)
	startup.settings_button.pressed.emit()
	_expect(startup.settings_panel.is_open(), "startup opens functional settings")
	_expect(
		String(
			startup.settings_panel.get_node("Margin/Layout/Controls").text
		).contains("WASD"),
		"settings panel exposes current controls"
	)
	_expect_equal(
		(startup.settings_panel.get_node("PreviewPlayer") as AudioStreamPlayer).bus,
		&"SFX",
		"settings preview is routed through the SFX bus"
	)
	(startup.settings_panel.get_node(
		"Margin/Layout/MasterRow/MasterSlider"
	) as HSlider).value = 61
	(startup.settings_panel.get_node(
		"Margin/Layout/SfxRow/SfxSlider"
	) as HSlider).value = 62
	await create_timer(0.4).timeout
	var deferred_config := ConfigFile.new()
	_expect_equal(
		deferred_config.load(settings.settings_path),
		OK,
		"shared settings debounce publishes the application config"
	)
	_expect(
		int(deferred_config.get_value("audio", "master_volume_percent", -1)) == 61
		and int(deferred_config.get_value("audio", "sfx_volume_percent", -1)) == 62,
		"debounced sliders persist both audible values"
	)
	startup.settings_back_button.pressed.emit()
	_expect(not startup.settings_panel.is_open(), "startup closes shared settings")
	startup.free()

	var pause := PauseMenuScene.instantiate() as SlicePauseMenu
	root.add_child(pause)
	await process_frame
	pause.settings_panel.setup(settings)
	_expect(
		pause.settings_panel is SliceSettingsPanel,
		"pause uses the same settings panel scene"
	)
	pause.open()
	pause.settings_button.pressed.emit()
	_expect(pause.settings_panel.is_open(), "pause opens functional settings")
	pause.settings_back_button.pressed.emit()
	_expect(not pause.settings_panel.is_open(), "pause returns from shared settings")
	pause.release_for_transition()
	pause.free()
	settings.set_master_volume_percent(100, false)
	settings.set_sfx_volume_percent(100, false)
	settings.free()


func _check_hud_safe_edges() -> void:
	var hud := SliceHudScene.instantiate() as SliceHud
	root.add_child(hud)
	await process_frame
	_expect_equal(hud.minimap.offset_right, -18.0, "minimap uses the right safe margin")
	_expect_equal(hud.minimap.offset_bottom, -18.0, "minimap uses the bottom safe margin")
	_expect_equal(hud.minimap.size, Vector2(220, 134), "minimap keeps its readable size")
	_expect(
		hud.minimap.get_node("Header/Title").get_theme_font_size("font_size") >= 15,
		"minimap title no longer uses 12-13px text"
	)
	_expect(
		hud.minimap.get_node("Intel").get_theme_font_size("font_size") >= 15,
		"minimap intel no longer uses 12px text"
	)
	_expect(
		hud.rule_label.get_theme_font_size("font_size") >= 16,
		"task rule uses readable body text"
	)
	hud._set_prompt_layout(true)
	_expect_equal(hud.prompt_panel.anchor_left, 0.0, "wide prompt uses left edge anchoring")
	_expect_equal(hud.prompt_panel.anchor_right, 1.0, "wide prompt uses right edge anchoring")
	_expect_equal(
		hud.prompt_panel.offset_left,
		556.0,
		"wide prompt clears the bottom-left player stack"
	)
	_expect_equal(
		hud.prompt_panel.offset_right,
		-256.0,
		"wide prompt clears the bottom-right minimap stack"
	)
	_expect_equal(hud.prompt_label.anchor_right, 1.0, "prompt text follows panel width")
	hud._set_prompt_layout(false)
	_expect_equal(hud.prompt_panel.anchor_left, 0.5, "normal prompt returns to center")
	_expect_equal(
		hud.prompt_panel.offset_right - hud.prompt_panel.offset_left,
		720.0,
		"normal prompt keeps the frozen centered width"
	)
	var map_viewport := hud.minimap.get_node(
		"MapViewportContainer/MapViewport"
	) as SubViewport
	_expect_equal(
		map_viewport.render_target_update_mode,
		SubViewport.UPDATE_ALWAYS,
		"minimap refresh remains unchanged until A/B measurement"
	)
	hud.free()


func _check_power_link_contexts() -> void:
	var service := SliceSaveService.new(_test_root.path_join("world"))
	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = service
	root.add_child(world)
	await process_frame
	await physics_frame
	_expect_equal(
		world._power_links.context(),
		SlicePowerLinkLayer.CONTEXT_NORMAL,
		"ordinary play starts with power topology hidden"
	)
	_expect(not world._power_links.context_visible(), "ordinary play hides cyan power links")
	_clear_inventory(world.pocket)
	world.pocket.add(SliceBuildingCatalog.POWER_RELAY_ID, 1)
	_expect(
		world.begin_building_placement(SliceBuildingCatalog.POWER_RELAY_ID),
		"powered relay placement starts"
	)
	_expect_equal(
		world._power_links.context(),
		SlicePowerLinkLayer.CONTEXT_PLACEMENT,
		"power placement exposes the topology"
	)
	_expect(world._power_links.context_visible(), "power placement shows link geometry")
	world.cancel_building_placement()
	_expect(not world._power_links.context_visible(), "cancel returns to ordinary hidden state")
	world.pocket.add(SliceBuildingCatalog.FLOOR_ID, 1)
	_expect(
		world.begin_building_placement(SliceBuildingCatalog.FLOOR_ID),
		"passive floor placement starts"
	)
	_expect(
		not world._power_links.context_visible(),
		"passive placement does not expose irrelevant power topology"
	)
	world.cancel_building_placement()

	var storage := world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.STORAGE_ID),
		"package4-storage",
		Vector2i(62, 10),
		0,
		{}
	) as SliceStorage
	world.open_building_actions(storage)
	_expect_equal(
		world._power_links.context(),
		SlicePowerLinkLayer.CONTEXT_DEVICE,
		"powered device inspection exposes the topology"
	)
	world.close_building_actions()
	_expect(not world._power_links.context_visible(), "closing device inspection hides links")
	var conveyor := world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.CONVEYOR_ID),
		"package4-conveyor",
		Vector2i(68, 10),
		0,
		{}
	) as SliceConveyor
	world.open_building_actions(conveyor)
	_expect(
		not world._power_links.context_visible(),
		"passive device inspection leaves the power overlay hidden"
	)
	world.free()


func _clear_inventory(inventory: Inventory) -> void:
	for item_id in inventory.item_ids():
		inventory.remove(item_id, inventory.count(item_id))


func _cleanup() -> void:
	_remove_tree(ProjectSettings.globalize_path(_test_root))


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		var child := path.path_join(entry)
		if dir.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)


func _expect(condition: bool, label: String) -> void:
	_assertion_count += 1
	if not condition:
		failures.append(label)


func _expect_equal(actual, expected, label: String) -> void:
	_assertion_count += 1
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, expected, actual])
