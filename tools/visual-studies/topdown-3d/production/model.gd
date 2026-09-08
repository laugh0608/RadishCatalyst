extends RefCounted

## Isolated Web-equivalent production rules. No client, save or power services.
const STEP := 0.05
const DIRS := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const CATALOG := {
	"collector": {"name": "晶体采集器", "w": 2, "d": 2, "output": Vector2i(1, 1)},
	"reactor": {"name": "基础反应器", "w": 3, "d": 3, "input": Vector2i(0, 2), "output": Vector2i(2, 2)},
	"storage": {"name": "终端仓", "w": 2, "d": 2, "input": Vector2i(0, 1)},
	"belt": {"name": "传送带", "w": 1, "d": 1},
}
const REFERENCE := {
	"collector": Vector2i(-8, -1), "reactor": Vector2i(-1, -2),
	"storage": Vector2i(6, -1), "belt": Vector2i(-6, 0),
}
const INITIAL_KITS := {"collector": 1, "reactor": 1, "storage": 1, "belt": 24}
var entities: Array[Dictionary] = []
var kits := INITIAL_KITS.duplicate()
var bag := {"crystal": 0, "catalyst": 0}
var next_id := 1
var revision := 0
var time := 0.0
var remainder := 0.0
var generated := 0
var completed := 0
var delivered := 0
var delivered_batch := 0
var lesson := {"first_delivery": false, "cut": false, "starved": false,
	"recovered": false, "batch_at_starve": 0}


static func success(extra: Dictionary = {}) -> Dictionary:
	return {"ok": true}.merged(extra)


static func failure(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}


func entity_at(cell: Vector2i) -> Dictionary:
	for e in entities:
		var def: Dictionary = CATALOG[e.type]
		if cell.x >= e.x and cell.x < e.x + def.w and cell.y >= e.z and cell.y < e.z + def.d:
			return e
	return {}


func by_id(id: int) -> Dictionary:
	for e in entities:
		if e.id == id:
			return e
	return {}


static func port(e: Dictionary, role: String) -> Dictionary:
	if not CATALOG[e.type].has(role):
		return {}
	var offset: Vector2i = CATALOG[e.type][role]
	return {"x": e.x + offset.x, "z": e.z + offset.y, "dx": -1 if role == "input" else 1, "dz": 0}


func placement(type: String, cell: Vector2i, actor: Variant = null) -> Dictionary:
	if not CATALOG.has(type):
		return failure("请选择有效构件和格位")
	if kits[type] < 1:
		return failure("构件已用完；可拆回已有构件重新放置")
	var def: Dictionary = CATALOG[type]
	if cell.x < -10 or cell.x + def.w > 10 or cell.y < -6 or cell.y + def.d > 7:
		return failure("超出可建造厂坪")
	if type == "collector" and cell != REFERENCE.collector:
		return failure("采集器需要完整覆盖青色晶体矿点")
	for x in range(cell.x, cell.x + def.w):
		for z in range(cell.y, cell.y + def.d):
			if not entity_at(Vector2i(x, z)).is_empty():
				return failure("这里已有设备或传送带")
	if actor != null and type != "belt":
		if actor.x > cell.x - 0.3 and actor.x < cell.x + def.w + 0.3 and actor.z > cell.y - 0.3 and actor.z < cell.y + def.d + 0.3:
			return failure("工程师站在这里，先移开再放置")
	return success()


func place(type: String, cell: Vector2i, dir := 0, actor: Variant = null) -> Dictionary:
	var valid := placement(type, cell, actor)
	if not valid.ok:
		return valid
	if dir < 0 or dir > 3:
		return failure("传送带方向无效")
	var e := {"id": next_id, "type": type, "x": cell.x, "z": cell.y, "dir": dir if type == "belt" else 0}
	next_id += 1
	match type:
		"collector": e.merge({"buffer": 0, "progress": 0.0})
		"reactor": e.merge({"input": 0, "output": 0, "processing": false, "progress": 0.0})
		"storage": e.merge({"crystal": 0, "catalyst": 0})
		"belt": e.merge({"cargo": "", "progress": 0.0, "entry": -DIRS[dir], "cursor": 0})
	entities.append(e)
	kits[type] -= 1
	revision += 1
	return success({"entity": e})


