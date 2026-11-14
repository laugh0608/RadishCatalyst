extends "res://scripts/factory/fixed_burn_statistics.gd"

const STORAGE_KEYS := ["charge_j", "discharge_j", "storage_loss_j", "storage_discarded_j"]


func new_record() -> Dictionary:
	var result := super.new_record()
	for key in STORAGE_KEYS:
		result[key] = 0
	return result


func count_keys() -> Array:
	return super.count_keys() + STORAGE_KEYS


func begin_step(power: Dictionary, dt: float) -> void:
	super.begin_step(power, dt)
	for key in ["charge_j", "discharge_j", "storage_loss_j"]:
		current[key] += power[key]
		totals[key] += power[key]


func discard_storage(joules: int) -> void:
	var target: Dictionary = buckets.back() if ticks > 0 and ticks % 20 == 0 and current.ticks == 0 else current
	target.storage_discarded_j += joules
	totals.storage_discarded_j += joules
	revision += 1


func restore(value: Dictionary) -> void:
	super.restore(value)
	for r in buckets + [current, totals]:
		for key in STORAGE_KEYS:
			r[key] = int(r[key])
