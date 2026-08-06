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

const COLOR_TEXT := Color(0.118, 0.145, 0.149)
const COLOR_MUTED := Color(0.24, 0.28, 0.28)
const COLOR_READY := Color(0.035, 0.42, 0.4)
const COLOR_WARNING := Color(0.702, 0.392, 0.102)
const COLOR_BLOCKED := Color(0.722, 0.18, 0.149)
const COLOR_SELECTED := Color(0.106, 0.38, 0.55)

var _world: Node
var _open := false
var _recipe_cards: Dictionary = {}
var _inventory_slots: Dictionary = {}
var _selected_recipe_id := ""
var _last_result := ""

@onready var _root: Control = $Root
@onready var _recipe_grid: GridContainer = (
	$Root/Window/Margin/Layout/Content/Recipes/RecipeScroll/RecipeGrid
)
@onready var _inventory_grid: GridContainer = (
	$Root/Window/Margin/Layout/Content/Inventory/InventoryGrid
)
@onready var _capacity: Label = (
	$Root/Window/Margin/Layout/Content/Inventory/SectionHeader/Capacity
)
@onready var _placement: Label = (
	$Root/Window/Margin/Layout/Content/Inventory/Placement/Text
)
@onready var _detail_icon: TextureRect = (
	$Root/Window/Margin/Layout/Content/Current/Detail/Margin/Layout/Hero/Icon
)
@onready var _detail_name: Label = (
	$Root/Window/Margin/Layout/Content/Current/Detail/Margin/Layout/Hero/Name
)
@onready var _detail_output: Label = (
	$Root/Window/Margin/Layout/Content/Current/Detail/Margin/Layout/Hero/Output
)
@onready var _detail_cost: Label = (
	$Root/Window/Margin/Layout/Content/Current/Detail/Margin/Layout/Cost/Label
)
@onready var _detail_state: Label = (
	$Root/Window/Margin/Layout/Content/Current/Detail/Margin/Layout/State
)
@onready var _detail_craft: Button = (
	$Root/Window/Margin/Layout/Content/Current/Detail/Margin/Layout/Actions/Craft
)
@onready var _detail_select: Button = (
	$Root/Window/Margin/Layout/Content/Current/Detail/Margin/Layout/Actions/SelectExisting
)
@onready var _result_text: Label = (
	$Root/Window/Margin/Layout/Content/Current/Result/Text
)
@onready var _close_button: Button = (
	$Root/Window/Margin/Layout/Header/Margin/Row/Close
)


func setup(world: Node) -> void:
	_world = world
	_build_recipe_cards()
	_build_inventory_slots()
	_close_button.pressed.connect(close)
	_detail_craft.pressed.connect(_on_detail_craft_pressed)
	_detail_select.pressed.connect(_on_detail_select_pressed)
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
		_selected_recipe_id = String(recipe["id"])
		_activate_recipe(recipe, key_event.shift_pressed)
		get_viewport().set_input_as_handled()


func _activate_recipe(
	recipe: Dictionary,
	select_existing: bool = false
) -> void:
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
	var blocker := SliceRecipes.craft_block_reason(recipe, _world.pocket)
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


func selected_recipe_id() -> String:
	return _selected_recipe_id


func detail_craft_button() -> Button:
	return _detail_craft


func detail_select_button() -> Button:
	return _detail_select


