extends "res://scripts/checks/factory_routing_boot_check.gd"


func run() -> void:
	evidence_topic = "factory-item-admission-v1"
	screenshot_topic = "2026-10-12-factory-item-admission-preview"
	input_description_override = "Formal Boot/create: focused synthetic Enter; construction: precision coordinates/button signals; actor: natural synthetic WASD; sample/F/Tab/I/Escape: routed keys; configuration/pause/transfer/save: synthetic mouse; dropdown choices/SpinBox values: exact control setters; no stock/unlock/actor position/time injection"
	if "--visual-only" in OS.get_cmdline_user_args():
		input_description_override = "Formal Boot/continue: focused synthetic Enter; paused restore/panel layout only; nearby target: routed F/Tab/Escape; build/preview/save-return: synthetic mouse, exact coordinate setters and routed R; no walking, natural production or configuration-submit assertion; no stock/unlock/actor position/time injection"
	await super.run()


func _first_line() -> void:
	driver.expect(world.model.supply_id == Codec.V2.Config.ADMISSION_SUPPLY_ID and world.model.kits.admission_gate == 8, "Boot creates ordinary V5 with eight gates")
	await native_click(world.hud.buttons.mission)
	await walk(Vector2(2.5, 2.5))
	await driver.key(KEY_F)
	driver.expect(world.model.discovery.sample_taken and world.model.bag.get("crust_sample", 0) == 1, "unique sample collected by natural walk and F")
	await walk(Vector2(-16, 5.7))
	await place("collector", -20, -1, "collector")
	await place("admission_gate", -18, 0, "crystal_gate")
	await place("reactor", -13, -2, "basic_reactor")
	for x in range(-17, -13): await place("belt", x, 0)
	await place("admission_gate", -10, 0, "catalyst_gate")
	await place("reactor", -6, -2, "trial_reactor")
	for x in range(-9, -6): await place("belt", x, 0)
	await place("admission_gate", -3, 0, "solvent_gate")
	await place("storage", -2, -1, "warehouse")
	await place("power_source", -19, -6, "source")
	await place("power_junction", -13, 2, "node_a")
	await place("power_junction", -6, 2, "node_b")
	await walk(Vector2(-17.5, 2))
	await _configure("crystal_gate", "crystal", 0)
	await walk(Vector2(-17.5, 4))
	await walk(Vector2(-10, 4))
	await walk(Vector2(-10, 2))
	await _configure("catalyst_gate", "catalyst", 2)
	await walk(Vector2(-10, 4))
	await walk(Vector2(-3, 4))
	await walk(Vector2(-3, 2))
	await _configure("solvent_gate", "crust_solvent", 4)
	await walk(Vector2(-3, 4))
	await walk(Vector2(-7.5, 4))
	await walk(Vector2(-7.5, 1.6))
	await _open_nearby("trial_reactor")
	if finished: return
	await recipe("solvent_trial")
	await native_click(world.discovery_panel.buttons.crust_sample_put_one)
	await driver.key(KEY_ESCAPE)
	await wait_for(func(): return world.model.discovery.trial_completed and world.model.by_id(ids.trial_reactor).output.is_empty(), 90, "trial completes naturally and first solvent reaches gate")
	await _open_nearby("trial_reactor")
	if finished: return
	await recipe("crust_solvent")
	await driver.key(KEY_ESCAPE)
	await walk(Vector2(-7.5, 4))
	await walk(Vector2(-10, 4))
	await walk(Vector2(-10, 2))
	await _configure("catalyst_gate", "catalyst", 0)
	await walk(Vector2(-10, 4))
	await walk(Vector2(-3, 4))
	await walk(Vector2(-3, 2))
	await wait_for(func():
		var g: Dictionary = world.model.by_id(ids.solvent_gate)
		return g.quota_used == 3 and g.cargo == "crust_solvent" and g.progress > 0.1 and g.progress < 0.5,
		100, "third solvent sent and fourth captured in partial transit")
	await native_click(world.hud.buttons.pause)
	await _open_nearby("solvent_gate")
	if finished: return
	var g: Dictionary = world.model.by_id(ids.solvent_gate)
	driver.expect(g.quota_used == 3 and g.cargo == "crust_solvent", "paused quota checkpoint is exactly three plus held fourth")
	await native_click(world.discovery_panel.admission_controls.accepting_button)
	driver.expect(not g.accepting and g.quota_used == 3, "closing receiver preserves held cargo and used quota")
	await _gate_layout()
	await native_shot("quota-three-and-held-fourth")
	await driver.key(KEY_ESCAPE)
	await native_click(world.hud.buttons.save)
	var expected := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)
	driver.expect(Codec.decode(expected, world.store.world_id).ok, "natural V5 line obeys strict inventory batch and quota contract")
	write_json("expected.json", expected)
	write_json("ids.json", ids)
	stage("admission-write-complete", "zero stock crystal filter, natural sample/trial, unlimited catalyst feed, finite solvent quota; third sent/fourth held; receiver closed for independent draining")
	await native_click(world.hud.buttons.return)
	driver.expect(boot.factory_world == null, "write saves and releases isolated world")


