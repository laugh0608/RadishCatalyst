extends SceneTree

const Model := preload("res://scripts/factory/discovery_model.gd")
const Guidance := preload("res://scripts/factory/discovery_guidance.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const RangeCheck := preload("res://scripts/checks/factory_range_power_check.gd")
const Check := preload("res://scripts/checks/factory_discovery_check.gd")
const ID := "1234567890abcdef1234567890abcdef"
var assertions := 0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("run")


func expect(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures.append(label)
		push_error(label)


func step(model: RefCounted) -> Dictionary:
	var before := Codec.snapshot(model, ID, "引导检查", 1)
	var result := Guidance.current(model)
	Guidance.text(model)
	Guidance.overview(model)
	expect(before == Codec.snapshot(model, ID, "引导检查", 1), "guidance is read-only at " + result.id)
	expect(not result.action_label.is_empty() and not result.next.is_empty(), "actionable advice at " + result.id)
	if result.has("target_id"):
		expect(not model.by_id(result.target_id).is_empty(), "target exists at " + result.id)
	return result


func run() -> void:
	var m := Model.new(true)
	expect(step(m).tool == "collector", "empty world starts with collection")
	var node_only := Model.new(true)
	node_only.place("collector", Vector2i(-20, -1))
	node_only.place("reactor", Vector2i(-13, -2))
	node_only.place("power_junction", Vector2i(-17, -3))
	expect(step(node_only).get("tool", "") == "power_source", "node-only network asks for a source rather than an unavailable existing supply")
	m.actor.x = 2.5
	m.actor.z = 3.5
	expect(m.survey_sample(true).ok, "sample-first fixture uses authoritative pickup")
	expect(step(m).id == "first_line" and "已收好" in Guidance.text(m), "sample-first still prepares catalyst without repeat pickup")
	m = RangeCheck.build_line(m)
	m.advance(9.35)
	var reactor: Dictionary = m.entity_at(Vector2i(-13, -2))
	expect(step(m).target_id == reactor.id and "加工" in Guidance.text(m), "natural first batch progress")
	var source: Dictionary = m.entity_at(Vector2i(-20, -6))
	m.set_source_enabled(source.id, false)
	expect(step(m).target_id == source.id and "关闭" in Guidance.text(m), "blackout points to the actual network source")
	m.set_source_enabled(source.id, true)
	m.advance(22)
	expect(step(m).id == "trial", "two completed catalyst and earlier sample advance to trial")
	var e: Dictionary = m.place("reactor", Vector2i(-6, 4)).entity
	m.actor.x = -5
	m.actor.z = 7.2
	expect(m.change_recipe(e.id, "solvent_trial").ok, "prepare real trial recipe")
	m.place("power_junction", Vector2i(-7, 2))
	m.place("power_junction", Vector2i(-11, 2))
	expect(m.transfer(e.id, "crust_sample", true, false).ok, "sample moved into trial input")
	var advice := step(m)
	expect(advice.id == "trial" and "催化剂" in advice.next and not "样本" in advice.next, "sample already in input is not requested twice")
	var warehouse: Dictionary = m.entity_at(Vector2i(-6, -1))
	expect(advice.target_id == warehouse.id, "real takeable warehouse stock is located")
	# Declared branch fixtures isolate blocked/in-process states; Boot covers natural production.
	e.input = {}
	e.invested = {"crust_sample": 1, "catalyst": 2}
	e.processing = true
	e.progress = 4.25
	m.revision += 1
	expect("4.2 / 10" in Guidance.text(m) and "已投入" in step(m).next, "in-process sample is not requested again")
	m.discovery.trial_completed = true
	e.processing = false
	e.invested = {}
	m.revision += 1
	advice = step(m)
	expect(advice.id == "outer" and advice.target_id == e.id and "解壳剂" in advice.next, "completed trial suggests switching reusable empty reactor")
	warehouse.items = {"crust_solvent": 4}
	m.revision += 1
	advice = step(m)
	expect(advice.target_id == warehouse.id and "背包 0 / 4" in advice.progress and "总持有 4" in advice.progress, "held inventory is not claimed as carried")
	m.actor.x = -5
	m.actor.z = 2
	m.transfer(warehouse.id, "crust_solvent", false, true)
	expect(step(m).action == "location", "carried opening materials locate passage")
	m.actor.x = 1.5
	m.actor.z = 0
	expect(step(m).action == "location" and not m.open_passage("outer").ok, "guide uses the same west-side reachability as the operation")
	m.actor.x = 3
	m.actor.z = 0
	expect(step(m).action == "discovery", "near passage offers original operation")
	expect(m.open_passage("outer").ok, "open through actual cost command")
	expect(step(m).id == "rich" and "普通线" in Guidance.text(m), "rich return is recommended rather than mandatory")
	expect(step(m).cell == Vector2i(10, -1), "rich collection preview points to the newly accessible site")
	m.bag.crust_solvent = 8
	expect(step(m).id == "inner", "ordinary production can bypass recommended rich line")
	m.bag.erase("crust_solvent")
	m.statistics.totals.consumed.rich_crystal = 1
	expect(step(m).id == "inner", "completed rich batch advances despite temporary shortage")
	m.discovery.passages.inner = true
	expect(step(m).id == "complete" and "复用" in Guidance.text(m), "permanent completion never regresses")
	var fresh := RangeCheck.build_line(Model.new(true))
	fresh.advance(35)
	expect(step(fresh).id == "sample", "line-first locates the unique ground sample")
	var saved := Codec.snapshot(fresh, ID, "恢复引导", 1)
	var decoded := Codec.decode(JSON.parse_string(JSON.stringify(saved, "", false, true)), ID)
	expect(decoded.ok and Check.equivalent(Guidance.current(fresh), Guidance.current(decoded.model)), "restored facts reconstruct identical guidance")
	# Removal and stock location diagnostics are derived anew, with no stale tutorial state.
	fresh = RangeCheck.build_line(Model.new(true))
	fresh.discovery.sample_taken = true
	fresh.discovery.surveyed = true
	fresh.discovery.trial_completed = true
	var store: Dictionary = fresh.entity_at(Vector2i(-6, -1))
	store.items = {"crust_solvent": 1}
	fresh.revision += 1
	expect(step(fresh).target_id == store.id, "locates a real stock holder")
	fresh.salvage(store.id)
	expect(not step(fresh).has("target_id") or step(fresh).target_id != store.id, "salvaged target is never reused")
	fresh.bag.clear()
	fresh.entity_at(Vector2i(-10, 0)).cargo = "crust_solvent"
	fresh.revision += 1
	expect(step(fresh).action == "statistics" and "在途" in step(fresh).next, "transit goods are not offered for direct take")
	fresh = RangeCheck.build_line(Model.new(true))
	var basic: Dictionary = fresh.entity_at(Vector2i(-13, -2))
	basic.output = {"catalyst": 1}
	fresh.revision += 1
	expect("出料" in step(fresh).next, "first line backpressure points at blocked output")
	basic.output = {}
	basic.input = {"crystal": 2}
	var second: Dictionary = fresh.place("reactor", Vector2i(-13, 3)).entity
	second.input = {"crystal": 2}
	var third: Dictionary = fresh.place("reactor", Vector2i(-17, 3)).entity
	third.input = {"crystal": 2}
	fresh.place("power_junction", Vector2i(-15, 2))
	fresh.revision += 1
	expect(step(fresh).action == "statistics" and "供电不足" in step(fresh).next, "capacity shortage directs player to electricity diagnostics")
	print("First journey state: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
