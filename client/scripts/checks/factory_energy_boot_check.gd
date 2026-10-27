extends "res://scripts/checks/factory_expansion_boot_check.gd"

const EnergyLayout := preload("res://scripts/checks/factory_energy_layout.gd")
const Walking := preload("res://scripts/checks/factory_energy_walk.gd")
var comparison := {}
var generator_off := false
var recovered_read := false


func run() -> void:
	evidence_topic = "factory-energy-and-focus-feedback-v1" if "--standby-feedback" in OS.get_cmdline_user_args() else "factory-production-expansion-e2"
	screenshot_topic = "2026-10-27-factory-energy-feedback-preview" if "--standby-feedback" in OS.get_cmdline_user_args() else "2026-10-23-factory-energy-e2-preview"
	new_world_type = 3
	new_world_title = "能源循环 E2 · 自然生产"
	generator_off = "--generator-off" in OS.get_cmdline_user_args()
	recovered_read = "--recovered-read" in OS.get_cmdline_user_args()
	await super.run()


func _first_line() -> void:
	world.view.yaw = 0
	world.view.sync_camera()
	driver.expect(world.model.supply_id == Codec.V7.Energy.SUPPLY_ID and world.model.owned_count() == 165 and world.model.bag.is_empty() and world.model.entities.is_empty(), "formal Boot creates empty ordinary E2 with 165 kits")
	baseline_time = world.model.time
	await native_click(world.hud.buttons.pause)
	await native_click(world.hud.buttons.mission)
	for row in Layout.rows("A"):
		await place(row.type, row.x, row.z, row.name, row.dir)
		if finished: return
	driver.expect(world.model.entities.size() == 34, "A approved 34 entities built through HUD")
	await native_click(world.hud.buttons.pause)
	await _go("GI", "A")
	await _configure_gate("GI", "iron_ore", 8)
	await _go("GQ", "A")
	await _configure_gate("GQ", "crystal", 6)
	await wait_for(func(): return world.model.completed_by_recipe.direct_refining == 4 and world.model.by_id(ids.F).output.is_empty() and world.model.by_id(ids.U).items.get("crystal", 0) == 6, 100, "A naturally produces four metal plates and six crystals")
	if finished: return
	await _go("F", "A")
	await _choose_recipe("F", "direct_sintering")
	await _go("U", "A")
	await _move_item("U", "crystal", false)
	await _go("F", "A")
	await _move_item("F", "crystal", true)
	await wait_for(func(): return world.model.by_id(ids.T).items.get("construction_pack", 0) == 2, 90, "A two construction packs arrive using natural clock")
	if finished: return
	driver.expect(world.model.completed_by_recipe.direct_refining == 4 and world.model.completed_by_recipe.direct_sintering == 2 and world.model.completed_by_recipe.construction_assembly == 2, "A consumes exactly 8 iron and 6 crystals in completed recipes")
	await _go("T", "A")
	await _move_item("T", "construction_pack", false)
	await native_click(world.hud.buttons.pause)
	if not world.ui.build: await native_click(world.hud.buttons.build)
	if finished: return
	world.hud.assembly_target.select(Codec.V6.Expansion.ASSEMBLY_COST.keys().find("refinery"))
	world._refresh()
	await native_click(world.hud.buttons.assemble)
	if finished: return
	driver.expect(world.model.kits.refinery == 1 and world.model.owned_count() == 166 and not world.model.first_expansion_placed, "real assembly button spends two carried packs and selects furnace tool")
	driver.expect(world.ui.tool == "refinery", "successful assembly selects matching build tool")
	write_json("manufactured-before-placement.json", _snapshot())
	await place("refinery", -12, -5, "R")
	driver.expect(world.model.first_expansion_placed and world.model.entities.filter(func(e): return e.type == "refinery").size() == 2, "actual second furnace placement completes first expansion")
	driver.expect(transfer_commands == 3 and recipe_commands == 1, "A requires three transfer commands and one recipe switch")
	stage("A-complete", "zero materials; direct recipe chain; two packs spent on one furnace; actual second furnace placed")
	write_json("route-A.json", {"elapsed_model_seconds": world.model.time - baseline_time, "transfer_commands": transfer_commands, "recipe_commands": recipe_commands, "completed": world.model.completed_by_recipe.duplicate(), "held": world.model.material_balance().held, "owned": world.model.owned_count()})
	await _cold_start()


