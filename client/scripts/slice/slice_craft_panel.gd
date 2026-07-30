class_name SliceCraftPanel
extends CanvasLayer

## Graphical handheld crafting and backpack panel.
## docs/features/slice-graphical-crafting-and-inventory-v1.md

const CRYSTAL_ICON := "res://assets/sprites/slice/cargo_crystal.png"
const CATALYST_ICON := "res://assets/sprites/slice/cargo_catalyst.png"
const PART_ICON := "res://assets/icons/slice_mechanical_part.svg"
const CARD_STYLE := preload("res://assets/themes/slice_ui_card.tres")
const SURFACE_STYLE := preload("res://assets/themes/slice_ui_surface.tres")
const INVENTORY_ITEMS: Array[String] = [
	"crystal",
	"catalyst",
	"part",
	SliceBuildingCatalog.FLOOR_ID,
	SliceBuildingCatalog.COLLECTOR_ID,
	SliceBuildingCatalog.REACTOR_ID,
	SliceBuildingCatalog.POWER_RELAY_ID,
	SliceBuildingCatalog.CONVEYOR_ID,
	SliceBuildingCatalog.STORAGE_ID,
]

const COLOR_TEXT := Color(0.88, 0.92, 0.93)
const COLOR_MUTED := Color(0.59, 0.65, 0.67)
const COLOR_READY := Color(0.34, 0.82, 0.80)
const COLOR_WARNING := Color(0.96, 0.68, 0.30)
const COLOR_BLOCKED := Color(0.92, 0.43, 0.35)
const COLOR_SELECTED := Color(0.30, 0.92, 0.86)

var _world: Node
var _open := false
var _recipe_cards: Dictionary = {}
var _inventory_slots: Dictionary = {}

@onready var _root: Control = $Root
@onready var _rule: Label = $Root/Window/Margin/Layout/RulePanel/Rule
@onready var _recipe_grid: GridContainer = (
	$Root/Window/Margin/Layout/Content/Recipes/RecipeScroll/RecipeGrid
)
@onready var _inventory_grid: GridContainer = (
	$Root/Window/Margin/Layout/Content/Inventory/InventoryGrid
)
@onready var _capacity: Label = (
	$Root/Window/Margin/Layout/Content/Inventory/SectionHeader/Capacity
)
@onready var _close_button: Button = $Root/Window/Margin/Layout/Header/Close


func setup(world: Node) -> void:
	_world = world
	_build_recipe_cards()
	_build_inventory_slots()
	_close_button.pressed.connect(close)
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
			_refresh()
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
		_activate_recipe(recipe, key_event.shift_pressed)
		get_viewport().set_input_as_handled()


func _activate_recipe(
	recipe: Dictionary,
	select_existing: bool = false
) -> void:
	var kind := String(recipe["kind"])
	var output := String(recipe["output"])
	var building_id := String(recipe.get("building_id", ""))
	var existing_count: int = _world.pocket.count(output)
	if kind == "building" and select_existing:
		if existing_count > 0:
			_world.select_building_kit(building_id)
		_refresh()
		return

	var selected_before: String = _world.selected_building_id()
	var crafted: bool = _world.craft(String(recipe["id"]))
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


func capacity_text() -> String:
	return _capacity.text


func _build_recipe_cards() -> void:
	if not _recipe_cards.is_empty():
		return
	var shortcut := 1
	for recipe in SliceRecipes.RECIPES:
		var card := _create_recipe_card(recipe, shortcut)
		_recipe_grid.add_child(card["panel"])
		_recipe_cards[String(recipe["id"])] = card
		shortcut += 1


