extends "res://scripts/checks/factory_device_interaction_boot_check.gd"


func run() -> void:
	evidence_topic = "factory-conveyor-routing-v1"
	screenshot_topic = "2026-10-08-factory-conveyor-routing-preview"
	await super.run()


func _first_line() -> void:
	driver.expect(world.model.supply_id == Codec.V2.Config.ROUTING_SUPPLY_ID and world.model.kits.splitter == 8, "formal menu creates schema4 ordinary supply")
	await native_click(world.hud.buttons.mission)
	await walk(Vector2(-16, 5.7))
	await walk(Vector2(-16, 2))
	await place("collector", -20, -1, "collector")
	await _place_attachment("splitter", Vector2i(-18, 0))
	await place("reactor", -13, -2, "reactor_a")
	await place("reactor", -13, 4, "reactor_b")
	await _place_attachment("merger", Vector2i(-6, 0))
	await place("storage", -3, -1, "storage")
	await place("power_source", -19, -6, "source")
	await place("power_junction", -13, 2, "node")
	for x in range(-17, -13): await place("belt", x, 0)
	for z in range(1, 6): await place("belt", -18, z, "", 1)
	for x in range(-18, -13): await place("belt", x, 6)
	for x in range(-10, -6): await place("belt", x, 0)
	for x in range(-10, -6): await place("belt", x, 6)
	for z in range(6, 0, -1): await place("belt", -6, z, "", 3)
	for x in range(-5, -3): await place("belt", x, 0)
	world.view.inspection_target = Vector3(-11.5, 0, 1.5) # Camera-only framing, no actor/state change.
	stage("line-built", "ordinary zero-stock two-reactor split/merge line through formal construction commands")
	await driver.shot("01-routing-line")
	await wait_for(func(): return world.model.delivered >= 4, 90, "both branches naturally produce and merge into warehouse")
	driver.expect(world.model.by_id(ids.reactor_a).active_batch > 0 and world.model.by_id(ids.reactor_b).active_batch > 0, "both reactors continue independent batches")
	driver.expect(world.model.power_state().installed_kw == 120, "one ordinary source supplies the example line")
	check_failures()
	if finished: return
	await _open_nearby("splitter")
	if finished: return
	driver.expect("下一次先尝试" in world.discovery_panel.device_summary.production.text and "无需供电" in world.discovery_panel.device_summary.power.text, "routing panel explains rotation and passive transport")
	await _layout_checks()
	await native_shot("02-splitter-panel")
	await native_click(world.discovery_panel.buttons.close)
	# Break the end of one input branch; its remaining four slots fill naturally.
	await native_click(world.hud.buttons.pause)
	await walk_paused_inspection(Vector2(-14.5, 2))
	ids.repair_belt = world.model.entity_at(Vector2i(-14, 0)).id
	await _open_nearby("repair_belt")
	if finished: return
	await native_click(world.discovery_panel.buttons.salvage)
	driver.expect(world.model.entity_at(Vector2i(-14, 0)).is_empty(), "nearby salvage disconnects branch without destroying held cargo")
	if world.discovery_panel.visible: await native_click(world.discovery_panel.buttons.close)
	await native_click(world.hud.buttons.pause)
	var other_batch: int = world.model.by_id(ids.reactor_b).active_batch
	await wait_for(func(): return not world.model.entity_at(Vector2i(-17, 0)).cargo.is_empty() and world.model.entity_at(Vector2i(-17, 0)).progress >= 0.999, 30, "broken branch backpressure reaches splitter")
	await wait_for(func(): return world.model.by_id(ids.reactor_b).active_batch > other_batch, 25, "unblocked branch continues while other branch is full")
	await walk(Vector2(-16, 2))
	await _open_nearby("splitter")
	if finished: return
	driver.expect("前输出：目标已满" in world.discovery_panel.device_summary.ports.text, "splitter names the full front branch")
	await native_shot("03-blocked-branch")
	await native_click(world.discovery_panel.buttons.close)
	await place("belt", -14, 0, "repair_belt")
	var previous_batch: int = world.model.by_id(ids.reactor_a).active_batch
	await wait_for(func(): return world.model.by_id(ids.reactor_a).active_batch > previous_batch, 20, "repair restores the previously blocked production branch")
	await wait_for(func(): return not world.model.by_id(ids.splitter).cargo.is_empty() and world.model.by_id(ids.splitter).progress > 0.1 and world.model.by_id(ids.splitter).progress < 0.8, 5, "partial attachment transit prepared naturally")
	await native_click(world.hud.buttons.pause)
	await native_click(world.hud.buttons.save)
	driver.expect(Codec.decode(Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence), world.store.world_id).ok, "natural line snapshot obeys strict conservation")
	write_json("expected.json", Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence))
	write_json("ids.json", ids)
	await driver.shot("04-partial-routing-save")
	stage("write-complete", "natural split/merge, partial transit, live panel, blocked branch and repair")
	await native_click(world.hud.buttons.return)
	driver.expect(boot.factory_world == null, "routing world saves and returns")