func _cold_start() -> void:
	await _profile("P")
	await _quota("GI", "iron_ore", 12); await _quota("GQ", "crystal", 9)
	await wait_for(func(): return world.model.by_id(ids.T1).items.get("construction_pack", 0) == 3, 300, "P naturally makes three packs for first generator")
	if finished: return
	await _go("T1", "P"); await _move_item("T1", "construction_pack", false)
	await _assemble("cell_generator")
	await _profile("C")
	await _toggle("G", false)
	await _quota("GI", "iron_ore", 4); await _quota("GQ", "crystal", 4)
	await _quota("GK", "carbon_ore", 2); await _quota("GF", "industrial_cell", 2)
	await wait_for(func(): return world.model.by_id(ids.G).fuel.get("industrial_cell", 0) == 2, 300, "C cold start naturally delivers two cells")
	if finished: return
	await _toggle("G", true)
	driver.expect(world.model.statistics.totals.cells_activated == 0 and world.model.by_id(ids.G).remaining_kj == 0 and world.model.power_state().request_kw <= 220, "C baseline power never activates fuel")
	stage("C-ready", "ordinary E2; mined first expansion and three-pack generator; R12 fuel delivered with original base power")
	await _save_checkpoint("C-ready")


func _restore() -> void:
	world.view.yaw = 0; world.view.sync_camera()
	ids = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("ids.json")))
	for name in ids: ids[name] = int(ids[name])
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("expected.json")))
	driver.expect(Compare.equivalent(Codec.snapshot(world.model, world.store.world_id, world.store.world_name, int(expected.sequence)), expected), "independent Boot restores every E2 authoritative field before simulation")
	check_failures()
	if finished: return
	if recovered_read: await _continue_recovered()
	elif visual_only: await _review_energy()
	elif complete_read: await _complete_energy()
	else: await _demand_line()


func _demand_line() -> void:
	await _profile("P")
	await _quota("GI", "iron_ore", 100); await _quota("GQ", "crystal", 75)
	await wait_for(func(): return world.model.by_id(ids.T1).items.get("construction_pack", 0) == 25, 600, "P naturally manufactures remaining 25 packs")
	if finished: return
	await _go("T1", "P"); await _move_item("T1", "construction_pack", false)
	for type in ["collector", "refinery", "refinery", "refinery", "assembler", "assembler", "admission_gate", "splitter", "splitter"]: await _assemble(type)
	for i in 10: await _assemble("belt")
	driver.expect(world.model.owned_count() == 256 and world.model.bag.get("construction_pack", 0) == 0, "thirty real packs build exact D budget")
	await _profile("D")
	await _toggle("G", false)
	await _go("G", "D"); await _move_item("G", "industrial_cell", true)
	await _quota("GI", "iron_ore", 80); await _quota("GQ", "crystal", 60)
	await _quota("GK", "carbon_ore", 6); await _quota("GQE", "crystal", 12); await _quota("GF", "industrial_cell", 6)
	await wait_for(func(): return world.model.power_state().request_kw > 240 and world.model.by_id(ids.E).processing and world.model.by_id(ids.E).progress > 0.5, 300, "D real deficit with R12 partial batch")
	if finished: return
	driver.expect(world.model.by_id(ids.S1).enabled and world.model.by_id(ids.S2).enabled and world.model.power_state().available_kw == 240, "D real deficit retains both original base sources")
	stage("D-partial", "real manufactured D; unchanged 240 kW base; generator off; R12 invested partial batch and transport state")
	await _save_checkpoint("D-partial")