func _configure(name: String, item: String, quota: int) -> void:
	await _open_nearby(name)
	if finished: return
	var controls: Control = world.discovery_panel.admission_controls
	controls.item.select(world.model.Admission.ALLOWED_ITEMS.find(item) + 1)
	controls.mode.select(1 if quota > 0 else 0)
	controls.limit.value = maxi(1, quota)
	await driver.settle()
	await native_click(controls.apply_button)
	var e: Dictionary = world.model.by_id(ids[name])
	driver.expect(e.filter_item == item and e.quota_limit == quota and e.quota_used == 0, "exact settings applied to " + name)
	if not e.accepting: await native_click(controls.accepting_button)
	driver.expect(e.accepting, "new receipt explicitly allowed for " + name)
	await driver.key(KEY_ESCAPE)


func _restore() -> void:
	ids = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("ids.json")))
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("expected.json")))
	var actual := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, expected.sequence)
	driver.expect(expected.save_schema_version == 5 and Check.equivalent(expected, actual), "independent Boot restores full quota progress batches and statistics")
	await _open_nearby("solvent_gate")
	if finished: return
	await _gate_layout()
	await native_shot("restored-quota-checkpoint")
	if "--visual-only" in OS.get_cmdline_user_args():
		await driver.key(KEY_ESCAPE)
		await native_click(world.hud.buttons.build)
		await native_click(world.hud.buttons.admission_gate)
		world.hud.cell_x.value = -3
		world.hud.cell_z.value = 4
		await driver.key(KEY_R)
		await driver.shot("gate-rotated-preview")
		await driver.key(KEY_ESCAPE)
		await native_click(world.hud.buttons.return)
		return
	await native_click(world.discovery_panel.buttons.pause)
	await wait_for(func(): return world.model.by_id(ids.solvent_gate).quota_used == 4, 10, "closed gate naturally drains exactly the fourth item")
	await active(3, "observe quota exhausted without a fifth output")
	var g: Dictionary = world.model.by_id(ids.solvent_gate)
	var warehouse: Dictionary = world.model.by_id(ids.warehouse)
	driver.expect(g.quota_used == 4 and g.cargo.is_empty() and warehouse.items.get("crust_solvent", 0) == 4, "exact total four remains after full restoration")
	var controls: Control = world.discovery_panel.admission_controls
	await native_click(controls.accepting_button)
	await active(1, "reopened exhausted quota cannot accept fifth")
	driver.expect(g.quota_used == 4 and g.cargo.is_empty(), "re-enable does not reset quota")
	await native_click(controls.reset_button)
	driver.expect(g.quota_used == 0 and g.accepting and g.quota_limit == 4, "explicit reset starts same configured round")
	await wait_for(func(): return g.quota_used >= 1 and warehouse.items.get("crust_solvent", 0) >= 5, 35, "reset lets natural line deliver again")
	await native_click(world.discovery_panel.buttons.pause)
	await native_shot("quota-reset-and-continued")
	await driver.key(KEY_ESCAPE)
	await driver.key(KEY_I)
	driver.expect(world.discovery_panel.inventory_only, "V5 retains standalone inventory")
	await driver.key(KEY_I)
	stage("admission-read-complete", "independent full restoration, closed receiver drains fourth, exhausted reopen preserves count, explicit reset continues natural delivery")
	await native_click(world.hud.buttons.return)
	driver.expect(boot.factory_world == null, "read saves and releases lock")


func _gate_layout() -> void:
	await _layout_checks()
	var controls: Control = world.discovery_panel.admission_controls
	driver.expect(controls.visible and root.get_visible_rect().encloses(controls.get_global_rect()), "configuration controls visible outside summary scroll")
	driver.expect(controls.get_global_rect().encloses(controls.apply_button.get_global_rect()) and controls.get_global_rect().encloses(controls.reset_button.get_global_rect()), "quota main actions remain reachable")
