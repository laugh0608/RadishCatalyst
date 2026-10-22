extends RefCounted

## Read-only frame observations. An event lies in (previous_tick, current_tick].
## Sampling gaps above one second invalidate event accounting; no inferred catch-up.
const Layout := preload("res://scripts/checks/factory_engineering_layout.gd")
const Items := preload("res://scripts/factory/items.gd")
var model: RefCounted
var devices: Array[Dictionary] = []
var events: Array[Dictionary] = []
var density: Array[Dictionary] = []
var errors: Array[String] = []
var previous_tick := 0
var start_tick := 0
var max_gap_ticks := 0
var max_store := 0
var initial_completed := 0
var observed_completed := 0
var initial_delivered := 0
var observed_delivered := 0


func _init(value: RefCounted) -> void:
	model = value
	previous_tick = model.statistics.ticks
	start_tick = previous_tick
	initial_completed = model.completed
	initial_delivered = delivery_count()
	for index in 20:
		var ids := Layout.ids(model, index)
		for name in ["catalyst", "solvent", "upper-store", "lower-store"]:
			var entity: Dictionary = model.by_id(ids[name])
			devices.append({"cell": index, "name": name, "id": entity.id,
				"previous": state(entity), "count": 0, "last_lower_tick": start_tick,
				"max_gap_ticks": 0})


func state(entity: Dictionary) -> int:
	return int(entity.active_batch) if entity.type == "reactor" else Items.count(entity.items)


func reject(reason: String) -> void:
	if not errors.has(reason): errors.append(reason)


func delivery_count() -> int:
	var total := 0
	for amount in model.statistics.totals.delivered.values(): total += int(amount)
	return total


func observe() -> void:
	var tick: int = model.statistics.ticks
	if tick == previous_tick: return
	var gap := tick - previous_tick
	max_gap_ticks = maxi(max_gap_ticks, gap)
	if gap <= 0 or gap > 20: reject("observation interval outside (0, 1] seconds")
	if model.entities.size() != 1280: reject("engineering entity count changed")
	for row in devices:
		var entity: Dictionary = model.by_id(row.id)
		if entity.is_empty():
			reject("observed device removed")
			continue
		var current := state(entity)
		var amount := 0
		if entity.type == "reactor":
			if row.previous > 0 and current != row.previous: amount = 1
			observed_completed += amount
		else:
			amount = current - int(row.previous)
			if amount < 0: reject("warehouse inventory decreased")
			max_store = maxi(max_store, current)
			observed_delivered += amount
		if amount > 0:
			row.count += amount
			row.max_gap_ticks = maxi(row.max_gap_ticks, tick - int(row.last_lower_tick))
			row.last_lower_tick = previous_tick
			events.append({"id": row.id, "from_tick": previous_tick, "to_tick": tick, "amount": amount})
		row.previous = current
	# A cancellation or a missed completion must never look like real work.
	if observed_completed != model.completed - initial_completed: reject("per-device completions disagree with model total")
	if observed_delivered != delivery_count() - initial_delivered: reject("warehouse arrivals disagree with delivery total")
	if tick / 20 != previous_tick / 20:
		var sample := {"tick": tick, "running": 0, "waiting": 0, "blocked": 0,
			"belts_occupied": 0, "attachments_occupied": 0, "warehouses_full": 0}
		for entity in model.entities:
			if entity.type in ["reactor", "collector"]:
				var kind: String = model.feedback(entity).kind
				if sample.has(kind): sample[kind] += 1
			elif entity.type == "storage":
				if Items.count(entity.items) >= 200: sample.warehouses_full += 1
			elif entity.has("cargo") and not entity.cargo.is_empty():
				sample["belts_occupied" if entity.type == "belt" else "attachments_occupied"] += 1
		var power: Dictionary = model.power_state()
		sample.request_kw = power.request_kw
		sample.deficit_kw = power.deficit_kw
		density.append(sample)
	previous_tick = tick


func report() -> Dictionary:
	observe()
	var rows := devices.duplicate(true)
	var maximum := 0
	for row in rows:
		row.max_gap_ticks = maxi(row.max_gap_ticks, previous_tick - int(row.last_lower_tick))
		maximum = maxi(maximum, row.max_gap_ticks)
	return {"start_tick": start_tick, "end_tick": previous_tick, "devices": rows,
		"events": events, "density_sampled_each_second": density, "errors": errors,
		"max_observation_gap_seconds": max_gap_ticks * 0.05,
		"max_conservative_event_gap_or_tail_seconds": maximum * 0.05,
		"max_store": max_store, "deficit_kj_total": model.statistics.totals.deficit_kj,
		"method": "Batch transitions and warehouse deltas reconciled with model totals; events bracketed by ticks; conservative gaps include start/end and cross-phase intervals."}
