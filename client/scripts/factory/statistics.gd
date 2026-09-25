extends RefCounted

const ENERGY := ["installed_kj", "available_kj", "requested_kj", "supplied_kj", "used_kj", "deficit_kj"]
const MATERIAL := ["produced", "consumed", "acquired", "delivered"]
var ticks := 0
var totals := record()
var buckets: Array = []
var current := bucket(0)
var revision := 0


static func record() -> Dictionary:
	return {"produced": {}, "consumed": {}, "acquired": {}, "delivered": {},
		"installed_kj": 0.0, "available_kj": 0.0, "requested_kj": 0.0,
		"supplied_kj": 0.0, "used_kj": 0.0, "deficit_kj": 0.0}


static func bucket(start: int) -> Dictionary:
	return record().merged({"start_tick": start, "ticks": 0})


func event(kind: String, item: String, count: int) -> void:
	assert(kind in MATERIAL and count > 0)
	# Commands at an exact second belong to the just-closed bucket.
	var target: Dictionary = buckets.back() if ticks > 0 and ticks % 20 == 0 and current.ticks == 0 else current
	target[kind][item] = target[kind].get(item, 0) + count
	totals[kind][item] = totals[kind].get(item, 0) + count
	revision += 1


func begin_step(power: Dictionary, dt: float) -> void:
	current.ticks += 1
	ticks += 1
	var values := [power.installed_kw, power.available_kw, power.request_kw, power.supplied_kw, power.supplied_kw, power.deficit_kw]
	for i in ENERGY.size():
		current[ENERGY[i]] += values[i] * dt
		totals[ENERGY[i]] += values[i] * dt


func end_step() -> void:
	if current.ticks == 20:
		buckets.append(current)
		if buckets.size() > 600:
			buckets.pop_front()
		current = bucket(ticks)
		revision += 1


func window(seconds: int) -> Dictionary:
	assert(seconds in [60, 300, 600])
	var selected := buckets.slice(maxi(0, buckets.size() - seconds))
	var result := record().merged({"seconds": selected.size(), "through_tick": ticks - ticks % 20, "has_samples": not selected.is_empty()})
	for b in selected:
		for kind in MATERIAL:
			for item in b[kind]:
				result[kind][item] = result[kind].get(item, 0) + b[kind][item]
		for key in ENERGY:
			result[key] += b[key]
	return result


func snapshot() -> Dictionary:
	return {"ticks": ticks, "totals": totals.duplicate(true), "buckets": buckets.duplicate(true), "current": current.duplicate(true)}


func restore(value: Dictionary) -> void:
	ticks = int(value.ticks)
	totals = value.totals.duplicate(true)
	buckets = value.buckets.duplicate(true)
	current = value.current.duplicate(true)
	for r in buckets + [current, totals]:
		for key in ["start_tick", "ticks"]:
			if r.has(key):
				r[key] = int(r[key])
		for kind in MATERIAL:
			for item in r[kind]:
				r[kind][item] = int(r[kind][item])
