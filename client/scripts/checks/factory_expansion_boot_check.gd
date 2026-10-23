extends "res://scripts/checks/factory_routing_boot_check.gd"

const Compare := preload("res://scripts/checks/factory_expansion_compare.gd")
const Layout := preload("res://scripts/checks/factory_expansion_layout.gd")
var complete_read := false
var visual_only := false
var last_route: Array[Vector2] = []
var transfer_commands := 0
var recipe_commands := 0
var baseline_recipes := {}
var baseline_time := 0.0


func run() -> void:
	if new_world_type != 3:
		evidence_topic = "factory-production-expansion-e1"
		screenshot_topic = "2026-10-22-factory-expansion-e1-preview"
		new_world_type = 2
		new_world_title = "生产扩建 E1 · 自然生产"
	complete_read = "--complete-read" in OS.get_cmdline_user_args()
	visual_only = "--visual-only" in OS.get_cmdline_user_args()
	await super.run()


func _first_line() -> void:
	world.view.yaw = 0
	world.view.sync_camera()
	driver.expect(world.model.supply_id == Codec.V6.Expansion.SUPPLY_ID and world.model.owned_count() == 165 and world.model.bag.is_empty() and world.model.entities.is_empty(), "formal Boot creates empty ordinary E1 with 165 kits")
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
	await _save_checkpoint("A-second-furnace")


func _restore() -> void:
	world.view.yaw = 0
	world.view.sync_camera()
	ids = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("ids.json")))
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("expected.json")))
	driver.expect(Compare.equivalent(Codec.snapshot(world.model, world.store.world_id, world.store.world_name, int(expected.sequence)), expected), "independent Boot restores complete saved E1 checkpoint before first simulation frame")
	var route: Array = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("route.json")))
	for point in route: last_route.append(Vector2(point[0], point[1]))
	baseline_time = world.model.time
	baseline_recipes = world.model.completed_by_recipe.duplicate()
	check_failures()
	if finished: return
	if visual_only:
		await _review()
	elif complete_read:
		await _complete_reuse()
	else:
		await _start_reuse()


func _start_reuse() -> void:
	driver.expect(world.model.first_expansion_placed and world.model.assembly_counts.refinery == 1 and world.model.completed_by_recipe.construction_assembly == 2, "B starts from manufactured second furnace, not a fixture supply")
	# Return along the verified A route before rebuilding its crystal terminal.
	await native_click(world.hud.buttons.pause)
	await _go("U", "A")
	await _open_nearby("U")
	if finished: return
	await native_click(world.discovery_panel.buttons.salvage)
	if world.discovery_panel.visible: await driver.key(KEY_ESCAPE)
	# The two iron belts under the crusher and one preceding it are now empty.
	await _return_to_hub()
	await walk(Vector2(-29.5, 4))
	await walk(Vector2(-29.5, -9))
	await walk(Vector2(-22.5, -9))
	last_route = [Vector2(-3.5, 4), Vector2(-29.5, 4), Vector2(-29.5, -9), Vector2(-22.5, -9)]
	for x in [-23, -22]:
		ids.remove_belt = world.model.entity_at(Vector2i(x, -11)).id
		await _open_nearby("remove_belt")
		if finished: return
		await native_click(world.discovery_panel.buttons.salvage)
		if world.discovery_panel.visible: await driver.key(KEY_ESCAPE)
	await _return_to_hub()
	await native_click(world.hud.buttons.pause)
	var rows := Layout.rows("B")
	var next_ids := {}
	for row in rows:
		var e: Dictionary = world.model.entity_at(Vector2i(row.x, row.z))
		if e.is_empty():
			await place(row.type, row.x, row.z, row.name, row.dir)
			if finished: return
			e = world.model.by_id(ids[row.name])
		next_ids[row.name] = e.id
	ids = next_ids
	driver.expect(world.model.entities.size() == 62 and world.model.owned_count() == 166, "B reuses ordinary kits and actual second furnace")
	await native_click(world.hud.buttons.pause)
	await _go("F", "B")
	await _choose_recipe("F", "mixed_refining")
	await _go("R", "B")
	await _choose_recipe("R", "slag_sintering")
	await _go("C", "B")
	await _choose_recipe("C", "carbon_crushing")
	await _go("GK", "B")
	await _configure_gate("GK", "carbon_ore", 1)
	await wait_for(func(): return world.model.by_id(ids.U).items.get("carbon_ore", 0) == 1, 30, "B one carbon mineral arrives from 20 second collector")
	if finished: return
	await _go("U", "B")
	await _move_item("U", "carbon_ore", false)
	await _go("C", "B")
	await _move_item("C", "carbon_ore", true)
	await wait_for(func(): return world.model.by_id(ids.F).input.get("carbon_powder", 0) == 2, 20, "B carbon powder flows into refinery")
	if finished: return
	await _choose_recipe("C", "iron_crushing")
	await _go("GQ", "B")
	await _configure_gate("GQ", "crystal", 1)
	await _go("GI", "B")
	await _configure_gate("GI", "iron_ore", 4)
	await wait_for(func(): return world.model.by_id(ids.F).processing and world.model.by_id(ids.F).progress >= 4 and world.model.by_id(ids.F).progress < 8, 40, "R08 natural partial batch checkpoint")
	if finished: return
	await native_click(world.hud.buttons.pause)
	stage("B-partial", "two natural carbon powder inputs; crusher switched to iron; R08 invested and partially processed")
	write_json("route-B-partial.json", {"elapsed_model_seconds": world.model.time - baseline_time, "transfer_commands": transfer_commands, "recipe_commands": recipe_commands, "completed": world.model.completed_by_recipe.duplicate()})
	await _save_checkpoint("B-R08-partial")


