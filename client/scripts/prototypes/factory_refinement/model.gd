extends "res://scripts/factory/discovery_model.gd"

## Demo-only topology adapter. Never passed to a save store or codec.
const RADIUS := 6.0


func covers(a: Dictionary, b: Dictionary) -> bool:
	return Grid.center(a).distance_to(Grid.center(b)) <= RADIUS + 1e-9 \
		and Grid.line_open(Grid.center(a), Grid.center(b), discovery.passages)


func rebuild_wireless() -> void:
	var nodes: Array[Dictionary] = []
	for e in entities:
		if Grid.is_node(e):
			nodes.append(e)
	nodes.sort_custom(func(a, b): return a.id < b.id)
	power_links.clear()
	for i in nodes.size():
		for j in range(i + 1, nodes.size()):
			if covers(nodes[i], nodes[j]):
				power_links.append([nodes[i].id, nodes[j].id])
	revision += 1
	grid.rebuild(self)
	for e in entities:
		if not DiscoveryRules.POWER.has(e.type):
			continue
		var best := 0
		var best_powered := false
		var best_distance := INF
		for node in nodes:
			if not covers(node, e):
				continue
			var powered: bool = grid.groups[grid.membership[node.id]].capacity_kw > 0
			var distance := Grid.center(node).distance_squared_to(Grid.center(e))
			if best == 0 or (powered and not best_powered) or (powered == best_powered and distance < best_distance):
				best = node.id
				best_powered = powered
				best_distance = distance
		e.power_node_id = best
	# Force the allocator to observe new consumer memberships as one transaction.
	revision += 1


func place(type: String, cell: Vector2i, dir := 0, player: Variant = null) -> Dictionary:
	var result := super.place(type, cell, dir, player)
	if result.ok:
		rebuild_wireless()
	return result


func salvage(id: int, confirmed := false) -> Dictionary:
	var result := super.salvage(id, confirmed)
	if result.ok:
		rebuild_wireless()
	return result


func set_source_enabled(id: int, enabled: bool) -> Dictionary:
	var result := super.set_source_enabled(id, enabled)
	if result.ok:
		rebuild_wireless()
	return result


func feedback(e: Dictionary) -> Dictionary:
	var result := super.feedback(e)
	if result.get("power", "") == "未接线":
		result.power = "不在供电覆盖内"
		if result.label == "未接线":
			result.label = result.power
	return result
