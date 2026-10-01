extends "res://scripts/factory/model.gd"

const Items := preload("res://scripts/factory/items.gd")
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


## Schema 2 uses the same item maps in simulation and persistence.


func _init() -> void:
	supply_id = DiscoveryRules.SUPPLY_ID
	kits = DiscoveryRules.SUPPLY.duplicate()
	bag = {}


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
		var e: Dictionary = result.entity
		match type:
			"collector":
				e.mineral = "crystal" if cell.x < 4 else "rich_crystal"
				e.buffer = {}
			"reactor":
				e.recipe_id = "basic_catalyst"
				e.input = {}
				e.output = {}
				e.invested = {}
			"storage":
				e.erase("crystal")
				e.erase("catalyst")
				e.items = {}
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
	if e.is_empty():
		return failure("构件已经不存在")
	var items := Items.contents(e)
	if Items.count(bag) + Items.count(items) > 200:
		return failure("背包容量不足，回收未改变任何物料")
	Items.merge(bag, items)
	kits[e.type] += 1
	entities.erase(e)
	revision += 1
	rebuild_indexes()
	for pair in attached:
		power_links.erase(pair)
	for device in entities:
		if device.get("power_node_id", 0) == id:
			device.power_node_id = 0
	return success({"items": items, "type": e.type})


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
				Items.add(e.buffer, e.mineral, 1)
				generated += 1
				statistics.event("produced", e.mineral, 1)
		elif e.type == "reactor":
			var recipe: Dictionary = DiscoveryRules.RECIPES[e.recipe_id]
			if not e.processing:
				e.invested = recipe.input.duplicate()
				Items.merge(e.input, e.invested, -1)
				e.processing = true
				e.active_batch = next_batch
				next_batch += 1
			e.progress += work
			if e.progress >= recipe.seconds - 1e-9:
				e.output = recipe.output.duplicate()
				completed += 1
				e.output_batch = e.active_batch
				e.active_batch = 0
				e.processing = false
				e.progress = 0.0
				for item in e.invested:
					statistics.event("consumed", item, e.invested[item])
				for item in e.output:
					statistics.event("produced", item, e.output[item])
				e.invested.clear()
				if e.recipe_id == "solvent_trial":
					discovery.trial_completed = true
					revision += 1
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
	var production := {"kind": "ready", "label": "等待物料"}
	match e.type:
		"collector":
			production = {"kind": "blocked", "label": "缓冲已满"} if Items.count(e.buffer) >= 50 else {"kind": "running", "label": "缓冲可用，可采集"}
		"reactor":
			production = {"kind": "running", "label": "有在制，可推进"} if e.processing else {"kind": "blocked", "label": "等待取出输出"} if not e.output.is_empty() else {"kind": "running", "label": "原料齐全，可开批"} if work_spec(e).ready else {"kind": "waiting", "label": "缺少配方原料"}
		"storage":
			production = {"kind": "blocked", "label": "仓储已满"} if Items.count(e.items) >= 200 else {"kind": "ready", "label": "接收物料"}
		"belt":
			production = {"kind": "blocked", "label": "前方堵塞"} if belt_blocked(e) else {"kind": "ready", "label": "等待物料"} if e.cargo.is_empty() else {"kind": "running", "label": "运输中"}
	if e.type == "reactor" and not recipe_available(e.recipe_id) and e.output.is_empty():
		production = {"kind": "ready", "label": "试制已完成，请切换常规配方"}
	if not DiscoveryRules.POWER.has(e.type):
		return production
	var device: Dictionary = state.devices[e.id]
	var label := "未接线" if e.power_node_id == 0 else "无启用电源" if grid.groups[device.network].capacity_kw == 0 else "待机" if device.request_kw == 0 else "供电不足 · %.1f%%" % (device.fraction * 100) if device.fraction < 1 else "充分供电"
	var result: Dictionary = production.merged({"production": production.label, "power": label})
	if device.request_kw > 0 and device.fraction < 1:
		result.kind = "waiting"
		result.label = label
	return result


