extends "res://scripts/factory/grid_controls_model.gd"

const Buffer := Integrated.Storage
const StorageStats := preload("res://scripts/factory/grid_storage_statistics.gd")


func _init() -> void:
	super()
	supply_id = Buffer.SUPPLY_ID
	grid.storage_enabled = true
	statistics = StorageStats.new()
	research_nodes = research_nodes.merged({Buffer.TYPE: Buffer.NODE})
	kits[Buffer.TYPE] = 0
	assembly_costs[Buffer.TYPE] = Buffer.ASSEMBLY_PACKS
	assembly_counts[Buffer.TYPE] = 0


func _place_entity(type: String, cell: Vector2i, dir: int) -> Dictionary:
	var result := super._place_entity(type, cell, 0 if type == Buffer.TYPE else dir)
	if type == Buffer.TYPE:
		result.entity.merge({"enabled": true, "stored_j": 0, "power_node_id": 0})
	return result


func assembly_status(type: String) -> Dictionary:
	var quote := super.assembly_status(type)
	if not quote.ok or type != Buffer.TYPE:
		return quote
	if core.items.get(Energy.CELL, 0) < Buffer.ASSEMBLY_CELLS:
		return failure("核心缺少工业电芯 ×%d" % Buffer.ASSEMBLY_CELLS)
	quote.extra_cost = {Energy.CELL: Buffer.ASSEMBLY_CELLS}
	return quote


func assemble(type: String) -> Dictionary:
	var result := super.assemble(type)
	if result.ok and result.has("extra_cost"):
		_consume_core(result.extra_cost)
	return result


func extra_consumption() -> Dictionary:
	var consumed := super.extra_consumption()
	var cells: int = assembly_counts[Buffer.TYPE] * Buffer.ASSEMBLY_CELLS
	if cells > 0:
		Items.add(consumed, Energy.CELL, cells)
	return consumed


func _commit_power(allocation: Dictionary, dt: float) -> void:
	super._commit_power(allocation, dt)
	for id in allocation.buffers:
		by_id(id).stored_j += allocation.buffers[id].stored_delta_j


func set_device_enabled(id: int, enabled: bool) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != Buffer.TYPE:
		return super.set_device_enabled(id, enabled)
	if not near_entity(e):
		return failure("请走到储能设施两格内操作")
	if e.enabled == enabled:
		return failure("储能已经处于所选状态")
	e.enabled = enabled
	revision += 1
	return success()


func salvage(id: int, confirmed := false) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != Buffer.TYPE:
		return super.salvage(id, confirmed)
	if not near_entity(e):
		return failure("请走到储能设施两格内回收")
	if e.enabled and e.stored_j > 0:
		return failure("请先停用储能，锁定回收时将损失的电量")
	var lost: int = e.stored_j
	if lost > 0 and not confirmed:
		return failure("回收将损失 %.3f kJ 已存电量，重放时为空。" % (lost / 1000.0)).merged(
			{"needs_confirmation": true, "connections": connections(id)})
	var result := super.salvage(id, confirmed)
	if result.ok and lost > 0:
		statistics.discard_storage(lost)
	return result


func stored_joules() -> int:
	var result := 0
	for e in entities:
		if e.type == Buffer.TYPE:
			result += e.stored_j
	return result


func feedback(e: Dictionary) -> Dictionary:
	if e.type != Buffer.TYPE:
		return super.feedback(e)
	var state: Dictionary = power_state().buffers[e.id]
	var label := "等待余电或负载缺口"
	var kind := "ready"
	if not e.enabled:
		label = "已停用 · 电量保留"
	elif state.network < 0:
		label = "未接网 · 电量保留"
		kind = "blocked"
	elif state.charge_j > 0:
		label = "充电 %.1f kW" % (state.charge_j / (1000.0 * STEP))
		kind = "running"
	elif state.discharge_j > 0:
		label = "放电 %.1f kW" % (state.discharge_j / (1000.0 * STEP))
		kind = "running"
	elif e.stored_j == Buffer.CAPACITY_J:
		label = "已充满"
	return {"kind": kind, "label": label}
