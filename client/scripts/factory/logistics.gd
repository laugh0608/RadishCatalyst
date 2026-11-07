extends RefCounted

## Shared factory: one-hop snapshot transport. This module also owns UI port diagnostics.
const DIRS := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const OUTPUT_NAMES := ["前", "左", "右"]
const INPUT_NAMES := ["后", "左", "右"]
const BELT_CONFLICT := "普通带只能接一路，请用汇合器"
const Integrated := preload("res://data/factory/integrated_rules.gd")
const Items := preload("res://scripts/factory/items.gd")
const Expansion := preload("res://data/factory/expansion_rules.gd")
const Admission := preload("res://scripts/factory/admission.gd")
const Timed := Integrated.Timed


static func transport(e: Dictionary) -> bool:
	return e.get("type", "") in ["belt", "splitter", "merger", "admission_gate", Timed.TYPE]


static func ports(model: RefCounted, e: Dictionary, role: String) -> Array[Dictionary]:
	if e.type == Integrated.CORE:
		return Integrated.ports(Vector2i(e.x, e.z), role)
	var result: Array[Dictionary] = []
	if Expansion.PORTS.has(e.type):
		for coordinates in Expansion.PORTS[e.type][role]:
			result.append({"x": e.x + coordinates[0], "z": e.z + coordinates[1], "dx": coordinates[2], "dz": coordinates[3], "index": result.size(), "name": "副" if role == "output" and result.size() == 1 else "主" if role == "output" else str(result.size() + 1)})
		return result
	var dir: int = e.get("dir", 0)
	var sides: Array = []
	if e.type in ["admission_gate", Timed.TYPE]:
		sides = [2] if role == "input" else [0]
	elif e.type == "splitter":
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


static func belt_input_conflict(model: RefCounted, target: Dictionary) -> bool:
	if not model.single_inlet_belts or target.type != "belt":
		return false
	var sides: Array = model.input_sides[target.id] if target.has("id") else model._find_belt_inputs(target)
	return sides.size() > 1


static func output_connection(model: RefCounted, output: Dictionary) -> Dictionary:
	var target: Dictionary = model.entity_at(Vector2i(output.x + output.dx, output.z + output.dz))
	if target.is_empty():
		return {"ok": false, "reason": "未连接"}
	var input := receiving_port(model, target, output)
	if input.is_empty():
		return {"ok": false, "reason": "方向不匹配"}
	if model.single_inlet_belts and target.type == "belt":
		var sides: Array = model.input_sides[target.id]
		var incoming := DIRS.find(Vector2i(input.dx, input.dz))
		if sides.size() > 1 or (sides.size() == 1 and incoming not in sides):
			return {"ok": false, "reason": BELT_CONFLICT, "conflict": true}
	return {"ok": true, "reason": "已接通", "target": target, "output": output, "input": input}


static func input_connection(model: RefCounted, target: Dictionary, input: Dictionary) -> Dictionary:
	var source: Dictionary = model.entity_at(Vector2i(input.x + input.dx, input.z + input.dz))
	if source.is_empty():
		return {"ok": false, "reason": "未连接"}
	if source.type == Integrated.CORE and target.type != "belt":
		return {"ok": false, "reason": "核心出料首格需要传送带"}
	for output in ports(model, source, "output"):
		if receiving_port(model, target, output) == input:
			if belt_input_conflict(model, target):
				return {"ok": false, "reason": BELT_CONFLICT}
			return {"ok": true, "reason": "已接通", "source": source, "output": output}
	return {"ok": false, "reason": "方向不匹配"}


static func output_status(model: RefCounted, source: Dictionary, output: Dictionary, item: String) -> Dictionary:
	if source.type == Timed.TYPE:
		var reason := dispatch_reason(source)
		if not reason.is_empty():
			return {"ok": false, "reason": reason}
	var connection := output_connection(model, output)
	if not connection.ok:
		return connection
	var target: Dictionary = connection.target
	if source.type == Integrated.CORE and target.type != "belt":
		return {"ok": false, "reason": "首格需要传送带"}
	if item == "crust_sample":
		return {"ok": false, "reason": "样本不可自动运输"}
	if target.type == "admission_gate":
		var reason := Admission.receive_reason(target, item)
		if not reason.is_empty(): return {"ok": false, "reason": reason}
	if target.type == Timed.TYPE:
		if not target.active:
			return {"ok": false, "reason": "节拍器未启用"}
		if not item.is_empty() and item != target.filter_item:
			return {"ok": false, "reason": "节拍器只收 " + Items.NAMES[target.filter_item]}
	if transport(target):
		if not target.cargo.is_empty():
			return {"ok": false, "reason": "目标已满"}
	elif not item.is_empty() and model.input_room(target, item) <= 0:
		var accepts: bool = target.type in ["storage", Integrated.CORE] or (target.type == "cell_generator" and item == "industrial_cell") or (target.type in model.process_types and model.recipe_available(target.recipe_id) and model.recipes[target.recipe_id].input.has(item))
		return {"ok": false, "reason": "目标已满" if accepts else "目标不收该物品"}
	return connection.merged({"reason": "可接收", "source": source}, true)


