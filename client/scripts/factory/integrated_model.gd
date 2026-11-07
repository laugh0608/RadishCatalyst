extends "res://scripts/factory/expansion_model.gd"

const Integrated := preload("res://data/factory/integrated_rules.gd")
var core: Dictionary


func _init() -> void:
	super()
	map_id = Integrated.MAP_ID
	supply_id = Integrated.SUPPLY_ID
	kits = Integrated.SUPPLY.duplicate()
	assembly_costs.clear()
	assembly_counts.clear()
	actor.x = Integrated.SPAWN.x
	actor.z = Integrated.SPAWN.y
	var outputs := {}
	for port in Integrated.ports(Vector2i.ZERO, "output"):
		outputs[port.id] = {"item": "", "enabled": false, "cooldown_ticks": 0}
	core = {"id": next_id, "type": Integrated.CORE, "x": Integrated.CORE_CELL.x, "z": Integrated.CORE_CELL.y,
		"dir": 0, "level": 1, "items": {}, "outputs": outputs, "input_cursors": {}, "output_cursors": {}}
	next_id += 1
	entities.append(core)
	rebuild_indexes()
	_refresh_automatic_power()


func placement(type: String, cell: Vector2i, player: Variant = null) -> Dictionary:
	if type == Integrated.CORE:
		return failure("基地核心由地图预置")
	if type in Integrated.LOCKED:
		return failure("该构件尚未研究")
	return super.placement(type, cell, player)


func salvage(id: int, confirmed := false) -> Dictionary:
	if id == core.id:
		return failure("基地核心不可回收")
	return super.salvage(id, confirmed)


func recipe_available(id: String) -> bool:
	return id in Integrated.RECIPES


func near_sample() -> bool:
	return false


func near_passage(_id: String) -> bool:
	return false


func configure_output(id: int, port_id: String, item: String, enabled: bool) -> Dictionary:
	if id != core.id or not near_entity(core):
		return failure("请走到基地核心两格内")
	if not core.outputs.has(port_id):
		return failure("无效的核心输出口")
	if (enabled or not item.is_empty()) and (item not in item_ids or item == "crust_sample"):
		return failure("请选择可运输的物品")
	var output: Dictionary = core.outputs[port_id]
	if item != output.item or (enabled and not output.enabled):
		output.cooldown_ticks = Integrated.COOLDOWN_TICKS
	output.item = item
	output.enabled = enabled
	revision += 1
	return success()
