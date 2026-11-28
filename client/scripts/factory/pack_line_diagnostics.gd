extends RefCounted

const Logistics := preload("res://scripts/factory/logistics.gd")


static func missing_inputs(model: RefCounted, press: Dictionary) -> Dictionary:
	var missing := {}
	for item in model.recipes.construction_assembly.input:
		var needed: int = model.recipes.construction_assembly.input[item] - press.input.get(item, 0)
		if needed > 0:
			missing[item] = needed
	return missing


## Walk back from this press only. A closed gate can drain its current item,
## but cannot promise more of the same item from farther upstream.
static func has_incoming(model: RefCounted, press: Dictionary, item: String) -> bool:
	var pending: Array[Dictionary] = [press]
	var seen := {int(press.id): true}
	while not pending.is_empty():
		var device: Dictionary = pending.pop_back()
		for port in Logistics.ports(model, device, "input"):
			var connection := Logistics.input_connection(model, device, port)
			if not connection.ok:
				continue
			var source: Dictionary = connection.source
			if seen.has(source.id) or not Logistics.transport(source):
				continue
			seen[source.id] = true
			if source.cargo == item:
				return true
			if source.type == "admission_gate" and not Logistics.Admission.receive_reason(source.merged({"cargo": ""}, true), item).is_empty():
				continue
			if not source.cargo.is_empty() and source.progress >= 1.0 - 1e-9 and not _blocked_output(model, source).is_empty():
				continue
			pending.append(source)
	return false


## Follow actual backpressure through occupied slots. Moving cargo or a free
## arbitration opportunity can clear on the next step without player action.
static func output_obstruction(model: RefCounted, press: Dictionary) -> Dictionary:
	if not press.output.has("construction_pack"):
		return {}
	return _blocked_output(model, press)


static func _blocked_output(model: RefCounted, source: Dictionary) -> Dictionary:
	var pending: Array[Dictionary] = [source]
	var visited := {int(source.id): true}
	var block := {}
	while not pending.is_empty():
		var device: Dictionary = pending.pop_back()
		var item: String = device.get("cargo", "construction_pack")
		var outputs := Logistics.ports(model, device, "output")
		var connected := false
		for port in outputs:
			var status := Logistics.output_status(model, device, port, item)
			if status.ok:
				return {}
			var connection := Logistics.output_connection(model, port)
			if not connection.ok:
				if outputs.size() == 1 and block.is_empty():
					block = {"device": device, "reason": "出口" + status.reason}
				continue
			connected = true
			var target: Dictionary = connection.target
			if not Logistics.transport(target) or target.cargo.is_empty() or status.reason != "目标已满":
				if block.is_empty():
					block = {"device": target, "reason": status.reason}
				continue
			if target.progress < 1.0 - 1e-9:
				return {}
			if not visited.has(target.id):
				visited[target.id] = true
				pending.append(target)
		if not connected and block.is_empty():
			block = {"device": device, "reason": Logistics.feedback(model, device).label}
	return block if not block.is_empty() else {"device": source, "reason": "下游环路被货物占满"}