static func step(model: RefCounted, dt: float) -> void:
	var requests := {}
	# Generate every option before committing any transfer; no newly vacated slot
	# can be used in this step. Producers and transport compete in the same rounds.
	for source in model.entities:
		if source.type == Integrated.CORE:
			_request_core_outputs(model, source, requests)
			continue
		var item: String
		if transport(source):
			if source.cargo.is_empty() or (source.type == Timed.TYPE and not source.active):
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
			var output_item: String = item if transport(source) else model._output_item_at(source, output)
			if output_item.is_empty() or output_item == "crust_sample": continue
			var option := output_status(model, source, output, output_item)
			if option.ok:
				option.item = output_item
				option.batch = source.get("batch", 0) if transport(source) else source.get("output_batch", 0)
				options.append(option)
		if not options.is_empty():
			requests[source.id] = options
	var assigned_sources := {}
	var assigned_targets := {}
	var transfers: Array[Dictionary] = []
	# Both reservations use untouched step-start inventory; transfers commit last.
	var core_inputs := {}
	var core_input_ports := {}
	var core_outputs := {}
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
			option.request_key = source_id
			if not contenders.has(option.target.id):
				contenders[option.target.id] = []
			contenders[option.target.id].append(option)
		var proposed_core_outputs: Array[Dictionary] = []
		for target_id in contenders:
			var list: Array = contenders[target_id]
			var target: Dictionary = list[0].target
			if target.type == Integrated.CORE:
				_reserve_core_inputs(model, list, core_inputs, core_input_ports, assigned_sources, transfers)
				continue
			list.sort_custom(func(a, b): return _priority(a, target) < _priority(b, target))
			if list[0].source.type == Integrated.CORE:
				proposed_core_outputs.append(list[0])
		var approved := _reserve_core_outputs(proposed_core_outputs, core_outputs)
		for target_id in contenders:
			var list: Array = contenders[target_id]
			if list[0].target.type == Integrated.CORE:
				continue
			for winner in list:
				if winner.source.type == Integrated.CORE and not approved.has(winner.request_key):
					continue
				transfers.append(winner)
				assigned_sources[winner.request_key] = true
				assigned_targets[target_id] = true
				break
	# Ordinary sources and targets occur once. Core reservations are per port.
	transfers.sort_custom(func(a, b): return a.source.id < b.source.id)
	for transfer in transfers:
		_commit(model, transfer)


static func _request_core_outputs(model: RefCounted, core: Dictionary, requests: Dictionary) -> void:
	for port in ports(model, core, "output"):
		var config: Dictionary = core.outputs[port.id]
		if not config.enabled:
			continue
		config.cooldown_ticks = maxi(0, config.cooldown_ticks - 1)
		if config.cooldown_ticks > 0 or core.items.get(config.item, 0) == 0:
			continue
		var option := output_status(model, core, port, config.item)
		if option.ok:
			option.item = config.item
			option.batch = 0
			requests[port.id] = [option]


static func _core_order(a: Dictionary, b: Dictionary, cursors: Dictionary, role: String, count: int) -> bool:
	if a.item != b.item:
		return a.item < b.item
	var cursor: int = cursors.get(a.item, 0)
	var rank_a: int = (a[role].index - cursor + count) % count
	var rank_b: int = (b[role].index - cursor + count) % count
	return rank_a < rank_b if rank_a != rank_b else a.source.id < b.source.id


static func _reserve_core_outputs(candidates: Array[Dictionary], counts: Dictionary) -> Dictionary:
	if candidates.is_empty():
		return {}
	var core: Dictionary = candidates[0].source
	var cursors: Dictionary = core.output_cursors
	candidates.sort_custom(func(a, b): return _core_order(a, b, cursors, "output", 4))
	var approved := {}
	for move in candidates:
		var used: int = counts.get(move.item, 0)
		if used >= core.items.get(move.item, 0):
			continue
		counts[move.item] = used + 1
		cursors[move.item] = (move.output.index + 1) % 4
		approved[move.request_key] = true
	return approved


static func _reserve_core_inputs(model: RefCounted, candidates: Array, counts: Dictionary,
		ports_used: Dictionary, sources_used: Dictionary, transfers: Array[Dictionary]) -> void:
	var core: Dictionary = candidates[0].target
	var cursors: Dictionary = core.input_cursors
	candidates.sort_custom(func(a, b): return _core_order(a, b, cursors, "input", 12))
	for move in candidates:
		var used: int = counts.get(move.item, 0)
		if ports_used.has(move.input.id) or used >= model.input_room(core, move.item):
			continue
		ports_used[move.input.id] = true
		counts[move.item] = used + 1
		cursors[move.item] = (move.input.index + 1) % 12
		sources_used[move.request_key] = true
		transfers.append(move)


