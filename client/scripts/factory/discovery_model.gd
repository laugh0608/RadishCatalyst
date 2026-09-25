extends "res://scripts/factory/model.gd"

const Grid := preload("res://scripts/factory/power_grid.gd")
const Statistics := preload("res://scripts/factory/statistics.gd")
var power_links: Array = []
var discovery := {"surveyed": false, "sample_taken": false, "trial_completed": false, "passages": {"outer": false, "inner": false}}
var statistics := Statistics.new()
var statistics_ui := {"window_seconds": 60, "favorites": []}
var grid := Grid.new()
var power := {}
var power_revision := -1
var power_time := -1.0


## D2-A runtime supports only basic_catalyst; codec blocks D2-B content states.


func _init() -> void:
	supply_id = DiscoveryRules.SUPPLY_ID
	kits = DiscoveryRules.SUPPLY.duplicate()


func ore_sites() -> Array[Vector2i]:
	return DiscoveryRules.ore_sites()


func placement(type: String, cell: Vector2i, player: Variant = null) -> Dictionary:
	var valid := super.placement(type, cell, player)
	if not valid.ok:
		return valid
	for x in range(cell.x, cell.x + CATALOG[type].w):
		for z in range(cell.y, cell.y + CATALOG[type].d):
			if not DiscoveryRules.open_cell(Vector2i(x, z), discovery.passages):
				return failure("矿区尚未开放，不能穿过矿壳建设")
	return success()


func place(type: String, cell: Vector2i, dir := 0, player: Variant = null) -> Dictionary:
	var result := super.place(type, cell, dir, player)
	if result.ok:
		if DiscoveryRules.POWER.has(type):
			result.entity.power_node_id = 0
		if type == "power_source":
			result.entity.enabled = true
	return result


func connect_power(node_id: int, target_id: int) -> Dictionary:
	var valid := Grid.connection(self, node_id, target_id)
	if not valid.ok:
		return valid
	var target := by_id(target_id)
	if Grid.is_node(target):
		var pair := [mini(node_id, target_id), maxi(node_id, target_id)]
		if pair in power_links:
			return failure("两节点已经连接")
		power_links.append(pair)
		power_links.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	else:
		if target.power_node_id == node_id:
			return failure("设备已经接入此节点")
		target.power_node_id = node_id
	revision += 1
	return success()


func disconnect_power(a_id: int, b_id: int) -> Dictionary:
	var a := by_id(a_id)
	var b := by_id(b_id)
	if a.is_empty() or b.is_empty():
		return failure("连接端点不存在")
	var pair := [mini(a_id, b_id), maxi(a_id, b_id)]
	if pair in power_links:
		power_links.erase(pair)
	elif b.get("power_node_id", 0) == a_id:
		b.power_node_id = 0
	elif a.get("power_node_id", 0) == b_id:
		a.power_node_id = 0
	else:
		return failure("没有这条连接")
	revision += 1
	return success()


func set_source_enabled(id: int, enabled: bool) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != "power_source":
		return failure("请选择封装电源")
	if e.enabled == enabled:
		return failure("电源已经处于所选状态")
	e.enabled = enabled
	revision += 1
	return success()


func connections(id: int) -> Array:
	var result: Array = []
	for pair in power_links:
		if id in pair:
			result.append(pair.duplicate())
	for e in entities:
		if e.get("power_node_id", 0) == id or (e.id == id and e.get("power_node_id", 0) != 0):
			result.append([e.power_node_id, e.id])
	return result


func salvage(id: int, confirmed := false) -> Dictionary:
	var e := by_id(id)
	var attached := connections(id)
	if Grid.is_node(e) and not attached.is_empty() and not confirmed:
		return failure("回收将断开 %d 条连接，请确认" % attached.size()).merged({"needs_confirmation": true, "connections": attached})
	var result := super.salvage(id)
	if result.ok:
		for pair in attached:
			power_links.erase(pair)
		for device in entities:
			if device.get("power_node_id", 0) == id:
				device.power_node_id = 0
	return result


func power_state() -> Dictionary:
	if power_revision != revision or power_time != time:
		power = grid.allocate(self, STEP)
		power_revision = revision
		power_time = time
	return power


func _step(dt: float) -> void:
	var allocation := grid.allocate(self, dt)
	statistics.begin_step(allocation, dt)
	time = statistics.ticks * STEP
	for e in entities:
		var work: float = allocation.work.get(e.id, 0.0)
		if work <= 0:
			continue
		if e.type == "collector":
			e.progress += work
			if e.progress >= 1 - 1e-9:
				e.progress = 0.0
				e.buffer += 1
				generated += 1
				statistics.event("produced", "crystal", 1)
		elif e.type == "reactor":
			if not e.processing:
				e.input -= 2
				e.processing = true
				e.active_batch = next_batch
				next_batch += 1
			e.progress += work
			if e.progress >= 10 - 1e-9:
				e.output = 1
				completed += 1
				e.output_batch = e.active_batch
				e.active_batch = 0
				e.processing = false
				e.progress = 0.0
				statistics.event("consumed", "crystal", 2)
				statistics.event("produced", "catalyst", 1)
	_logistics(dt)
	statistics.end_step()


func _record_delivery(item: String) -> void:
	statistics.event("delivered", item, 1)


func feedback(e: Dictionary) -> Dictionary:
	var state := power_state()
	if e.type == "power_source":
		return {"kind": "ready" if e.enabled else "waiting", "label": "启用 · 120 kW" if e.enabled else "已关闭 · 仍可导通"}
	if e.type == "power_junction":
		return {"kind": "ready", "label": "被动配电节点"}
	var production := super.feedback(e)
	var condition: String = production.label
	if e.type == "collector" and e.buffer < 50:
		condition = "缓冲可用，可采集"
	elif e.type == "reactor" and (e.processing or (e.input >= 2 and e.output == 0)):
		condition = "有在制，可推进" if e.processing else "原料齐全，可开批"
	if not DiscoveryRules.POWER.has(e.type):
		return production
	var device: Dictionary = state.devices[e.id]
	var label := "未接线" if e.power_node_id == 0 else "无启用电源" if grid.groups[device.network].capacity_kw == 0 else "待机" if device.request_kw == 0 else "供电不足 · %.1f%%" % (device.fraction * 100) if device.fraction < 1 else "充分供电"
	if device.request_kw > 0 and device.fraction < 1:
		return {"kind": "waiting", "label": label, "production": condition, "power": label}
	return production.merged({"production": condition, "power": label})


func blocked_for_actor(x: float, z: float) -> bool:
	for dx in [-0.29, 0.29]:
		for dz in [-0.29, 0.29]:
			if not DiscoveryRules.open_cell(Vector2i(floori(x + dx), floori(z + dz)), discovery.passages):
				return true
	return super.blocked_for_actor(x, z)