## Follow the dominant axis first, stopping at the first obstacle (no auto-routing).
func extend_path(path: Array[Vector2i], target: Vector2i) -> Dictionary:
	var next: Array[Vector2i] = path.duplicate()
	var back := next.find(target)
	if back >= 0:
		return success({"path": next.slice(0, back + 1)})
	if next.is_empty():
		var valid := placement("belt", target)
		if valid.ok:
			next.append(target)
		return valid.merged({"path": next})
	var cursor: Vector2i = next.back()
	var axes := [0, 1] if absi(target.x - cursor.x) >= absi(target.y - cursor.y) else [1, 0]
	for axis in axes:
		while cursor[axis] != target[axis]:
			cursor[axis] += signi(target[axis] - cursor[axis])
			var valid := placement("belt", cursor)
			if not valid.ok:
				return valid.merged({"path": next})
			if next.size() >= kits.belt:
				return failure("传送带构件不足；松开铺下已预览部分").merged({"path": next})
			var previous := next.find(cursor)
			if previous >= 0:
				next = next.slice(0, previous + 1)
			else:
				next.append(cursor)
	return success({"path": next})


static func path_directions(path: Array[Vector2i], dir: int) -> Array[int]:
	var directions: Array[int] = []
	for i in path.size():
		if i + 1 < path.size():
			directions.append(DIRS.find(path[i + 1] - path[i]))
		elif i > 0:
			directions.append(DIRS.find(path[i] - path[i - 1]))
		else:
			directions.append(dir)
	return directions


func place_path(path: Array[Vector2i], dir := 0) -> Dictionary:
	if path.is_empty():
		return failure("拖动经过空格后再松开铺设")
	if path.size() > kits.belt:
		return failure("传送带构件不足")
	var seen := {}
	for cell in path:
		var valid := placement("belt", cell)
		if not valid.ok:
			return valid
		if seen.has(cell):
			return failure("路径不能重复经过同一格")
		seen[cell] = true
	var directions := path_directions(path, dir)
	for direction in directions:
		if direction < 0 or direction > 3:
			return failure("路径必须逐格正交相连")
	# Validation precedes all mutations, including kit deduction.
	var placed: Array[Dictionary] = []
	for i in path.size():
		placed.append(place("belt", path[i], directions[i]).entity)
	return success({"entities": placed})


static func contents(e: Dictionary) -> Dictionary:
	match e.type:
		"collector": return {"crystal": e.buffer, "catalyst": 0}
		"reactor": return {"crystal": e.input + (2 if e.processing else 0), "catalyst": e.output}
		"storage": return {"crystal": e.crystal, "catalyst": e.catalyst}
	return {"crystal": 1 if e.cargo == "crystal" else 0, "catalyst": 1 if e.cargo == "catalyst" else 0}


func salvage(id: int) -> Dictionary:
	var e := by_id(id)
	if e.is_empty():
		return failure("构件已经不存在")
	var items := contents(e)
	if bag.crystal + bag.catalyst + items.crystal + items.catalyst > 200:
		return failure("回收箱已满；先把物品放入设备或终端仓")
	var had_input := false
	for r in entities:
		if r.type == "reactor" and input_connected(r):
			had_input = true
	bag.crystal += items.crystal
	bag.catalyst += items.catalyst
	kits[e.type] += 1
	entities.erase(e)
	revision += 1
	if e.type == "belt" and lesson.first_delivery and had_input:
		for r in entities:
			if r.type == "reactor" and not input_connected(r):
				lesson.cut = true
	return success({"items": items, "type": e.type})


func deposit(id: int) -> Dictionary:
	var e := by_id(id)
	if e.is_empty():
		return failure("设备已经不存在")
	var amount := 0
	for item in ["crystal", "catalyst"]:
		var room := 0
		if e.type == "collector" and item == "crystal":
			room = 50 - e.buffer
		if e.type == "reactor" and item == "crystal":
			room = 2 - e.input
		if e.type == "storage":
			room = 200 - e.crystal - e.catalyst
		var n := mini(bag[item], room)
		if n <= 0:
			continue
		bag[item] -= n
		amount += n
		if e.type == "collector":
			e.buffer += n
		elif e.type == "reactor":
			e.input += n
		else:
			e[item] += n
	return success({"amount": amount}) if amount > 0 else failure("没有可投入的物品，或设备缓冲已满")


func rotate(id: int) -> Dictionary:
	var e := by_id(id)
	if e.is_empty() or e.type != "belt":
		return failure("只有传送带可以转向")
	if not e.cargo.is_empty():
		return failure("带上有货物；请拆回货物和构件后重新放置")
	e.dir = (e.dir + 1) % 4
	e.entry = -DIRS[e.dir]
	revision += 1
	return success()