func _profile(layout: String) -> void:
	if world.discovery_panel.visible: await driver.key(KEY_ESCAPE)
	if world.ui.paused: await native_click(world.hud.buttons.pause)
	var rows := EnergyLayout.rows(layout)
	# Stop each existing producer through the local panel before dismantling.
	for entity in world.model.entities.duplicate():
		if not entity.has("enabled") or entity.type == "power_source": continue
		ids.old_device = entity.id
		await _toggle("old_device", false)
		if finished: return
	for entity in world.model.entities.duplicate():
		if rows.any(func(row): return row.type == entity.type and row.x == entity.x and row.z == entity.z and row.dir == entity.dir): continue
		ids.removed = entity.id
		await _go("removed", layout); await _open_nearby("removed")
		if finished: return
		await native_click(world.discovery_panel.buttons.salvage)
		if world.power_dialog.visible: await native_click(world.power_dialog.get_ok_button())
		driver.expect(world.model.by_id(entity.id).is_empty(), "formal recovery preserves cargo " + str(entity.id))
		if world.discovery_panel.visible: await driver.key(KEY_ESCAPE)
		check_failures()
		if finished: return
	# Leave the future footprints using actual movement before paused construction.
	var hub_route := Walking.route(world.model, {"type": "power_junction", "x": -3, "z": 5})
	driver.expect(not hub_route.is_empty(), "reachable staging area before rebuilding")
	for point in hub_route:
		await walk(point)
		if finished: return
	await native_click(world.hud.buttons.pause)
	var next_ids := {}
	for row in rows:
		var entity: Dictionary = world.model.entity_at(Vector2i(row.x, row.z))
		if entity.is_empty():
			await place(row.type, row.x, row.z, row.name, row.dir)
			if finished: return
			entity = world.model.by_id(ids[row.name])
		next_ids[row.name] = entity.id
	ids = next_ids
	await native_click(world.hud.buttons.pause)
	for name in EnergyLayout.recipes(layout):
		if world.model.by_id(ids[name]).recipe_id != EnergyLayout.recipes(layout)[name]:
			await _go(name, layout); await _choose_recipe(name, EnergyLayout.recipes(layout)[name])
			if finished: return
	for name in ids.keys():
		var entity: Dictionary = world.model.by_id(ids[name])
		if entity.has("enabled") and entity.type != "power_source" and not entity.enabled: await _toggle(name, true)
	driver.expect(world.model.entities.size() == rows.size(), "exact approved layout entity count " + layout)
	stage("layout-" + layout, "formal salvage, assembly and precision construction; real collision-aware walking; retained cargo")


func _go(name: String, _route_stage: String) -> void:
	if finished: return
	if world.discovery_panel.visible: await driver.key(KEY_ESCAPE)
	if world.ui.paused: await native_click(world.hud.buttons.pause)
	var route := Walking.route(world.model, world.model.by_id(ids[name]))
	driver.expect(not route.is_empty(), "walkable interaction route " + name)
	check_failures()
	if finished: return
	for point in route:
		await walk(point)
		if finished: return


func _toggle(name: String, enabled: bool) -> void:
	if finished or world.model.by_id(ids[name]).enabled == enabled: return
	await _go(name, ""); await _open_nearby(name)
	if finished: return
	await native_click(world.discovery_panel.buttons.device_toggle)
	driver.expect(world.model.by_id(ids[name]).enabled == enabled, "local device toggle " + name)
	await driver.key(KEY_ESCAPE)


func _quota(name: String, item: String, quota: int) -> void:
	if finished: return
	await _go(name, ""); await _open_nearby(name)
	if finished: return
	var controls: Control = world.discovery_panel.admission_controls
	var gate: Dictionary = world.model.by_id(ids[name])
	if gate.accepting: await native_click(controls.accepting_button)
	await driver.key(KEY_ESCAPE)
	await wait_for(func(): return gate.cargo.is_empty(), 120, "closed gate drains " + name)
	if finished: return
	await _open_nearby(name)
	controls.item.select(world.model.admission_items.find(item) + 1)
	controls.mode.select(1); controls.limit.value = quota
	await driver.settle()
	await native_click(controls.apply_button)
	if gate.quota_used > 0: await native_click(controls.reset_button)
	driver.expect(gate.filter_item == item and gate.quota_limit == quota and gate.quota_used == 0, "formal gate quota " + name)
	await native_click(controls.accepting_button)
	await driver.key(KEY_ESCAPE)


