class_name SliceCraftPanel
extends CanvasLayer

## P2-B graphical manufacturing and categorized backpack surface.
## docs/features/slice-game-ui-visual-finalization-v1.md

const SURFACE_STYLE := preload("res://assets/themes/slice_ui_craft_surface.tres")

const VIEW_MANUFACTURE := "manufacture"
const VIEW_INVENTORY := "inventory"

const COLOR_TEXT := Color(0.91, 0.929, 0.922)
const COLOR_MUTED := Color(0.659, 0.698, 0.706)
const COLOR_DIM := Color(0.537, 0.576, 0.588)
const COLOR_A1 := Color(0.498, 0.573, 0.722)
const COLOR_WARNING := Color(0.804, 0.647, 0.408)

signal terminal_opened
signal recipe_inspected(recipe_id: String)

var _world: Node
var _open := false
var _recipe_cards: Dictionary = {}
var _inventory_slots: Dictionary = {}
var _inventory_groups: Dictionary = {}
var _material_rows: Dictionary = {}
var _selected_recipe_id := ""
var _last_result := ""
var _active_view := VIEW_MANUFACTURE

@onready var _root: Control = $Root
@onready var _manufacture_view: Control = (
	$Root/Window/Margin/Layout/Content/Manufacture
)
@onready var _inventory_view: Control = (
	$Root/Window/Margin/Layout/Content/Inventory
)
@onready var _manufacture_button: Button = (
	$Root/Window/Margin/Layout/Header/Margin/Row/Views/Manufacture
)
@onready var _inventory_button: Button = (
	$Root/Window/Margin/Layout/Header/Margin/Row/Views/Inventory
)
@onready var _recipe_grid: GridContainer = (
	$Root/Window/Margin/Layout/Content/Manufacture/Catalog/Margin/Layout/RecipeScroll/RecipeGrid
)
@onready var _catalog_count: Label = (
	$Root/Window/Margin/Layout/Content/Manufacture/Catalog/Margin/Layout/SectionHeader/Count
)
@onready var _catalog_footer: Label = (
	$Root/Window/Margin/Layout/Content/Manufacture/Catalog/Margin/Layout/CatalogFooter
)
@onready var _material_list: VBoxContainer = (
	$Root/Window/Margin/Layout/Content/Manufacture/Materials/Margin/Layout/MaterialList
)
@onready var _output_icon: TextureRect = (
	$Root/Window/Margin/Layout/Content/Manufacture/Materials/Margin/Layout/Output/Margin/Row/Icon
)
@onready var _output_name: Label = (
	$Root/Window/Margin/Layout/Content/Manufacture/Materials/Margin/Layout/Output/Margin/Row/Identity/Name
)
@onready var _output_count: Label = (
	$Root/Window/Margin/Layout/Content/Manufacture/Materials/Margin/Layout/Output/Margin/Row/Identity/Count
)
@onready var _inventory_group_list: VBoxContainer = (
	$Root/Window/Margin/Layout/Content/Inventory/Margin/Layout/InventoryScroll/InventoryGroups
)
@onready var _capacity: Label = (
	$Root/Window/Margin/Layout/Content/Inventory/Margin/Layout/SectionHeader/Capacity
)
@onready var _placement: Label = (
	$Root/Window/Margin/Layout/Content/Inventory/Margin/Layout/Placement/Margin/Text
)
@onready var _detail_kind: Label = (
	$Root/Window/Margin/Layout/Content/Manufacture/Result/Margin/Layout/SectionHeader/Kind
)
@onready var _detail_icon: TextureRect = (
	$Root/Window/Margin/Layout/Content/Manufacture/Result/Margin/Layout/Hero/Icon
)
@onready var _detail_name: Label = (
	$Root/Window/Margin/Layout/Content/Manufacture/Result/Margin/Layout/Hero/Name
)
@onready var _detail_output: Label = (
	$Root/Window/Margin/Layout/Content/Manufacture/Result/Margin/Layout/Hero/Output
)
@onready var _detail_existing: Label = (
	$Root/Window/Margin/Layout/Content/Manufacture/Result/Margin/Layout/Hero/Existing
)
@onready var _detail_state: Label = (
	$Root/Window/Margin/Layout/Content/Manufacture/Result/Margin/Layout/State/Margin/Text
)
@onready var _detail_craft: Button = (
	$Root/Window/Margin/Layout/Content/Manufacture/Result/Margin/Layout/Actions/Craft
)
@onready var _detail_select: Button = (
	$Root/Window/Margin/Layout/Content/Manufacture/Result/Margin/Layout/Actions/SelectExisting
)
@onready var _result_text: Label = (
	$Root/Window/Margin/Layout/Content/Manufacture/Result/Margin/Layout/Feedback/Margin/Text
)
@onready var _footer_status: Label = (
	$Root/Window/Margin/Layout/Footer/Margin/Row/Status
)
@onready var _footer_detail: Label = (
	$Root/Window/Margin/Layout/Footer/Margin/Row/Detail
)
@onready var _close_button: Button = (
	$Root/Window/Margin/Layout/Header/Margin/Row/Close
)
@onready var _help: Label = $Root/Window/Margin/Layout/Footer/Margin/Row/Help