func _complete_reuse() -> void:
	driver.expect(world.model.by_id(ids.F).processing and world.model.by_id(ids.F).recipe_id == "mixed_refining", "restore R08 investment without re-consuming inputs")
	await native_click(world.hud.buttons.pause)
	await wait_for(func(): return world.model.by_id(ids.T).items.get("construction_pack", 0) == 2, 100, "restored mixed and slag recipes deliver two new packs naturally")
	if finished: return
	await _go("T", "B")
	await _move_item("T", "construction_pack", false)
	await native_click(world.hud.buttons.pause)
	driver.expect(world.model.bag.get("construction_pack", 0) == 2 and world.model.completed_by_recipe.construction_assembly == 4, "two reusable packs ready for player's next expansion choice")
	driver.expect(world.model.completed_by_recipe.mixed_refining == 2 and world.model.completed_by_recipe.slag_sintering == 1 and world.model.completed_by_recipe.iron_crushing == 2 and world.model.completed_by_recipe.carbon_crushing == 1, "B uses 4 iron ore 1 carbon ore and 1 crystal for same two packs")
	driver.expect(world.model.first_expansion_placed and world.model.owned_count() == 166, "completed expansion fact persists without auto-manufacturing more devices")
	stage("B-complete", "independent R08 restore; paired metal and slag output; carrier reuse; two packs carried for optional next build")
	write_json("route-B-complete.json", {"elapsed_model_seconds": world.model.time - baseline_time, "transfer_commands": transfer_commands, "recipe_commands": recipe_commands, "completed": world.model.completed_by_recipe.duplicate(), "held": world.model.material_balance().held})
	await _save_checkpoint("B-complete")


func _return_to_hub() -> void:
	if world.discovery_panel.visible: await driver.key(KEY_ESCAPE)
	var reverse := last_route.duplicate()
	reverse.reverse()
	for point in reverse:
		await walk(point)
		if finished: return
	if last_route.is_empty(): await walk(Vector2(-3.5, 4))
	last_route.clear()


func _go(name: String, route_stage: String) -> void:
	await _return_to_hub()
	if finished: return
	last_route = Layout.waypoints(name, route_stage)
	for point in last_route:
		await walk(point)
		if finished: return


func _configure_gate(name: String, item: String, quota: int) -> void:
	await _open_nearby(name)
	if finished: return
	var controls: Control = world.discovery_panel.admission_controls
	var gate: Dictionary = world.model.by_id(ids[name])
	if gate.accepting: await native_click(controls.accepting_button)
	controls.item.select(world.model.admission_items.find(item) + 1)
	controls.mode.select(1)
	controls.limit.value = quota
	await driver.settle()
	await native_click(controls.apply_button)
	driver.expect(gate.filter_item == item and gate.quota_limit == quota and gate.quota_used == 0 and not gate.accepting, "configure closed gate " + name)
	await native_click(controls.accepting_button)
	await driver.key(KEY_ESCAPE)


func _choose_recipe(name: String, recipe_id: String) -> void:
	await _open_nearby(name)
	if finished: return
	var panel: Control = world.discovery_panel
	var index: int = panel.recipe_ids.find(recipe_id)
	driver.expect(index >= 0 and not panel.buttons.recipe.disabled, "empty machine can select " + recipe_id)
	if index < 0: check_failures(); return
	panel.recipe.select(index)
	await driver.settle(15)
	driver.expect(panel.recipe_ids[panel.recipe.selected] == recipe_id, "refresh preserves pending recipe choice")
	await native_click(panel.buttons.recipe)
	recipe_commands += 1
	driver.expect(world.model.by_id(ids[name]).recipe_id == recipe_id, "real recipe button applied " + recipe_id)
	await driver.key(KEY_ESCAPE)