func _assemble(type: String) -> void:
	if finished: return
	if not world.ui.build: await native_click(world.hud.buttons.build)
	var before: int = world.model.kits.get(type, 0)
	world.hud.assembly_target.select(world.model.assembly_costs.keys().filter(func(key): return key != "cell_generator" or world.model.first_expansion_placed).find(type))
	world._refresh()
	await native_click(world.hud.buttons.assemble)
	driver.expect(world.model.kits[type] == before + (8 if type == "belt" else 1), "actual assembly " + type)
	await driver.key(KEY_ESCAPE)
	if world.ui.build: await native_click(world.hud.buttons.build)
	check_failures()


func _complete_energy() -> void:
	var before := _packs()
	var start: float = world.model.time
	var energy: float = world.model.statistics.totals.cell_supplied_kj
	var initial_energy: Dictionary = world.model.statistics.totals.duplicate(true)
	var wall_start := Time.get_ticks_usec()
	var observed := {"peak_request_kw": 0.0, "peak_deficit_kw": 0.0}
	write_json("comparison-start.json", _snapshot())
	if world.ui.paused: await native_click(world.hud.buttons.pause)
	# Both branches start timing at the identical restored checkpoint, including travel.
	await _go("G", "D"); await _open_nearby("G")
	if finished: return
	if world.model.by_id(ids.G).enabled == generator_off:
		await native_click(world.discovery_panel.buttons.device_toggle)
	driver.expect(world.model.by_id(ids.G).enabled != generator_off, "comparison uses selected generator state")
	await driver.key(KEY_ESCAPE)
	await wait_for(func():
		var power: Dictionary = world.model.power_state()
		observed.peak_request_kw = maxf(observed.peak_request_kw, power.request_kw)
		observed.peak_deficit_kw = maxf(observed.peak_deficit_kw, power.deficit_kw)
		return _packs() >= before + 4,
		360, "four new packs arrive under natural clock")
	if finished: return
	comparison = {"generator_enabled": not generator_off, "seconds": world.model.time - start, "cell_supplied_kj": world.model.statistics.totals.cell_supplied_kj - energy, "start_packs": before, "end_packs": _packs()}
	comparison.wall_seconds = (Time.get_ticks_usec() - wall_start) / 1000000.0
	comparison.merge(observed)
	comparison.energy_delta = {}
	for field in ["requested_kj", "supplied_kj", "used_kj", "deficit_kj", "base_supplied_kj", "cell_supplied_kj"] + (["standby_kj"] if initial_energy.has("standby_kj") else []):
		comparison.energy_delta[field] = world.model.statistics.totals[field] - initial_energy[field]
	write_json("comparison.json", comparison)
	write_json("comparison-end.json", _snapshot())
	if not generator_off: await _expand_recover()
	if not finished: await _save_checkpoint("D-four-packs" if generator_off else "D-plus-recovered")