func _place_attachment(kind: String, cell: Vector2i) -> void:
	await native_click(world.hud.buttons[kind])
	world.hud.cell_x.value = cell.x
	world.hud.cell_z.value = cell.y
	await driver.key(KEY_R)
	await driver.settle()
	driver.expect(world.ui.dir == 1 and world.view.build_model.visible, "new attachment rotates its imported preview")
	var hints: Array = world.view.port_hints.get_children().filter(func(h): return h.get_meta("entity_id") == -1)
	driver.expect(hints.size() == 4, "attachment preview exposes one-plus-three directional ports")
	for i in 3: await driver.key(KEY_R)
	ids[kind] = world.model.next_id
	world.hud.buttons.place.pressed.emit()
	driver.expect(world.model.by_id(ids[kind]).type == kind and world.model.by_id(ids[kind]).dir == 0, "precision fields commit rotated-back attachment")
	await driver.key(KEY_ESCAPE)


func walk_paused_inspection(point: Vector2) -> void:
	# Movement uses the same explicit player pause toggle; never teleport the actor.
	await native_click(world.hud.buttons.pause)
	await walk(point)
	await native_click(world.hud.buttons.pause)


func _open_nearby(name: String) -> void:
	await driver.key(KEY_ESCAPE)
	var target: Dictionary = world._interaction_target()
	var count: int = target.get("count", 0)
	for i in count:
		if world._interaction_target().id == ids[name]: break
		await driver.key(KEY_TAB)
	driver.expect(world._interaction_target().id == ids[name], "nearby target cycles to " + name)
	check_failures()
	if finished: return
	await driver.key(KEY_F)
	driver.expect(world.discovery_panel.visible and world.discovery_panel.selected == ids[name], "F opens exact routing target " + name)
	check_failures()


func _restore() -> void:
	if "--visual-only" in OS.get_cmdline_user_args():
		await _visual_review()
		return
	ids = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("ids.json")))
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("expected.json")))
	var actual := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, expected.sequence)
	driver.expect(Check.equivalent(actual, expected) and actual.save_schema_version == 4, "independent Boot restores cargo progress both cursors batches and statistics")
	await _open_nearby("splitter")
	if finished: return
	await native_shot("05-restored-splitter")
	await native_click(world.discovery_panel.buttons.close)
	var delivered: int = world.model.delivered
	await native_click(world.hud.buttons.pause)
	await wait_for(func(): return world.model.delivered >= delivered + 2, 30, "restored split/merge line continues natural delivery")
	await walk(Vector2(-16, 8.5))
	await walk(Vector2(-5, 8.5))
	await walk(Vector2(-5, 2))
	await _open_nearby("merger")
	if finished: return
	driver.expect("入口" in world.discovery_panel.device_summary.production.text, "merger panel displays input rotation")
	await native_shot("06-restored-merger")
	await native_click(world.discovery_panel.buttons.close)
	await driver.key(KEY_I)
	driver.expect(world.discovery_panel.inventory_only and world._producing(), "standalone inventory remains live in routing world")
	await driver.key(KEY_I)
	stage("read-complete", "complete routing snapshot restored and naturally continued")
	await native_click(world.hud.buttons.return)
	driver.expect(boot.factory_world == null, "independent routing session saves and releases lock")


func _visual_review() -> void:
	ids = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("ids.json")))
	await _open_nearby("splitter")
	if finished: return
	await _layout_checks()
	await native_shot("review-splitter")
	await native_click(world.discovery_panel.buttons.close)
	await native_click(world.hud.buttons.build)
	await native_click(world.hud.buttons.splitter)
	world.hud.cell_x.value = -15
	world.hud.cell_z.value = -4
	await driver.key(KEY_R)
	await driver.shot("review-rotated-preview")
	await driver.key(KEY_ESCAPE)
	await native_click(world.hud.buttons.pause)
	await walk(Vector2(-16, 8.5))
	await walk(Vector2(-5, 8.5))
	await walk(Vector2(-5, 2))
	await _open_nearby("merger")
	if finished: return
	await native_shot("review-merger")
	await native_click(world.discovery_panel.buttons.close)
	await native_click(world.hud.buttons.pause)
	world.ui.build = false
	world.view.inspection_target = Vector3(-11.5, 0, 1.5)
	world._refresh()
	await driver.settle(20)
	await driver.shot("review-combined-line")
	stage("visual-review", "formal Boot on hash-verified copied natural snapshot; camera framing only, real walk/F/Tab/buttons, no stock/time injection")
	await native_click(world.hud.buttons.return)