func _move_item(name: String, item: String, putting: bool) -> void:
	await _open_nearby(name)
	if finished: return
	await native_click(world.discovery_panel.buttons[item + ("_put_all" if putting else "_take_all")])
	transfer_commands += 1
	driver.expect("已转移" in world.discovery_panel.result_label.text, "actual item transfer " + item)
	await driver.key(KEY_ESCAPE)


func native_click(button: Button) -> void:
	# E1's larger backpack scrolls independently of the device detail column.
	if button.has_meta("item_id") and not button.is_visible_in_tree():
		var slot: Button = world.discovery_panel.item_button(button.get_meta("item_id"), button.get_meta("bag_side"))
		if slot != null: await native_click(slot)
	var parent: Node = button.get_parent()
	while parent != null:
		if parent is ScrollContainer: parent.ensure_control_visible(button)
		parent = parent.get_parent()
	await super.native_click(button)


func _snapshot() -> Dictionary:
	return Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)


func _save_checkpoint(label: String) -> void:
	if not world.ui.paused: await native_click(world.hud.buttons.pause)
	await native_click(world.hud.buttons.save)
	driver.expect(not world.save_failed and Codec.decode(_snapshot(), world.store.world_id).ok, "strict content-world save succeeds " + label)
	write_json("expected.json", _snapshot())
	write_json("ids.json", ids)
	write_json("route.json", last_route.map(func(point): return [point.x, point.y]))
	await native_click(world.hud.buttons.return)
	driver.expect(boot.factory_world == null, "save and return releases content world")


func _review() -> void:
	if not ids.has("C"):
		await _review_direct()
		return
	# This copy begins at the natural R08 checkpoint. Only camera framing is direct.
	world.view.inspection_target = Vector3(-16, 0, -5)
	await driver.settle(20)
	await driver.shot("01-recovered-production")
	await native_click(world.hud.buttons.pause)
	await walk(Vector2(-26, -7))
	await walk(Vector2(-16.5, -7))
	last_route = Layout.waypoints("F", "B")
	await native_click(world.hud.buttons.pause)
	ids.slag_break = world.model.entity_at(Vector2i(-16, -9)).id
	await _open_nearby("slag_break")
	if finished: return
	await native_click(world.discovery_panel.buttons.salvage)
	await driver.key(KEY_ESCAPE)
	await native_click(world.hud.buttons.pause)
	await walk(Vector2(-15, -7))
	await walk(Vector2(-15, -12))
	await native_click(world.hud.buttons.pause)
	ids.main_break = world.model.entity_at(Vector2i(-16, -11)).id
	await _open_nearby("main_break")
	if finished: return
	await native_click(world.discovery_panel.buttons.salvage)
	await driver.key(KEY_ESCAPE)
	await native_click(world.hud.buttons.pause)
	await walk(Vector2(-15, -7))
	await walk(Vector2(-16.5, -7))
	await wait_for(func(): return not world.model.by_id(ids.F).output.is_empty(), 25, "natural mixed output retained at disconnected ports")
	if finished: return
	await native_click(world.hud.buttons.pause)
	await _open_nearby("F")
	if finished: return
	driver.expect("未连接" in world.discovery_panel.device_summary.ports.text, "refinery names disconnected output ports")
	await _layout_checks()
	await native_shot("02-refinery-both-outlets-disconnected")
	await driver.key(KEY_ESCAPE)
	await place("belt", -16, -11, "main_repaired")
	await native_click(world.hud.buttons.pause)
	await wait_for(func(): return not world.model.by_id(ids.F).output.has("metal_plate") and world.model.by_id(ids.F).output.has("mineral_slag"), 10, "repair drains main output while slag remains blocked")
	if finished: return
	await native_click(world.hud.buttons.pause)
	await _open_nearby("F")
	if finished: return
	driver.expect("副口矿渣积压" in world.discovery_panel.device_summary.production.text, "held slag explains why the next batch cannot start")
	await native_shot("03-refinery-slag-blocked")
	await driver.key(KEY_ESCAPE)
	await place("belt", -16, -9, "slag_repaired")
	await native_click(world.hud.buttons.pause)
	await wait_for(func(): return world.model.by_id(ids.F).output.is_empty(), 10, "repair drains retained slag without duplication")
	if finished: return
	for name in ["C", "R", "A"]:
		await _go(name, "B")
		if finished: return
		await native_click(world.hud.buttons.pause)
		await _open_nearby(name)
		if finished: return
		await _layout_checks()
		await native_shot("04-device-" + name)
		await driver.key(KEY_ESCAPE)
		await native_click(world.hud.buttons.pause)
	await native_click(world.hud.buttons.pause)
	await driver.key(KEY_I)
	driver.expect(world.discovery_panel.inventory_only, "all E1 items available in standalone backpack")
	await native_shot("05-expanded-backpack")
	await driver.key(KEY_I)
	if not world.ui.build: await native_click(world.hud.buttons.build)
	for dimensions in [Vector2i(1100, 720), Vector2i(1440, 900)]:
		root.size = dimensions
		await driver.settle(25)
		driver.expect(root.get_visible_rect().encloses(world.hud.footer.get_global_rect()), "E1 build and assembly footer fits " + str(dimensions))
		driver.expect(world.hud.buttons.assemble.disabled and "166/326" in world.hud.assembly_info.text, "assembly explains owned budget and refuses missing carried packs")
		await driver.shot("06-assembly-%dx%d" % [dimensions.x, dimensions.y])
	await driver.key(KEY_ESCAPE)
	if world.ui.build: await native_click(world.hud.buttons.build)
	world.view.inspection_target = Vector3(-17, 0, -4)
	await driver.settle(20)
	await driver.shot("07-repaired-reuse-line")
	driver.expect(world.model.material_balance().balanced and Codec.decode(_snapshot(), world.store.world_id).ok, "visual interactions preserve E1 material and batch ledgers")
	stage("visual-review", "copied natural R08 checkpoint; routed walk/F/Tab/I, real salvage and repair; primary drains while slag held; both window sizes; camera only framing")
	await _save_checkpoint("visual-review-repaired")