func setup(world: Node) -> void:
	_world = world
	_build_recipe_cards()
	_reconcile_inventory_groups()
	_close_button.pressed.connect(close)
	_manufacture_button.pressed.connect(
		_set_active_view.bind(VIEW_MANUFACTURE)
	)
	_inventory_button.pressed.connect(_set_active_view.bind(VIEW_INVENTORY))
	_detail_craft.pressed.connect(_on_detail_craft_pressed)
	_detail_select.pressed.connect(_on_detail_select_pressed)
	_set_active_view(VIEW_MANUFACTURE)
	_root.visible = false
	for changed_signal in [
		_world.inventory_changed,
		_world.core_storage_changed,
		_world.building_storage_changed,
		_world.core_repair_completed,
		_world.core_charge_changed,
		_world.placement_changed,
	]:
		changed_signal.connect(_on_guidance_changed)
	if _world.combat_controller != null:
		_world.combat_controller.state_changed.connect(_on_guidance_changed)


func _on_guidance_changed(_changed_value = null) -> void:
	if _open:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("craft_menu"):
		if not _open:
			_world.close_core_storage()
			_world.close_core_charge_confirmation()
			_world.close_building_actions()
			_open = true
			_root.visible = true
			_set_active_view(VIEW_MANUFACTURE)
			_refresh()
			terminal_opened.emit()
		else:
			close()
		get_viewport().set_input_as_handled()
		return
	if not _open or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var index := key_event.keycode - KEY_1
	if index >= 0 and index < SliceRecipes.RECIPES.size():
		var recipe: Dictionary = SliceRecipes.RECIPES[index]
		if not SliceRecipes.is_unlocked(recipe, _world.is_core_charged()):
			get_viewport().set_input_as_handled()
			return
		_selected_recipe_id = String(recipe["id"])
		recipe_inspected.emit(_selected_recipe_id)
		_set_active_view(VIEW_MANUFACTURE)
		_activate_recipe(recipe, key_event.shift_pressed)
		get_viewport().set_input_as_handled()


func _activate_recipe(
	recipe: Dictionary,
	select_existing: bool = false
) -> void:
	if not SliceRecipes.is_unlocked(recipe, _world.is_core_charged()):
		return
	_selected_recipe_id = String(recipe["id"])
	var kind := String(recipe["kind"])
	var output := String(recipe["output"])
	var building_id := String(recipe.get("building_id", ""))
	var existing_count: int = _world.pocket.count(output)
	if kind == "building" and select_existing:
		if existing_count > 0:
			_world.select_building_kit(building_id)
			_last_result = "已选中 %s · 可放置 ×%d" % [
				String(recipe["name"]), existing_count
			]
		else:
			_last_result = "背包中没有可选中的 %s" % String(recipe["name"])
		_refresh()
		return

	var selected_before: String = _world.selected_building_id()
	var blocker := _craft_block_reason(recipe)
	var crafted: bool = _world.craft(String(recipe["id"]))
	_last_result = (
		"已制造 %s ×%d" % [
			String(recipe["name"]), int(recipe.get("output_count", 1))
		]
		if crafted
		else blocker if not blocker.is_empty() else "制造失败，请重试"
	)
	if (
		crafted
		and output == SliceBuildingCatalog.FLOOR_ID
		and not selected_before.is_empty()
		and selected_before != SliceBuildingCatalog.FLOOR_ID
	):
		var previous_definition := SliceBuildingCatalog.find(selected_before)
		if (
			previous_definition != null
			and _world.pocket.count(previous_definition.kit_item_id) > 0
		):
			_world.select_building_kit(selected_before)
	_refresh()