func grid_index() -> Dictionary:
	var result := {}
	for e in entities:
		for x in range(e.x, e.x + CATALOG[e.type].w):
			for z in range(e.z, e.z + CATALOG[e.type].d):
				result[Vector2i(x, z)] = e
	return result


static func accepts_belt(target: Dictionary, direction: Vector2i) -> bool:
	return target.dir != (DIRS.find(direction) + 2) % 4


func belt_inputs(b: Dictionary) -> Array[int]:
	var inputs: Array[int] = []
	for side in 4:
		if side == b.dir:
			continue
		var source := entity_at(Vector2i(b.x, b.z) + DIRS[side])
		if source.is_empty():
			continue
		if source.type == "belt":
			if Vector2i(source.x, source.z) + DIRS[source.dir] == Vector2i(b.x, b.z):
				inputs.append(side)
		else:
			var p := port(source, "output")
			if not p.is_empty() and p.x + p.dx == b.x and p.z + p.dz == b.z:
				inputs.append(side)
	return inputs


static func sink_accepts(e: Dictionary, source: Dictionary, item: String) -> bool:
	var p := port(e, "input")
	if p.is_empty() or source.x != p.x - 1 or source.z != p.z or source.dir != 0:
		return false
	if e.type == "reactor":
		return item == "crystal" and e.input < 2
	return e.type == "storage" and e.crystal + e.catalyst < 200


func advance(seconds: float) -> void:
	assert(is_finite(seconds) and seconds >= 0 and seconds <= 120, "Advance must be 0–120 seconds")
	remainder += seconds
	while remainder >= STEP - 0.000000001:
		_step(STEP)
		remainder -= STEP


func _step(dt: float) -> void:
	time += dt
	for e in entities:
		if e.type == "collector" and e.buffer < 50:
			e.progress += dt
			if e.progress >= 1 - 0.000000001:
				e.buffer += 1
				generated += 1
				e.progress -= 1
		if e.type == "reactor":
			if not e.processing and e.input >= 2 and e.output == 0:
				e.input -= 2
				e.processing = true
				e.progress = 0.0
			if e.processing:
				e.progress += dt
				if e.progress >= 10 - 0.000000001:
					e.output += 1
					completed += 1
					e.output_batch = completed
					e.processing = false
					e.progress = 0.0
	var map := grid_index()
	var belts: Array[Dictionary] = []
	var occupied := {}
	var contenders := {}
	for e in entities:
		if e.type == "belt":
			belts.append(e)
			if not e.cargo.is_empty():
				occupied[e.id] = true
	for b in belts:
		if b.cargo.is_empty():
			continue
		b.progress = minf(1, b.progress + dt)
		if b.progress < 1 - 0.000000001:
			continue
		var direction: Vector2i = DIRS[b.dir]
		var next: Dictionary = map.get(Vector2i(b.x, b.z) + direction, {})
		if next.is_empty():
			continue
		if next.type == "belt":
			if occupied.has(next.id) or not accepts_belt(next, direction):
				continue
			if not contenders.has(next.id):
				contenders[next.id] = []
			contenders[next.id].append(b)
		elif sink_accepts(next, b, b.cargo):
			if next.type == "reactor":
				next.input += 1
			else:
				next[b.cargo] += 1
				if b.cargo == "catalyst":
					delivered += 1
					delivered_batch = maxi(delivered_batch, b.get("batch", 0))
					lesson.first_delivery = true
			b.cargo = ""
			b.progress = 0.0
	for target_id in contenders:
		var target := by_id(target_id)
		var list: Array = contenders[target_id]
		list.sort_custom(func(a, b): return a.id < b.id)
		var winner: Dictionary = list[0]
		for b in list:
			if b.id > target.cursor:
				winner = b
				break
		target.cargo = winner.cargo
		target.batch = winner.get("batch", 0)
		target.progress = 0.0
		target.entry = Vector2i(winner.x - target.x, winner.z - target.z)
		target.cursor = winner.id
		winner.cargo = ""
		winner.progress = 0.0
	for e in entities:
		var item := ""
		if e.type == "collector" and e.buffer > 0:
			item = "crystal"
		if e.type == "reactor" and e.output > 0:
			item = "catalyst"
		if item.is_empty():
			continue
		var p := port(e, "output")
		var b: Dictionary = map.get(Vector2i(p.x + 1, p.z), {})
		if b.is_empty() or b.type != "belt" or not b.cargo.is_empty() or b.dir == 2:
			continue
		b.cargo = item
		b.batch = e.get("output_batch", 0) if e.type == "reactor" else 0
		b.progress = 0.0
		b.entry = Vector2i(-1, 0)
		if e.type == "collector":
			e.buffer -= 1
		else:
			e.output -= 1
	for r in entities:
		if r.type != "reactor":
			continue
		if lesson.cut and not lesson.starved and not r.processing and r.input < 2 and r.output == 0 and not input_connected(r):
			lesson.starved = true
			lesson.batch_at_starve = completed
		if lesson.starved and not lesson.recovered and input_connected(r) and delivered_batch > lesson.batch_at_starve:
			lesson.recovered = true


