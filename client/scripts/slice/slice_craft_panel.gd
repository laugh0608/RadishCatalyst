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


func setup(world: Node) -> void:
	_world = world
	_root.visible = false
	_world.inventory_changed.connect(_on_inventory_changed)


func _on_inventory_changed() -> void:
	if _open:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("craft_menu"):
		if not _open:
			_world.close_core_storage()
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
		var kind := String(recipe["kind"])
		var output := String(recipe["output"])
		if kind == "building" and _world.pocket.count(output) > 0:
			_world.select_building_kit(String(recipe["building_id"]))
		else:
			_world.craft(String(recipe["id"]))
		_refresh()
		get_viewport().set_input_as_handled()


func close() -> void:
	_open = false
	_root.visible = false


func _refresh() -> void:
	var lines: Array[String] = ["【随身合成面板】  B 关闭"]
	var number := 1
	for recipe in SliceRecipes.RECIPES:
		var cost: Dictionary = recipe["cost"]
		var status := ""
		if String(recipe["kind"]) == "building":
			var kit_count: int = _world.pocket.count(String(recipe["output"]))
			if _world.selected_building_id() == String(recipe["building_id"]):
				status = "  （放置中，剩余 %d）" % kit_count
			elif kit_count > 0:
				status = "  （已有 %d，按键选中）" % kit_count
			elif not _world.can_afford(cost):
				status = "  （缺料）"
		elif not _world.can_afford(cost):
			status = "  （缺料）"
		lines.append("[%d] %s   需 %s%s" % [
			number, String(recipe["name"]), SliceRecipes.cost_text(cost), status
		])
		number += 1
	_list.text = "\n".join(lines)