func _review_direct() -> void:
	await native_click(world.hud.buttons.pause)
	await _go("A", "A")
	if finished: return
	await native_click(world.hud.buttons.pause)
	await _open_nearby("A")
	if finished: return
	var connected := 0
	var e: Dictionary = world.model.by_id(ids.A)
	for port in world.model.Logistics.ports(world.model, e, "input"):
		if world.model.Logistics.input_connection(world.model, e, port).ok: connected += 1
	driver.expect(connected == 1 and world.model.completed_by_recipe.construction_assembly == 2, "direct route completes both input materials through one connected assembler inlet")
	await _layout_checks()
	await native_shot("direct-assembler-one-inlet-two-materials")
	await driver.key(KEY_ESCAPE)
	world.view.inspection_target = Vector3(-17, 0, -5)
	await driver.settle(20)
	await driver.shot("direct-second-furnace-line")
	stage("direct-visual-review", "natural A completed checkpoint; actual routed walk/F and one-inlet two-material assembly panel; no stock or actor injection")
	await _save_checkpoint("direct-visual-review")


func _layout_checks() -> void:
	var selected: Dictionary = world.model.by_id(world.discovery_panel.selected)
	for dimensions in [Vector2i(1100, 720), Vector2i(1440, 900)]:
		root.size = dimensions
		await driver.settle(25)
		var bounds: Rect2 = root.get_visible_rect()
		driver.expect(bounds.encloses(world.discovery_panel.frame.get_global_rect()), "E1 device panel fits " + str(dimensions))
		driver.expect(world.discovery_panel.frame.get_global_rect().encloses(world.discovery_panel.result_label.get_global_rect()), "E1 feedback remains outside scrolling")
		driver.expect(world.discovery_panel.frame.get_global_rect().encloses(world.discovery_panel.buttons.close.get_global_rect()), "E1 close remains reachable")
		await native_shot("layout-%s-%d-%dx%d" % [selected.type, selected.id, dimensions.x, dimensions.y])


func finish() -> void:
	if finished: return
	finished = true
	for code in held_keys: push_key(code, false)
	held_keys.clear()
	var name := "review-result.json" if visual_only else "complete-read-result.json" if complete_read else "read-result.json" if read_mode else "write-result.json"
	write_json(name, {"assertions": driver.assertions, "failures": driver.failures, "stages": stages, "foreground_seconds": foreground_seconds, "focus_pauses": focus_pauses, "pending_focus_pause": focus_pause, "transfer_commands": transfer_commands, "recipe_commands": recipe_commands, "input": "Formal Boot and distinct ordinary E1; precision HUD placement, recipe/gate dropdown candidates; routed WASD/F/Tab/Escape and synthetic mouse transfer/assembly/save; natural main-loop clock; no material/unlock/actor-position/time injection"}.merged(execution_evidence()))
	print("E1 Boot: %d assertions, %d failures" % [driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)
