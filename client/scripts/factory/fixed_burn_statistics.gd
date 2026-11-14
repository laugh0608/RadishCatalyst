extends "res://scripts/factory/statistics.gd"

const SOURCE_KEYS := {"enabled_kj": "enabled_kw", "base_supplied_kj": "base_supplied_kw",
	"fuel_released_kj": "fuel_released_kw", "spill_kj": "spill_kw", "standby_kj": "standby_supplied_kw"}
const EXTRA := ["enabled_kj", "base_supplied_kj", "fuel_released_kj", "spill_kj", "standby_kj", "discarded_kj"]


func _init() -> void:
	totals = new_record()
	current = new_bucket(0)


func new_record() -> Dictionary:
	var result := record()
	for key in EXTRA:
		result[key] = 0.0
	result.cells_activated = 0
	return result


func energy_keys() -> Array:
	return ENERGY + EXTRA


func count_keys() -> Array:
	return ["cells_activated"]


func begin_step(power: Dictionary, dt: float) -> void:
	super.begin_step(power, dt)
	for key in SOURCE_KEYS:
		var value: float = power[SOURCE_KEYS[key]] * dt
		current[key] += value
		totals[key] += value


func fuel_event(key: String, amount: Variant) -> void:
	assert(key in ["cells_activated", "discarded_kj"] and amount > 0)
	var target: Dictionary = buckets.back() if ticks > 0 and ticks % 20 == 0 and current.ticks == 0 else current
	target[key] += amount
	totals[key] += amount
	revision += 1


func restore(value: Dictionary) -> void:
	super.restore(value)
	for r in buckets + [current, totals]:
		r.cells_activated = int(r.cells_activated)