func close() -> void:
	_open = false
	_root.visible = false


func is_open() -> bool:
	return _open


func active_view() -> String:
	return _active_view


func show_inventory() -> void:
	_set_active_view(VIEW_INVENTORY)


func manufacture_view_visible() -> bool:
	return _manufacture_view.visible


func inventory_view_visible() -> bool:
	return _inventory_view.visible


func recipe_card(recipe_id: String) -> PanelContainer:
	var card_data: Dictionary = _recipe_cards.get(recipe_id, {})
	return card_data.get("panel") as PanelContainer


func inventory_slot(item_id: String) -> PanelContainer:
	var slot_data: Dictionary = _inventory_slots.get(item_id, {})
	return slot_data.get("panel") as PanelContainer


func recipe_card_count() -> int:
	return _recipe_cards.size()


func inventory_slot_count() -> int:
	return _inventory_slots.size()


func inventory_group_count() -> int:
	return _inventory_groups.size()


func visible_recipe_card_count() -> int:
	var result := 0
	for card_data in _recipe_cards.values():
		if (card_data["panel"] as PanelContainer).visible:
			result += 1
	return result


func material_requirement_count() -> int:
	return _material_rows.size()


func inventory_slot_count_text(item_id: String) -> String:
	var slot_data: Dictionary = _inventory_slots.get(item_id, {})
	var count_label := slot_data.get("count") as Label
	return "" if count_label == null else count_label.text


func material_requirement_text(item_id: String) -> String:
	var row_data: Dictionary = _material_rows.get(item_id, {})
	var count_label := row_data.get("count") as Label
	return "" if count_label == null else count_label.text


func capacity_text() -> String:
	return _capacity.text


func selected_recipe_id() -> String:
	return _selected_recipe_id


func detail_craft_button() -> Button:
	return _detail_craft


func detail_select_button() -> Button:
	return _detail_select


func select_recipe(recipe_id: String) -> void:
	var recipe := SliceRecipes.find(recipe_id)
	if (
		recipe.is_empty()
		or not SliceRecipes.is_unlocked(recipe, _world.is_core_charged())
	):
		return
	_selected_recipe_id = recipe_id
	recipe_inspected.emit(recipe_id)
	_last_result = ""
	_set_active_view(VIEW_MANUFACTURE)
	_refresh()


func _set_active_view(view_id: String) -> void:
	_active_view = (
		VIEW_INVENTORY if view_id == VIEW_INVENTORY else VIEW_MANUFACTURE
	)
	_manufacture_view.visible = _active_view == VIEW_MANUFACTURE
	_inventory_view.visible = _active_view == VIEW_INVENTORY
	_manufacture_button.button_pressed = _active_view == VIEW_MANUFACTURE
	_inventory_button.button_pressed = _active_view == VIEW_INVENTORY
	_refresh_footer()


func _build_recipe_cards() -> void:
	if not _recipe_cards.is_empty():
		return
	var shortcut := 1
	for recipe in SliceRecipes.RECIPES:
		var card := _create_recipe_card(recipe, shortcut)
		_recipe_grid.add_child(card["panel"])
		_recipe_cards[String(recipe["id"])] = card
		if _selected_recipe_id.is_empty():
			_selected_recipe_id = String(recipe["id"])
		shortcut += 1


