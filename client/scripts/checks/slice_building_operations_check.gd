extends SceneTree

const SliceWorldScene := preload("res://scenes/slice/SliceWorld.tscn")
const UI_CARD_STYLE := preload("res://assets/themes/slice_ui_card.tres")
const UI_SURFACE_STYLE := preload("res://assets/themes/slice_ui_surface.tres")
const UI_SHELL_STYLE_PATH := "res://assets/themes/slice_ui_shell.tres"

var failures: Array[String] = []
var _save_dir := ""
var _assertion_count := 0
var _reached_end := false


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	await _run_checks()
	if not _reached_end:
		failures.append("building operations check did not reach its final assertion")
	if failures.is_empty():
		print(
			"Slice building operations checks passed (%d assertions)."
			% _assertion_count
		)
		_cleanup_save_dir()
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_cleanup_save_dir()
	quit(1)


func _run_checks() -> void:
	_check_catalog_and_recipes()
	await _check_world_operations()


func _check_catalog_and_recipes() -> void:
	var expected := {
		SliceBuildingCatalog.FLOOR_ID: Vector2i.ONE,
		SliceBuildingCatalog.COLLECTOR_ID: Vector2i(2, 2),
		SliceBuildingCatalog.REACTOR_ID: Vector2i(3, 3),
		SliceBuildingCatalog.POWER_RELAY_ID: Vector2i.ONE,
		SliceBuildingCatalog.CONVEYOR_ID: Vector2i.ONE,
		SliceBuildingCatalog.STORAGE_ID: Vector2i(2, 2),
	}
	_expect_equal(SliceBuildingCatalog.all().size(), 6, "six definitions registered")
	for building_id in expected:
		var definition := SliceBuildingCatalog.find(String(building_id))
		_expect_equal(definition != null, true, "%s definition exists" % building_id)
		_expect_equal(
			definition.footprint,
			expected[building_id],
			"%s footprint" % building_id
		)

	var reactor := SliceBuildingCatalog.find(SliceBuildingCatalog.REACTOR_ID)
	var conveyor := SliceBuildingCatalog.find(SliceBuildingCatalog.CONVEYOR_ID)
	var storage := SliceBuildingCatalog.find(SliceBuildingCatalog.STORAGE_ID)
	_expect_equal(
		reactor.texture_path_for_rotation(1).ends_with("reactor_right.png"),
		true,
		"reactor rotation selects fixed right frame"
	)
	_expect_equal(
		conveyor.texture_path_for_rotation(2).ends_with("conveyor_down.png"),
		true,
		"conveyor rotation selects fixed down frame"
	)
	_expect_equal(
		storage.texture_path_for_rotation(3).ends_with("storage_left.png"),
		true,
		"storage rotation selects fixed left frame"
	)

	var recipe_expectations := {
		"reactor": [SliceBuildingCatalog.REACTOR_ID, 1, {"part": 4}],
		"power_relay": [SliceBuildingCatalog.POWER_RELAY_ID, 1, {"part": 1}],
		"conveyor": [
			SliceBuildingCatalog.CONVEYOR_ID,
			4,
			{"crystal": 1, "part": 1},
		],
		"storage": [SliceBuildingCatalog.STORAGE_ID, 1, {"part": 2}],
	}
	for recipe_id in recipe_expectations:
		var recipe := SliceRecipes.find(String(recipe_id))
		var expectation: Array = recipe_expectations[recipe_id]
		_expect_equal(recipe["output"], expectation[0], "%s output id" % recipe_id)
		_expect_equal(
			int(recipe["output_count"]), expectation[1], "%s output count" % recipe_id
		)
		_expect_equal(recipe["cost"], expectation[2], "%s cost" % recipe_id)

	var missing_inventory := Inventory.new(30)
	_expect_equal(
		SliceRecipes.craft_block_reason(
			SliceRecipes.find("reactor"),
			missing_inventory
		),
		"缺少 机械零件 ×4",
		"recipe blocker names the missing material and amount"
	)
	var full_inventory := Inventory.new(3)
	full_inventory.add(SliceWorld.ITEM_CRYSTAL, 1)
	_expect_equal(
		SliceRecipes.craft_block_reason(
			SliceRecipes.find("floor"),
			full_inventory
		),
		"背包还需 1 格",
		"recipe blocker uses post-consumption capacity"
	)
	var exact_inventory := Inventory.new(4)
	exact_inventory.add(SliceWorld.ITEM_CRYSTAL, 1)
	_expect_equal(
		SliceRecipes.craft_block_reason(
			SliceRecipes.find("floor"),
			exact_inventory
		),
		"",
		"recipe blocker accepts an exact post-consumption fit"
	)


