extends RefCounted

## Schema 4: one-hop snapshot transport. This module also owns UI port diagnostics.
const DIRS := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const OUTPUT_NAMES := ["前", "左", "右"]
const INPUT_NAMES := ["后", "左", "右"]


static func transport(e: Dictionary) -> bool:
	return e.get("type", "") in ["belt", "splitter", "merger"]


static func ports(model: RefCounted, e: Dictionary, role: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dir: int = e.get("dir", 0)
	var sides: Array = []
	if e.type == "splitter":
		sides = [2] if role == "input" else [0, 3, 1]
	elif e.type == "merger" or e.type == "belt":
		sides = [2, 3, 1] if role == "input" else [0]
	else:
		var p: Dictionary = model.port(e, role)
		if not p.is_empty():
			result.append(p.merged({"index": 0, "name": ""}))
		return result
	for i in sides.size():
		var side: Vector2i = DIRS[(dir + sides[i]) % 4]
		result.append({"x": e.x, "z": e.z, "dx": side.x, "dz": side.y,
			"index": i, "name": (INPUT_NAMES if role == "input" else OUTPUT_NAMES)[i]})
	return result


static func receiving_port(model: RefCounted, target: Dictionary, output: Dictionary) -> Dictionary:
	for p in ports(model, target, "input"):
		if p.x == output.x + output.dx and p.z == output.z + output.dz and p.dx == -output.dx and p.dz == -output.dz:
			return p
	return {}


static func output_status(model: RefCounted, source: Dictionary, output: Dictionary, item: String) -> Dictionary:
	var target: Dictionary = model.entity_at(Vector2i(output.x + output.dx, output.z + output.dz))
	if target.is_empty():
		return {"ok": false, "reason": "未连接"}
	var input := receiving_port(model, target, output)
	if input.is_empty():
		return {"ok": false, "reason": "方向不匹配"}
	if item == "crust_sample":
		return {"ok": false, "reason": "样本不可自动运输"}
	if transport(target):
		if not target.cargo.is_empty():
			return {"ok": false, "reason": "目标已满"}
	elif not item.is_empty() and model.input_room(target, item) <= 0:
		var accepts: bool = target.type == "storage" or (target.type == "reactor" and model.recipe_available(target.recipe_id) and model.DiscoveryRules.RECIPES[target.recipe_id].input.has(item))
		return {"ok": false, "reason": "目标已满" if accepts else "目标不收该物品"}
	return {"ok": true, "reason": "可接收", "source": source, "target": target, "output": output, "input": input}


static func step(model: RefCounted, dt: float) -> void:
	var requests := {}
	# Generate every option before committing any transfer; no newly vacated slot
	# can be used in this step. Producers and transport compete in the same rounds.
	for source in model.entities:
		var item: String
		if transport(source):
			if source.cargo.is_empty():
				continue
			source.progress = minf(1.0, source.progress + dt)
			if source.progress < 1.0 - 1e-9:
				continue
			item = source.cargo
		else:
			item = model._output_item(source)
		if item.is_empty() or item == "crust_sample":
			continue
		var outputs := ports(model, source, "output")
		var options: Array[Dictionary] = []
		var cursor: int = source.get("output_cursor", 0)
		for offset in outputs.size():
			var output: Dictionary = outputs[(cursor + offset) % outputs.size()]
			var option := output_status(model, source, output, item)
			if option.ok:
				option.item = item
				option.batch = source.get("batch", 0) if transport(source) else source.get("output_batch", 0)
				options.append(option)
		if not options.is_empty():
			requests[source.id] = options
	var assigned_sources := {}
	var assigned_targets := {}
	var transfers: Array[Dictionary] = []
	for round_index in 3:
		var contenders := {}
		for source_id in requests:
			if assigned_sources.has(source_id):
				continue
			var options: Array = requests[source_id]
			while not options.is_empty() and assigned_targets.has(options[0].target.id):
				options.pop_front()
			if options.is_empty():
				continue
			var option: Dictionary = options.pop_front()
			if not contenders.has(option.target.id):
				contenders[option.target.id] = []
			contenders[option.target.id].append(option)
		for target_id in contenders:
			var list: Array = contenders[target_id]
			var target: Dictionary = list[0].target
			list.sort_custom(func(a, b): return _priority(a, target) < _priority(b, target))
			var winner: Dictionary = list[0]
			transfers.append(winner)
			assigned_sources[winner.source.id] = true
			assigned_targets[target_id] = true
	# Each source and target occurs once. Snapshot occupancy also ensures a
	# transport entity cannot be both a sender and a receiver in this transaction.
	transfers.sort_custom(func(a, b): return a.source.id < b.source.id)
	for transfer in transfers:
		_commit(model, transfer)


static func _priority(request: Dictionary, target: Dictionary) -> int:
	if target.type == "merger":
		return (request.input.index - target.input_cursor + 3) % 3
	if target.type == "belt":
		# Rank first by whether the source follows the saved ID, then by ID.
		return request.source.id if request.source.id > target.cursor else 9007199254740992 + request.source.id
	return request.source.id


static func _commit(model: RefCounted, move: Dictionary) -> void:
	var source: Dictionary = move.source
	var target: Dictionary = move.target
	if transport(source):
		source.cargo = ""
		source.batch = 0
		source.progress = 0.0
		if source.type != "belt":
			source.entry = -DIRS[source.dir]
		if source.type == "splitter":
			source.output_cursor = (move.output.index + 1) % 3
	else:
		model._take_output(source, move.item)
	if transport(target):
		target.cargo = move.item
		target.batch = move.batch
		target.progress = 0.0
		target.entry = Vector2i(move.input.dx, move.input.dz)
		if target.type == "merger":
			target.input_cursor = (move.input.index + 1) % 3
		elif target.type == "belt":
			target.cursor = source.id
	else:
		model._receive_item(target, move.item)
		if target.type == "storage":
			model._record_delivery(move.item)
			if move.item == "catalyst":
				model.delivered += 1
				model.delivered_batch = maxi(model.delivered_batch, move.batch)


static func feedback(model: RefCounted, e: Dictionary) -> Dictionary:
	if e.cargo.is_empty():
		return {"kind": "ready", "label": "等待来料"}
	if e.progress < 1.0 - 1e-9:
		return {"kind": "running", "label": "运输中"}
	var reasons: Array[String] = []
	for p in ports(model, e, "output"):
		var state := output_status(model, e, p, e.cargo)
		if state.ok:
			return {"kind": "waiting", "label": "本步等待其他来料先行"}
		if state.reason not in reasons:
			reasons.append(state.reason)
	return {"kind": "blocked", "label": "全部出口未连接" if reasons == ["未连接"] else " / ".join(reasons)}


static func port_text(model: RefCounted, e: Dictionary) -> String:
	var lines := PackedStringArray()
	var item: String = e.get("cargo", model._output_item(e))
	for role in ["input", "output"]:
		for p in ports(model, e, role):
			var message := "未连接"
			if role == "output":
				message = output_status(model, e, p, item).reason
			else:
				var source: Dictionary = model.entity_at(Vector2i(p.x + p.dx, p.z + p.dz))
				if not source.is_empty():
					message = "方向不匹配"
					for output in ports(model, source, "output"):
						if not receiving_port(model, e, output).is_empty():
							message = "已连接 #%d" % source.id
			lines.append("%s%s：%s" % [p.name, "输入" if role == "input" else "输出", message])
	return "\n".join(lines)