func _expand_recover() -> void:
	for name in ["T1", "T2"]:
		if world.model.by_id(ids[name]).items.get("construction_pack", 0) > 0:
			await _go(name, "D"); await _move_item(name, "construction_pack", false)
	await _assemble("cell_generator"); await _assemble("splitter")
	await _profile("D+")
	driver.expect(world.model.owned_count() == 258, "D+ naturally spends four packs and owns 258 kits/devices")
	await _quota("GI", "iron_ore", 256); await _quota("GQ", "crystal", 192)
	await _quota("GK", "carbon_ore", 6); await _quota("GQE", "crystal", 12); await _quota("GF", "industrial_cell", 6)
	await wait_for(func(): return world.model.by_id(ids.G).remaining_kj > 0 and world.model.by_id(ids.G2).remaining_kj > 0 and world.model.power_state().sources[ids.G] > 0 and world.model.power_state().sources[ids.G2] > 0, 300, "both real generators supply the expanded production line")
	if finished: return
	await _go("GF", "D+"); await _open_nearby("GF")
	await native_click(world.discovery_panel.admission_controls.accepting_button)
	await driver.key(KEY_ESCAPE)
	await active(10, "closed fuel gate drains downstream tail")
	for name in ["G", "G2"]:
		await _go(name, "D+")
		if world.model.by_id(ids[name]).fuel.get("industrial_cell", 0) > 0: await _move_item(name, "industrial_cell", false)
	var activated: int = world.model.statistics.totals.cells_activated
	await wait_for(func(): return world.model.by_id(ids.G).remaining_kj == 0 and world.model.by_id(ids.G2).remaining_kj == 0, 600, "real production exhausts current cells with no intact fuel")
	if finished: return
	driver.expect(world.model.power_state().available_kw == 240 and world.model.statistics.totals.cells_activated == activated, "exhaustion retains original base supply without consuming withdrawn fuel")
	write_json("exhausted.json", _snapshot())
	for name in ["Q", "F2", "F3", "H1", "H2", "A1", "A2"]: await _toggle(name, false)
	var batches := {}
	for name in ["F2", "F3", "H1", "H2", "A1", "A2"]:
		var entity: Dictionary = world.model.by_id(ids[name])
		batches[name] = {"progress": entity.progress, "invested": entity.invested.duplicate(true)}
	await _quota("GI", "iron_ore", 32); await _quota("GK", "carbon_ore", 2); await _quota("GQE", "crystal", 4); await _quota("GF", "industrial_cell", 2)
	var produced: int = world.model.completed_by_recipe.cell_assembly
	await wait_for(func(): return world.model.completed_by_recipe.cell_assembly > produced and world.model.by_id(ids.G).fuel.get("industrial_cell", 0) + world.model.by_id(ids.G2).fuel.get("industrial_cell", 0) > 0, 480, "base-powered recovery produces and delivers a new cell")
	if finished: return
	driver.expect(world.model.statistics.totals.cells_activated == activated and world.model.power_state().request_kw <= 220, "shed load lets base supply cover recovery")
	for name in batches:
		var entity: Dictionary = world.model.by_id(ids[name])
		driver.expect(entity.progress == batches[name].progress and entity.invested == batches[name].invested, "local stop preserves partial batch " + name)
	for name in ["Q", "F2", "F3", "H1", "H2", "A1", "A2"]: await _toggle(name, true)
	await _quota("GI", "iron_ore", 32); await _quota("GK", "carbon_ore", 3); await _quota("GQE", "crystal", 6); await _quota("GF", "industrial_cell", 3)
	await wait_for(func(): return world.model.statistics.totals.cells_activated > activated and world.model.by_id(ids.E).processing and world.model.by_id(ids.E).progress > 0.2, 180, "resumed expanded line activates new fuel while R12 remains partial")
	stage("D-plus-recovered", "two manufactured generators; real fuel exhaustion; seven local stops preserve batches; base-powered cell recovery and resumed generation")


func _packs() -> int:
	return world.model.by_id(ids.T1).items.get("construction_pack", 0) + world.model.by_id(ids.T2).items.get("construction_pack", 0)