func _create_recipe_card(recipe: Dictionary, shortcut: int) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = "RecipeCard_%s" % String(recipe["id"])
	panel.custom_minimum_size = Vector2(198, 164)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _surface_style(false, false))
	panel.tooltip_text = "%s：%s" % [
		String(recipe["name"]),
		SliceRecipes.cost_text(recipe["cost"]),
	]

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	margin.add_child(layout)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(0, 88)
	icon.texture = _item_icon(String(recipe["output"]))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(icon)

	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 6)
	layout.add_child(identity)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.text = String(recipe["name"])
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	identity.add_child(name_label)

	var hotkey := Label.new()
	hotkey.name = "Hotkey"
	hotkey.add_theme_color_override("font_color", COLOR_MUTED)
	hotkey.add_theme_font_size_override("font_size", 14)
	hotkey.text = "%d" % shortcut
	hotkey.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	identity.add_child(hotkey)

	var status := Label.new()
	status.name = "Status"
	status.add_theme_color_override("font_color", COLOR_MUTED)
	status.add_theme_font_size_override("font_size", 12)
	status.text = "检查状态…"
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layout.add_child(status)

	var select_button := Button.new()
	select_button.name = "SelectRecipe"
	select_button.flat = true
	select_button.focus_mode = Control.FOCUS_NONE
	select_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	select_button.tooltip_text = "查看 %s" % String(recipe["name"])
	select_button.pressed.connect(
		_on_recipe_selected.bind(String(recipe["id"]))
	)
	panel.add_child(select_button)

	return {
		"panel": panel,
		"status": status,
		"hotkey": hotkey,
	}


func _reconcile_inventory_groups() -> Array[Dictionary]:
	var groups := SliceInventoryReadModel.inventory_groups(
		_world.pocket,
		true,
		_has_critical_sample(),
		SliceItemCatalog.visible_ids(_world.is_core_charged())
	)
	for child in _inventory_group_list.get_children():
		_inventory_group_list.remove_child(child)
		child.queue_free()
	_inventory_slots.clear()
	_inventory_groups.clear()

	for group in groups:
		var category := String(group["category"])
		var section := VBoxContainer.new()
		section.name = "InventoryGroup_%s" % category
		section.add_theme_constant_override("separation", 6)
		_inventory_group_list.add_child(section)

		var header := HBoxContainer.new()
		section.add_child(header)

		var title := Label.new()
		title.name = "Title"
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.add_theme_color_override("font_color", COLOR_TEXT)
		title.add_theme_font_size_override("font_size", 14)
		title.text = String(group["title"])
		header.add_child(title)

		var summary := Label.new()
		summary.name = "Summary"
		summary.add_theme_color_override("font_color", COLOR_MUTED)
		summary.add_theme_font_size_override("font_size", 12)
		summary.text = "%d 项" % (group["items"] as Array).size()
		header.add_child(summary)

		var grid := GridContainer.new()
		grid.name = "Items"
		grid.columns = 6
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		section.add_child(grid)
		_inventory_groups[category] = {
			"section": section,
			"title": title,
			"grid": grid,
		}
		for item in group["items"]:
			var item_id := String(item["item_id"])
			var slot := _create_inventory_slot(item)
			grid.add_child(slot["panel"])
			_inventory_slots[item_id] = slot
	return groups


func _create_inventory_slot(item: Dictionary) -> Dictionary:
	var item_id := String(item["item_id"])
	var panel := PanelContainer.new()
	panel.name = "InventorySlot_%s" % item_id.replace(".", "_")
	panel.custom_minimum_size = Vector2(210, 118)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _surface_style(false, false))
	panel.tooltip_text = String(item["display_name"])

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(72, 72)
	icon.texture = _read_model_icon(item)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(icon)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	identity.add_theme_constant_override("separation", 3)
	layout.add_child(identity)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.add_theme_color_override("font_color", COLOR_MUTED)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.text = String(item["short_name"])
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	identity.add_child(name_label)

	var count_label := Label.new()
	count_label.name = "Count"
	count_label.add_theme_color_override("font_color", COLOR_TEXT)
	count_label.add_theme_font_size_override("font_size", 18)
	count_label.text = "0"
	identity.add_child(count_label)

	return {
		"panel": panel,
		"count": count_label,
		"name": name_label,
		"category": String(item["category"]),
	}


func _on_recipe_selected(recipe_id: String) -> void:
	select_recipe(recipe_id)