func _check_world_operations() -> void:
	var repo_root := (
		ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	)
	_save_dir = repo_root.path_join(
		"tools/runtime-intake/2026-07-29-building-operations-%d"
		% Time.get_ticks_usec()
	)
	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = SliceSaveService.new(_save_dir)
	root.add_child(world)
	await process_frame
	await physics_frame
	world.core_repaired = true
	world._rebuild_power_grid()
	world._craft_panel._refresh()
	_expect_equal(
		world._craft_panel.recipe_card_count(),
		SliceRecipes.RECIPES.size(),
		"graphical panel creates one card per authoritative recipe"
	)
	_expect_equal(
		world._craft_panel.inventory_slot_count(),
		9,
		"graphical backpack exposes the stable nine-item slice inventory"
	)
	for recipe in SliceRecipes.RECIPES:
		var recipe_id := String(recipe["id"])
		var card := world._craft_panel.recipe_card(recipe_id)
		var icon := card.find_child("Icon", true, false) as TextureRect
		var select_button := card.find_child(
			"SelectRecipe", true, false
		) as Button
		_expect_equal(
			card != null and icon != null and icon.texture != null,
			true,
			"%s recipe navigation row has a graphical identity" % recipe_id
		)
		_expect_equal(
			select_button != null,
			true,
			"%s recipe navigation row exposes mouse selection" % recipe_id
		)
	world._craft_panel.select_recipe("part")
	_expect_equal(
		world._craft_panel.detail_craft_button() != null,
		true,
		"selected recipe exposes the shared mouse craft action"
	)
	for item_id in SliceCraftPanel.INVENTORY_ITEMS:
		var slot := world._craft_panel.inventory_slot(item_id)
		var slot_icon := slot.find_child("Icon", true, false) as TextureRect
		_expect_equal(
			slot != null and slot_icon != null and slot_icon.texture != null,
			true,
			"%s inventory slot has a graphical identity" % item_id
		)
	_expect_equal(
		world._craft_panel.capacity_text(),
		"0 / 30",
		"graphical backpack shows authoritative total capacity"
	)
	_expect_equal(
		_panel_style_path(
			world._craft_panel.get_node("Root/Window")
		) == UI_SHELL_STYLE_PATH
		and _panel_style_path(
			world._building_action_panel.get_node("Root/Window")
		) == UI_SHELL_STYLE_PATH,
		true,
		"crafting and device panels share the foreground shell role"
	)
	var first_recipe_style := (
		world._craft_panel.recipe_card("part").get_theme_stylebox(
			"panel"
		) as StyleBoxFlat
	)
	var first_slot_style := (
		world._craft_panel.inventory_slot(
			SliceWorld.ITEM_CRYSTAL
		).get_theme_stylebox("panel") as StyleBoxFlat
	)
	_expect_equal(
		first_recipe_style != null
		and first_recipe_style.bg_color == UI_CARD_STYLE.bg_color,
		true,
		"recipe cards inherit the shared raised card material"
	)
	_expect_equal(
		first_slot_style != null
		and first_slot_style.bg_color == UI_SURFACE_STYLE.bg_color,
		true,
		"inventory slots inherit the shared recessed surface material"
	)

	world.pocket.add(SliceWorld.ITEM_CRYSTAL, 2)
	world.pocket.add(SliceWorld.ITEM_FLOOR_KIT, 1)
	world.begin_building_placement(SliceBuildingCatalog.FLOOR_ID)
	world._craft_panel._activate_recipe(SliceRecipes.find("floor"))
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		5,
		"selected floor recipe key appends another complete batch"
	)
	_expect_equal(
		world.selected_building_id(),
		SliceBuildingCatalog.FLOOR_ID,
		"appended floor batch keeps its placement active"
	)
	world.pocket.add(SliceWorld.ITEM_REACTOR_KIT, 1)
	world.select_building_kit(SliceBuildingCatalog.REACTOR_ID)
	world._craft_panel._refresh()
	world._craft_panel.select_recipe("floor")
	var floor_select := world._craft_panel.detail_select_button()
	_expect_equal(
		floor_select.text.contains("选中已有 ×5"),
		true,
		"floor card exposes explicit existing-kit mouse selection"
	)
	world._craft_panel._activate_recipe(SliceRecipes.find("floor"))
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		9,
		"reactor placement can craft the second floor batch"
	)
	_expect_equal(
		world.selected_building_id(),
		SliceBuildingCatalog.REACTOR_ID,
		"support-floor crafting restores the reactor preview"
	)
	world._craft_panel._activate_recipe(SliceRecipes.find("floor"), true)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		9,
		"Shift-selecting existing floors consumes no resources"
	)
	_expect_equal(
		world.selected_building_id(),
		SliceBuildingCatalog.FLOOR_ID,
		"Shift-number explicitly selects existing floor kits"
	)
	world._craft_panel._activate_recipe(SliceRecipes.find("reactor"))
	_expect_equal(
		world.selected_building_id(),
		SliceBuildingCatalog.FLOOR_ID,
		"plain recipe activation never falls back to selecting an existing kit"
	)
	world.cancel_building_placement()
	world.pocket.remove(
		SliceWorld.ITEM_FLOOR_KIT,
		world.pocket.count(SliceWorld.ITEM_FLOOR_KIT)
	)
	world.pocket.remove(
		SliceWorld.ITEM_CRYSTAL,
		world.pocket.count(SliceWorld.ITEM_CRYSTAL)
	)
	world.pocket.remove(
		SliceWorld.ITEM_REACTOR_KIT,
		world.pocket.count(SliceWorld.ITEM_REACTOR_KIT)
	)

	var floor_definition := SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID)
	_spawn_floor_rect(world, Vector2i(25, 3), Vector2i(3, 3))
	_spawn_floor_rect(world, Vector2i(25, 7), Vector2i(3, 3))
	_spawn_floor_rect(world, Vector2i(22, 7), Vector2i.ONE)
	_spawn_floor_rect(world, Vector2i(31, 3), Vector2i.ONE)
	_spawn_floor_rect(world, Vector2i(33, 3), Vector2i(2, 2))
	var standalone_floor := world._spawn_building(
		floor_definition, "", Vector2i(36, 3), 0, {}
	)

	var missing_floor := world._validate_placement(
		SliceBuildingCatalog.find(SliceBuildingCatalog.REACTOR_ID),
		Vector2i(38, 3),
		0
	)
	_expect_equal(
		String(missing_floor.get("reason", "")),
		"此处无法自动铺设工业地板",
		"device without complete floor support reports short reason"
	)

	var reactor := _place_device(
		world, SliceBuildingCatalog.REACTOR_ID, Vector2i(25, 3), 1
	)
	var relay := _place_device(
		world, SliceBuildingCatalog.POWER_RELAY_ID, Vector2i(22, 7), 3
	)
	var conveyor := _place_device(
		world, SliceBuildingCatalog.CONVEYOR_ID, Vector2i(31, 3), 1
	)
	var storage := _place_device(
		world, SliceBuildingCatalog.STORAGE_ID, Vector2i(33, 3), 3
	) as SliceStorage
	await physics_frame

	_expect_equal(
		(reactor.get_node("Sprite") as Sprite2D).texture.resource_path.ends_with(
			"reactor_right.png"
		),
		true,
		"placed reactor uses approved right frame"
	)
	_expect_equal(
		(conveyor.get_node("Sprite") as Sprite2D).texture.resource_path.ends_with(
			"conveyor_right.png"
		),
		true,
		"placed conveyor uses approved right frame"
	)
	_expect_equal(
		storage.get_node_or_null("InteractionSite") != null,
		true,
		"generic storage receives shared interaction area"
	)

	world.pocket.add(SliceWorld.ITEM_CRYSTAL, 2)
	world.open_building_actions(storage)
	_expect_equal(
		world._building_action_panel.port_state(0),
		"unconnected",
		"storage panel exposes structured IO connection state"
	)
	var deposit_crystal := world._building_action_panel.action_button(
		"deposit_crystal"
	)
	_expect_equal(
		deposit_crystal != null and not deposit_crystal.disabled,
		true,
		"storage panel exposes an enabled mouse deposit action"
	)
	deposit_crystal.pressed.emit()
	_expect_equal(
		storage.inventory.count(SliceWorld.ITEM_CRYSTAL),
		2,
		"storage mouse deposit routes through the authoritative transfer API"
	)
	var withdraw_crystal := world._building_action_panel.action_button(
		"withdraw_crystal"
	)
	_expect_equal(
		withdraw_crystal != null and not withdraw_crystal.disabled,
		true,
		"storage panel refreshes its mouse withdraw action"
	)
	withdraw_crystal.pressed.emit()
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_CRYSTAL),
		2,
		"storage mouse withdraw returns material to the backpack"
	)
	world._building_action_panel.close()
	world.pocket.remove(SliceWorld.ITEM_CRYSTAL, 2)

	var placed_reactor := reactor as SliceReactor
	placed_reactor.input_inventory.add(SliceWorld.ITEM_CRYSTAL, 2)
	world.open_building_actions(placed_reactor)
	var reactor_snapshot := world._building_action_panel.current_snapshot()
	_expect_equal(
		(reactor_snapshot["ports"] as Array).size(),
		2,
		"reactor panel exposes separate IN and OUT state cards"
	)
	_expect_equal(
		String((reactor_snapshot["process"] as Dictionary)["title"]),
		"2 晶体  →  1 催化剂",
		"reactor panel presents the fixed recipe as a flow"
	)
	var recover_reactor := world._building_action_panel.action_button(
		"recover_reactor"
	)
	_expect_equal(
		recover_reactor != null and not recover_reactor.disabled,
		true,
		"reactor panel exposes an enabled mouse recovery action"
	)
	recover_reactor.pressed.emit()
	_expect_equal(
		placed_reactor.input_inventory.is_empty()
		and world.pocket.count(SliceWorld.ITEM_CRYSTAL) == 2,
		true,
		"reactor mouse recovery remains atomic"
	)
	world._building_action_panel.close()
	world.pocket.remove(SliceWorld.ITEM_CRYSTAL, 2)

	var reactor_id := reactor.instance_id
	_expect_equal(
		world.begin_building_adjustment(reactor),
		true,
		"reactor enters adjustment"
	)
	_expect_equal(reactor.visible, false, "adjustment temporarily hides original")
	world.cancel_building_placement()
	await process_frame
	_expect_equal(reactor.visible, true, "Esc restores adjusted building")
	_expect_equal(reactor.origin_cell, Vector2i(25, 3), "cancel restores origin")
	_expect_equal(reactor.instance_id, reactor_id, "cancel preserves stable id")

	_expect_equal(
		world.begin_building_adjustment(reactor),
		true,
		"reactor re-enters adjustment"
	)
	world.rotate_building_placement()
	await process_frame
	await physics_frame
	var moved_validation := world._validate_placement(
		reactor.definition, Vector2i(25, 7), world.selected_building_rotation()
	)
	world._placement.update_target(
		Vector2i(25, 7),
		reactor.definition.block_center(
			Vector2i(25, 7),
			SliceWorld.TILE_SIZE,
			world.selected_building_rotation()
		),
		moved_validation
	)
	_expect_equal(
		bool(moved_validation.get("valid", false)),
		true,
		"adjusted reactor validates on complete floor support"
	)
	_expect_equal(world.try_place_building(), true, "adjustment commits")
	_expect_equal(reactor.origin_cell, Vector2i(25, 7), "adjustment moves origin")
	_expect_equal(reactor.building_rotation, 2, "adjustment commits rotation")
	_expect_equal(reactor.instance_id, reactor_id, "adjustment preserves stable id")
	_expect_equal(
		(reactor.get_node("Sprite") as Sprite2D).texture.resource_path.ends_with(
			"reactor_down.png"
		),
		true,
		"adjustment switches to approved down frame"
	)

	var supporting_floor := _find_building(
		world, SliceBuildingCatalog.FLOOR_ID, Vector2i(25, 7)
	)
	_expect_equal(
		world.adjustment_block_reason(supporting_floor),
		"地板上有设施",
		"supporting floor cannot move"
	)
	_expect_equal(
		world.demolition_block_reason(supporting_floor),
		"地板上有设施",
		"supporting floor cannot be demolished"
	)

	_expect_equal(
		world.begin_building_adjustment(standalone_floor),
		true,
		"unused floor enters adjustment"
	)
	await process_frame
	var floor_move := world._validate_placement(
		floor_definition, Vector2i(37, 3), 0
	)
	world._placement.update_target(
		Vector2i(37, 3),
		floor_definition.block_center(Vector2i(37, 3), SliceWorld.TILE_SIZE, 0),
		floor_move
	)
	_expect_equal(world.try_place_building(), true, "unused floor adjustment commits")
	_expect_equal(
		world._industrial_floor.get_cell_source_id(Vector2i(36, 3)),
		-1,
		"floor adjustment clears old tile"
	)
	_expect_equal(
		world._industrial_floor.get_cell_source_id(Vector2i(37, 3)),
		0,
		"floor adjustment writes new tile"
	)

	storage.inventory.add(SliceWorld.ITEM_CRYSTAL, 1)
	_expect_equal(
		world.demolition_block_reason(storage),
		"先清空储物箱",
		"non-empty storage is demolition-gated"
	)
	storage.inventory.remove(SliceWorld.ITEM_CRYSTAL, 1)
	var storage_kits_before := world.pocket.count(SliceWorld.ITEM_STORAGE_KIT)
	_expect_equal(world.demolish_building(storage), true, "empty storage demolishes")
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_STORAGE_KIT),
		storage_kits_before + 1,
		"storage demolition returns one kit"
	)

	world.pocket.add(SliceWorld.ITEM_CRYSTAL, world.pocket.free_space())
	_expect_equal(
		world.demolition_block_reason(relay),
		"背包空间不足",
		"full backpack blocks demolition"
	)
	world.pocket.remove(SliceWorld.ITEM_CRYSTAL, world.pocket.count(SliceWorld.ITEM_CRYSTAL))
	_expect_equal(world.demolish_building(relay), true, "relay demolishes with space")
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_POWER_RELAY_KIT),
		1,
		"relay demolition returns one kit"
	)

	world.open_building_actions(conveyor)
	_expect_equal(world.is_building_actions_open(), true, "E target opens action panel")
	_send_panel_key(world._building_action_panel, KEY_2)
	_expect_equal(
		world._building_instances.has(conveyor),
		true,
		"first demolition press only asks for confirmation"
	)
	_send_panel_key(world._building_action_panel, KEY_2)
	_expect_equal(
		world._building_instances.has(conveyor),
		false,
		"second demolition press removes building"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_CONVEYOR_KIT),
		1,
		"confirmed demolition returns one conveyor kit"
	)

	var collector := world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.COLLECTOR_ID),
		"",
		Vector2i(45, 10),
		0,
		{"buffer": 1}
	) as SliceCollector
	_expect_equal(
		world.demolition_block_reason(collector),
		"先取空采集器",
		"non-empty collector is demolition-gated"
	)

	world.core_repaired = true
	for definition in SliceBuildingCatalog.all():
		if world.pocket.count(definition.kit_item_id) <= 0:
			world.pocket.add(definition.kit_item_id, 1)
	var moved_to_core := world.transfer_all_building_kits_to_core()
	_expect_equal(moved_to_core >= 6, true, "central storage accepts all kit types")
	for definition in SliceBuildingCatalog.all():
		_expect_equal(
			world.core_storage.count(definition.kit_item_id) > 0,
			true,
			"core stores %s" % definition.kit_item_id
		)
	var moved_to_pocket := world.transfer_all_building_kits_to_pocket()
	_expect_equal(
		moved_to_pocket, moved_to_core, "central storage returns all kit types"
	)
	_reached_end = true
	world.free()


