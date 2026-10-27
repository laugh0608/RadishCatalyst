extends "res://scripts/factory/expansion_model.gd"

const Energy := preload("res://data/factory/energy_rules.gd")
const EnergyStatistics := preload("res://scripts/factory/energy_statistics.gd")
var energy_origin := {}
var standby_power := false


func _init(with_standby := false) -> void:
	super()
	standby_power = with_standby
	supply_id = Energy.SUPPLY_ID
	kits[Energy.GENERATOR] = 0
	recipes.merge(Energy.RECIPES)
	item_ids.append(Energy.CELL)
	admission_items.append(Energy.CELL)
	completed_by_recipe[Energy.RECIPE] = 0
	assembly_costs[Energy.GENERATOR] = 3
	assembly_counts[Energy.GENERATOR] = 0
	statistics = EnergyStatistics.new(standby_power)


func placement(type: String, cell: Vector2i, player: Variant = null) -> Dictionary:
	if type == Energy.GENERATOR and not first_expansion_placed:
		return failure("先制造并放下第二台精炼炉，再建设电芯能源线")
	return super.placement(type, cell, player)


func _place_entity(type: String, cell: Vector2i, dir: int) -> Dictionary:
	var result := super._place_entity(type, cell, dir)
	if DiscoveryRules.POWER.has(type): result.entity.enabled = true
	if type == Energy.GENERATOR:
		result.entity.merge({"enabled": true, "fuel": {}, "remaining_kj": 0.0})
	return result


func recipe_available(id: String) -> bool:
	return first_expansion_placed if id == Energy.RECIPE else super.recipe_available(id)


func assemble(type: String) -> Dictionary:
	if type == Energy.GENERATOR and not first_expansion_placed:
		return failure("先完成第二台精炼炉，解锁电芯发电机")
	return super.assemble(type)


func work_spec(e: Dictionary) -> Dictionary:
	var spec := super.work_spec(e)
	if not e.enabled: spec.ready = false
	spec.standby_kw = Energy.STANDBY_KW[e.type] if standby_power and e.enabled else 0.0
	return spec


func set_device_enabled(id: int, enabled: bool) -> Dictionary:
	var e := by_id(id)
	if not DiscoveryRules.POWER.has(e.get("type", "")) and e.get("type", "") != Energy.GENERATOR:
		return failure("请选择用电设备或电芯发电机")
	if not near_entity(e): return failure("请走到设备两格内启停")
	if e.enabled == enabled: return failure("设备已经处于所选状态")
	e.enabled = enabled
	revision += 1
	if e.type == Energy.GENERATOR: _refresh_automatic_power()
	return success()


func input_room(e: Dictionary, item: String, manual := false) -> int:
	if e.type == Energy.GENERATOR:
		return Energy.FUEL_CAPACITY - Items.count(e.fuel) if item == Energy.CELL else 0
	return super.input_room(e, item, manual)


func _receive_item(e: Dictionary, item: String) -> void:
	if e.type == Energy.GENERATOR:
		assert(item == Energy.CELL and input_room(e, item) > 0)
		Items.add(e.fuel, item, 1)
	else:
		super._receive_item(e, item)


func transfer(id: int, item: String, putting: bool, all_items: bool) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != Energy.GENERATOR: return super.transfer(id, item, putting, all_items)
	if item != Energy.CELL or not near_entity(e): return failure("请走到发电机两格内取放完整电芯；余能不能取回")
	var room := input_room(e, item, true) if putting else 200 - Items.count(bag)
	var available: int = bag.get(item, 0) if putting else e.fuel.get(item, 0)
	var amount := mini(mini(room, available), Energy.FUEL_CAPACITY if all_items else 1)
	if amount <= 0: return failure("没有可转移的完整电芯，或容量不足")
	Items.add(bag, item, -amount if putting else amount)
	Items.add(e.fuel, item, amount if putting else -amount)
	revision += 1
	return success({"amount": amount})


func _commit_power(allocation: Dictionary, dt: float) -> void:
	for id in allocation.generators:
		var e := by_id(id)
		var spent: float = allocation.generators[id] * dt
		if spent <= 0: continue
		var total: float = e.remaining_kj + Energy.CELL_KJ * e.fuel.get(Energy.CELL, 0)
		assert(spent <= total + 1e-9)
		# Roundoff at the last fraction of a fixed step cannot make negative energy.
		spent = minf(spent, total)
		if spent > e.remaining_kj:
			assert(e.fuel.get(Energy.CELL, 0) > 0)
			Items.add(e.fuel, Energy.CELL, -1)
			e.remaining_kj += Energy.CELL_KJ
			statistics.event("consumed", Energy.CELL, 1)
			statistics.fuel_event("cells_activated", 1)
		e.remaining_kj -= spent
		assert(e.remaining_kj >= 0 and e.remaining_kj <= Energy.CELL_KJ)


func salvage(id: int, confirmed := false) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != Energy.GENERATOR: return super.salvage(id, confirmed)
	if not near_entity(e): return failure("请走到设备两格内回收")
	var lost: float = e.remaining_kj
	if not confirmed and (lost > 0 or not connections(id).is_empty()):
		return failure("回收将断开连接并损失当前余能 %.1f kJ（最多 7,200 kJ）；完整电芯退回。可先停用再拆。" % lost).merged({"needs_confirmation": true, "connections": connections(id)})
	var result := super.salvage(id, confirmed)
	if result.ok and lost > 0: statistics.fuel_event("discarded_kj", lost)
	return result


func extra_consumption() -> Dictionary:
	return {Energy.CELL: statistics.totals.cells_activated} if statistics.totals.cells_activated > 0 else {}


func energy_balance() -> Dictionary:
	var remaining := 0.0
	for e in entities:
		if e.type == Energy.GENERATOR: remaining += e.remaining_kj
	return {"activated": statistics.totals.cells_activated, "supplied_kj": statistics.totals.cell_supplied_kj,
		"discarded_kj": statistics.totals.discarded_kj, "remaining_kj": remaining}


func feedback(e: Dictionary) -> Dictionary:
	if e.type == Energy.GENERATOR:
		var state := power_state()
		var group: Dictionary = grid.groups[grid.membership[e.id]]
		var label: String
		if not e.enabled: label = "已停用 · 保留余能，仍可导通"
		elif group.request_kw == 0: label = "同网没有实际负载，电芯未消耗"
		elif group.request_kw <= group.base_capacity_kw: label = "基础电源已满足需求，电芯未消耗"
		elif e.remaining_kj == 0 and e.fuel.is_empty(): label = "燃料耗尽，基础供电仍在" if group.base_capacity_kw > 0 else "燃料耗尽，同网没有基础供电"
		else: label = "按缺口供电 · %.1f kW" % state.sources[e.id]
		return {"kind": "running" if state.sources[e.id] > 0 else "waiting", "label": label}
	var result := super.feedback(e)
	if DiscoveryRules.POWER.has(e.type) and not e.enabled:
		result.kind = "ready"
		result.label = "手动停机 · 保留进度，被动物流继续"
		result.production = result.label
		result.power = "已停机 · 0 kW"
	return result


func item_known(item: String) -> bool:
	return first_expansion_placed if item == Energy.CELL else super.item_known(item)
