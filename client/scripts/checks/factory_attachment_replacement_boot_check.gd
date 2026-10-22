extends "res://scripts/checks/factory_device_interaction_boot_check.gd"


func run() -> void:
	evidence_topic = "factory-attachment-replacement-v1"
	screenshot_topic = "2026-10-17-factory-attachment-replacement-preview"
	input_description_override = "Formal Boot/new ordinary V5 world; focused synthetic Enter menus; setup through precision fields/placement signals; real-time collector production; synthetic mouse hover/click, R, Enter and placement button replace loaded belts; camera framing only; no cargo, actor or time injection. Read is an independent Boot with saved world."
	await super.run()


func _first_line() -> void:
	await native_click(world.hud.buttons.pause)
	await native_click(world.hud.buttons.mission)
	await place("collector", -20, -1)
	for x in range(-18, -15): await place("belt", x, 0)
	await place("belt", -20, 2, "alternate", 3)
	await place("storage", -15, -1)
	await place("power_source", -22, -5)
	world.view.inspection_target = Vector3(-17, 0, 0)
	await native_click(world.hud.buttons.pause)
	await wait_for(func(): return [-18, -17, -16].all(func(x): return world.model.entity_at(Vector2i(x, 0)).cargo == "crystal"), 15, "all three belts hold naturally mined crystal")
	if finished: return
	await native_click(world.hud.buttons.pause)
	var held: Dictionary = world.model.material_balance().held
	var bag_before: int = world.model.bag.get("crystal", 0)
	var types := ["splitter", "merger", "admission_gate"]
	for index in 3:
		var type: String = types[index]
		var cell := Vector2i(-18 + index, 0)
		var old_id: int = world.model.entity_at(cell).id
		var belt_kits: int = world.model.kits.belt
		driver.expect(not world.model.near_entity(world.model.entity_at(cell)), type + " loaded replacement is beyond two-cell interaction reach")
		await native_click(world.hud.buttons[type])
		await driver.motion(driver.cell_screen(cell))
		await driver.settle()
		driver.expect(world.ui.cell == cell and world.ui.dir == 0, type + " mouse preview inherits belt heading")
		driver.expect("替换传送带" in world.hud.placement_reason.text and "物料回收至背包" in world.hud.placement_reason.text and not world.hud.buttons.place.disabled, type + " preview explains loaded belt replacement")
		var before := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)
		var connections: String = world.hud.connection_preview.text
		var bounds: Rect2 = world.hud.world_image.get_global_rect()
		await driver.key(KEY_R)
		driver.expect(world.ui.dir == 1 and world.hud.connection_preview.text != connections, type + " R changes heading and diagnostics")
		await driver.motion(driver.cell_screen(cell))
		driver.expect(world.ui.dir == 1, type + " hover on same belt preserves manual rotation")
		await driver.motion(driver.cell_screen(Vector2i(-20, 2)))
		await driver.settle()
		driver.expect(world.ui.dir == 3, type + " moving to different belt inherits its heading")
		await driver.motion(driver.cell_screen(cell))
		await driver.settle()
		driver.expect(world.ui.dir == 0 and world.hud.connection_preview.text == connections, type + " returning to target resets inheritance consistently")
		driver.expect(Check.equivalent(before, Codec.snapshot(world.model, world.store.world_id, world.store.world_name, before.sequence)), type + " preview and R leave authoritative state untouched")
		driver.expect(world.hud.world_image.get_global_rect() == bounds, type + " replacement feedback preserves screen-to-grid mapping")
		await driver.shot("0%d-%s-preview" % [index + 1, type])
		check_failures()
		if finished: return
		if index == 0:
			await driver.world_click(cell)
		elif index == 1:
			await driver.key(KEY_ENTER)
		else:
			# Precision coordinates use the same target inheritance and submit command.
			world.hud.cell_z.value = 2
			world.hud.cell_x.value = -18
			world.hud.cell_z.value = 0
			world.hud.cell_x.value = -16
			await driver.settle()
			driver.expect(world.ui.dir == 0, "precision coordinates inherit the target belt heading")
			await native_click(world.hud.buttons.place)
		var placed: Dictionary = world.model.entity_at(cell)
		driver.expect(placed.type == type and placed.dir == 0 and world.model.by_id(old_id).is_empty(), type + " routed input replaces exact belt with previewed direction")
		driver.expect(world.model.kits.belt == belt_kits + 1 and world.model.bag.get("crystal", 0) == bag_before + index + 1, type + " returns belt kit and naturally produced cargo")
		driver.expect(world.model.material_balance().held == held and placed.cargo == "", type + " preserves total inventory with empty new slot")
		ids[type] = placed.id
		check_failures()
		if finished: return
	var gate: Dictionary = world.model.by_id(ids.admission_gate)
	driver.expect(gate.filter_item == "" and not gate.accepting, "replaced gate remains unconfigured and closed")
	await driver.shot("04-replaced-line")
	await native_click(world.hud.buttons.save)
	var saved := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)
	driver.expect(Codec.decode(saved, world.store.world_id).ok, "modified natural world strictly validates")
	write_json("expected.json", saved)
	write_json("ids.json", ids)
	stage("replacement-write", "three remote loaded belts replaced by mouse/Enter/button, material conserved and save validated")
	await native_click(world.hud.buttons.return)
	driver.expect(boot.factory_world == null, "replacement world saves and returns")


