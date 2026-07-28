extends SceneTree

const SLICE_WORLD_SCENE := preload("res://scenes/slice/SliceWorld.tscn")

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
	save_dir = "/private/tmp/radishcatalyst-journey-guidance-%d" % (
		Time.get_ticks_usec()
	)
	var world := SLICE_WORLD_SCENE.instantiate() as SliceWorld
	world.save_service = SliceSaveService.new(save_dir)
	root.add_child(world)
	await process_frame
	await physics_frame

	var hud := world.get_node("SliceHud") as SliceHud
	var craft_panel := world._craft_panel as SliceCraftPanel
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
		hud.crystal_label.text == "0/30"
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
		hud.health_bar.value == 100.0
		and hud.health_bar.max_value == 100.0,
		true,
		"player health uses a synchronized visible bar"
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
		craft_panel._rule.text.contains("6 格接力、4 格供能"),
		true,
		"craft panel exposes the current collector power rule"
	)

	var collector := SliceCollector.new()
	collector.powered = true
	world._collector_nodes.append(collector)
	hud._refresh_state()
	_expect_stage(
		world,
		"power_reactor",
		"基地目标 2/3",
		"青色口进料、琥珀口出料"
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
		"晶体箱 → 带 → 青色入料口"
	)
	craft_panel._refresh()
	_expect_equal(
		craft_panel._rule.text.contains("琥珀出料口 → 带 → 催化剂箱"),
		true,
		"craft panel exposes the fixed two-ended line rule"
	)

	var storage := SliceStorage.new()
	craft_panel._open = true
	craft_panel._root.visible = true
	storage.inventory.add(SliceWorld.ITEM_CATALYST, 1)
	world._building_instances.append(storage)
	world.building_storage_changed.emit("journey_storage")
	_expect_stage(
		world,
		"run_catalyst_line",
		"产出催化剂 1/2",
		"晶体箱 → 带 → 青色入料口"
	)
	storage.inventory.add(SliceWorld.ITEM_CATALYST, 1)
	world.building_storage_changed.emit("journey_storage")
	_expect_stage(
		world,
		"collect_catalyst",
		"从催化剂箱取出产物",
		"再按 6 取出"
	)
	_expect_equal(
		craft_panel._rule.text.contains("取出全部催化剂"),
		true,
		"open craft panel follows storage-driven guidance changes"
	)
	craft_panel._open = false
	craft_panel._root.visible = false
	world._building_instances.erase(storage)
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
		and hud.prompt_label.text.contains("R 旋转"),
		true,
		"placement keycap stays separate from the actionable prompt body"
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


func _check_contrast_panels(hud: SliceHud) -> void:
	for node_name in [
		"LeftStatusPanel",
		"RightStatusPanel",
		"PlayerStatusPanel",
		"PromptPanel",
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
		hud.get_node("LeftStatusPanel").size.x < 800.0
		and hud.get_node("RightStatusPanel").size.x < 640.0,
		true,
		"top components stay bounded to their safe corners"
	)
	_expect_equal(
		hud.enemy_health_bar != null
		and hud.get_node("PromptPanel/PromptKey") is Panel,
		true,
		"conditional combat and interaction components use bars and keycaps"
	)
	var player_panel := hud.get_node("PlayerStatusPanel") as Panel
	var prompt_panel := hud.get_node("PromptPanel") as Panel
	_expect_equal(
		prompt_panel.position.x
		>= player_panel.position.x + player_panel.size.x + 24.0,
		true,
		"bottom prompt stays clear of the player status component"
	)


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