func _create_recipe_card(recipe: Dictionary, shortcut: int) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = "RecipeCard_%s" % String(recipe["id"])
	panel.custom_minimum_size = Vector2(498, 142)
	panel.add_theme_stylebox_override("panel", _card_style(false, false))
	panel.tooltip_text = "%s：%s" % [
		String(recipe["name"]),
		SliceRecipes.cost_text(recipe["cost"]),
	]

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	layout.add_child(header)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(54, 54)
	icon.texture = _item_icon(String(recipe["output"]))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(icon)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 0)
	header.add_child(identity)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	name_label.add_theme_font_size_override("font_size", 21)
	name_label.text = String(recipe["name"])
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	identity.add_child(name_label)

	var output_label := Label.new()
	output_label.name = "Output"
	output_label.add_theme_color_override("font_color", COLOR_MUTED)
	output_label.add_theme_font_size_override("font_size", 15)
	output_label.text = "单次产出 ×%d" % int(recipe.get("output_count", 1))
	identity.add_child(output_label)

	var hotkey := Label.new()
	hotkey.name = "Hotkey"
	hotkey.custom_minimum_size = Vector2(38, 32)
	hotkey.add_theme_color_override("font_color", Color(0.98, 0.82, 0.48))
	hotkey.add_theme_font_size_override("font_size", 18)
	hotkey.text = "[%d]" % shortcut
	hotkey.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hotkey.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(hotkey)

	var cost_label := Label.new()
	cost_label.name = "Cost"
	cost_label.add_theme_color_override("font_color", Color(0.72, 0.77, 0.78))
	cost_label.add_theme_font_size_override("font_size", 16)
	cost_label.text = "材料  %s" % SliceRecipes.cost_text(recipe["cost"])
	cost_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layout.add_child(cost_label)

	var state_row := HBoxContainer.new()
	state_row.add_theme_constant_override("separation", 8)
	layout.add_child(state_row)

	var status := Label.new()
	status.name = "Status"
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_theme_font_size_override("font_size", 16)
	status.text = "检查材料…"
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	state_row.add_child(status)

	var craft_button := Button.new()
	craft_button.name = "Craft"
	craft_button.custom_minimum_size = Vector2(116, 36)
	craft_button.add_theme_font_size_override("font_size", 16)
	craft_button.text = "制作"
	craft_button.pressed.connect(
		_on_craft_pressed.bind(String(recipe["id"]))
	)
	state_row.add_child(craft_button)

	var select_button := Button.new()
	select_button.name = "SelectExisting"
	select_button.custom_minimum_size = Vector2(138, 36)
	select_button.add_theme_font_size_override("font_size", 16)
	select_button.text = "选中已有"
	select_button.visible = String(recipe["kind"]) == "building"
	select_button.pressed.connect(
		_on_select_existing_pressed.bind(String(recipe["id"]))
	)
	state_row.add_child(select_button)

	return {
		"panel": panel,
		"status": status,
		"craft": craft_button,
		"select": select_button,
	}


func _build_inventory_slots() -> void:
	if not _inventory_slots.is_empty():
		return
	for item_id in INVENTORY_ITEMS:
		var slot := _create_inventory_slot(item_id)
		_inventory_grid.add_child(slot["panel"])
		_inventory_slots[item_id] = slot