func _on_detail_craft_pressed() -> void:
	var recipe := SliceRecipes.find(_selected_recipe_id)
	if not recipe.is_empty():
		_activate_recipe(recipe)


func _on_detail_select_pressed() -> void:
	var recipe := SliceRecipes.find(_selected_recipe_id)
	if not recipe.is_empty():
		_activate_recipe(recipe, true)


func _refresh() -> void:
	var selected_id: String = _world.selected_building_id()
	_refresh_recipe_visibility()
	for recipe in SliceRecipes.RECIPES:
		if not SliceRecipes.is_unlocked(recipe, _world.is_core_charged()):
			continue
		_refresh_recipe_card(recipe, selected_id)
	for group in _reconcile_inventory_groups():
		for item in group["items"]:
			_refresh_inventory_slot(item, selected_id)
	var profile: SliceInventoryProfile = _world.pocket.profile()
	_capacity.text = (
		(
			"常规每类 %d · 步枪 1" % profile.per_item_capacity
			if _world.is_core_charged()
			else "不限种类 · 每类 %d" % profile.per_item_capacity
		)
		if profile.is_per_item()
		else "%d / %d" % [_world.pocket.total(), profile.total_capacity]
	)
	_placement.text = (
		"当前放置 · 未选择建筑套件"
		if selected_id.is_empty()
		else "当前放置 · %s" % _short_item_name(selected_id)
	)
	_refresh_selected_recipe(selected_id)
	_refresh_footer()


func _refresh_recipe_card(recipe: Dictionary, selected_id: String) -> void:
	var card: Dictionary = _recipe_cards[String(recipe["id"])]
	var panel := card["panel"] as PanelContainer
	var status := card["status"] as Label
	var hotkey := card["hotkey"] as Label
	var output := String(recipe["output"])
	var existing_count: int = _world.pocket.count(output)
	var building_id := String(recipe.get("building_id", ""))
	var selected := (
		String(recipe["kind"]) == "building"
		and selected_id == building_id
	)
	var blocker := _craft_block_reason(recipe)
	var is_current := String(recipe["id"]) == _selected_recipe_id

	if selected:
		status.text = "放置中 · 剩余 %d" % existing_count
		status.add_theme_color_override("font_color", COLOR_A1)
	elif not blocker.is_empty():
		status.text = blocker
		status.add_theme_color_override("font_color", COLOR_WARNING)
	elif existing_count > 0 and String(recipe["kind"]) == "building":
		status.text = "材料可用 · 已有 %d" % existing_count
		status.add_theme_color_override("font_color", COLOR_MUTED)
	else:
		status.text = "材料可用 · %s" % SliceRecipes.cost_text(recipe["cost"])
		status.add_theme_color_override("font_color", COLOR_MUTED)
	hotkey.add_theme_color_override(
		"font_color", COLOR_A1 if is_current else COLOR_MUTED
	)
	panel.add_theme_stylebox_override(
		"panel", _surface_style(is_current, false)
	)