func _review_energy() -> void:
	if ids.has("F1") and not ids.has("G2"): await _review_empty_and_working()
	if finished: return
	await _go("G", "")
	if finished: return
	await native_click(world.hud.buttons.pause)
	await _open_nearby("G")
	if finished: return
	var before := _snapshot()
	await _layout_checks()
	driver.expect("120 kW" in world.discovery_panel.device_summary.values.output.text and "7,200 kJ" in world.discovery_panel.device_summary.values.process.text, "generator panel distinguishes output and stored energy")
	await native_shot("01-generator-panel")
	if world.model.by_id(ids.G).remaining_kj > 0:
		await native_click(world.discovery_panel.buttons.salvage)
		driver.expect(world.power_dialog.visible and "余能" in world.power_description.text and "7,200" in world.power_description.text, "live generator recovery explains finite energy loss")
		await native_shot("01-generator-recovery-confirmation")
		await native_click(world.power_dialog.get_cancel_button())
		driver.expect(Compare.equivalent(before, Codec.snapshot(world.model, world.store.world_id, world.store.world_name, before.sequence)), "cancel generator recovery keeps every authoritative field")
	var generator: Dictionary = world.model.by_id(ids.G)
	var was_enabled: bool = generator.enabled
	await native_click(world.discovery_panel.buttons.device_toggle)
	driver.expect(generator.enabled != was_enabled, "actual generator stop/resume control changes state")
	await native_shot("01-generator-toggled")
	await native_click(world.discovery_panel.buttons.device_toggle)
	driver.expect(Compare.equivalent(before, Codec.snapshot(world.model, world.store.world_id, world.store.world_name, before.sequence)), "paused panel refresh and stop/resume cycle preserve fuel, energy and all saved state")
	await driver.key(KEY_ESCAPE)
	await _go("E", "")
	if finished: return
	await native_click(world.hud.buttons.pause)
	await _open_nearby("E")
	if finished: return
	var assembler: Dictionary = world.model.by_id(ids.E)
	driver.expect(assembler.recipe_id == "cell_assembly", "R12 appears on the actual assembler")
	var connected := 0
	for port in world.model.Logistics.ports(world.model, assembler, "input"):
		if world.model.Logistics.input_connection(world.model, assembler, port).ok: connected += 1
	driver.expect(connected == 3, "R12 uses three connected material inlets")
	await _layout_checks()
	await native_shot("02-three-input-cell-assembly")
	var progress: float = assembler.progress
	var invested: Dictionary = assembler.invested.duplicate(true)
	await native_click(world.discovery_panel.buttons.device_toggle)
	driver.expect(not assembler.enabled and "手动停机" in world.model.feedback(assembler).label, "actual local stop shows preserved-production status")
	await native_shot("03-consumer-stopped")
	await native_click(world.discovery_panel.buttons.device_toggle)
	driver.expect(assembler.enabled and assembler.progress == progress and assembler.invested == invested, "actual local resume retains recipe batch")
	await driver.key(KEY_ESCAPE)
	await native_click(world.hud.buttons.statistics)
	world.statistics_panel.page.select(1); world.statistics_panel.page.item_selected.emit(1)
	for dimensions in [Vector2i(1100, 720), Vector2i(1440, 900)]:
		root.size = dimensions
		await driver.settle(20)
		driver.expect(root.get_visible_rect().encloses(world.statistics_panel.power_summary.get_global_rect()), "expanded energy summary remains visible " + str(dimensions))
		driver.expect("电芯供能" in world.statistics_panel.power_summary.text and "启用额定" in world.statistics_panel.power_summary.text, "statistics distinguishes enabled, available and actual cell energy")
		await driver.shot("04-energy-statistics-%dx%d" % [dimensions.x, dimensions.y])
	await native_click(world.statistics_panel.buttons.close)
	world.view.inspection_target = Vector3(generator.x - 3, 0, generator.z)
	await driver.settle(20); await driver.shot("05-energy-line")
	stage("energy-visual", "copied natural checkpoint; real WASD/F panels; three R12 inlets, imported generator, exact fuel state, local stop/resume and energy statistics at both sizes")
	await _save_checkpoint("visual-energy")