func select_recipe(recipe_id: String) -> void:
	if SliceRecipes.find(recipe_id).is_empty():
		return
	_selected_recipe_id = recipe_id
	_last_result = ""
	_refresh()


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
	panel.custom_minimum_size = Vector2(328, 68)
	panel.add_theme_stylebox_override("panel", _card_style(false, false))
	panel.tooltip_text = "%s：%s" % [
		String(recipe["name"]),
		SliceRecipes.cost_text(recipe["cost"]),
	]

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(48, 48)
	icon.texture = _item_icon(String(recipe["output"]))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(icon)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 0)
	layout.add_child(identity)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.text = String(recipe["name"])
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	identity.add_child(name_label)

	var output_label := Label.new()
	output_label.name = "Output"
	output_label.add_theme_color_override("font_color", COLOR_MUTED)
	output_label.add_theme_font_size_override("font_size", 13)
	output_label.text = "检查状态…"
	identity.add_child(output_label)

	var hotkey := Label.new()
	hotkey.name = "Hotkey"
	hotkey.custom_minimum_size = Vector2(32, 32)
	hotkey.add_theme_color_override("font_color", COLOR_WARNING)
	hotkey.add_theme_font_size_override("font_size", 18)
	hotkey.text = "[%d]" % shortcut
	hotkey.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hotkey.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	layout.add_child(hotkey)

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
		"status": output_label,
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
	panel.custom_minimum_size = Vector2(112, 126)
	panel.add_theme_stylebox_override("panel", _slot_style(false))
	panel.tooltip_text = String(SliceRecipes.ITEM_NAMES.get(item_id, item_id))

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 1)
	panel.add_child(layout)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(54, 54)
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
	_placement.text = (
		"当前放置\n— 未选择建筑套件"
		if selected_id.is_empty()
		else "当前放置\n● %s" % _short_item_name(selected_id)
	)
	_refresh_selected_recipe(selected_id)


func _refresh_recipe_card(recipe: Dictionary, selected_id: String) -> void:
	var card: Dictionary = _recipe_cards[String(recipe["id"])]
	var panel := card["panel"] as PanelContainer
	var status := card["status"] as Label
	var output := String(recipe["output"])
	var existing_count: int = _world.pocket.count(output)
	var building_id := String(recipe.get("building_id", ""))
	var selected := (
		String(recipe["kind"]) == "building"
		and selected_id == building_id
	)
	var blocker := SliceRecipes.craft_block_reason(recipe, _world.pocket)

	var blocked := false
	if selected:
		status.text = "● 放置中 · %d" % existing_count
		status.add_theme_color_override("font_color", COLOR_SELECTED)
	elif existing_count > 0 and String(recipe["kind"]) == "building":
		status.text = (
			"已有 %d · %s" % [existing_count, blocker]
			if not blocker.is_empty()
			else "● 就绪 · 已有 %d" % existing_count
		)
		status.add_theme_color_override("font_color", COLOR_WARNING)
		blocked = not blocker.is_empty()
	elif blocker.is_empty():
		status.text = "● 就绪"
		status.add_theme_color_override("font_color", COLOR_READY)
	else:
		status.text = blocker
		status.add_theme_color_override("font_color", COLOR_BLOCKED)
		blocked = true
	panel.add_theme_stylebox_override(
		"panel",
		_card_style(
			String(recipe["id"]) == _selected_recipe_id,
			blocked and String(recipe["id"]) == _selected_recipe_id
		)
	)


func _refresh_selected_recipe(selected_building_id: String) -> void:
	var recipe := SliceRecipes.find(_selected_recipe_id)
	if recipe.is_empty():
		return
	var output := String(recipe["output"])
	var existing_count: int = _world.pocket.count(output)
	var building_id := String(recipe.get("building_id", ""))
	var selected := (
		String(recipe["kind"]) == "building"
		and selected_building_id == building_id
	)
	var blocker := SliceRecipes.craft_block_reason(recipe, _world.pocket)
	_detail_icon.texture = _item_icon(output)
	_detail_name.text = String(recipe["name"])
	_detail_output.text = "产出 ×%d" % int(recipe.get("output_count", 1))
	_detail_cost.text = "材料  %s" % SliceRecipes.cost_text(recipe["cost"])
	_detail_craft.disabled = not blocker.is_empty()
	_detail_craft.text = "制作 ×%d" % int(recipe.get("output_count", 1))
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
		_detail_state.text = "● 当前正在放置 · 剩余 %d" % existing_count
		_detail_state.add_theme_color_override("font_color", COLOR_SELECTED)
	elif blocker.is_empty():
		_detail_state.text = "● 材料就绪"
		_detail_state.add_theme_color_override("font_color", COLOR_READY)
	else:
		_detail_state.text = blocker
		_detail_state.add_theme_color_override("font_color", COLOR_BLOCKED)
	_result_text.text = (
		_last_result if not _last_result.is_empty() else "尚未进行制造操作"
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
