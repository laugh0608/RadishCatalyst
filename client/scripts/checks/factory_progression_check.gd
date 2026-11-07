extends SceneTree

const Journey := preload("res://scripts/checks/factory_progression_journey.gd")
const P := Journey.P
var checks := 0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("run")


func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)
		push_error(label)


func run() -> void:
	var journey := Journey.new()
	_definition(journey.model)
	_transactions()
	_natural(journey)
	print("Factory progression state: " + JSON.stringify({"assertions": checks, "failures": failures,
		"seconds": journey.model.time, "recipes": journey.model.completed_by_recipe}))
	quit(0 if failures.is_empty() else 1)


func _definition(model: RefCounted) -> void:
	var known_nodes := {}
	var known_recipes := {}
	var known_types := {}
	for id in P.NODES:
		var node: Dictionary = P.NODES[id]
		expect(node.requires.all(func(dep): return known_nodes.has(dep) and P.NODES[dep].level <= node.level), id + " prerequisite order and acyclicity")
		known_nodes[id] = true
		for item in node.cost:
			expect(item in model.item_ids and node.cost[item] is int and node.cost[item] > 0, id + " valid cost " + item)
		for recipe in node.recipes:
			expect(model.recipes.has(recipe) and not known_recipes.has(recipe), id + " known distinct recipe " + recipe)
			known_recipes[recipe] = true
		for type in node.devices:
			expect(model.kits.has(type) and model.assembly_costs.has(type) and not known_types.has(type), id + " known distinct kit " + type)
			known_types[type] = true
	expect(known_recipes.size() == model.recipes.size() and known_types.size() == model.kits.size(), "all integrated recipes and kits have exactly one owner")


func _transactions() -> void:
	var model := Journey.Model.new()
	var core := model.core
	model.actor.z += 1
	core.items = {"metal_plate": 20, "porous_carrier": 0}
	model.bag = {"porous_carrier": 10, "construction_pack": 10}
	var before: Dictionary = core.items.duplicate()
	expect(not model.research(P.ASSEMBLY).ok and core.items == before and model.statistics.totals.consumed.is_empty(), "cannot combine bag and core or partially pay")
	expect(not model.research(P.SAMPLE).ok and not model.research("unknown").ok and core.items == before, "missing sample and unknown research preserve stock")
	expect(not model.research(P.CELLS).ok and not model.upgrade_core().ok, "cannot skip tier or I research")
	core.items.porous_carrier = 1
	model.actor.z -= 4
	expect(not model.research(P.ASSEMBLY).ok and not model.upgrade_core().ok and not model.assemble("belt").ok, "three commands enforce proximity")
	model.actor.z += 4
	expect(model.research(P.ASSEMBLY).ok and not model.research(P.ASSEMBLY).ok, "duplicate research is rejected")
	expect(core.items.metal_plate == 16 and model.statistics.totals.consumed.metal_plate == 4 and model.kits.assembler == 1, "one charge and no extra starter kit")
	expect(not model.assemble("belt").ok and not model.assemble("crusher").ok, "bag cannot pay and locked kits cannot be manufactured")
	core.items.construction_pack = 2
	model.kits.belt += P.MAX_OWNED - model.owned_count() - 7
	var owned: int = model.owned_count()
	expect(not model.assemble("belt").ok and model.owned_count() == owned and core.items.construction_pack == 2, "whole batch capacity check")
	model.kits.belt -= 1
	expect(model.assemble("belt").ok and model.owned_count() == P.MAX_OWNED and core.items.construction_pack == 1, "eight pieces fit exactly at the budget")