func blocked_for_actor(x: float, z: float) -> bool:
	for dx in [-0.29, 0.29]:
		for dz in [-0.29, 0.29]:
			if not DiscoveryRules.open_cell(Vector2i(floori(x + dx), floori(z + dz)), discovery.passages):
				return true
	return super.blocked_for_actor(x, z)


func recipe_available(id: String) -> bool:
	if id == "basic_catalyst":
		return true
	if id == "solvent_trial":
		return discovery.sample_taken and not discovery.trial_completed
	return id in ["crust_solvent", "rich_catalyst"] and discovery.trial_completed


func work_spec(e: Dictionary) -> Dictionary:
	if e.type == "collector":
		return {"ready": Items.count(e.buffer) < 50, "seconds": 1.0, "kw": 20.0}
	var recipe: Dictionary = DiscoveryRules.RECIPES[e.recipe_id]
	return {"ready": e.processing or (recipe_available(e.recipe_id) and e.output.is_empty() and Items.contains(e.input, recipe.input)), "seconds": recipe.seconds, "kw": recipe.kw}


func near_entity(e: Dictionary) -> bool:
	if e.is_empty():
		return false
	var point := Vector2(actor.x, actor.z)
	var nearest := Vector2(clampf(point.x, e.x + 0.001, e.x + CATALOG[e.type].w - 0.001), clampf(point.y, e.z + 0.001, e.z + CATALOG[e.type].d - 0.001))
	return point.distance_to(nearest) <= 2 and Grid.line_open(point, nearest, discovery.passages)


func change_recipe(id: int, recipe_id: String) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != "reactor" or not near_entity(e):
		return failure("请走到反应器两格内操作")
	if not recipe_available(recipe_id):
		return failure("配方尚未掌握，或唯一试制已经完成")
	if e.processing:
		return failure("仍有在制，请先完成或取消本批")
	if not e.input.is_empty() or not e.output.is_empty():
		return failure("请先取空输入和输出，再切换配方")
	if e.recipe_id == recipe_id:
		return failure("已经选择此配方")
	e.recipe_id = recipe_id
	revision += 1
	return success()


func cancel_batch(id: int) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") != "reactor" or not near_entity(e):
		return failure("请走到反应器两格内取消")
	if not e.processing:
		return failure("没有在制批次")
	if Items.count(bag) + Items.count(e.invested) > 200:
		return failure("背包放不下完整投入，本批保持不变")
	Items.merge(bag, e.invested)
	e.invested.clear()
	e.processing = false
	e.progress = 0.0
	e.active_batch = 0
	revision += 1
	return success()


func input_room(e: Dictionary, item: String, manual := false) -> int:
	if item not in DiscoveryRules.ITEMS or (item == "crust_sample" and not manual):
		return 0
	match e.type:
		"collector":
			return 50 - Items.count(e.buffer) if item == e.mineral else 0
		"reactor":
			if not recipe_available(e.recipe_id):
				return 0
			return maxi(0, int(DiscoveryRules.RECIPES[e.recipe_id].input.get(item, 0)) - int(e.input.get(item, 0)))
		"storage": return 200 - Items.count(e.items)
	return 0


