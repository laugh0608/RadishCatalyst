extends SceneTree

const Query := preload("res://scripts/factory/statistics_query.gd")
const Guidance := preload("res://scripts/factory/discovery_guidance.gd")
const PowerCheck := preload("res://scripts/checks/factory_power_check.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const Model := preload("res://scripts/factory/discovery_model.gd")
const App := preload("res://scripts/factory/app.gd")
const ID := "1234567890abcdef1234567890abcdef"
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	call_deferred("run")


func expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
		push_error(label)


func run() -> void:
	var m := PowerCheck.line()
	var zero := Query.materials(m, 60)
	expect(not zero.window.has_samples and zero.rows.size() == 2, "new world has no samples and hides discoveries")
	expect(zero.rows.catalyst.theory_produced == 6 and zero.rows.crystal.theory_consumed == 12, "unpowered theoretical configuration remains 6 per minute")
	m.connect_power(13, 1)
	m.connect_power(14, 2)
	m.advance(9.35)
	var before: Dictionary = Codec.snapshot(m, ID, "统计", 1)
	var result := Query.materials(m, 600)
	expect(result.window.seconds == 9 and result.window.through_tick == 180, "incomplete window uses completed seconds only")
	expect(result.rows.crystal.invested == 2 and result.rows.crystal.held == 9, "in-progress original input retained in stock")
	expect(result.rows.crystal.produced == 60 and result.rows.catalyst.produced == 0, "actual production counts completed events")
	expect(before == Codec.snapshot(m, ID, "统计", 1), "queries do not mutate authoritative state")
	for item in result.rows:
		expect(result.rows[item].held == m.material_balance().held.get(item, 0), "inventory decomposition conserves " + item)
	m.statistics_ui = {"window_seconds": 300, "favorites": ["catalyst"]}
	var restored: Dictionary = Codec.decode(JSON.parse_string(JSON.stringify(Codec.snapshot(m, ID, "统计", 1), "", false, true)), ID)
	expect(restored.ok, "half bucket snapshot decodes")
	if restored.ok:
		expect(Query.materials(restored.model, 600) == result, "history and stock query restore without duplication")
		expect(restored.model.statistics_ui == m.statistics_ui, "favorites and window persist")
	m.advance(610, 13000)
	for seconds in [60, 300, 600]:
		result = Query.materials(m, seconds)
		expect(result.window.seconds == seconds and result.rows.crystal.points.size() == seconds, "bounded window " + str(seconds))
		var sum := 0
		for point in result.rows.catalyst.points:
			sum += point.a
		expect(absf(result.rows.catalyst.produced - sum * 60.0 / seconds) < 1e-8, "chart and rate agree " + str(seconds))
	var power := Query.electricity(m, 60)
	expect(absf(power.window.supplied_kj - power.window.used_kj) < 1e-7, "power window conserves energy")
	m.disconnect_power(13, 1)
	# A synthetic empty buffer makes the collector request power despite old backpressure.
	m.by_id(1).buffer.clear()
	m.revision += 1
	power = Query.electricity(m, 60)
	expect(1 in power.unplugged and power.current.deficit_kw >= 20, "unconnected demand not canceled by isolated capacity")
	var custom := Model.new()
	custom.discovery.sample_taken = true
	custom.discovery.surveyed = true
	custom.discovery.trial_completed = true
	custom.discovery.passages.outer = true
	var reactor: Dictionary = custom.place("reactor", Vector2i(14, -2)).entity
	reactor.recipe_id = "rich_catalyst"
	result = Query.materials(custom, 60)
	expect(result.rows.catalyst.theory_produced == 15 and result.rows.rich_crystal.theory_consumed == 5, "three-unit recipe theory")
	reactor.output = {"catalyst": 2}
	reactor.invested = {"rich_crystal": 1}
	result = Query.materials(custom, 60)
	expect(result.rows.catalyst.buffer == 2 and result.rows.rich_crystal.invested == 1, "partial multi-output and original work occupancy")
	reactor.recipe_id = "solvent_trial"
	result = Query.materials(custom, 60)
	expect(result.rows.crust_solvent.theory_produced == 0 and result.rows.catalyst.theory_consumed == 0, "one-time trial has no continuous theory")
	custom.entities.clear()
	result = Query.materials(custom, 60)
	expect(result.rows.catalyst.devices.is_empty(), "removed devices disappear from query")
	expect("反哺" in Guidance.text(custom), "outer opening guidance")
	custom.discovery.passages.inner = true
	expect("复用" in Guidance.text(custom), "second opening guidance")
	# Exact-second commands must update the last complete bucket once.
	var fresh := Model.new()
	fresh.advance(1)
	fresh.actor.x = 2.5
	fresh.actor.z = 3.5
	fresh.survey_sample(true)
	result = Query.materials(fresh, 60)
	expect(result.rows.crust_sample.acquired == 1 and result.rows.crust_sample.produced == 0, "boundary pickup is external acquisition")
	expect("试制" in Guidance.text(fresh), "sample-first path supported")
	var panel := preload("res://scripts/factory/statistics_panel.gd").new()
	root.add_child(panel)
	panel.show_for(fresh)
	panel.selected_item = "crust_sample"
	panel.refresh()
	expect(panel.rows.size() == 3 and panel.detail.visible, "known rows and detail attach")
	panel.page.select(1)
	panel.refresh()
	expect(panel.power_body.visible and not panel.material_rows.visible, "power page attached")
	panel.queue_free()
	await process_frame
	print("Factory statistics: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
