extends SceneTree

const SliceWorldScene := preload("res://scenes/slice/SliceWorld.tscn")
const CRAFT_SURFACE_STYLE := preload(
	"res://assets/themes/slice_ui_craft_surface.tres"
)
const CRAFT_SHELL_STYLE_PATH := "res://assets/themes/slice_ui_craft_shell.tres"
const DEVICE_SHELL_STYLE_PATH := (
	"res://assets/themes/slice_ui_device_shell.tres"
)
const CORE_SHELL_STYLE_PATH := "res://assets/themes/slice_ui_core_shell.tres"

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
		reactor.texture_path_for_rotation(1).ends_with("reactor_down.png"),
		true,
		"reactor rotation request keeps the compact three-by-three front"
	)
	_expect_equal(
		conveyor.texture_path_for_rotation(2).ends_with("conveyor_down.png"),
		true,
		"conveyor rotation selects fixed down frame"
	)
	_expect_equal(
		storage.texture_path_for_rotation(3).ends_with("storage.png"),
		true,
		"storage rotation request keeps the locked V1 front"
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
		"pulse_rifle": [
			SliceItemCatalog.PULSE_RIFLE_ID,
			1,
			{SliceItemCatalog.PART_ID: 4, SliceItemCatalog.CATALYST_ID: 1},
		],
		"pulse_cell": [
			SliceItemCatalog.PULSE_CELL_ID,
			8,
			{SliceItemCatalog.PART_ID: 1, SliceItemCatalog.CATALYST_ID: 1},
		],
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
		"背包还需 5 格",
		"recipe blocker uses post-consumption capacity"
	)
	var exact_inventory := Inventory.new(8)
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
		world._craft_panel.visible_recipe_card_count(),
		7,
		"uncharged core keeps equipment and field-supply recipes hidden"
	)
	world._craft_panel.select_recipe("pulse_rifle")
	_expect_equal(
		world._craft_panel.selected_recipe_id(),
		"part",
		"hidden rifle recipe cannot become the selected recipe"
	)
	_expect_equal(
		world._craft_panel.recipe_card_count(),
		SliceRecipes.RECIPES.size(),
		"graphical panel creates one card per authoritative recipe"
	)
	_expect_equal(
		world._craft_panel.inventory_slot_count(),
		9,
		"graphical backpack exposes nine currently unlocked ordinary items"
	)
	_expect_equal(
		world._craft_panel.inventory_group_count(),
		3,
		"graphical backpack groups unlocked items by shared catalog category"
	)
	_expect_equal(
		(
			world._craft_panel.get_node(
				"Root/Window/Margin/Layout/Content/Manufacture/Catalog/Margin/Layout/RecipeScroll/RecipeGrid"
			) as GridContainer
		).columns,
		3,
		"P2-B manufacturing catalog uses the approved compact recipe grid"
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
	_expect_equal(
		world._craft_panel.material_requirement_count(),
		1,
		"selected recipe exposes one authoritative material requirement"
	)
	_expect_equal(
		world._craft_panel.material_requirement_text(SliceWorld.ITEM_CRYSTAL),
		"0 / 3",
		"material validation shows authoritative available and required counts"
	)
	_expect_equal(
		world._craft_panel.manufacture_view_visible()
		and not world._craft_panel.inventory_view_visible(),
		true,
		"manufacturing opens without a permanently adjacent full backpack"
	)
	world._craft_panel.show_inventory()
	_expect_equal(
		world._craft_panel.inventory_view_visible()
		and not world._craft_panel.manufacture_view_visible(),
		true,
		"categorized backpack replaces the manufacturing body when selected"
	)
	world._craft_panel.select_recipe("part")
	for item_id in SliceItemCatalog.visible_ids(false):
		var slot := world._craft_panel.inventory_slot(item_id)
		var slot_icon := slot.find_child("Icon", true, false) as TextureRect
		_expect_equal(
			slot != null and slot_icon != null and slot_icon.texture != null,
			true,
			"%s inventory slot has a graphical identity" % item_id
		)
	_expect_equal(
		world._craft_panel.capacity_text(),
		"不限种类 · 每类 200",
		"graphical backpack shows the per-item pocket rule"
	)
	_expect_equal(
		world._craft_panel.inventory_slot_count_text(SliceWorld.ITEM_CRYSTAL),
		"0 / 200",
		"graphical backpack shows the selected category stack capacity"
	)
	_expect_equal(
		_panel_style_path(
			world._craft_panel.get_node("Root/Window")
		) == CRAFT_SHELL_STYLE_PATH
		and _panel_style_path(
			world._building_action_panel.get_node("Root/Window")
		) == DEVICE_SHELL_STYLE_PATH,
		true,
		"P2-B and P2-C keep separate scoped dark shells"
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
		and first_recipe_style.bg_color == CRAFT_SURFACE_STYLE.bg_color,
		true,
		"recipe cards use the P2-B neutral manufacturing surface"
	)
	_expect_equal(
		first_slot_style != null
		and first_slot_style.bg_color == CRAFT_SURFACE_STYLE.bg_color,
		true,
		"categorized inventory slots reuse the same neutral item surface"
	)

	world.pocket.add(SliceWorld.ITEM_PART, 4)
	world.pocket.add(SliceWorld.ITEM_CATALYST, 1)
	var locked_materials := world.pocket.to_dict()
	_expect_equal(
		world.craft("pulse_rifle"),
		false,
		"authoritative world blocks rifle crafting before first core charge"
	)
	_expect_equal(
		world.pocket.to_dict(),
		locked_materials,
		"locked rifle crafting consumes no materials"
	)
	world.core_energy = SliceWorld.CORE_CHARGE_TARGET
	world.core_charge_changed.emit(world.core_energy)
	world._craft_panel._refresh()
	_expect_equal(
		world._craft_panel.visible_recipe_card_count(),
		9,
		"first core charge reveals recipes eight and nine"
	)
	_expect_equal(
		world._craft_panel.inventory_slot_count(),
		11,
		"charged backpack reveals rifle and pulse-cell property slots"
	)
	_expect_equal(
		world._craft_panel.inventory_group_count(),
		5,
		"charged backpack reveals equipment and field-supply groups"
	)
	_expect_equal(
		world._craft_panel.capacity_text(),
		"常规每类 200 · 步枪 1",
		"charged backpack summary exposes the rifle capacity exception"
	)
	world._craft_panel.select_recipe("pulse_rifle")
	_expect_equal(
		world._craft_panel.selected_recipe_id(),
		"pulse_rifle",
		"charged rifle recipe becomes selectable"
	)
	_expect_equal(world.craft("pulse_rifle"), true, "charged rifle recipe crafts once")
	_expect_equal(
		world.pocket.count(SliceItemCatalog.PULSE_RIFLE_ID),
		1,
		"rifle enters the backpack as ordinary property"
	)
	_expect_equal(
		world.craft("pulse_rifle"),
		false,
		"pocket rifle blocks duplicate manufacturing"
	)
	_expect_equal(
		world.transfer_pocket_to_core(SliceItemCatalog.PULSE_RIFLE_ID),
		1,
		"rifle property transfers into the core warehouse"
	)
	world.pocket.add(SliceWorld.ITEM_PART, 4)
	world.pocket.add(SliceWorld.ITEM_CATALYST, 1)
	_expect_equal(
		world.craft("pulse_rifle"),
		false,
		"core-stored rifle still blocks duplicate manufacturing"
	)
	_expect_equal(
		world.transfer_core_to_pocket(SliceItemCatalog.PULSE_RIFLE_ID),
		1,
		"rifle property transfers back without duplication"
	)
	world.pocket.add(SliceWorld.ITEM_PART, 1)
	world.pocket.add(SliceWorld.ITEM_CATALYST, 1)
	_expect_equal(world.craft("pulse_cell"), true, "charged pulse-cell recipe crafts")
	_expect_equal(
		world.pocket.count(SliceItemCatalog.PULSE_CELL_ID),
		8,
		"pulse-cell recipe outputs one eight-cell batch"
	)
	_expect_equal(
		world.transfer_pocket_to_core(SliceItemCatalog.PULSE_CELL_ID),
		8,
		"pulse cells transfer into the core warehouse"
	)
	_expect_equal(
		world.transfer_core_to_pocket(SliceItemCatalog.PULSE_CELL_ID),
		8,
		"pulse cells transfer back without loss"
	)
	for item_id in [
		SliceItemCatalog.PULSE_RIFLE_ID,
		SliceItemCatalog.PULSE_CELL_ID,
		SliceWorld.ITEM_PART,
		SliceWorld.ITEM_CATALYST,
	]:
		world.pocket.remove(item_id, world.pocket.count(item_id))

	world.pocket.restore_existing("future.item", 3)
	world._craft_panel._refresh()
	_expect_equal(
		world._craft_panel.inventory_slot_count(),
		12,
		"unknown old item creates a visible compatibility slot"
	)
	_expect_equal(
		world._craft_panel.inventory_slot_count_text("future.item"),
		"3 / 200",
		"compatibility slot keeps its authoritative amount and pocket cap"
	)
	world._core_storage_panel.open()
	_expect_equal(
		world._core_storage_panel.item_row_count(),
		12,
		"core warehouse mirrors all known and compatibility items in both columns"
	)
	_expect_equal(
		world._core_storage_panel.pocket_slot("future.item") != null
		and world._core_storage_panel.core_slot("future.item") != null,
		true,
		"compatibility item remains a valid source and drop target"
	)
	var control_press := InputEventMouseButton.new()
	control_press.button_index = MOUSE_BUTTON_RIGHT
	control_press.pressed = true
	control_press.ctrl_pressed = true
	world._core_storage_panel.pocket_slot("future.item")._gui_input(
		control_press
	)
	_expect_equal(
		world._core_storage_panel.drag_is_pending()
		and world._core_storage_panel.drag_selected_amount() == 2,
		true,
		"macOS control-click begins directly with the rounded-up half selected"
	)
	var second_control_press := InputEventKey.new()
	second_control_press.keycode = KEY_CTRL
	second_control_press.pressed = true
	world._core_storage_panel._input(second_control_press)
	_expect_equal(
		world._core_storage_panel.drag_selected_amount(),
		1,
		"each additional control press halves the current drag selection"
	)
	world._core_storage_panel.cancel_drag()
	var plain_press := InputEventMouseButton.new()
	plain_press.button_index = MOUSE_BUTTON_LEFT
	plain_press.pressed = true
	world._core_storage_panel.pocket_slot("future.item")._gui_input(
		plain_press
	)
	_expect_equal(
		world._core_storage_panel.drag_is_pending()
		and world._core_storage_panel.drag_selected_amount() == 3,
		true,
		"plain left press begins a direct whole-stack drag"
	)
	world._core_storage_panel.cancel_drag()
	_expect_equal(
		world._core_storage_panel.transfer_drag("future.item", "pocket", true),
		2,
		"control drag moves the rounded-up half of an odd stack"
	)
	_expect_equal(
		world.pocket.count("future.item"),
		1,
		"half drag leaves the other half in the backpack"
	)
	_expect_equal(
		world._core_storage_panel.transfer_drag("future.item", "pocket", false),
		1,
		"plain drag moves the remaining complete stack"
	)
	world.pocket.add("future.item", 199)
	_expect_equal(
		world._core_storage_panel.transfer_drag("future.item", "core", false),
		1,
		"whole-stack drop transfers only what the destination can accept"
	)
	_expect_equal(
		world._core_storage_panel.result_text().contains("容量受限"),
		true,
		"capacity-limited partial transfer stays explicit"
	)
	_expect_equal(
		world.pocket.count("future.item"),
		200,
		"capacity-limited drop fills but never overflows the target category"
	)
	_expect_equal(
		_panel_style_path(
			world._core_storage_panel.get_node("Root/Window")
		) == CORE_SHELL_STYLE_PATH,
		true,
		"P2-D core warehouse uses its scoped deep-steel shell"
	)
	_expect_equal(
		world.pocket.count("future.item") + world.core_storage.count("future.item"),
		202,
		"compatibility transfer never loses or duplicates property before cleanup"
	)
	world.pocket.remove("future.item", 200)
	world.core_storage.remove("future.item", 2)
	world._core_storage_panel.close()
	world._craft_panel._refresh()

	world.pocket.add(SliceWorld.ITEM_CRYSTAL, 2)
	world.pocket.add(SliceWorld.ITEM_FLOOR_KIT, 1)
	world.begin_building_placement(SliceBuildingCatalog.FLOOR_ID)
	world._craft_panel._activate_recipe(SliceRecipes.find("floor"))
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		9,
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
		floor_select.text.contains("选中已有 ×9"),
		true,
		"floor card exposes explicit existing-kit mouse selection"
	)
	world._craft_panel._activate_recipe(SliceRecipes.find("floor"))
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_FLOOR_KIT),
		17,
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
		17,
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
	) as SliceConveyor
	var storage := _place_device(
		world, SliceBuildingCatalog.STORAGE_ID, Vector2i(33, 3), 3
	) as SliceStorage
	await physics_frame

	_expect_equal(
		(reactor.get_node("Sprite") as Sprite2D).texture.resource_path.ends_with(
			"reactor_down.png"
		),
		true,
		"placed reactor uses the compact three-by-three front"
	)
	_expect_equal(
		(conveyor.get_node("Sprite") as Sprite2D).texture.resource_path.ends_with(
			"conveyor_right.png"
		),
		true,
		"placed conveyor uses approved right frame"
	)
	_expect_equal(
		(storage.get_node("Sprite") as Sprite2D).texture.resource_path.ends_with(
			"storage.png"
		),
		true,
		"placed storage uses the locked V1 front"
	)
	_expect_equal(
		(relay.get_node("Sprite") as Sprite2D).texture.resource_path.ends_with(
			"power_relay.png"
		),
		true,
		"placed relay uses one locked V2 body"
	)
	_expect_equal(
		storage.get_node_or_null("InteractionSite") != null,
		true,
		"generic storage receives shared interaction area"
	)

	world.pocket.add(SliceWorld.ITEM_CRYSTAL, 2)
	# P2-C's disconnected representative keeps power available so the local
	# OUT fault, rather than the higher-priority power fault, is the focus.
	storage.powered = true
	storage.inventory.add(SliceWorld.ITEM_CRYSTAL, 1)
	storage.output_item_id = SliceWorld.ITEM_CRYSTAL
	world.open_building_actions(storage)
	_expect_equal(
		world._building_action_panel.primary_status_text(),
		"OUT 未连接",
		"storage promotes only its authoritative disconnected output"
	)
	_expect_equal(
		world._building_action_panel.result_visible(),
		false,
		"device feedback stays quiet until an operation produces a result"
	)
	_expect_equal(
		String(
			world._building_action_panel.current_snapshot()["details"]
		).contains("手动存取仍可用"),
		true,
		"disconnected storage keeps manual transfer visibly available"
	)
	var storage_snapshot := world._building_action_panel.current_snapshot()
	_expect_equal(
		not (storage_snapshot["inventory_items"] as Array).is_empty()
		and (storage_snapshot["slot_1"] as Dictionary).is_empty()
		and (storage_snapshot["process"] as Dictionary).is_empty(),
		true,
		"storage uses its inventory selector without fake production slots"
	)
	storage.inventory.remove(SliceWorld.ITEM_CRYSTAL, 1)
	storage.output_item_id = ""
	world._building_action_panel._refresh()
	_expect_equal(
		world._building_action_panel.port_state(0),
		"unconnected",
		"storage panel exposes structured IO connection state"
	)
	var deposit_crystal := world._building_action_panel.action_button(
		"storage_deposit"
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
		"storage_withdraw"
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
	var toggle_storage := world._building_action_panel.action_button(
		"storage_toggle_mode"
	)
	_expect_equal(
		toggle_storage != null and not toggle_storage.disabled,
		true,
		"storage panel exposes its mode switch"
	)
	toggle_storage.pressed.emit()
	_expect_equal(
		storage.mode,
		SliceStorage.MODE_TRANSFER,
		"storage panel switches to transfer mode"
	)
	_expect_equal(
		String(
			world.building_logistics_status_snapshot(storage)[0]["label"]
		),
		"IN",
		"mode switch rebuilds the transfer input in the same frame"
	)
	world._building_action_panel.action_button(
		"storage_toggle_mode"
	).pressed.emit()
	_expect_equal(
		storage.mode,
		SliceStorage.MODE_SUPPLY,
		"second panel switch restores supply mode"
	)
	_expect_equal(
		String(
			world.building_logistics_status_snapshot(storage)[0]["label"]
		),
		"OUT",
		"supply output is restored in the same frame"
	)
	world._building_action_panel.close()
	world.pocket.remove(SliceWorld.ITEM_CRYSTAL, 2)

	var placed_reactor := reactor as SliceReactor
	placed_reactor.input_inventory.add(SliceWorld.ITEM_CRYSTAL, 2)
	world.open_building_actions(placed_reactor)
	var reactor_snapshot := world._building_action_panel.current_snapshot()
	_expect_equal(
		world._building_action_panel.content_title_text(),
		"反应流程",
		"reactor promotes its material flow instead of a generic device form"
	)
	_expect_equal(
		(reactor_snapshot["ports"] as Array).size(),
		2,
		"reactor panel exposes separate IN and OUT state cards"
	)
	_expect_equal(
		String((reactor_snapshot["process"] as Dictionary)["title"]),
		"加工 · 10 秒",
		"reactor panel keeps material amounts and duration on one flow axis"
	)
	_expect_equal(
		world._building_action_panel.process_axis_text(),
		"IN · 2 晶体 → 加工 · 10 秒 → OUT · 1 催化剂",
		"reactor visually orders IN, process and OUT without a duplicate list"
	)
	_expect_equal(
		(
			world._building_action_panel.get_node(
				"Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/FlowRow/FlowArrowIn"
			) as Label
		).visible
		and (
			world._building_action_panel.get_node(
				"Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/FlowRow/FlowArrowOut"
			) as Label
		).visible,
		true,
		"reactor shows both directional links on the single process axis"
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

	var conveyor_snapshot := SliceBuildingPanelSnapshot.build(
		world, conveyor
	)
	_expect_equal(
		String(conveyor_snapshot["content_title"]),
		"输送状态",
		"conveyor keeps its transport-specific surface"
	)
	_expect_equal(
		not (conveyor_snapshot["slot_1"] as Dictionary).is_empty()
		and not (conveyor_snapshot["process"] as Dictionary).is_empty()
		and (conveyor_snapshot["slot_2"] as Dictionary).is_empty(),
		true,
		"conveyor does not inherit a fake second production slot"
	)
	var relay_snapshot := SliceBuildingPanelSnapshot.build(world, relay)
	_expect_equal(
		String(relay_snapshot["content_title"]),
		"供电影响",
		"relay keeps its power-impact surface"
	)
	_expect_equal(
		(relay_snapshot["slot_1"] as Dictionary).is_empty()
		and (relay_snapshot["process"] as Dictionary).is_empty(),
		true,
		"relay does not display invented load or production values"
	)
	var floor_snapshot := SliceBuildingPanelSnapshot.build(
		world, standalone_floor
	)
	_expect_equal(
		String(floor_snapshot["content_title"]),
		"地面支撑",
		"floor keeps its passive structural surface"
	)
	_expect_equal(
		(floor_snapshot["power"] as Dictionary).is_empty()
		and (floor_snapshot["ports"] as Array).is_empty()
		and (floor_snapshot["process"] as Dictionary).is_empty(),
		true,
		"floor does not masquerade as a powered processing device"
	)

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
	_expect_equal(
		reactor.building_rotation,
		0,
		"fixed reactor adjustment preserves canonical rotation"
	)
	_expect_equal(reactor.instance_id, reactor_id, "adjustment preserves stable id")
	_expect_equal(
		(reactor.get_node("Sprite") as Sprite2D).texture.resource_path.ends_with(
			"reactor_down.png"
		),
		true,
		"reactor adjustment keeps the compact three-by-three front"
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

	world.pocket.add(
		SliceWorld.ITEM_POWER_RELAY_KIT,
		world.pocket.free_space_for(SliceWorld.ITEM_POWER_RELAY_KIT)
	)
	_expect_equal(
		world.demolition_block_reason(relay),
		"背包空间不足",
		"full returned-kit category blocks demolition"
	)
	world.pocket.remove(
		SliceWorld.ITEM_POWER_RELAY_KIT,
		world.pocket.count(SliceWorld.ITEM_POWER_RELAY_KIT)
	)
	_expect_equal(world.demolish_building(relay), true, "relay demolishes with space")
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_POWER_RELAY_KIT),
		1,
		"relay demolition returns one kit"
	)

	var conveyor_rotation := conveyor.building_rotation
	var transportable_items := [
		SliceWorld.ITEM_CRYSTAL,
		SliceWorld.ITEM_CATALYST,
	]
	for index in range(transportable_items.size()):
		var item_id: String = transportable_items[index]
		var progress := 0.25 + float(index) * 0.5
		var merge_cursor := index + 3
		var item_count_before := world.pocket.count(item_id)
		conveyor.merge_cursor = merge_cursor
		conveyor.set_cargo(item_id, progress)
		_expect_equal(
			world.adjustment_block_reason(conveyor),
			"先清空传送带",
			"loaded %s conveyor blocks adjustment" % item_id
		)
		_expect_equal(
			world.demolition_block_reason(conveyor),
			"先清空传送带",
			"loaded %s conveyor blocks demolition" % item_id
		)
		var recovery := world.recover_conveyor_cargo(conveyor)
		_expect_equal(
			bool(recovery.get("success", false)),
			true,
			"%s conveyor cargo recovers" % item_id
		)
		_expect_equal(
			world.pocket.count(item_id),
			item_count_before + 1,
			"%s recovery returns exactly one item" % item_id
		)
		_expect_equal(
			conveyor.has_cargo(),
			false,
			"%s recovery clears conveyor cargo" % item_id
		)
		_expect_equal(
			conveyor.cargo_progress,
			0.0,
			"%s recovery clears cargo progress" % item_id
		)
		_expect_equal(
			conveyor.building_rotation,
			conveyor_rotation,
			"%s recovery preserves conveyor rotation" % item_id
		)
		_expect_equal(
			conveyor.merge_cursor,
			merge_cursor,
			"%s recovery preserves merge cursor" % item_id
		)
		_expect_equal(
			world.adjustment_block_reason(conveyor),
			"",
			"recovered %s conveyor allows adjustment" % item_id
		)
		_expect_equal(
			world.demolition_block_reason(conveyor),
			"",
			"recovered %s conveyor allows demolition" % item_id
		)
		world.pocket.remove(item_id, 1)

	world.pocket.add(
		SliceWorld.ITEM_CRYSTAL,
		world.pocket.free_space_for(SliceWorld.ITEM_CRYSTAL)
	)
	conveyor.merge_cursor = 9
	conveyor.set_cargo(SliceWorld.ITEM_CRYSTAL, 0.625)
	var full_pocket_before := world.pocket.contents_view()
	var failed_cargo_before: String = conveyor.cargo_item_id
	var failed_progress_before: float = conveyor.cargo_progress
	var failed_rotation_before: int = conveyor.building_rotation
	var failed_cursor_before: int = conveyor.merge_cursor
	var failed_recovery := world.recover_conveyor_cargo(conveyor)
	_expect_equal(
		bool(failed_recovery.get("success", true)),
		false,
		"full target category rejects conveyor cargo recovery"
	)
	_expect_equal(
		String(failed_recovery.get("message", "")),
		"背包中该物品已达上限",
		"full target category reports the authoritative blocker"
	)
	_expect_equal(
		world.pocket.contents_view(),
		full_pocket_before,
		"failed conveyor recovery leaves the full backpack unchanged"
	)
	_expect_equal(
		conveyor.cargo_item_id,
		failed_cargo_before,
		"failed conveyor recovery preserves cargo"
	)
	_expect_equal(
		conveyor.cargo_progress,
		failed_progress_before,
		"failed conveyor recovery preserves cargo progress"
	)
	_expect_equal(
		conveyor.building_rotation,
		failed_rotation_before,
		"failed conveyor recovery preserves rotation"
	)
	_expect_equal(
		conveyor.merge_cursor,
		failed_cursor_before,
		"failed conveyor recovery preserves merge cursor"
	)
	_expect_equal(
		world.adjustment_block_reason(conveyor),
		"先清空传送带",
		"failed conveyor recovery keeps adjustment blocked"
	)
	_expect_equal(
		world.demolition_block_reason(conveyor),
		"先清空传送带",
		"failed conveyor recovery keeps demolition blocked"
	)
	world.pocket.remove(
		SliceWorld.ITEM_CRYSTAL,
		world.pocket.count(SliceWorld.ITEM_CRYSTAL)
	)
	conveyor.clear_cargo()

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
	var collector_snapshot := SliceBuildingPanelSnapshot.build(
		world, collector
	)
	_expect_equal(
		String(collector_snapshot["content_title"]),
		"产出缓冲",
		"collector keeps its output-buffer surface"
	)
	_expect_equal(
		not (collector_snapshot["slot_1"] as Dictionary).is_empty()
		and not (collector_snapshot["process"] as Dictionary).is_empty()
		and (collector_snapshot["slot_2"] as Dictionary).is_empty(),
		true,
		"collector does not inherit the reactor output slot"
	)
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
	var selected_rotation := world.selected_building_rotation()
	var validation := world._validate_placement(
		definition, origin, selected_rotation
	)
	world._placement.update_target(
		origin,
		definition.block_center(
			origin, SliceWorld.TILE_SIZE, selected_rotation
		),
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
