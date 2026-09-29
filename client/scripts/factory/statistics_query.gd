extends RefCounted

const Rules := preload("res://data/factory/discovery_rules.gd")
const Items := preload("res://scripts/factory/items.gd")


static func known_items(model: RefCounted) -> Array:
	var result := ["crystal", "catalyst"]
	if model.discovery.sample_taken:
		result.append("crust_sample")
	if model.discovery.trial_completed:
		result.append_array(["crust_solvent", "rich_crystal"])
	return result


static func materials(model: RefCounted, seconds: int) -> Dictionary:
	var window: Dictionary = model.statistics.window(seconds)
	var rows := {}
	for item in known_items(model):
		rows[item] = {"item": item, "storage": 0, "bag": model.bag.get(item, 0),
			"buffer": 0, "transit": 0, "invested": 0, "held": 0, "devices": [],
			"theory_produced": 0.0, "theory_consumed": 0.0,
			"produced": rate(window.produced.get(item, 0), window.seconds),
			"consumed": rate(window.consumed.get(item, 0), window.seconds),
			"acquired": window.acquired.get(item, 0), "points": []}
	for e in model.entities:
		var locations := {}
		var produces := {}
		var consumes := {}
		match e.type:
			"collector":
				locations.buffer = e.buffer
				produces[e.mineral] = 60.0
			"reactor":
				locations.buffer = e.input.duplicate()
				Items.merge(locations.buffer, e.output)
				locations.invested = e.invested
				if e.recipe_id != "solvent_trial" and model.recipe_available(e.recipe_id):
					var recipe: Dictionary = Rules.RECIPES[e.recipe_id]
					for item in recipe.output:
						produces[item] = recipe.output[item] * 60.0 / recipe.seconds
					for item in recipe.input:
						consumes[item] = recipe.input[item] * 60.0 / recipe.seconds
			"storage": locations.storage = e.items
			"belt": locations.transit = {e.cargo: 1} if not e.cargo.is_empty() else {}
		for item in rows:
			var row: Dictionary = rows[item]
			var present := false
			for location in locations:
				var amount: int = locations[location].get(item, 0)
				row[location] += amount
				present = present or amount > 0
			row.theory_produced += produces.get(item, 0.0)
			row.theory_consumed += consumes.get(item, 0.0)
			var related: bool = produces.has(item) or consumes.has(item)
			if e.type == "reactor":
				var recipe: Dictionary = Rules.RECIPES[e.recipe_id]
				related = related or recipe.input.has(item) or recipe.output.has(item)
			if present or related:
				row.devices.append(e.id)
	var selected: Array = model.statistics.buckets.slice(maxi(0, model.statistics.buckets.size() - seconds))
	for item in rows:
		var row: Dictionary = rows[item]
		row.held = row.storage + row.bag + row.buffer + row.transit + row.invested
		row.net = row.produced - row.consumed
		row.active = row.held > 0 or row.produced > 0 or row.consumed > 0 or row.acquired > 0
		for b in selected:
			row.points.append({"start": b.start_tick * 0.05, "seconds": b.ticks * 0.05,
				"a": b.produced.get(item, 0), "b": b.consumed.get(item, 0)})
	return {"window": window, "rows": rows}


static func rate(amount: float, seconds: float) -> float:
	return amount * 60.0 / seconds if seconds > 0 else 0.0


static func electricity(model: RefCounted, seconds: int) -> Dictionary:
	var window: Dictionary = model.statistics.window(seconds)
	var power: Dictionary = model.power_state()
	var groups: Array = []
	for i in model.grid.groups.size():
		var group: Dictionary = model.grid.groups[i]
		var devices: Array = group.nodes.duplicate()
		for id in power.devices:
			if power.devices[id].network == i:
				devices.append(id)
		groups.append({"nodes": group.nodes.duplicate(), "capacity": group.capacity_kw,
			"request": group.request_kw, "supply": group.supplied_kw,
			"deficit": maxf(0, group.request_kw - group.capacity_kw), "devices": devices})
	var unplugged := []
	for id in power.devices:
		if power.devices[id].network < 0:
			unplugged.append(id)
	var points := []
	for b in model.statistics.buckets.slice(maxi(0, model.statistics.buckets.size() - seconds)):
		points.append({"start": b.start_tick * 0.05, "seconds": b.ticks * 0.05,
			"a": b.supplied_kj, "b": b.requested_kj, "c": b.installed_kj, "d": b.deficit_kj})
	return {"window": window, "current": power, "groups": groups, "unplugged": unplugged, "points": points}