func _natural(j: RefCounted) -> void:
	var model: RefCounted = j.model
	var core: Dictionary = model.core
	expect(core.items.is_empty() and model.bag.is_empty(), "progression begins with no materials")
	j.prepare_tier_one()
	expect(model.bag.get("crust_sample", 0) == 1 and model.research(P.SAMPLE).ok and model.bag.get("crust_sample", 0) == 1, "X1 consumes plates and preserves the naturally found sample")
	expect(core.items.construction_pack == 3, "three genuine I-tier construction packs")
	Journey.must(model.configure_output(core.id, "OUT_S0", "iron_ore", true))
	var output: Dictionary = core.outputs.duplicate(true)
	var ports: Array = model.Logistics.ports(model, core, "input")
	expect(model.upgrade_core().ok and not model.upgrade_core().ok and core.items.construction_pack == 1, "II consumes two packs once")
	expect(core.level == 2 and model.researched.size() == 4 and core.outputs == output and model.Logistics.ports(model, core, "input") == ports and model.power_state().available_kw == 360.0, "upgrade preserves geometry, configuration and power; II nodes still unresearched")
	expect(model.assemble("belt").ok and model.kits.belt == 264, "core stock manufactures eight belts")
	j.crusher = j.place("crusher", Vector2i(-10, 28))
	j.reactor = j.place("reactor", Vector2i(-5, 21))
	j.make(j.refinery, "direct_refining", 7)
	j.make(j.refinery, "direct_sintering", 1)
	j.make(j.crusher, "carbon_crushing", 3)
	j.make(j.crusher, "iron_crushing", 2)
	j.make(j.reactor, "basic_catalyst", 4)
	j.near(core)
	expect(model.research(P.CELLS).ok and model.research(P.MIXED).ok, "E1 and M2 pay with natural materials")
	expect(model.recipe_available("cell_assembly") and model.device_unlocked("cell_generator") and not model.placement("cell_generator", Vector2i(-16, 28)).ok, "E1 unlocks the recipe and kit without gifting a generator")
	j.make(j.assembler, "cell_assembly")
	j.make(j.refinery, "mixed_refining", 1, false)
	var out: Array = model.Logistics.ports(model, j.refinery, "output")
	expect(model._output_item_at(j.refinery, out[0]) == "metal_plate" and model._output_item_at(j.refinery, out[1]) == "mineral_slag", "mixed refinery splits the actual products across ports")
	j.carry(j.refinery, core, "metal_plate", 2)
	j.carry(j.refinery, core, "mineral_slag", 1)
	j.make(j.refinery, "mixed_refining")
	j.carry(j.crystal, core, "crystal", 2)
	j.near(core)
	expect(model.research(P.REUSE).ok, "M3 pays with real mixed-refining slag")
	j.make(j.crusher, "iron_crushing", 2)
	j.make(j.crusher, "carbon_crushing")
	j.make(j.refinery, "mixed_refining", 2)
	j.make(j.refinery, "slag_sintering")
	expect(core.items.get("industrial_cell", 0) == 1 and core.items.get("porous_carrier", 0) >= 2, "II routes make usable outputs")
	j.make(j.refinery, "direct_sintering")
	j.make(j.assembler, "construction_assembly", 3)
	j.near(core)
	expect(model.assemble("cell_generator").ok and model.kits.cell_generator == 1, "three naturally produced packs manufacture the E1 kit")
	j.make(j.reactor, "solvent_trial")
	expect(model.discovery.trial_completed and not model.recipe_available("solvent_trial") and not model.recipe_available("rich_catalyst"), "unique trial completes and rich recipe still requires actual access")
	j.make(j.reactor, "basic_catalyst", 22)
	j.make(j.reactor, "crust_solvent", 11)
	j.near(core)
	for i in 12:
		Journey.must(model.transfer(core.id, "crust_solvent", false, false))
	model.actor.x = 3
	model.actor.z = 0
	expect(model.open_passage("outer").ok and not model.recipe_available("rich_catalyst"), "outer passage alone does not unlock R04")
	model.actor.x = 19
	expect(model.open_passage("inner").ok and model.recipe_available("rich_catalyst"), "actual inner passage enables R04")
	expect(model.researched.size() == 7 and model.material_balance().balanced, "all seven nodes and complete material ledger")