func _spawn_floor_rect(
	world: SliceWorld,
	origin: Vector2i,
	size: Vector2i
) -> void:
	var definition := SliceBuildingCatalog.find(SliceBuildingCatalog.FLOOR_ID)
	for y in range(size.y):
		for x in range(size.x):
			world._spawn_building(
				definition, "", origin + Vector2i(x, y), 0, {}
			)


func _place_device(
	world: SliceWorld,
	building_id: String,
	origin: Vector2i,
	rotation: int
) -> SliceBuildingInstance:
	var definition := SliceBuildingCatalog.find(building_id)
	world.pocket.add(definition.kit_item_id, 1)
	_expect_equal(world.begin_building_placement(building_id), true, "%s selected" % building_id)
	for _step in range(rotation):
		world.rotate_building_placement()
	var validation := world._validate_placement(definition, origin, rotation)
	world._placement.update_target(
		origin,
		definition.block_center(origin, SliceWorld.TILE_SIZE, rotation),
		validation
	)
	_expect_equal(
		bool(validation.get("valid", false)),
		true,
		"%s validates" % building_id
	)
	var index := world._building_instances.size()
	_expect_equal(world.try_place_building(), true, "%s places" % building_id)
	return world._building_instances[index]


func _find_building(
	world: SliceWorld,
	building_id: String,
	origin: Vector2i
) -> SliceBuildingInstance:
	for instance in world._building_instances:
		if instance.building_id == building_id and instance.origin_cell == origin:
			return instance
	return null


func _send_panel_key(panel: SliceBuildingActionPanel, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	panel._unhandled_input(event)


func _panel_style_path(node: Node) -> String:
	var control := node as Control
	if control == null:
		return ""
	var style := control.get_theme_stylebox("panel")
	return "" if style == null else style.resource_path


func _expect_equal(actual, expected, context: String) -> void:
	_assertion_count += 1
	if actual == expected:
		return
	failures.append(
		"%s: expected %s, got %s" % [context, str(expected), str(actual)]
	)


func _cleanup_save_dir() -> void:
	if _save_dir.is_empty():
		return
	for filename in [
		"slice_world.json",
		"slice_world.bak.json",
		"slice_world.tmp.json",
	]:
		var path := _save_dir.path_join(filename)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(_save_dir):
		DirAccess.remove_absolute(_save_dir)