static func core_output_feedback(model: RefCounted, core: Dictionary, port: Dictionary) -> String:
	var config: Dictionary = core.outputs[port.id]
	if config.item.is_empty(): return "未配置"
	if not config.enabled: return "已关闭"
	if core.items.get(config.item, 0) == 0: return "缺货"
	var status := output_status(model, core, port, config.item)
	if not status.ok: return status.reason
	if config.cooldown_ticks > 0: return "冷却 %.2f 秒" % (config.cooldown_ticks * model.STEP)
	return "可出料"


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
		if source.type == "admission_gate" and source.quota_mode == "quota":
			source.quota_used += 1
		if source.type == Timed.TYPE:
			source.sent += 1
		source.cargo = ""
		source.batch = 0
		source.progress = 0.0
		if source.type != "belt":
			source.entry = -DIRS[source.dir]
		if source.type == "splitter":
			source.output_cursor = (move.output.index + 1) % 3
	elif source.type == Integrated.CORE:
		Items.add(source.items, move.item, -1)
		source.outputs[move.output.id].cooldown_ticks = Integrated.COOLDOWN_TICKS
	else:
		model._take_output(source, move.item)
		if source.type in Expansion.PROCESSORS:
			source.output_cursor = (move.output.index + 1) % ports(model, source, "output").size()
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
	if belt_input_conflict(model, e):
		return {"kind": "blocked", "label": BELT_CONFLICT}
	if e.type == Timed.TYPE:
		var reason := dispatch_reason(e)
		if not reason.is_empty():
			return {"kind": "waiting", "label": reason}
	if e.cargo.is_empty():
		if e.type == "admission_gate":
			var input: Dictionary = ports(model, e, "input")[0]
			var connection := input_connection(model, e, input)
			var incoming: Dictionary = connection.source if connection.ok else {}
			var item: String = ""
			if not incoming.is_empty():
				item = incoming.cargo if transport(incoming) else model._output_item_at(incoming, connection.output)
			var reason := Admission.receive_reason(e, item)
			if not reason.is_empty(): return {"kind": "waiting" if reason == "已停止接收" else "blocked", "label": reason}
			if not connection.ok: return {"kind": "blocked" if connection.reason == "方向不匹配" else "waiting", "label": connection.reason}
		return {"kind": "ready", "label": "等待来料"}
	if e.progress < 1.0 - 1e-9:
		return {"kind": "running", "label": "已停止接收 · 正在排空" if e.type == "admission_gate" and not e.accepting else "运输中"}
	var reasons: Array[String] = []
	for p in ports(model, e, "output"):
		var state := output_status(model, e, p, e.cargo)
		if state.ok:
			return {"kind": "waiting", "label": "本步等待其他来料先行"}
		if state.reason not in reasons:
			reasons.append(state.reason)
	return {"kind": "blocked", "label": "全部出口未连接" if reasons == ["未连接"] else " / ".join(reasons)}


static func dispatch_reason(e: Dictionary) -> String:
	if e.filter_item.is_empty():
		return "待设置节拍"
	if not e.active:
		return "节拍已停用 · 相位与货物保留"
	if e.phase_ticks >= e.window_s * Timed.TICKS_PER_SECOND:
		return "等待下一放行窗口"
	if e.sent >= e.quota:
		return "本窗额度已用完"
	return ""


static func port_text(model: RefCounted, e: Dictionary) -> String:
	var lines := PackedStringArray()
	var item: String = e.get("cargo", model._output_item(e))
	for role in ["input", "output"]:
		for p in ports(model, e, role):
			var message := "未连接"
			if role == "output":
				message = output_status(model, e, p, item if transport(e) else model._output_item_at(e, p)).reason
			else:
				var connection := input_connection(model, e, p)
				message = "已连接 #%d" % connection.source.id if connection.ok else connection.reason
			lines.append("%s%s：%s" % [p.name, "输入" if role == "input" else "输出", message])
	return "\n".join(lines)


static func preview_text(model: RefCounted, e: Dictionary) -> String:
	# Empty construction ghosts only describe geometry, never reserve cargo or capacity.
	var groups := PackedStringArray()
	for role in ["input", "output"]:
		var lines := PackedStringArray()
		for p in ports(model, e, role):
			var connection := input_connection(model, e, p) if role == "input" else output_connection(model, p)
			lines.append("%s%s：%s" % [p.name, "输入" if role == "input" else "输出", connection.reason])
		if not lines.is_empty():
			groups.append(" · ".join(lines))
	return "\n".join(groups)