func finish() -> void:
	if finished: return
	finished = true
	for code in held_keys: push_key(code, false)
	held_keys.clear()
	var name := "recovered-read-result.json" if recovered_read else "review-result.json" if visual_only else "complete-read-result.json" if complete_read else "read-result.json" if read_mode else "write-result.json"
	write_json(name, {"assertions": driver.assertions, "failures": driver.failures, "stages": stages, "comparison": comparison, "foreground_seconds": foreground_seconds, "focus_pauses": focus_pauses, "input": "Formal Boot E2; real main-loop production; synthetic WASD/F/Tab and mouse buttons; precision build coordinates and recipe/quota candidates; no material/unlock/actor/time injection"}.merged(execution_evidence()))
	print("E2 Boot: %d assertions, %d failures" % [driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)


func walk(to: Vector2) -> void:
	world.view.inspection_target = null
	var owner := root.gui_get_focus_owner()
	if owner:
		owner.release_focus()
	var until := functional_seconds + 20.0
	while Vector2(world.actor.x, world.actor.z).distance_to(to) > 0.08:
		await wait_for_focus()
		var delta := to - Vector2(world.actor.x, world.actor.z)
		var angle := deg_to_rad(world.view.yaw)
		var input := Vector2(delta.x * cos(angle) - delta.y * sin(angle), delta.x * sin(angle) + delta.y * cos(angle))
		var desired := []
		if absf(input.x) > absf(input.y) * 0.4:
			desired.append(KEY_D if input.x > 0 else KEY_A)
		if absf(input.y) > absf(input.x) * 0.4:
			desired.append(KEY_S if input.y > 0 else KEY_W)
		for code in held_keys:
			if code not in desired:
				push_key(code, false)
		for code in desired:
			if code not in held_keys:
				push_key(code, true)
		held_keys = desired
		await process_frame
		if functional_seconds > until:
			driver.expect(false, "walking blocked at %s toward %s" % [Vector2(world.actor.x, world.actor.z), to])
			finish()
			return
	for code in held_keys:
		push_key(code, false)
	held_keys.clear()
	await driver.settle()



func _continue_recovered() -> void:
	var totals: Dictionary = world.model.statistics.totals
	var energy: float = totals.cell_supplied_kj
	var produced: int = world.model.completed_by_recipe.cell_assembly
	driver.expect(world.model.by_id(ids.E).processing and world.model.energy_balance().remaining_kj > 0, "independent restore keeps R12 partial and active generator energy")
	await native_click(world.hud.buttons.pause)
	await wait_for(func(): return world.model.completed_by_recipe.cell_assembly > produced and world.model.statistics.totals.cell_supplied_kj > energy, 60, "independent continuation completes saved R12 and supplies real work")
	if finished: return
	await _save_checkpoint("recovered-independent-continuation")


func _review_empty_and_working() -> void:
	# D's successful parent contains an off generator, no activated energy and real deficit.
	await _go("GF", "D"); await _open_nearby("GF")
	if finished: return
	if world.model.by_id(ids.GF).accepting: await native_click(world.discovery_panel.admission_controls.accepting_button)
	await driver.key(KEY_ESCAPE)
	await active(3, "review drains closed fuel admission")
	await _go("G", "D"); await _move_item("G", "industrial_cell", false)
	await _toggle("G", true)
	await wait_for(func(): return world.model.power_state().request_kw > 240, 60, "review empty fuel under real deficit")
	if finished: return
	await native_click(world.hud.buttons.pause)
	await _open_nearby("G")
	driver.expect(world.model.by_id(ids.G).remaining_kj == 0 and world.model.by_id(ids.G).fuel.is_empty() and "燃料耗尽" in world.model.feedback(world.model.by_id(ids.G)).label, "empty-fuel feedback preserves base supply")
	await native_shot("00-generator-empty-under-load")
	await native_click(world.discovery_panel.buttons.industrial_cell_put_all)
	await driver.key(KEY_ESCAPE)
	await native_click(world.hud.buttons.pause)
	await wait_for(func(): return world.model.by_id(ids.G).remaining_kj > 0 and world.model.power_state().sources[ids.G] > 0, 60, "real returned fuel supplies deficit")
	if finished: return
	await native_click(world.hud.buttons.pause)
	await _open_nearby("G")
	await native_shot("00-generator-supplying-real-load")
	await driver.key(KEY_ESCAPE)
	await _go("GF", "D"); await _open_nearby("GF")
	await native_click(world.discovery_panel.admission_controls.accepting_button)
	await driver.key(KEY_ESCAPE)


func _process(delta: float) -> bool:
	var result := super._process(delta)
	if visual_only and not background_mode and not finished and foreground_seconds > 0 and is_instance_valid(world):
		var focused_window: bool = root.has_focus() or world.discovery_panel.get_window().has_focus() or (world.power_dialog.visible and world.power_dialog.has_focus())
		if not focused_window:
			driver.expect(false, "focus_lost: E2 short review stopped without reacquiring focus")
			finish()
	return result
