extends "res://scripts/checks/factory_device_interaction_boot_check.gd"

const Guidance := preload("res://scripts/factory/discovery_guidance.gd")


func run() -> void:
	evidence_topic = "factory-first-journey-v1"
	screenshot_topic = "2026-10-05-factory-first-journey-preview"
	await super.run()


func _first_line() -> void:
	driver.expect(world.model.automatic_power and world.model.entities.is_empty(), "new schema 3 starts empty")
	var actor_before: Dictionary = world.actor.duplicate(true)
	var stock_before: Dictionary = world.model.kits.duplicate()
	await native_click(world.hud.buttons.guide_action)
	driver.expect(world.ui.tool == "collector" and world.model.entities.is_empty() and world.model.kits == stock_before, "guide selects build tool without placing or spending")
	driver.expect(world.actor == actor_before, "guide never teleports the player")
	await driver.key(KEY_ESCAPE)
	await native_click(world.hud.buttons.mission)
	driver.expect(not world.hud.buttons.guide_action.visible and world.hud.mission.get_line_count() == 1, "collapsed goal hides long advice and action")
	await native_click(world.hud.buttons.mission)
	await driver.shot("00-first-goal")
	root.size = Vector2i(1100, 720)
	await driver.settle(20)
	_check_goal_bounds()
	await driver.shot("01-minimum-goal")
	await native_click(world.hud.buttons.discovery)
	driver.expect(world.discovery_panel.guide_overview.visible and "首条产线" in world.discovery_panel.guide_overview.text and "内矿道" in world.discovery_panel.guide_overview.text, "full journey can be reviewed in existing process panel")
	await native_shot("02-review-steps")
	await press(world.discovery_panel.buttons.close)
	root.size = Vector2i(1440, 900)
	await driver.settle(15)
	await full_journey()


func connect_devices(a: String, b: String) -> void:
	# Reuse the natural journey without issuing any obsolete explicit wiring commands.
	var first: Dictionary = world.model.by_id(ids[a])
	var second: Dictionary = world.model.by_id(ids[b])
	world.model.power_state()
	var node_id: int = second.id if world.model.Grid.is_node(second) else second.power_node_id
	driver.expect(world.model.grid.membership.has(node_id) and world.model.grid.membership[first.id] == world.model.grid.membership[node_id], "automatic network reaches " + b)
	check_failures()


func panel(id: int) -> void:
	await wait_for_focus()
	world.ui.selected = id
	world._refresh()
	await driver.settle()
	# Submit one complete mouse gesture through the window route. A failed opening
	# must stop before press() waits for a hidden dialog to receive focus.
	world._action("device" if id > 0 else "discovery", null)
	driver.expect(world.discovery_panel.visible, "selected device or process panel opens before waiting on its controls")
	check_failures()


func statistics_checks() -> void:
	# Use the original player source action; the simulation remains on its natural clock.
	world.ui.selected = ids.source
	world._action("power_toggle", null)
	var snapshot: Array = []
	for key in ["basic", "solvent"]:
		var e: Dictionary = world.model.by_id(ids[key])
		snapshot.append([e.progress, e.invested.duplicate(true), e.processing])
	await active(1.5, "source disabled holds in-progress work")
	for i in 2:
		var e: Dictionary = world.model.by_id(ids[["basic", "solvent"][i]])
		driver.expect([e.progress, e.invested, e.processing] == snapshot[i], "blackout preserves batch " + str(i))
	driver.expect(world.model.power_state().supplied_kw == 0, "disabled only source supplies no electricity")
	await driver.shot("04-blackout-guidance")
	world._action("power_toggle", null)
	await active(1, "source re-enabled resumes work")
	driver.expect(world.model.by_id(ids.source).enabled and world.model.power_state().supplied_kw > 0, "source resumed through original action")
	await super.statistics_checks()


func stage(name: String, reason: String) -> void:
	if name in ["first-line", "trial", "outer", "rich-return", "inner"]:
		var expected: String = {"first-line": "first_line", "trial": "outer", "outer": "rich", "rich-return": "inner", "inner": "complete"}[name]
		driver.expect(Guidance.current(world.model).id == expected, "guidance follows real stage " + name)
		_check_goal_bounds()
		if name == "inner":
			write_json("ids.json", ids)
			write_json("completion.json", {"passages": world.model.discovery.passages, "totals": world.model.statistics.totals, "guidance": Guidance.current(world.model)})
	super.stage(name, reason)


func _check_goal_bounds() -> void:
	driver.expect(world.hud.world_slot.get_global_rect().encloses(world.hud.mission_panel.get_global_rect()), "goal fits within world area")
	driver.expect(not world.hud.mission_panel.get_global_rect().intersects(world.hud.inspector.get_global_rect()) or not world.hud.inspector.visible, "goal does not overlap device inspector")


func _restore() -> void:
	ids = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("ids.json")))
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("expected.json")))
	var actual := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, expected.sequence)
	driver.expect(Check.equivalent(actual, expected) and actual.save_schema_version == 3, "independent Boot restores full schema 3 snapshot")
	driver.expect(world.model.discovery.passages.outer and world.model.discovery.passages.inner and Guidance.current(world.model).id == "complete", "both permanent passages and guidance restore")
	driver.expect(world.model.statistics.totals.acquired.crust_sample == 1, "unique sample is not reissued")
	await native_click(world.hud.buttons.guide_action)
	driver.expect(world.statistics_panel.visible and world.ui.paused, "completion guide opens existing statistics while preserving pause")
	await driver.click(world.statistics_panel.buttons.close)
	driver.expect(not world.statistics_panel.visible, "statistics closes before resuming the restored world")
	check_failures()
	await driver.shot("12-restored-complete-journey")
	var produced: int = world.model.statistics.totals.produced.crust_solvent
	await driver.click(world.hud.buttons.pause)
	driver.expect(not world.ui.paused, "restore resumes before active-time wait")
	check_failures()
	await wait_for(func(): return world.model.statistics.totals.produced.crust_solvent > produced, 65, "restored natural solvent production continues")
	driver.expect(Guidance.current(world.model).id == "complete", "continued production does not regress guidance")
	await driver.shot("13-restored-production")
	stage("read-complete", "full snapshot, permanent openings and natural production restored")
	await driver.click(world.hud.buttons.return)


func finish() -> void:
	if finished:
		return
	finished = true
	write_json("read-result.json" if read_mode else "write-result.json", {"assertions": driver.assertions, "failures": driver.failures, "stages": stages,
		"foreground_seconds": foreground_seconds, "focus_pauses": focus_pauses, "pending_focus_pause": focus_pause,
		"input": "Formal Boot/create: focused synthetic Enter; restore selection/continue signals for first-frame snapshot. New guide buttons: routed synthetic mouse. Layout: HUD precision fields/actions; operations: focused Enter; walking: WASD; statistics: synthetic mouse and declared focus events. Natural production without material, unlock, position injection or time acceleration. This is engineering evidence, not player onboarding timing."}.merged(execution_evidence()))
	print("First journey Boot: %d assertions, %d failures" % [driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)