## Explicit commands cap to both inventories; failures never partially mutate.
func transfer(id: int, item: String, putting: bool, all_items: bool) -> Dictionary:
	var e := by_id(id)
	if item not in DiscoveryRules.ITEMS or not near_entity(e):
		return failure("请走到设备两格内，且位于同一可达区域")
	if e.type not in ["collector", "reactor", "storage"]:
		return failure("此构件没有可操作的库存")
	var inventories: Array = [e.buffer] if e.type == "collector" else [e.input, e.output] if e.type == "reactor" else [e.items]
	var room := input_room(e, item, true) if putting else 200 - Items.count(bag)
	var available := int(bag.get(item, 0)) if putting else 0
	if not putting:
		for inventory in inventories:
			available += int(inventory.get(item, 0))
	var amount := mini(mini(room, available), 200 if all_items else 1)
	if amount <= 0:
		return failure("没有可转移物品、容量不足，或当前配方不接收此物品")
	if putting:
		Items.add(bag, item, -amount)
		Items.add(inventories[0], item, amount)
	else:
		var left := amount
		for inventory in inventories:
			var n := mini(left, int(inventory.get(item, 0)))
			Items.add(inventory, item, -n)
			left -= n
		Items.add(bag, item, amount)
		if e.type == "reactor" and e.output.is_empty():
			e.output_batch = 0
	revision += 1
	return success({"amount": amount})


func deposit(_id: int) -> Dictionary:
	return failure("勘探工厂请按物品明确取放")


func survey_sample(pickup := false) -> Dictionary:
	var point := Vector2(actor.x, actor.z)
	if point.distance_to(DiscoveryRules.SAMPLE) > 2 or not Grid.line_open(point, DiscoveryRules.SAMPLE, discovery.passages):
		return failure("请走到外矿道样本两格内调查")
	if pickup and discovery.sample_taken:
		return failure("唯一样本已经拾取")
	if not discovery.surveyed:
		discovery.surveyed = true
		revision += 1
	if not pickup:
		return success()
	if Items.count(bag) >= 200:
		return failure("背包已满，调查已记录；样本仍留在原地")
	discovery.sample_taken = true
	Items.add(bag, "crust_sample", 1)
	statistics.event("acquired", "crust_sample", 1)
	revision += 1
	return success()


func open_passage(id: String) -> Dictionary:
	if not DiscoveryRules.PASSAGES.has(id):
		return failure("矿道不存在")
	if discovery.passages[id]:
		return failure("矿道已经打通")
	if id == "inner" and not discovery.passages.outer:
		return failure("请先打通外矿道")
	var rule: Dictionary = DiscoveryRules.PASSAGES[id]
	var point := Vector2(actor.x, actor.z)
	var target := Vector2(rule.x - 0.001, clampf(point.y, -1.999, 1.999))
	if point.x >= rule.x or point.distance_to(target) > 2 or not Grid.line_open(point, target, discovery.passages):
		return failure("请靠近矿道西侧入口两格内使用")
	if not discovery.trial_completed or bag.get("crust_solvent", 0) < rule.cost:
		return failure("背包需要 %d 份解壳剂" % rule.cost)
	Items.add(bag, "crust_solvent", -rule.cost)
	statistics.event("consumed", "crust_solvent", rule.cost)
	discovery.passages[id] = true
	revision += 1
	return success()


func _sink_accepts(e: Dictionary, source: Dictionary, item: String) -> bool:
	var p := port(e, "input")
	return not p.is_empty() and source.x == p.x - 1 and source.z == p.z and source.dir == 0 and input_room(e, item) > 0


func _receive_item(e: Dictionary, item: String) -> void:
	Items.add(e.input if e.type == "reactor" else e.items, item, 1)


func _output_item(e: Dictionary) -> String:
	if e.type == "collector" and not e.buffer.is_empty():
		return e.mineral
	if e.type == "reactor" and not e.output.is_empty():
		return e.output.keys()[0]
	return ""


func _take_output(e: Dictionary, item: String) -> void:
	Items.add(e.buffer if e.type == "collector" else e.output, item, -1)
	if e.type == "reactor" and e.output.is_empty():
		e.output_batch = 0


func material_balance() -> Dictionary:
	var held := bag.duplicate()
	for e in entities:
		Items.merge(held, Items.contents(e))
	var equivalent := 0
	for item in held:
		equivalent += held[item] * DiscoveryRules.WEIGHTS[item]
	return {"held": held, "equivalent": equivalent, "crystal": held.get("crystal", 0), "catalyst": held.get("catalyst", 0), "generated": generated}
