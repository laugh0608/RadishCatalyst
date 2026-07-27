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
		"placement guidance enables its contrast panel"
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
		"PromptPanel",
	]:
		var panel := hud.get_node_or_null(node_name) as ColorRect
		_expect_equal(panel != null, true, "%s exists" % node_name)
		if panel != null:
			_expect_equal(
				panel.color.a >= 0.7,
				true,
				"%s has a stable high-contrast alpha" % node_name
			)
	_expect_equal(
		hud.get_node("LeftStatusPanel").get_index()
		< hud.crystal_label.get_index(),
		true,
		"left contrast panel renders behind resource text"
	)
	_expect_equal(
		hud.get_node("RightStatusPanel").get_index()
		< hud.health_label.get_index(),
		true,
		"right contrast panel renders behind combat text"
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
