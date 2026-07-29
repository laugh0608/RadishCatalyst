class_name SliceCraftPanel
extends CanvasLayer

## Handheld crafting panel (arc L1,
## docs/features/slice-handheld-crafting-panel-v1.md). The craft_menu key (B)
## toggles it; while open, number keys 1..N craft the matching recipe. Prototype
## text UI — pixel styling is a later HUD-skin topic.

var _world: Node
var _open := false

@onready var _root: Control = $Root
@onready var _list: Label = $Root/Box/List
@onready var _rule: Label = $Root/Box/Rule


func setup(world: Node) -> void:
	_world = world
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
		_open = not _open
		_root.visible = _open
		if _open:
			_refresh()
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
	if kind == "building" and not crafted and existing_count > 0:
		_world.select_building_kit(building_id)
	elif (
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


func _refresh() -> void:
	_rule.text = "当前规则：%s" % _world.current_journey_rule_text()
	var lines: Array[String] = ["【随身合成面板】  B 关闭"]
	var number := 1
	for recipe in SliceRecipes.RECIPES:
		var cost: Dictionary = recipe["cost"]
		var status := ""
		if String(recipe["kind"]) == "building":
			var kit_count: int = _world.pocket.count(String(recipe["output"]))
			if _world.selected_building_id() == String(recipe["building_id"]):
				status = (
					"  （放置中，剩余 %d；[%d] 追加制作）"
					% [kit_count, number]
				)
			elif kit_count > 0:
				status = "  （已有 %d；Shift+%d 选中）" % [
					kit_count,
					number,
				]
			elif not _world.can_afford(cost):
				status = "  （缺料）"
		elif not _world.can_afford(cost):
			status = "  （缺料）"
		lines.append("[%d] %s   需 %s%s" % [
			number, String(recipe["name"]), SliceRecipes.cost_text(cost), status
		])
		number += 1
	_list.text = "\n".join(lines)