func _create_inventory_slot(item_id: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = "InventorySlot_%s" % item_id.replace(".", "_")
	panel.custom_minimum_size = Vector2(118, 116)
	panel.add_theme_stylebox_override("panel", _slot_style(false))
	panel.tooltip_text = String(SliceRecipes.ITEM_NAMES.get(item_id, item_id))

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 1)
	panel.add_child(layout)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(58, 58)
	icon.texture = _item_icon(item_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(icon)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.add_theme_color_override("font_color", COLOR_MUTED)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.text = _short_item_name(item_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layout.add_child(name_label)

	var count_label := Label.new()
	count_label.name = "Count"
	count_label.add_theme_color_override("font_color", COLOR_TEXT)
	count_label.add_theme_font_size_override("font_size", 20)
	count_label.text = "0"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(count_label)

	return {
		"panel": panel,
		"count": count_label,
		"name": name_label,
	}


func _on_craft_pressed(recipe_id: String) -> void:
	var recipe := SliceRecipes.find(recipe_id)
	if not recipe.is_empty():
		_activate_recipe(recipe)


func _on_select_existing_pressed(recipe_id: String) -> void:
	var recipe := SliceRecipes.find(recipe_id)
	if not recipe.is_empty():
		_activate_recipe(recipe, true)


func _refresh() -> void:
	_rule.text = "当前规则：%s" % _world.current_journey_rule_text()
	var selected_id: String = _world.selected_building_id()
	for recipe in SliceRecipes.RECIPES:
		_refresh_recipe_card(recipe, selected_id)
	for item_id in INVENTORY_ITEMS:
		_refresh_inventory_slot(item_id, selected_id)
	var capacity: int = _world.pocket.capacity
	_capacity.text = (
		"%d / %d" % [_world.pocket.total(), capacity]
		if capacity > 0
		else "%d / ∞" % _world.pocket.total()
	)


func _refresh_recipe_card(recipe: Dictionary, selected_id: String) -> void:
	var card: Dictionary = _recipe_cards[String(recipe["id"])]
	var panel := card["panel"] as PanelContainer
	var status := card["status"] as Label
	var craft_button := card["craft"] as Button
	var select_button := card["select"] as Button
	var output := String(recipe["output"])
	var existing_count: int = _world.pocket.count(output)
	var building_id := String(recipe.get("building_id", ""))
	var selected := (
		String(recipe["kind"]) == "building"
		and selected_id == building_id
	)
	var blocker := SliceRecipes.craft_block_reason(recipe, _world.pocket)

	craft_button.disabled = not blocker.is_empty()
	craft_button.text = "制作 ×%d" % int(recipe.get("output_count", 1))
	craft_button.tooltip_text = (
		blocker
		if not blocker.is_empty()
		else "消耗 %s" % SliceRecipes.cost_text(recipe["cost"])
	)
	if String(recipe["kind"]) == "building":
		select_button.disabled = existing_count <= 0 or selected
		select_button.text = (
			"放置中 ×%d" % existing_count
			if selected
			else "选中已有 ×%d" % existing_count
		)

	var blocked := false
	if selected:
		status.text = "● 当前正在放置 · 剩余 %d" % existing_count
		status.add_theme_color_override("font_color", COLOR_SELECTED)
	elif existing_count > 0 and String(recipe["kind"]) == "building":
		status.text = (
			"已有 %d · %s" % [existing_count, blocker]
			if not blocker.is_empty()
			else "已有 %d · 可追加制作" % existing_count
		)
		status.add_theme_color_override("font_color", COLOR_WARNING)
		blocked = not blocker.is_empty()
	elif blocker.is_empty():
		status.text = "● 材料就绪"
		status.add_theme_color_override("font_color", COLOR_READY)
	else:
		status.text = blocker
		status.add_theme_color_override("font_color", COLOR_BLOCKED)
		blocked = true
	panel.add_theme_stylebox_override(
		"panel",
		_card_style(selected, blocked)
	)


func _refresh_inventory_slot(item_id: String, selected_id: String) -> void:
	var slot: Dictionary = _inventory_slots[item_id]
	var count_label := slot["count"] as Label
	var panel := slot["panel"] as PanelContainer
	var count: int = _world.pocket.count(item_id)
	count_label.text = str(count)
	count_label.add_theme_color_override(
		"font_color",
		COLOR_WARNING if count > 0 else COLOR_MUTED
	)
	panel.add_theme_stylebox_override(
		"panel",
		_slot_style(item_id == selected_id)
	)


func _item_icon(item_id: String) -> Texture2D:
	match item_id:
		"crystal":
			return load(CRYSTAL_ICON) as Texture2D
		"catalyst":
			return load(CATALYST_ICON) as Texture2D
		"part":
			return load(PART_ICON) as Texture2D
	var definition := SliceBuildingCatalog.find(item_id)
	if definition == null:
		return null
	var texture := load(definition.texture_path_for_rotation(0)) as Texture2D
	if definition.texture_region.has_area():
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = definition.texture_region
		return atlas
	return texture


func _short_item_name(item_id: String) -> String:
	match item_id:
		SliceBuildingCatalog.FLOOR_ID:
			return "地板"
		SliceBuildingCatalog.COLLECTOR_ID:
			return "采集器"
		SliceBuildingCatalog.REACTOR_ID:
			return "反应器"
		SliceBuildingCatalog.POWER_RELAY_ID:
			return "中继"
		SliceBuildingCatalog.CONVEYOR_ID:
			return "传送带"
		SliceBuildingCatalog.STORAGE_ID:
			return "储物箱"
	return String(SliceRecipes.ITEM_NAMES.get(item_id, item_id))


func _card_style(selected: bool, blocked: bool) -> StyleBoxFlat:
	var style := CARD_STYLE.duplicate() as StyleBoxFlat
	if selected or blocked:
		style.border_width_left = 4
		style.border_width_top = 0
		style.border_width_right = 0
		style.border_width_bottom = 0
		style.border_color = COLOR_SELECTED if selected else COLOR_BLOCKED
	return style


func _slot_style(selected: bool) -> StyleBoxFlat:
	var style := SURFACE_STYLE.duplicate() as StyleBoxFlat
	if selected:
		style.border_width_left = 4
		style.border_width_top = 0
		style.border_width_right = 0
		style.border_width_bottom = 0
		style.border_color = COLOR_SELECTED
	return style
