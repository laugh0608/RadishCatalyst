extends "res://scripts/factory/expansion_model.gd"

const Integrated := preload("res://data/factory/integrated_rules.gd")
const Progression := preload("res://data/factory/integrated_progression.gd")
const BurnStats := preload("res://scripts/factory/fixed_burn_statistics.gd")
const Energy := preload("res://data/factory/energy_rules.gd")
var core: Dictionary
var researched := {Progression.BASE: true}
var research_nodes := Progression.NODES


func _init() -> void:
	super()
	map_id = Integrated.MAP_ID
	supply_id = Integrated.SUPPLY_ID
	kits = Integrated.SUPPLY.duplicate()
	grid.fixed_burn = true
	statistics = BurnStats.new()
	kits[Energy.GENERATOR] = 0
	assembly_costs[Energy.GENERATOR] = 3
	assembly_counts[Energy.GENERATOR] = 0
	recipes.merge(Energy.RECIPES)
	completed_by_recipe[Energy.RECIPE] = 0
	item_ids.append(Energy.CELL)
	admission_items.append(Energy.CELL)
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
	if kits.has(type) and not device_unlocked(type):
		return failure("该构件尚未研究")
	return super.placement(type, cell, player)


func _place_entity(type: String, cell: Vector2i, dir: int) -> Dictionary:
	var result := super._place_entity(type, cell, dir)
	if DiscoveryRules.POWER.has(type):
		result.entity.enabled = true
	if type == Energy.GENERATOR:
		result.entity.merge({"enabled": false, "fuel": {}, "burn_remaining_ticks": 0})
	return result


func work_spec(e: Dictionary) -> Dictionary:
	var spec := super.work_spec(e)
	if not e.enabled:
		spec.ready = false
	spec.standby_kw = Energy.STANDBY_KW[e.type] if e.enabled else 0.0
	return spec


func set_device_enabled(id: int, enabled: bool) -> Dictionary:
	var e := by_id(id)
	if not DiscoveryRules.POWER.has(e.get("type", "")) and e.get("type", "") != Energy.GENERATOR:
		return failure("请选择用电设备或电芯发电机")
	if not near_entity(e):
		return failure("请走到设备两格内启停")
	if e.enabled == enabled:
		return failure("设备已经处于所选状态")
	e.enabled = enabled
	revision += 1
	if e.type == Energy.GENERATOR:
		_refresh_automatic_power()
	return success()


func _commit_power(allocation: Dictionary, dt: float) -> void:
	assert(is_equal_approx(dt, STEP))
	for id in allocation.generators:
		if allocation.generators[id] == 0.0:
			continue
		var e := by_id(id)
		if e.burn_remaining_ticks == 0:
			Items.add(e.fuel, Energy.CELL, -1)
			e.burn_remaining_ticks = Integrated.BURN_TICKS
			statistics.event("consumed", Energy.CELL, 1)
			statistics.fuel_event("cells_activated", 1)
		e.burn_remaining_ticks -= 1


func salvage(id: int, confirmed := false) -> Dictionary:
	if id == core.id:
		return failure("基地核心不可回收")
	var e := by_id(id)
	if e.get("type", "") != Energy.GENERATOR:
		return super.salvage(id, confirmed)
	if not near_entity(e):
		return failure("请走到发电机两格内回收")
	if e.enabled:
		return failure("请先停用发电机")
	var lost: float = e.burn_remaining_ticks * STEP * Energy.GENERATOR_KW
	var attached := connections(id)
	if not confirmed and (lost > 0 or not attached.is_empty()):
		return failure("回收损失 %.1f kJ 余能并断开 %d 条连接。完整电芯退回。" % [lost, attached.size()]).merged({"needs_confirmation": true, "connections": attached})
	var result := super.salvage(id, confirmed)
	if result.ok and lost > 0:
		statistics.fuel_event("discarded_kj", lost)
	return result


func energy_balance() -> Dictionary:
	var remaining := 0.0
	for e in entities:
		if e.type == Energy.GENERATOR:
			remaining += e.burn_remaining_ticks * STEP * Energy.GENERATOR_KW
	return {"activated": statistics.totals.cells_activated, "released_kj": statistics.totals.fuel_released_kj,
		"discarded_kj": statistics.totals.discarded_kj, "remaining_kj": remaining}