func _restore() -> void:
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("expected.json")))
	ids = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("ids.json")))
	driver.expect(Check.equivalent(expected, Codec.snapshot(world.model, world.store.world_id, world.store.world_name, expected.sequence)), "independent Boot preserves exact modified world and recovered inventory")
	for type in ["splitter", "merger", "admission_gate"]:
		driver.expect(world.model.by_id(int(ids[type])).get("type", "") == type, "independent Boot restores " + type)
	var gate: Dictionary = world.model.by_id(int(ids.admission_gate))
	driver.expect(gate.filter_item == "" and not gate.accepting and gate.cargo == "", "independent Boot retains unconfigured empty gate")
	world.view.inspection_target = Vector3(-17, 0, 0)
	await driver.shot("05-independent-restore")
	await native_click(world.hud.buttons.splitter)
	await driver.motion(driver.cell_screen(Vector2i(-20, 2)))
	await driver.settle()
	driver.expect(world.ui.dir == 3, "restored side belt supplies north-facing replacement preview")
	var before := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)
	await driver.key(KEY_ESCAPE)
	driver.expect(world.ui.tool.is_empty() and Check.equivalent(before, Codec.snapshot(world.model, world.store.world_id, world.store.world_name, before.sequence)), "cancel replacement leaves original belt and cargo unchanged")
	await native_click(world.hud.buttons.splitter)
	world.hud.cell_x.value = -20
	world.hud.cell_z.value = 2
	await driver.key(KEY_R)
	driver.expect(world.ui.dir == 0, "R overrides restored belt heading before commit")
	root.size = Vector2i(1100, 720)
	await driver.settle(20)
	var label: Label = world.hud.placement_reason
	driver.expect(label.is_visible_in_tree() and label.get_global_rect().end.x <= root.get_visible_rect().size.x, "replacement explanation fits minimum window")
	await driver.shot("06-minimum-rotated-preview")
	await driver.click(world.hud.buttons.place)
	if finished: return
	var replaced: Dictionary = world.model.entity_at(Vector2i(-20, 2))
	driver.expect(replaced.type == "splitter" and replaced.dir == 0, "placement button preserves explicit R override")
	driver.expect(Codec.decode(Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence), world.store.world_id).ok, "rotated replacement retains strict save validity")
	await driver.shot("07-minimum-rotated-result")
	stage("replacement-read", "independent Boot restores three attachments, inventory, configuration and statistics; cancel and rotated commit at minimum window")
	root.size = Vector2i(1440, 900)
	await driver.settle(20)
	await native_click(world.hud.buttons.return)
	driver.expect(boot.factory_world == null, "replacement read returns cleanly")