func _refresh_selected_recipe(selected_building_id: String) -> void:
	var recipe := SliceRecipes.find(_selected_recipe_id)
	if recipe.is_empty():
		return
	var output := String(recipe["output"])
	var output_amount := int(recipe.get("output_count", 1))
	var existing_count: int = _world.pocket.count(output)
	var building_id := String(recipe.get("building_id", ""))
	var selected := (
		String(recipe["kind"]) == "building"
		and selected_building_id == building_id
	)
	var blocker := _craft_block_reason(recipe)

	_refresh_material_requirements(recipe)
	_output_icon.texture = _item_icon(output)
	_output_name.text = String(recipe["name"])
	_output_count.text = "产出 ×%d" % output_amount
	_detail_kind.text = _recipe_kind_title(recipe)
	_detail_icon.texture = _item_icon(output)
	_detail_name.text = String(recipe["name"])
	_detail_output.text = (
		"产出 ×%d · 用于世界放置" % output_amount
		if String(recipe["kind"]) == "building"
		else "产出 ×%d · 放入随身背包" % output_amount
	)
	_detail_existing.text = (
		"随身 %d · 核心 %d"
		% [existing_count, _world.core_storage.count(output)]
		if int(recipe.get("unique_total_limit", 0)) > 0
		else "随身已有 %d" % existing_count
	)
	_detail_craft.disabled = not blocker.is_empty()
	_detail_craft.text = "制作 ×%d" % output_amount
	_detail_craft.tooltip_text = (
		blocker
		if not blocker.is_empty()
		else "消耗 %s" % SliceRecipes.cost_text(recipe["cost"])
	)
	_detail_select.visible = String(recipe["kind"]) == "building"
	_detail_select.disabled = existing_count <= 0 or selected
	_detail_select.text = (
		"放置中 ×%d" % existing_count
		if selected
		else "选中已有 ×%d" % existing_count
	)
	if selected:
		_detail_state.text = "当前正在放置 · 剩余 %d" % existing_count
		_detail_state.add_theme_color_override("font_color", COLOR_A1)
	elif blocker.is_empty():
		_detail_state.text = "材料校验通过 · 可以制作"
		_detail_state.add_theme_color_override("font_color", COLOR_A1)
	else:
		_detail_state.text = _display_blocker(blocker)
		_detail_state.add_theme_color_override("font_color", COLOR_WARNING)
	_result_text.text = (
		_last_result if not _last_result.is_empty() else "确认材料后执行制作"
	)
	_result_text.add_theme_color_override(
		"font_color",
		COLOR_A1 if _last_result.begins_with("已") else (
			COLOR_WARNING if not _last_result.is_empty() else COLOR_MUTED
		)
	)


