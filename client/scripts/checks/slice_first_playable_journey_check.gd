extends SceneTree

const SLICE_WORLD_SCENE := preload("res://scenes/slice/SliceWorld.tscn")
const SLICE_UI_THEME := preload("res://assets/themes/slice_ui_theme.tres")
const UI_HUD_ACCENT_STYLE_PATH := (
	"res://assets/themes/slice_ui_hud_accent_shell.tres"
)
const UI_HUD_SHELL_STYLE_PATH := (
	"res://assets/themes/slice_ui_hud_shell.tres"
)
const UI_HUD_SURFACE_STYLE_PATH := (
	"res://assets/themes/slice_ui_hud_surface.tres"
)
const UI_SHELL_STYLE := preload("res://assets/themes/slice_ui_shell.tres")
const UI_CARD_STYLE := preload("res://assets/themes/slice_ui_card.tres")
const UI_SURFACE_STYLE := preload("res://assets/themes/slice_ui_surface.tres")
const UI_HUD_PROGRESS_TRACK_STYLE_PATH := (
	"res://assets/themes/slice_ui_hud_progress_track.tres"
)

var failures: Array[String] = []
var assertion_count := 0
var save_dir := ""


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	await _run()
	if failures.is_empty():
		print(
			"Slice first playable journey checks passed (%d assertions)."
			% assertion_count
		)
		_cleanup()
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run() -> void:
	_expect_equal(
		SliceWorld.COLLECTOR_PRODUCE_INTERVAL,
		1.0,
		"collector cadence keeps the package 2A wait budget"
	)
	var minimum_production_wait := (
		37.0 * SliceWorld.COLLECTOR_PRODUCE_INTERVAL
		+ 2.07 * SliceReactor.PROCESS_DURATION
	)
	_expect_equal(
		minimum_production_wait <= 60.0,
		true,
		"renewable crystals and reactor stay within the 60-second budget"
	)
	save_dir = SliceCheckPaths.check_run("journey-guidance")
	var world := SLICE_WORLD_SCENE.instantiate() as SliceWorld
	world.save_service = SliceSaveService.new(save_dir)
	root.add_child(world)
	await process_frame
	await physics_frame

	var hud := world.get_node("SliceHud") as SliceHud
	var craft_panel := world._craft_panel as SliceCraftPanel
	_check_ui_readability_contract()
	_expect_stage(world, "repair_core", "合成机械零件", "按 B 合成")
	_expect_equal(
		hud.goal_label.text.contains("合成机械零件"),
		true,
		"fresh HUD consumes the derived repair goal"
	)
	_expect_equal(
		hud.get_node("LeftStatusPanel").size.y <= 120.0,
		true,
		"default journey HUD is vertically compact"
	)
	_expect_equal(
		hud.kit_label.visible,
		false,
		"complete kit inventory stays in the contextual craft panel"
	)
	_expect_equal(
		hud.crystal_label.text == "0/200"
		and hud.catalyst_label.text == "0"
		and hud.part_label.text == "0",
		true,
		"separate resource slots keep all journey-critical inventory"
	)
	_expect_equal(
		(hud.get_node("RightStatusPanel/CrystalSlot/Icon") as TextureRect).texture
		!= null
		and (
			hud.get_node("RightStatusPanel/CatalystSlot/Icon") as TextureRect
		).texture != null
		and (
			hud.get_node("RightStatusPanel/PartSlot/Icon") as TextureRect
		).texture != null,
		true,
		"every journey resource slot has a graphical identity"
	)
	_expect_equal(
		(hud.get_node("RightStatusPanel/CrystalSlot/ItemName") as Label).text
		== "晶体"
		and (
			hud.get_node("RightStatusPanel/CatalystSlot/ItemName") as Label
		).text == "催化剂"
		and (
			hud.get_node("RightStatusPanel/PartSlot/ItemName") as Label
		).text == "机械零件",
		true,
		"resource slots identify item meaning without relying on color"
	)
	_expect_equal(
		hud.health_bar.value == 100.0
		and hud.health_bar.max_value == 100.0,
		true,
		"player health uses a synchronized visible bar"
	)
	_expect_equal(
		_panel_style_path(hud.get_node("LeftStatusPanel"))
		== UI_HUD_ACCENT_STYLE_PATH,
		true,
		"mission HUD uses the dedicated A1 accent shell"
	)
	_expect_equal(
		_panel_style_path(hud.get_node("RightStatusPanel"))
		== UI_HUD_SHELL_STYLE_PATH
		and _panel_style_path(hud.get_node("PlayerStatusPanel"))
		== UI_HUD_SHELL_STYLE_PATH,
		true,
		"inventory and player HUD use the dedicated deep-steel shell"
	)
	_expect_equal(
		_panel_style_path(
			hud.get_node("RightStatusPanel/CrystalSlot")
		) == UI_HUD_SURFACE_STYLE_PATH,
		true,
		"resource slots use the dedicated recessed HUD surface"
	)
	_expect_equal(
		_panel_style_path(hud.get_node("PromptPanel"))
		== UI_HUD_SHELL_STYLE_PATH,
		true,
		"interaction prompts use the dedicated deep-steel shell"
	)
	_expect_equal(
		_style_path(hud.health_bar, "background")
		== UI_HUD_PROGRESS_TRACK_STYLE_PATH,
		true,
		"health bars use the dedicated HUD progress track"
	)

	world.mark_core_repaired()
	hud._refresh_state()
	_expect_stage(
		world,
		"power_collector",
		"基地目标 1/3",
		"采集器只能放晶体地"
	)
	craft_panel._refresh()
	_expect_equal(
		world.current_journey_rule_text().contains("6 格接力、4 格供能"),
		true,
		"journey state exposes the current collector power rule"
	)

	var collector := SliceCollector.new()
	collector.powered = true
	world._collector_nodes.append(collector)
	hud._refresh_state()
	_expect_stage(
		world,
		"power_reactor",
		"基地目标 2/3",
		"青色口进料，琥珀口出料"
	)
	_expect_equal(
		hud.goal_label.text.contains("放置通电反应器"),
		true,
		"HUD advances when renewable collection is powered"
	)

	var reactor := SliceReactor.new()
	reactor.powered = true
	world._reactor_nodes.append(reactor)
	hud._refresh_state()
	_expect_stage(
		world,
		"run_catalyst_line",
		"基地目标 3/3",
		"采集器 → 带 → 反应器左侧 IN"
	)
	craft_panel._refresh()
	_expect_equal(
		world.current_journey_rule_text().contains(
			"右侧 OUT → 带 → 储物箱"
		),
		true,
		"journey state exposes the fixed two-ended line rule"
	)

	var storage := SliceStorage.new()
	craft_panel._open = true
	craft_panel._root.visible = true
	storage.inventory.add(SliceWorld.ITEM_CATALYST, 1)
	world._building_instances.append(storage)
	world._storage_nodes.append(storage)
	world.building_storage_changed.emit("journey_storage")
	_expect_stage(
		world,
		"run_catalyst_line",
		"产出催化剂 1/2",
		"采集器 → 带 → 反应器左侧 IN"
	)
	storage.inventory.add(SliceWorld.ITEM_CATALYST, 1)
	world.building_storage_changed.emit("journey_storage")
	_expect_stage(
		world,
		"collect_catalyst",
		"从储物箱取出产物",
		"选择催化剂后取出"
	)
	_expect_equal(
		world.current_journey_rule_text().contains("选择催化剂后取出"),
		true,
		"storage-driven guidance updates the authoritative journey rule"
	)
	craft_panel._open = false
	craft_panel._root.visible = false
	world._building_instances.erase(storage)
	world._storage_nodes.erase(storage)
	storage.free()

	world.pocket.add(SliceWorld.ITEM_CATALYST, 2)
	hud._refresh_state()
	_expect_stage(
		world,
		"charge_core",
		"返回核心完成首次充能",
		"优先消耗核心仓库"
	)
	_expect_equal(
		world.confirm_core_charge(),
		true,
		"two authoritative catalysts advance the real charge state"
	)
	hud._refresh_state()
	_expect_stage(
		world,
		"field",
		"前往东侧晶体区",
		"鼠标左键攻击"
	)

	_check_contrast_panels(hud)
	world._placement.begin(
		SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID)
	)
	hud._process(0.0)
	_expect_equal(
		hud.prompt_panel.visible,
		true,
		"placement guidance enables its keycap panel"
	)
	_expect_equal(
		not hud.prompt_label.text.begins_with("按 E")
		and not hud.prompt_label.text.contains("R 旋转"),
		true,
		"fixed-front floor placement hides the rotation keycap"
	)
	world._placement.cancel()
	world._placement.begin(
		SliceBuildingCatalog.find(SliceBuildingCatalog.CONVEYOR_ID)
	)
	hud._process(0.0)
	_expect_equal(
		hud.prompt_label.text.contains("R 旋转"),
		true,
		"cardinal conveyor placement keeps the rotation keycap"
	)
	world._placement.cancel()
	hud._process(0.0)
	_expect_equal(
		hud.prompt_panel.visible,
		false,
		"empty interaction state hides the prompt panel"
	)

	world._collector_nodes.erase(collector)
	world._reactor_nodes.erase(reactor)
	collector.free()
	reactor.free()
	world.free()


