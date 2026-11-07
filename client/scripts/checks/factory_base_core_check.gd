extends SceneTree

const Model := preload("res://scripts/factory/integrated_model.gd")
const View := preload("res://scripts/factory/view.gd")
const Route := preload("res://scripts/checks/factory_base_core_route.gd")
const Store := preload("res://scripts/factory/save/store.gd")
var failures: Array[String] = []
var checks := 0


func _init() -> void:
	call_deferred("run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func run() -> void:
	_contract()
	_arbitration()
	_output_backpressure()
	var route := _natural_route()
	var result := {"assertions": checks, "failures": failures, "route": route}
	print("Factory core state: " + JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)


func _contract() -> void:
	var model := Model.new()
	var core := model.core
	var rules := Model.Integrated
	model.actor.z += 1
	expect(model.owned_count() == 290 and model.entities.size() == 1 and core.items.is_empty(), "single core; sealed kits count; empty stock")
	expect(model.entity_at(Vector2i(-6, 27)) == core and model.blocked_for_actor(-8, 24), "6 by 6 footprint is indexed and solid")
	expect(not model.place("base_core", Vector2i(-10, 10)).ok and not model.rotate(core.id).ok and not model.salvage(core.id, true).ok, "core cannot be manufactured, rotated or recovered")
	expect(not model.place("reactor", Vector2i(-15, 19)).ok and not model.assemble("belt").ok, "locked stock and B2 commands")
	expect(model.recipe_available("direct_refining") and model.recipe_available("direct_sintering") and not model.recipe_available("basic_catalyst"), "B0 recipes only")
	expect(model.power_state().available_kw == 360.0 and model.power_state().request_kw == 0.0, "core is an always-on source, not a consumer")
	expect(View._check_core_asset(load(rules.MODEL_PATH)).is_empty(), "all 16 runtime ports agree with imported anchors")
	expect(not Store.new().save(model).ok, "memory review model explicitly rejected by Store")
	expect(not model.configure_output(core.id, "OUT_N0", "crust_sample", true).ok and not model.configure_output(core.id, "IN_N0", "iron_ore", true).ok, "non-transportable item and input configuration rejected")
	expect(model.input_room(core, "crust_sample") == 0 and model.input_room(core, "crust_sample", true) == rules.ITEM_LIMIT, "samples permitted by hand only")
	model.bag = {"crust_sample": 1, "iron_ore": 3}
	core.items.iron_ore = rules.ITEM_LIMIT - 1
	expect(model.transfer(core.id, "crust_sample", true, true).ok and model.transfer(core.id, "iron_ore", true, true).get("amount", 0) == 1, "manual transfer clamps to each item's capacity")
	expect(core.items.iron_ore == rules.ITEM_LIMIT and model.bag.iron_ore == 2, "full core retains remaining bag inventory")
	model.actor.z -= 4
	expect(not model.transfer(core.id, "iron_ore", false, true).ok and not model.configure_output(core.id, "OUT_N0", "iron_ore", true).ok, "remote stock and output commands fail")
	model.actor.z += 4
	model.bag.iron_ore = 199
	expect(model.transfer(core.id, "iron_ore", false, true).get("amount", 0) == 1 and model.bag.iron_ore == 200, "manual withdrawal clamps to bag capacity")


func _belt(model: RefCounted, cell: Vector2i, dir: int) -> Dictionary:
	var result: Dictionary = model.place("belt", cell, dir)
	expect(result.ok, "fixture belt at %s" % str(cell))
	return result.entity


func _load(belt: Dictionary, item: String) -> void:
	belt.cargo = item
	belt.progress = 1.0 if not item.is_empty() else 0.0


func _arbitration() -> void:
	var model := Model.new()
	model.actor.z += 1
	var core := model.core
	var n_out := _belt(model, Vector2i(-7, 21), 3)
	var s_out := _belt(model, Vector2i(-10, 28), 1)
	var n0 := _belt(model, Vector2i(-10, 21), 1)
	var n1 := _belt(model, Vector2i(-9, 21), 1)
	var contender := _belt(model, Vector2i(-6, 21), 2)
	for id in ["OUT_N0", "OUT_S0"]:
		expect(model.configure_output(core.id, id, "iron_ore", true).ok, "enable " + id)
	core.items.iron_ore = 1
	model.advance(0.95)
	expect(n_out.cargo.is_empty() and s_out.cargo.is_empty(), "newly enabled output waits 19 complete ticks")
	model.advance(Model.STEP)
	expect(n_out.cargo == "iron_ore" and s_out.cargo.is_empty() and not core.items.has("iron_ore"), "two ready outlets share one last item")
	expect(core.outputs.OUT_N0.cooldown_ticks == 20 and core.output_cursors.iron_ore == 1, "successful output resets exact interval and advances cursor")
	_load(n_out, "")
	model.advance(1.0)
	core.items.iron_ore = 1
	_load(contender, "crystal")
	# Older core request ranks first at the north belt; output cursor grants the
	# last item to the south, so the ordinary competitor still takes north.
	n_out.cursor = 0
	model.advance(Model.STEP)
	expect(s_out.cargo == "iron_ore" and n_out.cargo == "crystal" and contender.cargo.is_empty(), "fair output fallback keeps ordinary belt contention intact")

	_load(n_out, "")
	_load(s_out, "")
	_load(n0, "iron_ore")
	core.outputs.OUT_N0.cooldown_ticks = 0
	model.advance(Model.STEP)
	expect(n_out.cargo.is_empty() and core.items.iron_ore == 1, "new input cannot immediately fund output")

	core.items.iron_ore = Model.Integrated.ITEM_LIMIT - 1
	_load(n0, "iron_ore")
	_load(n1, "iron_ore")
	model.advance(Model.STEP)
	expect(core.items.iron_ore == Model.Integrated.ITEM_LIMIT - 1 and n0.cargo == "iron_ore" and n1.cargo.is_empty() and n_out.cargo == "iron_ore", "last input slot reserved once using start inventory even when output succeeds")
	_load(n1, "iron_ore")
	core.items.iron_ore = Model.Integrated.ITEM_LIMIT
	_load(s_out, "")
	core.outputs.OUT_S0.cooldown_ticks = 0
	model.advance(Model.STEP)
	expect(n0.cargo == "iron_ore" and n1.cargo == "iron_ore" and core.items.iron_ore == Model.Integrated.ITEM_LIMIT - 1, "output cannot make a full item available to inputs in the same step")
	model.advance(Model.STEP)
	expect(n0.cargo.is_empty() and n1.cargo == "iron_ore", "last input slot rotates to next actual port")
	core.items.iron_ore = 10
	_load(n0, "iron_ore")
	_load(n1, "carbon_ore")
	model.advance(Model.STEP)
	expect(n0.cargo.is_empty() and n1.cargo.is_empty() and core.items.iron_ore == 11 and core.items.carbon_ore == 1, "different items arrive through distinct ports in one step")
	_load(n0, "crust_sample")
	model.advance(Model.STEP)
	expect(n0.cargo == "crust_sample" and not core.items.has("crust_sample"), "illegitimate sample cargo cannot cross the core boundary")
	expect(model.configure_output(core.id, "OUT_N0", "carbon_ore", false).ok, "closing while changing the configured item")
	model.advance(0.5)
	expect(core.outputs.OUT_N0.cooldown_ticks == 20, "closed cooldown does not run")
	model.configure_output(core.id, "OUT_N0", "carbon_ore", true)
	expect(core.outputs.OUT_N0.cooldown_ticks == 20 and core.outputs.OUT_N0.item == "carbon_ore", "reopening restarts cooldown with applied item")


func _output_backpressure() -> void:
	var model := Model.new()
	model.actor.z += 1
	var core := model.core
	var north := _belt(model, Vector2i(-7, 21), 3)
	var south := _belt(model, Vector2i(-10, 28), 1)
	for id in ["OUT_N0", "OUT_S0"]:
		model.configure_output(core.id, id, "iron_ore", true)
	core.items.iron_ore = 4
	model.advance(1.0)
	expect(north.cargo == "iron_ore" and south.cargo == "iron_ore" and core.items.iron_ore == 2,
		"two enabled outlets can each ship in the same step")
	model.advance(2.0)
	expect(core.items.iron_ore == 2 and core.outputs.OUT_N0.cooldown_ticks == 0,
		"backpressure neither consumes stock nor accumulates extra output credit")
	_load(north, "")
	model.advance(Model.STEP)
	expect(core.items.iron_ore == 1 and north.cargo == "iron_ore" and core.outputs.OUT_N0.cooldown_ticks == 20,
		"clearing one blocked first tile releases one item and resumes pacing")


func _natural_route() -> Dictionary:
	var model := Model.new()
	var route := Route.build(model)
	expect(route.ok, "B0 S0 route builds: " + route.get("reason", ""))
	if not route.ok:
		return {}
	expect(route.lengths == [51, 28, 20] and model.kits.belt == 157, "audited 99 belts")
	expect(model.core.items.is_empty() and model.bag.is_empty() and model.owned_count() == 290, "route starts with zero material and preserves kits")
	expect(model.power_state().devices[route.collector.id].network >= 0 and model.power_state().devices[route.refinery.id].network >= 0, "core grid reaches collector and refinery")
	model.actor.z += 1
	model.configure_output(model.core.id, "OUT_S0", "iron_ore", true)
	while model.time < 160.0 and model.core.items.get("metal_plate", 0) == 0:
		model.advance(Model.STEP)
	var balance := model.material_balance()
	expect(model.core.items.get("metal_plate", 0) == 1 and model.completed_by_recipe.direct_refining >= 1, "first natural plate returns to core")
	expect(model.bag.is_empty() and balance.balanced and model.delivered == 0, "material ledger balances without manual movement or terminal delivery")
	return {"belt_lengths": route.lengths, "first_plate_seconds": model.time, "balanced": balance.balanced}