func feedback(e: Dictionary) -> Dictionary:
	if e.type == Integrated.CORE:
		return {"kind": "ready", "label": "基础供电 %.0f kW" % Integrated.BASE_KW}
	if e.type == Energy.GENERATOR:
		if not e.enabled:
			return {"kind": "waiting", "label": "已停用 · 保留燃烧余时，仍可导通"}
		var state := power_state()
		if state.sources[e.id] <= 0:
			return {"kind": "waiting", "label": "燃料耗尽 · 等待完整电芯"}
		var group: Dictionary = grid.groups[grid.membership[e.id]]
		var released := 0.0
		for id in group.generators:
			released += state.sources[id]
		return {"kind": "running", "label": "固定燃烧 · 同网当前有弃能" if released > group.request_kw + 1e-9 else "固定燃烧 · 当前释能 %.0f kW" % state.sources[e.id]}
	var result := super.feedback(e)
	if DiscoveryRules.POWER.has(e.type) and not e.enabled:
		return {"kind": "ready", "label": "手动停机 · 保留进度，被动物流继续",
			"production": "手动停机 · 保留进度，被动物流继续", "power": "已停机 · 0 kW"}
	return result


func device_research(type: String) -> String:
	for id in research_nodes:
		if type in research_nodes[id].devices:
			return id
	return ""


func device_unlocked(type: String) -> bool:
	return researched.has(device_research(type))


func recipe_available(id: String) -> bool:
	if id == "solvent_trial" and (not discovery.sample_taken or discovery.trial_completed):
		return false
	if id == "rich_catalyst" and not discovery.passages.inner:
		return false
	for node in researched:
		if id in research_nodes[node].recipes:
			return true
	return false


func item_known(item: String) -> bool:
	return recipe_available(Energy.RECIPE) if item == Energy.CELL else super.item_known(item)


func missing_stock(cost: Dictionary) -> Dictionary:
	var missing := {}
	for item in cost:
		var count: int = cost[item] - core.items.get(item, 0)
		if count > 0:
			missing[item] = count
	return missing


func _missing_research(required: Array) -> PackedStringArray:
	var missing := PackedStringArray()
	for id in required:
		if not researched.has(id):
			missing.append(research_nodes[id].name)
	return missing


func research_fact_missing(id: String) -> String:
	return "先在外矿道入口拾取矿壳样本" if research_nodes[id].sample and not discovery.sample_taken else ""


func research_status(id: String) -> Dictionary:
	if not near_entity(core):
		return failure("请走到基地核心两格内")
	if not research_nodes.has(id):
		return failure("未知研究")
	if researched.has(id):
		return failure("已完成研究")
	var node: Dictionary = research_nodes[id]
	if core.level < node.level:
		return failure("需要核心 II")
	var missing := _missing_research(node.requires)
	if not missing.is_empty():
		return failure("先研究 " + "、".join(missing))
	var fact_missing := research_fact_missing(id)
	if not fact_missing.is_empty():
		return failure(fact_missing)
	if not Items.contains(core.items, node.cost):
		return failure("核心缺少 " + Items.describe(missing_stock(node.cost)))
	return success()


func research(id: String) -> Dictionary:
	var status := research_status(id)
	if not status.ok:
		return status
	_consume_core(research_nodes[id].cost)
	researched[id] = true
	revision += 1
	return success()


func upgrade_status() -> Dictionary:
	if not near_entity(core):
		return failure("请走到基地核心两格内")
	if core.level != 1:
		return failure("核心已升至 II")
	var missing := _missing_research(Progression.II_REQUIRES)
	if not missing.is_empty():
		return failure("先研究 " + "、".join(missing))
	if not Items.contains(core.items, Progression.II_COST):
		return failure("核心缺少 " + Items.describe(missing_stock(Progression.II_COST)))
	return success()


func upgrade_core() -> Dictionary:
	var status := upgrade_status()
	if not status.ok:
		return status
	_consume_core(Progression.II_COST)
	core.level = 2
	revision += 1
	return success()


func assembly_status(type: String) -> Dictionary:
	if not near_entity(core):
		return failure("请走到基地核心两格内")
	if not researched.has(Progression.ASSEMBLY):
		return failure("先研究精密装配")
	if not device_unlocked(type):
		return failure("先研究此构件")
	return _assembly_quote(type, core.items, Progression.MAX_OWNED, "核心")


func assemble(type: String) -> Dictionary:
	var quote := assembly_status(type)
	return _commit_assembly(type, core.items, quote) if quote.ok else quote


func extra_consumption() -> Dictionary:
	var consumed := {}
	for id in researched:
		Items.merge(consumed, research_nodes[id].cost)
	if core.level >= 2:
		Items.merge(consumed, Progression.II_COST)
	if statistics.totals.cells_activated > 0:
		Items.add(consumed, Energy.CELL, statistics.totals.cells_activated)
	return consumed


func _consume_core(cost: Dictionary) -> void:
	Items.merge(core.items, cost, -1)
	for item in cost:
		statistics.event("consumed", item, cost[item])


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