func _check_ui_readability_contract() -> void:
	var ui_font := SLICE_UI_THEME.default_font as FontVariation
	_expect_equal(
		ui_font != null,
		true,
		"slice UI uses a dedicated readable font variation"
	)
	if ui_font != null:
		_expect_equal(
			float(ui_font.variation_opentype.get("wght", 0.0)),
			500.0,
			"slice UI keeps medium text weight"
		)
		var base_font := ui_font.base_font as FontFile
		_expect_equal(
			base_font != null
			and base_font.force_autohinter
			and base_font.hinting == TextServer.HINTING_NORMAL,
			true,
			"slice UI font keeps explicit autohinting and normal hinting"
		)
	var button_style := (
		SLICE_UI_THEME.get_stylebox("normal", "Button") as StyleBoxFlat
	)
	_expect_equal(
		button_style != null
		and button_style.bg_color.r > button_style.bg_color.b
		and _color_luma(button_style.bg_color) >= 0.78
		and _color_luma(button_style.bg_color) <= 0.85,
		true,
		"slice UI buttons use a light painted-metal material"
	)
	_expect_equal(
		UI_SHELL_STYLE.bg_color.r > UI_SHELL_STYLE.bg_color.b
		and UI_CARD_STYLE.bg_color.r > UI_CARD_STYLE.bg_color.b,
		true,
		"slice UI shell and cards use a warm industrial hierarchy"
	)
	var shell_luma := _color_luma(UI_SHELL_STYLE.bg_color)
	var card_luma := _color_luma(UI_CARD_STYLE.bg_color)
	var surface_luma := _color_luma(UI_SURFACE_STYLE.bg_color)
	_expect_equal(
		shell_luma >= 0.67 and shell_luma <= 0.74,
		true,
		"slice UI shell keeps a structural mid-light painted-metal band"
	)
	_expect_equal(
		card_luma >= shell_luma + 0.12 and card_luma >= 0.84,
		true,
		"slice UI cards clearly lift above the structural shell"
	)
	_expect_equal(
		surface_luma >= 0.67
		and surface_luma <= 0.74
		and UI_SURFACE_STYLE.bg_color.b
		> UI_SURFACE_STYLE.bg_color.r + 0.04,
		true,
		"slice UI recessed surfaces use a distinct cool structural plane"
	)
	_expect_equal(
		button_style != null
		and _color_luma(
			SLICE_UI_THEME.get_color("font_color", "Button")
		) <= 0.2,
		true,
		"slice UI light buttons use dark readable text"
	)
	var disabled_style := (
		SLICE_UI_THEME.get_stylebox("disabled", "Button") as StyleBoxFlat
	)
	_expect_equal(
		disabled_style != null
		and (
			_color_luma(disabled_style.bg_color)
			- _color_luma(
				SLICE_UI_THEME.get_color("font_disabled_color", "Button")
			)
		) >= 0.28,
		true,
		"slice UI disabled controls remain legible without reading as active"
	)


