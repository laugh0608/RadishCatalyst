extends RefCounted

## External fixed-step evidence; never changes model state or scheduling.
const Layout := preload("res://scripts/checks/factory_engineering_layout.gd")
const Items := preload("res://scripts/factory/items.gd")
var model: RefCounted
var cells: Array[Dictionary] = []
var counts: Array[Dictionary] = []
var windows: Array = []
var step_count := 0
var max_deficit_kw := 0.0
var peak_request_kw := 0.0
var max_store := 0
var max_distribution_difference := 0
var max_arrival_difference := 0
var window_start: Array = []
var last_event: Array[Dictionary] = []
var max_event_gap_steps := 0


func _init(value: RefCounted) -> void:
	model = value
	for index in 20:
		var named := Layout.ids(model, index)
		var cell := {}
		for name in named: cell[name] = model.by_id(named[name])
		cells.append(cell)
		counts.append({"catalyst": 0, "solvent": 0, "upper-store": 0, "lower-store": 0, "branch_feed": 0, "branch_bypass": 0, "merge_solvent": 0, "merge_bypass": 0, "merge_contentions": 0, "merge_contention_solvent": 0, "merge_contention_bypass": 0, "dispatched_upper": 0, "dispatched_lower": 0})
	for index in 20: last_event.append({"catalyst": 0, "solvent": 0, "upper-store": 0, "lower-store": 0})
	window_start = counts.duplicate(true)


func advance(steps: int) -> Dictionary:
	for tick in steps:
		var before := []
		for c in cells:
			before.append({"catalyst": c.catalyst.active_batch, "solvent": c.solvent.active_batch,
				"upper-store": Items.count(c["upper-store"].items), "lower-store": Items.count(c["lower-store"].items),
				"branch_cargo": c.branch.cargo, "branch_batch": c.branch.batch,
				"distribute_cargo": c.distribute.cargo, "distribute_batch": c.distribute.batch,
				"merge_empty": c.merge.cargo.is_empty(),
				"solvent_ready": not c["solvent-0"].cargo.is_empty() and c["solvent-0"].progress >= 0.95 - 1e-9,
				"bypass_ready": not c.g3.cargo.is_empty() and c.g3.progress >= 0.95 - 1e-9})
		model.advance(0.05, 1)
		step_count += 1
		for index in 20:
			var c: Dictionary = cells[index]
			var b: Dictionary = before[index]
			var count: Dictionary = counts[index]
			for name in ["catalyst", "solvent"]:
				if b[name] > 0 and c[name].active_batch != b[name]:
					count[name] += 1
					_event(index, name)
			for name in ["upper-store", "lower-store"]:
				var amount := Items.count(c[name].items)
				count[name] += amount - b[name]
				if amount > b[name]: _event(index, name)
				max_store = maxi(max_store, amount)
			max_arrival_difference = maxi(max_arrival_difference, absi(count["upper-store"] - count["lower-store"]))
			if not b.distribute_cargo.is_empty() and c.distribute.cargo.is_empty():
				for pair in [["upper-0", "dispatched_upper"], ["lower-0", "dispatched_lower"]]:
					if c[pair[0]].cargo == b.distribute_cargo and c[pair[0]].batch == b.distribute_batch and c[pair[0]].progress == 0: count[pair[1]] += 1
			max_distribution_difference = maxi(max_distribution_difference, absi(count.dispatched_upper - count.dispatched_lower))
			if not b.branch_cargo.is_empty() and c.branch.cargo.is_empty():
				for pair in [["feed-0", "branch_feed"], ["bypass-0", "branch_bypass"]]:
					if c[pair[0]].cargo == b.branch_cargo and c[pair[0]].batch == b.branch_batch and c[pair[0]].progress == 0: count[pair[1]] += 1
			if b.merge_empty and not c.merge.cargo.is_empty():
				# Facing E: left input is north (solvent), right input south (G3).
				var solvent: bool = c.merge.input_cursor == 2
				count["merge_solvent" if solvent else "merge_bypass"] += 1
				if b.solvent_ready and b.bypass_ready:
					count.merge_contentions += 1
					count["merge_contention_solvent" if solvent else "merge_contention_bypass"] += 1
		if step_count % 20 == 0:
			var power: Dictionary = model.power_state()
			max_deficit_kw = maxf(max_deficit_kw, power.deficit_kw)
			peak_request_kw = maxf(peak_request_kw, power.request_kw)
		if step_count % 2400 == 0:
			var rows := []
			var active := true
			for index in 20:
				var delta := {}
				for key in ["catalyst", "solvent", "upper-store", "lower-store"]:
					delta[key] = counts[index][key] - window_start[index][key]
					active = active and delta[key] > 0
				rows.append(delta)
			windows.append({"start_step": step_count - 2400, "end_step": step_count, "all_working": active, "cells": rows})
			window_start = counts.duplicate(true)
	return report()


func _event(index: int, name: String) -> void:
	max_event_gap_steps = maxi(max_event_gap_steps, step_count - last_event[index][name])
	last_event[index][name] = step_count


func report() -> Dictionary:
	var max_silence := max_event_gap_steps
	for row in last_event:
		for value in row.values(): max_silence = maxi(max_silence, step_count - value)
	var stores := []
	for c in cells:
		stores.append({"upper": c["upper-store"].items.duplicate(), "lower": c["lower-store"].items.duplicate(), "g3_used": c.g3.quota_used})
	return {"steps": step_count, "seconds": step_count * 0.05, "max_event_gap_or_tail_seconds": max_silence * 0.05, "cells": counts.duplicate(true), "windows": windows.duplicate(true),
		"stores": stores, "max_store": max_store, "max_distribution_difference": max_distribution_difference, "max_arrival_difference": max_arrival_difference,
		"peak_request_kw_sampled_each_second": peak_request_kw, "max_deficit_kw_sampled_each_second": max_deficit_kw,
		"deficit_kj_total": model.statistics.totals.deficit_kj}


func assert_work(check: SceneTree, label: String) -> void:
	for index in 20:
		for key in ["catalyst", "solvent", "upper-store", "lower-store"]:
			check.expect(counts[index][key] > 0, "%s cell %d actual %s" % [label, index, key])
	check.expect(report().max_event_gap_or_tail_seconds <= 120, label + " no completion or delivery gap exceeds 120 seconds")
	for window in windows: check.expect(window.all_working, label + " every complete 120-second window " + str(window.end_step))
	check.expect(max_store < 200 and max_distribution_difference <= 1, label + " storage headroom and fair distribution")
	check.expect(model.statistics.totals.deficit_kj == 0 and peak_request_kw > 0, label + " real finite work without energy deficit")
