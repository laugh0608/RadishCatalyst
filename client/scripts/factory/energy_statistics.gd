extends "res://scripts/factory/statistics.gd"

const Energy := preload("res://data/factory/energy_rules.gd")


func _init() -> void:
	totals = new_record()
	current = new_bucket(0)


func new_record() -> Dictionary:
	var result := record()
	for key in Energy.EXTRA_ENERGY: result[key] = 0.0
	for key in Energy.EXTRA_COUNTS: result[key] = 0
	return result


func energy_keys() -> Array:
	return ENERGY + Energy.EXTRA_ENERGY


func count_keys() -> Array:
	return Energy.EXTRA_COUNTS


func begin_step(power: Dictionary, dt: float) -> void:
	super.begin_step(power, dt)
	for pair in [["enabled_kj", "enabled_kw"], ["base_supplied_kj", "base_supplied_kw"], ["cell_supplied_kj", "cell_supplied_kw"]]:
		var value: float = power[pair[1]] * dt
		current[pair[0]] += value
		totals[pair[0]] += value


func fuel_event(key: String, value: Variant) -> void:
	assert(key in ["cells_activated", "discarded_kj"] and value > 0)
	assert(value is int if key == "cells_activated" else is_finite(value))
	var target: Dictionary = buckets.back() if ticks > 0 and ticks % 20 == 0 and current.ticks == 0 else current
	target[key] += value
	totals[key] += value
	revision += 1


func restore(value: Dictionary) -> void:
	super.restore(value)
	for r in buckets + [current, totals]:
		r.cells_activated = int(r.cells_activated)