func _color_luma(color: Color) -> float:
	return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b


func _check_contrast_panels(hud: SliceHud) -> void:
	for node_name in [
		"LeftStatusPanel",
		"RightStatusPanel",
		"PlayerStatusPanel",
		"PromptPanel",
		"CombatActionPanel",
	]:
		var panel := hud.get_node_or_null(node_name) as Panel
		_expect_equal(panel != null, true, "%s exists" % node_name)
		if panel != null:
			var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
			_expect_equal(
				style != null and style.bg_color.a >= 0.85,
				true,
				"%s uses an opaque game-component shell" % node_name
			)
			_expect_equal(
				panel.mouse_filter == Control.MOUSE_FILTER_STOP,
				true,
				"%s blocks placement clicks from crossing UI" % node_name
			)
	_expect_equal(
		hud.get_node("LeftStatusPanel").size.x < 800.0
		and hud.get_node("RightStatusPanel").size.x < 640.0,
		true,
		"top components stay bounded to their safe corners"
	)
	_expect_equal(
		hud.enemy_health_bar != null
		and hud.get_node("PromptPanel/PromptKey") is Panel
		and hud.get_node("CombatActionPanel/AttackKey") is Panel
		and hud.get_node("CombatActionPanel/DodgeKey") is Panel
		and hud.get_node("CombatNotice/Accent") is ColorRect,
		true,
		"conditional combat and interaction components use bars, keycaps and accents"
	)
	var player_panel := hud.get_node("PlayerStatusPanel") as Panel
	var prompt_panel := hud.get_node("PromptPanel") as Panel
	_expect_equal(
		prompt_panel.position.x
		>= player_panel.position.x + player_panel.size.x + 24.0,
		true,
		"bottom prompt stays clear of the player status component"
	)