func _refresh_material_requirements(recipe: Dictionary) -> void:
	for child in _material_list.get_children():
		_material_list.remove_child(child)
		child.queue_free()
	_material_rows.clear()
	var cost: Dictionary = recipe["cost"]
	for raw_item_id in cost:
		var item_id := String(raw_item_id)
		var needed := int(cost[raw_item_id])
		var available: int = _world.pocket.count(item_id)
		var definition := SliceItemCatalog.find(item_id)
		var item_name := item_id if definition == null else definition.display_name
		var missing := available < needed

		var panel := PanelContainer.new()
		panel.name = "Material_%s" % item_id.replace(".", "_")
		panel.custom_minimum_size = Vector2(0, 92)
		panel.add_theme_stylebox_override(
			"panel", _surface_style(false, missing)
		)
		_material_list.add_child(panel)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 9)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 9)
		panel.add_child(margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		margin.add_child(row)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(58, 58)
		icon.texture = _item_icon(item_id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(icon)

		var identity := VBoxContainer.new()
		identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		identity.alignment = BoxContainer.ALIGNMENT_CENTER
		identity.add_theme_constant_override("separation", 3)
		row.add_child(identity)

		var name_label := Label.new()
		name_label.name = "Name"
		name_label.add_theme_color_override("font_color", COLOR_TEXT)
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.text = item_name
		identity.add_child(name_label)

		var source_label := Label.new()
		source_label.name = "Source"
		source_label.add_theme_color_override("font_color", COLOR_MUTED)
		source_label.add_theme_font_size_override("font_size", 12)
		source_label.text = "随身库存"
		identity.add_child(source_label)

		var count_label := Label.new()
		count_label.name = "Count"
		count_label.add_theme_color_override(
			"font_color", COLOR_WARNING if missing else COLOR_TEXT
		)
		count_label.add_theme_font_size_override("font_size", 18)
		count_label.text = "%d / %d" % [available, needed]
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(count_label)

		_material_rows[item_id] = {
			"panel": panel,
			"count": count_label,
		}


func _refresh_inventory_slot(item: Dictionary, selected_id: String) -> void:
	var item_id := String(item["item_id"])
	var slot: Dictionary = _inventory_slots[item_id]
	var count_label := slot["count"] as Label
	var panel := slot["panel"] as PanelContainer
	var count := int(item["count"])
	count_label.text = (
		"×%d" % count
		if String(item["category"]) == SliceItemDefinition.CATEGORY_KEY_ITEM
		else "%d / %d" % [count, int(item["capacity"])]
	)
	count_label.add_theme_color_override(
		"font_color", COLOR_TEXT if count > 0 else COLOR_DIM
	)
	panel.add_theme_stylebox_override(
		"panel", _surface_style(item_id == selected_id, false)
	)


func _refresh_footer() -> void:
	if _world == null:
		return
	if _active_view == VIEW_INVENTORY:
		_footer_status.text = "分类背包"
		_footer_status.add_theme_color_override("font_color", COLOR_A1)
		_footer_detail.text = _capacity.text
		return
	var recipe := SliceRecipes.find(_selected_recipe_id)
	if recipe.is_empty():
		_footer_status.text = "制造终端"
		_footer_detail.text = "选择制造对象"
		return
	var blocker := _craft_block_reason(recipe)
	if blocker.is_empty():
		_footer_status.text = "材料就绪"
		_footer_status.add_theme_color_override("font_color", COLOR_A1)
	else:
		_footer_status.text = "等待材料"
		_footer_status.add_theme_color_override("font_color", COLOR_WARNING)
	_footer_detail.text = (
		_last_result
		if not _last_result.is_empty()
		else SliceRecipes.cost_text(recipe["cost"])
	)


func _display_blocker(blocker: String) -> String:
	if blocker.begins_with("缺少 "):
		return "材料不足 · 还需 %s" % blocker.trim_prefix("缺少 ")
	return blocker


func _refresh_recipe_visibility() -> void:
	var core_charged: bool = _world.is_core_charged()
	var visible_count := 0
	for recipe in SliceRecipes.RECIPES:
		var visible := SliceRecipes.is_unlocked(recipe, core_charged)
		var card: Dictionary = _recipe_cards[String(recipe["id"])]
		(card["panel"] as PanelContainer).visible = visible
		if visible:
			visible_count += 1
	_catalog_count.text = "%d 项" % visible_count
	_catalog_footer.text = (
		"全部配方 · 权威顺序 1—9"
		if core_charged
		else "基础配方 1—7 · 核心充能后解锁装备与外勤补给"
	)
	_help.text = (
		"鼠标选择 · 1—9 制造 · Shift + 1—7 选中已有 · Esc / B 关闭"
		if core_charged
		else "鼠标选择 · 1—7 制造 · Shift + 1—7 选中已有 · Esc / B 关闭"
	)


func _craft_block_reason(recipe: Dictionary) -> String:
	return SliceRecipes.craft_block_reason(
		recipe,
		_world.pocket,
		_world.core_storage,
		_world.is_core_charged()
	)


func _recipe_kind_title(recipe: Dictionary) -> String:
	match String(recipe["kind"]):
		"building":
			return "建筑套件"
		"equipment":
			return "装备"
		"field_supply":
			return "外勤补给"
	return "加工品"


func _item_icon(item_id: String) -> Texture2D:
	var definition := SliceItemCatalog.find(item_id)
	if definition == null:
		return null
	var texture := load(definition.icon_path) as Texture2D
	if definition.icon_region.has_area():
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = definition.icon_region
		return atlas
	return texture


func _read_model_icon(item: Dictionary) -> Texture2D:
	var icon_path := String(item.get("icon_path", ""))
	if icon_path.is_empty():
		return null
	var texture := load(icon_path) as Texture2D
	var icon_region: Rect2 = item.get("icon_region", Rect2())
	if icon_region.has_area():
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = icon_region
		return atlas
	return texture


func _short_item_name(item_id: String) -> String:
	var definition := SliceItemCatalog.find(item_id)
	return item_id if definition == null else definition.short_name


func _has_critical_sample() -> bool:
	return (
		_world != null
		and _world.combat_controller != null
		and _world.combat_controller.has_critical_sample()
	)


func _surface_style(selected: bool, warning: bool) -> StyleBoxFlat:
	var style := SURFACE_STYLE.duplicate() as StyleBoxFlat
	if selected:
		style.border_color = COLOR_A1
		style.border_width_bottom = 4
	elif warning:
		style.border_color = COLOR_WARNING.darkened(0.22)
		style.border_width_left = 3
		style.border_width_bottom = 1
	return style
