extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Driver := preload("res://scripts/checks/factory_window_driver.gd")
const Route := preload("res://scripts/checks/factory_frontier_route.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const Compare := preload("res://scripts/checks/factory_expansion_compare.gd")
const Guidance := preload("res://scripts/factory/discovery_guidance.gd")
const Codec := Store.Codec
const Frontier := Codec.V10.Frontier
const NAME := "开拓工厂联合复核"
const WINDOW_SECONDS := 360
const WARMUP_SECONDS := 420

var evidence := ""
var boot: Node
var driver := Driver.new()
var windowed := false


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var args := OS.get_cmdline_user_args()
	var play := "--play" in args
	var batch := ""
	for arg in args:
		if arg.begins_with("--batch="):
			batch = arg.trim_prefix("--batch=")
	if not batch.is_valid_filename() or ".." in batch:
		push_error("Requires a valid isolated frontier batch.")
		quit(2)
		return
	var parent := SliceCheckPaths.review_worlds("factory-frontier-v1") if play else SliceCheckPaths.check_run("factory-frontier-v1", false)
	evidence = parent.path_join(batch)
	windowed = DisplayServer.get_name() != "headless"
	if not DirAccess.dir_exists_absolute(evidence) or (play and not windowed):
		push_error("Requires an existing isolated frontier batch.")
		quit(2)
		return
	driver.capture_screenshots = windowed
	driver.shot_root = evidence
	root.add_child(driver)
	if windowed:
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1440, 900).min(DisplayServer.screen_get_usable_rect().size - Vector2i(32, 48))
		root.move_to_center()
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(evidence.path_join("slice"))
	boot.factory_save_root = evidence.path_join("factory")
	boot.factory_frontier_context = true
	root.add_child(boot)
	if play:
		return
	await driver.settle(15)
	if windowed and not root.has_focus():
		driver.expect(false, "window has focus")
	else:
		await _click(boot.startup_menu.find_child("FactoryButton", true, false))
		if "--read" in args:
			await _read()
		else:
			await _write_and_compare()
	print("Factory frontier: %d checks, %d failures" % [driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)


func _click(button: Button) -> void:
	if windowed:
		await driver.click(button)
	else:
		driver.expect(not button.disabled, "available: " + button.text)
		button.pressed.emit()
		await driver.settle()


func _write_and_compare() -> void:
	var menu: Control = boot.factory_menu
	var index := -1
	for i in menu.world_type.item_count:
		if menu.world_type.get_item_metadata(i) == Frontier.SUPPLY_ID:
			index = i
	driver.expect(index >= 0 and not Store.new(Store.DEFAULT_ROOT, false, true).allow_frontier, "frontier creation is opt-in and isolated")
	if index < 0:
		return
	var ordinary_store := Store.new(boot.factory_save_root)
	driver.expect(not ordinary_store.create(NAME, Frontier.SUPPLY_ID, true).ok, "ordinary store cannot create frontier")
	menu.world_type.select(index)
	menu.title_input.text = NAME
	await _click(menu.create_button)
	var world: Control = boot.factory_world
	driver.expect(world != null and world.initialized, "Boot creates an isolated frontier world")
	if world == null or not world.initialized:
		return
	driver.world = world
	world._set_paused(true)
	driver.expect(world.view.assets.reactor.resource_path == world.View.ASSET_ROOT + "reactor.glb", "new D1 keeps the existing reactor scene")
	var model: RefCounted = world.model
	var route := Route.new(model, _load("starter.json"))
	var layout := _load("layout.json")
	route.bootstrap()
	route.energy_line()
	var temporary := route.prepare_expansion(layout.incremental_packs + 4)
	driver.expect(not model.research_status(Frontier.RESEARCH).ok and "试制" in model.research_status(Frontier.RESEARCH).reason,
		"X2 requires a completed trial")
	route.prepare_research(temporary[0])
	if windowed:
		world.core_panel.open(model)
		var choices: OptionButton = world.core_panel.research_choice
		for i in choices.item_count:
			if choices.get_item_metadata(i) == Frontier.RESEARCH:
				choices.select(i)
		world.core_panel._refresh_progression()
		world.core_panel.tabs.current_tab = world.core_panel.tabs.get_tab_count() - 3
		await driver.shot("01-x2-research")
		await _click(world.core_panel.research_button)
		world.core_panel.close()
	else:
		route._must(model.research(Frontier.RESEARCH))
	driver.expect(model.researched.has(Frontier.RESEARCH) and not model.research(Frontier.RESEARCH).ok, "X2 submits only once")
	await _check_outer_guidance(world, route)
	route.open_outer_and_prepare_capsules(temporary[0], temporary[1])
	world._refresh()
	driver.expect(world.ui.waypoint.is_empty() and world.ui.interaction_kind != world.InteractionTarget.OUTER_PASSAGE
		and world.hud.buttons.guide_action.text == "定位胶囊组装机",
		"opening the outer passage clears its marker and points to the assembler while capsules are missing")
	await _click(world.hud.buttons.guide_action)
	driver.expect(world.ui.waypoint.get("point") == model.Grid.center(temporary[1]), "capsule guidance marks the existing assembler")
	route.walk_to(Route.GATE)
	world._refresh()
	driver.expect(world.ui.interaction_kind != world.InteractionTarget.FRONTIER_PASSAGE, "the field prompt waits for all four capsules")
	driver.expect(not model.open_passage(Frontier.PASSAGE).ok and model.bag.get(Frontier.CAPSULE, 0) == 3
		and model.blocked_for_actor(12.5, 7.5) and not model.placement("belt", Vector2i(12, 4)).ok,
		"three capsules leave inventory, collision and build gate intact")
	var id: String = world.store.world_id
	var before_gate := Codec.snapshot(model, id, NAME, world.store.sequence)
	var locked := Codec.decode(before_gate, id)
	driver.expect(locked.ok and not locked.model.discovery.passages[Frontier.PASSAGE], "closed gate and three capsules decode: " + locked.get("reason", ""))
	route.craft(temporary[1], "boring_capsule_assembly", 1)
	world._refresh()
	driver.expect(world.ui.waypoint.is_empty() and world.hud.buttons.guide_action.text == "定位炭矿支路入口",
		"the fourth capsule clears the factory marker and unlocks the north entrance locator")
	await _click(world.hud.buttons.guide_action)
	driver.expect(not model.open_passage(Frontier.PASSAGE).ok and model.bag.get(Frontier.CAPSULE, 0) == 4, "opening remotely consumes nothing")
	route.walk_to(Route.GATE)
	world._refresh()
	driver.expect(world.hud.interaction_button.visible and world.hud.interaction_button.text.begins_with("F  炭矿支路开路"),
		"four capsules and a reachable north entrance expose the field interaction")
	if windowed:
		await driver.shot("02-closed-frontier")
		await driver.key(KEY_F)
		driver.expect(world.discovery_panel.visible and model.bag.get(Frontier.CAPSULE, 0) == 4,
			"F opens the branch confirmation without consuming capsules")
		await driver.shot("03-four-capsules")
		await _click(world.discovery_panel.buttons.frontier)
		world.discovery_panel.close_panel()
	else:
		route._must(model.open_passage(Frontier.PASSAGE))
	driver.expect(model.discovery.passages[Frontier.PASSAGE] and not model.discovery.passages.inner
		and not model.bag.has(Frontier.CAPSULE) and not model.open_passage(Frontier.PASSAGE).ok
		and model.statistics.totals.consumed.get(Frontier.CAPSULE) == 4,
		"frontier opens without inner passage and charges exactly four capsules")
	world._refresh()
	driver.expect(world.ui.waypoint.is_empty() and world.ui.interaction_kind != world.InteractionTarget.FRONTIER_PASSAGE,
		"opening the branch clears its marker and field prompt")
	driver.expect("架设高产采集器" in world.hud.mission.text and world.hud.buttons.guide_action.text == "定位高产炭矿",
		"the open branch guides the player to place the prepared collector")
	if windowed:
		world._refresh()
		await _click(world.hud.buttons.guide_action)
		await driver.shot("04-open-frontier")
	route.expand(layout, temporary)
	var ids := {}
	for key in ["K", "Kh", "G", "F", "C", "Td", "Ts"]:
		ids[key] = route.devices[key].id
	driver.expect(route.devices.Kh.power_node_id != 0 and model.collector_cycle(route.devices.Kh) == 5.0
		and model.collector_cycle(route.devices.K) == 20.0, "both ore sources connected with distinct cycles")
	world._refresh()
	driver.expect("启动高产采集器" in world.hud.mission.text and "回流线已接到粉碎机" in world.hud.mission.text,
		"the actual line is recognized while the high-yield collector is stopped")
	var common := Codec.snapshot(model, id, NAME, world.store.sequence)
	var base := Codec.decode(common, id)
	driver.expect(base.ok, "common checkpoint decodes: " + base.get("reason", ""))
	if not base.ok:
		return
	var ordinary := _sample(base.model, ids, false)
	var rich := _sample(model, ids, true)
	for i in 2:
		driver.expect(rich[i].mixed >= 30 and rich[i].mixed * 5 >= ordinary[i].mixed * 6,
			"high-yield ore improves mixed batches by at least 20%% in window %d" % (i + 1))
		driver.expect(rich[i].high_ore > 0 and ordinary[i].high_ore == 0
			and ordinary[i].mixed <= 24 and rich[i].slag > 0 and rich[i].core_plate > 0 and rich[i].packs > 0,
			"comparison changes the sole source and proves sustained co-product recovery")
	var feedback_state := Codec.decode(Codec.snapshot(model, id, NAME, world.store.sequence), id)
	driver.expect(feedback_state.ok, "guidance fault checks use a copy of the live route")
	if feedback_state.ok:
		_check_production_guidance(feedback_state.model, ids)
	world._refresh()
	driver.expect("混料累计" in world.hud.mission.text and "用板材做构件包" in world.hud.mission.text
		and world.ui.waypoint.is_empty(), "live mixed output guides expansion and clears the old mine marker")
	if windowed:
		world._refresh()
		await _click(world.hud.buttons.guide_action)
		await driver.shot("05-powered-frontier-belt")
		world.view.inspection_target = Vector3(-23.0, 0.25, 8.0)
		await driver.shot("06-mixed-refining-and-slag")
	var expansion := await _verify_first_expansion(world, route)
	if expansion.is_empty():
		return
	var persisted := _checkpoint(model, ids)
	driver.expect(persisted, "checkpoint includes ore in transit, partial collection and crushing, and active fuel")
	var checkpoint := Codec.snapshot(model, id, NAME, world.store.sequence)
	_mutations(checkpoint, id)
	_backup_identity(checkpoint, id)
	await _click(world.hud.buttons["return"])
	driver.expect(boot.factory_world == null, "save and return releases the writer")
	if boot.factory_world != null:
		return
	var candidate := Store.new(boot.factory_save_root, false, true).find_candidate(id)
	driver.expect(candidate.ok and candidate.document.save_schema_version == Codec.V10.VERSION, "publish schema 10")
	if not candidate.ok:
		return
	driver.expect(not ordinary_store.find_candidate(id).ok, "ordinary menu cannot continue frontier")
	var sequence: int = candidate.document.sequence
	model.advance(30, 600)
	_save("expected.json", {"before": candidate.document, "after": Codec.snapshot(model, id, NAME, sequence), "ids": ids})
	_save("result.json", {"ordinary": ordinary, "high_yield": rich, "warmup_seconds": WARMUP_SECONDS, "expansion": expansion,
		"assertions": driver.assertions, "failures": driver.failures, "window": windowed})
	print("Frontier comparison: ", JSON.stringify({"ordinary": ordinary, "high_yield": rich}))
	print("Frontier expansion: ", JSON.stringify(expansion))


func _verify_first_expansion(world: Control, route: RefCounted) -> Dictionary:
	var model: RefCounted = world.model
	var start_tick: int = model.statistics.ticks
	var fuel_before: float = model.statistics.totals.fuel_released_kj
	var deficit_before: float = model.statistics.totals.deficit_kj
	var packs_before: int = model.core.items.get("construction_pack", 0)
	var cost: int = model.assembly_costs.refinery
	var expansion: Dictionary = route.collect_mixed_plate_packs(cost)
	driver.expect(not expansion.is_empty() and model.core.items.get("construction_pack", 0) == packs_before + cost,
		"the terminal receives new packs made with mixed plates and those packs reach the core")
	if expansion.is_empty():
		return {}
	route.prepare_slag_reuse()
	var stored_refineries: int = model.kits.refinery
	if windowed:
		world.view.inspection_target = null
		world.core_panel.open(model)
		world.core_panel.tabs.current_tab = world.core_panel.tabs.get_tab_count() - 1
		var options: OptionButton = world.core_panel.assembly_choice
		for i in options.item_count:
			if options.get_item_metadata(i) == "refinery":
				options.select(i)
				break
		world.core_panel.refresh(world.ui.paused)
		await driver.shot("06a-expansion-assembly")
		await _click(world.core_panel.assembly_button)
		world.core_panel.close()
	else:
		route._must(model.assemble("refinery"))
	var paid: bool = model.core.items.get("construction_pack", 0) == packs_before and model.kits.refinery == stored_refineries + 1
	driver.expect(paid, "refinery assembly spends the newly delivered packs and preserves the existing core stock")
	if not paid:
		return {}
	var furnace: Dictionary = route.build_slag_reuse_line()
	var carrier_before: int = model.core.items.get("porous_carrier", 0)
	var reuse_before: int = model.completed_by_recipe.slag_sintering
	route.stock(furnace, "mineral_slag", 4, true)
	route.stock(furnace, "crystal", 2, true)
	world._refresh()
	driver.expect(world.hud.buttons.guide_action.text == "定位矿渣烧结炉" and "载体回仓线已接通" in world.hud.mission.text,
		"the newly configured furnace is located before its first output")
	if windowed:
		world._open_device(furnace.id)
		world._refresh()
		await driver.shot("06b-slag-reuse-line")
		world.discovery_panel.close_panel()
	route.wait_for(func(): return model.core.items.get("porous_carrier", 0) >= carrier_before + 4,
		60, "new refinery delivers two successive batches of carriers to the core")
	var carriers: int = model.core.items.get("porous_carrier", 0) - carrier_before
	driver.expect(model.kits.refinery == stored_refineries and furnace.power_node_id > 0 and carriers == 4
		and model.completed_by_recipe.slag_sintering == reuse_before + 2 and model.material_balance().balanced,
		"the added powered refinery runs two batches and delivers all four carriers through the belt without refilling")
	world._refresh()
	driver.expect(world.hud.buttons.guide_action.text == "定位基地核心" and "查看矿渣回用成果" in world.hud.mission.text
		and "核心现有载体 %d 件" % (carrier_before + carriers) in world.hud.mission.text,
		"after real arrival, guidance points at the core and reflects its carrier stock")
	var elapsed: float = (model.statistics.ticks - start_tick) * Route.STEP
	var released: float = model.statistics.totals.fuel_released_kj - fuel_before
	driver.expect(is_equal_approx(released, elapsed * Route.Model.Energy.GENERATOR_KW)
		and is_equal_approx(model.statistics.totals.deficit_kj, deficit_before), "generation continues throughout construction without a deficit")
	if windowed:
		route.walk_near(model.core)
		world.core_panel.open(model)
		world.core_panel.tabs.current_tab = 0
		await driver.shot("06c-reused-carriers-in-core")
		world.core_panel.close()
	return expansion.merged({"packs_spent": cost, "refinery_id": furnace.id, "slag_spent_for_production": 4,
		"carriers_delivered": carriers, "construction_seconds": elapsed, "fuel_released_kj": released})


func _check_production_guidance(model: RefCounted, ids: Dictionary) -> void:
	var furnace: Dictionary = model.by_id(ids.F)
	# Isolate the diagnostic variables without changing the window world's route or ledger.
	furnace.processing = false
	furnace.output = {}
	furnace.input = {"iron_powder": 3}
	driver.expect("精炼炉缺炭粉" in Guidance.integrated_location(model).mission, "mixed refining distinguishes missing carbon")
	furnace.input = {"carbon_powder": 1}
	driver.expect("精炼炉缺铁粉" in Guidance.integrated_location(model).mission, "mixed refining distinguishes missing iron")
	var routes = Route.Model.BeltLogistics
	var output: Dictionary = routes.ports(model, furnace, "output")[0]
	var outlet: Dictionary = model.entity_at(Vector2i(output.x + output.dx, output.z + output.dz))
	var route := Route.new(model, {})
	route.advance_movement = false
	route.walk_near(outlet)
	route._must(model.salvage(outlet.id))
	furnace.output = {"metal_plate": 2}
	driver.expect("出料受阻 · 金属板：未连接" in Guidance.integrated_location(model).mission, "mixed refining identifies the disconnected plate output")
	var ore: Dictionary = model.by_id(ids.Kh)
	output = routes.ports(model, ore, "output")[0]
	var ore_outlet: Dictionary = model.entity_at(Vector2i(output.x + output.dx, output.z + output.dz))
	route.walk_near(ore_outlet)
	route._must(model.salvage(ore_outlet.id))
	var feedback := Guidance.integrated_location(model)
	driver.expect(feedback.action_label == "定位高产炭矿" and "还没有通往炭矿粉碎机的线路" in feedback.mission,
		"historical output cannot advance guidance when the ore line has been cut")


func _check_outer_guidance(world: Control, route: RefCounted) -> void:
	world._refresh()
	var guide: Button = world.hud.buttons.guide_action
	var entrance := Vector2(Route.Model.DiscoveryRules.PASSAGES.outer.x - 1, 0)
	driver.expect(guide.visible and guide.text == "定位外矿道" and "4 / 4" in world.hud.mission.text,
		"X2 shows the outer passage locator and carried solvent")
	driver.expect(world.ui.interaction_kind != world.InteractionTarget.OUTER_PASSAGE, "no outer passage interaction out of range")
	await _click(guide)
	driver.expect(world.ui.waypoint.get("point") == entrance and world.hud.waypoint_panel.visible,
		"outer passage locator marks the reachable west approach")
	if windowed:
		await driver.shot("01a-outer-passage-location")
	route.walk_to(entrance)
	world._refresh()
	driver.expect(guide.visible and guide.text == "查看外矿道操作", "near the passage, guidance offers the operation")
	var prompt: Button = world.hud.interaction_button
	driver.expect(prompt.visible and prompt.text.begins_with("F  外矿道开路"), "nearby outer passage has a local interaction prompt")
	if windowed:
		await driver.shot("01b-outer-passage-prompt")
		await driver.key(KEY_F)
		driver.expect(world.discovery_panel.visible and world.model.bag.get("crust_solvent", 0) == 4
			and not world.model.discovery.passages.outer, "F opens the panel without spending solvent")
		world.discovery_panel.close_panel()
		await driver.settle()
	await _click(prompt)
	driver.expect(world.discovery_panel.visible and not world.discovery_panel.buttons.outer.disabled,
		"clicking the prompt opens the panel with the outer passage button available")
	if windowed:
		await driver.shot("01c-outer-passage-operation")
	world.discovery_panel.close_panel()


func _sample(model: RefCounted, ids: Dictionary, high: bool) -> Array[Dictionary]:
	var route := Route.new(model, {})
	route.advance_movement = false
	var source: Dictionary = model.by_id(ids.Kh if high else ids.K)
	route.walk_near(source)
	route._must(model.set_device_enabled(source.id, true))
	if high:
		var guide := Guidance.integrated_location(model)
		driver.expect(guide.action_label == "定位炭矿粉碎机" and guide.point == model.Grid.center(model.by_id(ids.C))
			and "等炭矿到达" in guide.mission, "the connected but empty line locates its actual receiving crusher")
	model.advance(WARMUP_SECONDS, WARMUP_SECONDS * 20)
	var results: Array[Dictionary] = []
	for i in 2:
		var start := _metrics(model, ids)
		var peak := 0.0
		var carbon_wait := 0
		var iron_wait := 0
		var output_wait := 0
		var furnace: Dictionary = model.by_id(ids.F)
		for second in WINDOW_SECONDS:
			model.advance(1, 20)
			peak = maxf(peak, model.power_state().request_kw)
			if not furnace.processing:
				if not furnace.output.is_empty():
					output_wait += 1
				elif furnace.input.get("iron_powder", 0) < 3:
					iron_wait += 1
				elif not furnace.input.has("carbon_powder"):
					carbon_wait += 1
		var end := _metrics(model, ids)
		var delta := {}
		for key in start:
			delta[key] = end[key] - start[key]
		delta.merge({"peak_sampled_kw": peak, "carbon_wait_samples": carbon_wait,
			"iron_wait_samples": iron_wait, "output_wait_samples": output_wait})
		results.append(delta)
		driver.expect(delta.ticks == WINDOW_SECONDS * 20 and delta.activations == 6 and
			absf(delta.released_kj - WINDOW_SECONDS * 120) < 0.001 and absf(delta.deficit_kj) < 0.001,
			"same continuous fuel service with no power deficit")
		driver.expect(delta.cells >= 6 and delta.held_cells >= 0 and delta.held_coal_units >= 0 and
			2 * delta.ore == delta.held_coal_units + delta.mixed + 2 * delta.activations and
			model.material_balance().balanced, "both production lines conserve carbon without drawing down reserves")
	return results


func _metrics(model: RefCounted, ids: Dictionary) -> Dictionary:
	var totals: Dictionary = model.statistics.totals
	var held: Dictionary = model.material_balance().held
	return {"ticks": model.statistics.ticks, "ore": model.extracted_by_item.carbon_ore, "high_ore": model.frontier_extracted,
		"mixed": model.completed_by_recipe.mixed_refining, "cells": model.completed_by_recipe.cell_assembly,
		"packs": model.completed_by_recipe.construction_assembly, "slag": model.by_id(ids.Ts).items.get("mineral_slag", 0),
		"direct_plate": model.by_id(ids.Td).items.get("metal_plate", 0),
		"core_plate": model.core.items.get("metal_plate", 0), "spill_kj": totals.spill_kj,
		"activations": totals.cells_activated, "released_kj": totals.fuel_released_kj, "deficit_kj": totals.deficit_kj,
		"held_cells": held.get("industrial_cell", 0),
		"held_coal_units": 2 * held.get("carbon_ore", 0) + held.get("carbon_powder", 0) + 2 * held.get("industrial_cell", 0)}


func _checkpoint(model: RefCounted, ids: Dictionary) -> bool:
	for i in 400:
		if _live_frontier(model, ids):
			return true
		model.advance(Route.STEP, 1)
	return false


func _live_frontier(model: RefCounted, ids: Dictionary) -> bool:
	return model.by_id(ids.Kh).progress > 0.0 and model.by_id(ids.C).processing \
		and model.by_id(ids.G).burn_remaining_ticks > 0 and range(2, 9).any(func(z):
			return model.entity_at(Vector2i(12, z)).get("cargo", "") == "carbon_ore")


func _backup_identity(checkpoint: Dictionary, id: String) -> void:
	var save_root := evidence.path_join("identity-failure")
	var folder := save_root.path_join(id)
	assert(DirAccess.make_dir_recursive_absolute(folder.path_join("backups")) == OK)
	var main := checkpoint.duplicate(true)
	main.state.frontier_extracted = -1
	_save("identity-failure/%s/autosave.json" % id, main)
	var old := Codec.snapshot(Route.Model.new(), id, NAME, 1)
	_save("identity-failure/%s/backups/autosave.bak.1.json" % id, old)
	var path := folder.path_join("autosave.json")
	var hash := FileAccess.get_sha256(path)
	var result := Store.new(save_root, false, true).find_candidate(id)
	driver.expect(not result.ok and result.get("unsupported", false) and FileAccess.get_sha256(path) == hash,
		"mismatched schema 9 backup cannot replace a damaged schema 10 primary")


func _mutations(snapshot: Dictionary, id: String) -> void:
	for key in ["digest", "closed", "mined", "research", "charge", "legacy"]:
		var document := snapshot.duplicate(true)
		match key:
			"digest": document.definitions_sha256 = "wrong"
			"closed": document.state.discovery.passages[Frontier.PASSAGE] = false
			"mined": document.state.frontier_extracted = document.state.extracted_by_item.carbon_ore + 1
			"research": document.state.research.completed.erase(Frontier.RESEARCH)
			"charge": document.state.statistics.totals.consumed[Frontier.CAPSULE] = 3
			"legacy": document.save_schema_version = 9
		driver.expect(not Codec.decode(document, id).ok, "reject frontier save mutation: " + key)


func _read() -> void:
	var expected := _load("expected.json")
	var menu: Control = boot.factory_menu
	driver.expect(menu.worlds.size() == 1 and menu.worlds[0].schema == Codec.V10.VERSION
		and menu.worlds[0].id == expected.before.world_id, "isolated Boot lists the frontier world")
	if menu.worlds.size() != 1:
		return
	menu.list.select(0)
	menu.list.item_selected.emit(0)
	menu.world_ready.connect(func(_store, _model, _candidate):
		if boot.factory_world != null:
			boot.factory_world._set_paused(true), CONNECT_ONE_SHOT)
	await _click(menu.continue_button)
	var world: Control = boot.factory_world
	driver.expect(world != null and world.initialized, "independent Boot process restores frontier")
	if world == null or not world.initialized:
		return
	driver.world = world
	driver.expect(world.view.assets.reactor.resource_path == world.View.ASSET_ROOT + "reactor.glb", "continued D1 keeps the existing reactor scene")
	var model: RefCounted = world.model
	var startup: float = world.production_clock.active_usec / 1000000.0
	var snapshot := Codec.snapshot(model, world.store.world_id, NAME, world.store.sequence)
	snapshot.state.remainder_s -= startup
	driver.expect(Compare.equivalent(snapshot, expected.before), "same full schema 10 snapshot")
	driver.expect(model.frontier_extracted > 0 and model.discovery.passages[Frontier.PASSAGE]
		and _live_frontier(model, expected.ids), "opened branch, cargo, in-process ore and active fuel survive restore")
	world._refresh()
	driver.expect(world.hud.buttons.guide_action.text == "定位基地核心" and "查看矿渣回用成果" in world.hud.mission.text,
		"the restored production state brings back the expansion result and core locator")
	if windowed:
		await _click(world.hud.buttons.guide_action)
		await driver.shot("07-restored-frontier")
	model.advance(30, 600)
	snapshot = Codec.snapshot(model, world.store.world_id, NAME, world.store.sequence)
	snapshot.state.remainder_s -= startup
	driver.expect(Compare.equivalent(snapshot, expected.after), "same resumed 30-second trajectory")
	await _click(world.hud.buttons["return"])
	var outage := _supply_interruption(expected.before, expected.ids)
	_save("restore.json", {"assertions": driver.assertions, "failures": driver.failures,
		"window": windowed, "supply_interruption": outage})


func _supply_interruption(checkpoint: Dictionary, ids: Dictionary) -> Dictionary:
	var branch := Codec.decode(checkpoint, checkpoint.world_id)
	driver.expect(branch.ok, "outage check forks the saved frontier")
	if not branch.ok:
		return {}
	var model: RefCounted = branch.model
	var route := Route.new(model, {})
	route.advance_movement = false
	var source: Dictionary = model.by_id(ids.Kh)
	var furnace: Dictionary = model.by_id(ids.F)
	route.walk_near(source)
	route._must(model.set_device_enabled(source.id, false))
	var queued_ore: int = model.material_balance().held.get("carbon_ore", 0)
	# Allow the long belt and the queued R07 batches to drain before looking for starvation.
	var drain_limit := 180 + queued_ore * 8
	var drain := 0
	while drain < drain_limit:
		model.advance(1, 20)
		drain += 1
		if not furnace.processing and furnace.output.is_empty() and furnace.input.get("iron_powder", 0) >= 3 \
			and not furnace.input.has("carbon_powder"):
			break
	driver.expect(drain < drain_limit, "turning off the high-yield collector eventually stops mixed refining for lack of carbon")
	var batches: int = model.completed_by_recipe.mixed_refining
	route._must(model.set_device_enabled(source.id, true))
	var recovery := 0
	while recovery < 180 and model.completed_by_recipe.mixed_refining == batches:
		model.advance(1, 20)
		recovery += 1
	driver.expect(recovery < 180 and model.material_balance().balanced,
		"resuming the source restarts mixed refining without manual feed")
	return {"queued_ore": queued_ore, "drain_seconds": drain, "recovery_seconds": recovery}


func _load(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join(name)))


func _save(name: String, value: Dictionary) -> void:
	var file := FileAccess.open(evidence.path_join(name), FileAccess.WRITE)
	assert(file != null, "write evidence " + name)
	file.store_string(JSON.stringify(value, "\t", true, true))