func input_connected(reactor: Dictionary) -> bool:
	var map := grid_index()
	var goal := port(reactor, "input")
	for source in entities:
		if source.type != "collector":
			continue
		var p := port(source, "output")
		var b: Dictionary = map.get(Vector2i(p.x + 1, p.z), {})
		var direction := Vector2i(1, 0)
		var visited := {}
		while not b.is_empty() and b.type == "belt" and not visited.has(b.id) and accepts_belt(b, direction):
			visited[b.id] = true
			direction = DIRS[b.dir]
			if b.x + direction.x == goal.x and b.z + direction.y == goal.z and direction.x == 1:
				return true
			b = map.get(Vector2i(b.x, b.z) + direction, {})
	return false


func belt_blocked(b: Dictionary) -> bool:
	if b.cargo.is_empty() or b.progress < 1 - 0.000000001:
		return false
	var direction: Vector2i = DIRS[b.dir]
	var next := entity_at(Vector2i(b.x, b.z) + direction)
	if next.is_empty():
		return true
	if next.type == "belt":
		return not next.cargo.is_empty() or not accepts_belt(next, direction)
	return not sink_accepts(next, b, b.cargo)


func feedback(e: Dictionary) -> Dictionary:
	match e.type:
		"collector": return {"kind": "blocked", "label": "缓冲已满"} if e.buffer >= 50 else {"kind": "running", "label": "正在采集"}
		"reactor":
			if e.processing:
				return {"kind": "running", "label": "加工中"}
			return {"kind": "blocked", "label": "等待出料"} if e.output > 0 else {"kind": "waiting", "label": "缺少晶体"}
		"storage": return {"kind": "blocked", "label": "仓储已满"} if e.crystal + e.catalyst >= 200 else {"kind": "ready", "label": "接收物料"}
	if belt_blocked(e):
		return {"kind": "blocked", "label": "前方堵塞"}
	return {"kind": "ready", "label": "等待物料"} if e.cargo.is_empty() else {"kind": "running", "label": "运输中"}


func material_balance() -> Dictionary:
	var crystal: int = bag.crystal
	var catalyst: int = bag.catalyst
	for e in entities:
		var c := contents(e)
		crystal += c.crystal
		catalyst += c.catalyst
	return {"generated": generated, "crystal": crystal, "catalyst": catalyst, "equivalent": crystal + 2 * catalyst}


func blocked_for_actor(x: float, z: float) -> bool:
	if absf(x) > 11.4 or absf(z) > 8.2:
		return true
	for e in entities:
		if e.type == "belt":
			continue
		var distance := Vector2(maxf(maxf(e.x - x, 0), x - e.x - CATALOG[e.type].w), maxf(maxf(e.z - z, 0), z - e.z - CATALOG[e.type].d))
		if distance.length() < 0.29:
			return true
	return false


func move_actor(actor: Dictionary, dx: float, dz: float, dt: float) -> void:
	assert(is_finite(dx) and is_finite(dz) and is_finite(dt) and dt >= 0)
	actor.moving = false
	var direction := Vector2(dx, dz)
	if direction.is_zero_approx():
		return
	direction = direction.normalized()
	var distance := 3.3 * minf(dt, 0.06)
	var steps := maxi(1, ceili(distance / 0.06))
	for i in steps:
		var x: float = actor.x + direction.x * distance / steps
		var z: float = actor.z + direction.y * distance / steps
		if not blocked_for_actor(x, actor.z):
			actor.x = x
			actor.moving = true
		if not blocked_for_actor(actor.x, z):
			actor.z = z
			actor.moving = true
	if actor.moving:
		actor.angle = atan2(dx, dz)
		actor.walk += distance