func _panel_style_path(node: Node) -> String:
	return _style_path(node, "panel")


func _style_path(node: Node, style_name: String) -> String:
	var control := node as Control
	if control == null:
		return ""
	var style := control.get_theme_stylebox(style_name)
	return "" if style == null else style.resource_path


func _expect_stage(
	world: SliceWorld,
	stage: String,
	goal_fragment: String,
	rule_fragment: String
) -> void:
	var guidance := world.current_journey_guidance()
	_expect_equal(
		String(guidance.get("stage", "")),
		stage,
		"%s is the derived journey stage" % stage
	)
	_expect_equal(
		String(guidance.get("goal", "")).contains(goal_fragment),
		true,
		"%s exposes its short goal" % stage
	)
	_expect_equal(
		String(guidance.get("rule", "")).contains(rule_fragment),
		true,
		"%s exposes its current action rule" % stage
	)


func _expect_equal(actual, expected, context: String) -> void:
	assertion_count += 1
	if actual == expected:
		return
	failures.append(
		"%s: expected %s, got %s" % [context, str(expected), str(actual)]
	)


func _cleanup() -> void:
	if save_dir.is_empty():
		return
	var dir := DirAccess.open(save_dir)
	if dir != null:
		for file_name in dir.get_files():
			DirAccess.remove_absolute(save_dir.path_join(file_name))
	if DirAccess.dir_exists_absolute(save_dir):
		DirAccess.remove_absolute(save_dir)
