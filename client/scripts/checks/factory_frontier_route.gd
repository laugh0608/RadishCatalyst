extends "res://scripts/checks/factory_integrated_first_route.gd"

const Frontier := Model.Integrated.Frontier
const GATE := Vector2(12, 3)


func prepare_expansion(packs: int) -> Array[Dictionary]:
	steady()
	wait_for(func(): return devices.T.items.get("construction_pack", 0) >= packs, 600, "production funds frontier construction")
	_packs_to_core(packs)
	for type in ["collector", "crusher", "refinery", "storage", "reactor", "assembler"]:
		_must(model.assemble(type))
	for i in packs - 12:
		_must(model.assemble("belt"))
	var trial: Dictionary = _must(model.place("reactor", Vector2i(-15, 28))).entity
	var capsule_machine: Dictionary = _must(model.place("assembler", Vector2i(-9, 29))).entity
	var temporary_node: Dictionary = _must(model.place("power_junction", Vector2i(-18, 28))).entity

	walk_near(devices.G)
	wait_for(func(): return devices.G.fuel.get(CELL, 0) >= 3, 180, "reserve X2 cells from real G stock")
	stock(devices.G, CELL, 2, false)
	walk_near(model.core)
	stock(model.core, CELL, 2, true)
	for row in [["OUT_N0", "catalyst"], ["OUT_E0", "metal_plate"], ["OUT_S0", "carbon_powder"]]:
		_must(model.configure_output(model.core.id, row[0], row[1], false))
	wait_for(func(): return model.core.items.get("metal_plate", 0) >= 8 and model.core.items.get("carbon_powder", 0) >= 10 \
		and model.core.items.get("catalyst", 0) >= 16, 400, "reserve actual research and fabrication materials")
	_must(model.research(P.MIXED))
	stock(model.core, "carbon_powder", 8, false)
	stock(model.core, "catalyst", 16, false)

	var carrier_belt: Dictionary = model.entity_at(Vector2i(-13, 13))
	walk_near(carrier_belt)
	_must(model.salvage(carrier_belt.id))
	walk_near(devices.F2)
	for i in 10 - model.bag.get("porous_carrier", 0):
		wait_for(func(): return devices.F2.output.has("porous_carrier"), 40, "reserve naturally produced carriers")
		stock(devices.F2, "porous_carrier", 1, false)
	connect_line("F2", "A")
	walk_near(model.core)
	stock(model.core, "porous_carrier", 2, true)
	return [trial, capsule_machine, temporary_node]


func prepare_research(trial: Dictionary) -> void:
	craft(trial, "solvent_trial", 1)
	craft(trial, "crust_solvent", 5)
	walk_near(model.core)
	stock(model.core, "crust_solvent", 2, true)


func open_outer_and_prepare_capsules(trial: Dictionary, capsule_machine: Dictionary) -> void:
	walk_to(Vector2(3, 0))
	_must(model.open_passage("outer"))
	craft(trial, "carrier_solvent", 4)
	craft(capsule_machine, "boring_capsule_assembly", 3)


func expand(full_layout: Dictionary, temporary: Array[Dictionary]) -> void:
	for entity in temporary:
		walk_near(entity)
		_must(model.salvage(entity.id, true))
	for link in layout.routes:
		if [_name(link.source), _name(link.target)] not in full_layout.replaced:
			continue
		for cell in belt_path(link.points):
			var belt: Dictionary = model.entity_at(cell)
			walk_near(belt)
			_must(model.salvage(belt.id))
	walk_near(devices.F)
	_must(model.salvage(devices.F.id))

	layout = full_layout
	build("F", "refinery")
	build("Ci", "crusher")
	build("Fd", "refinery")
	build("Td", "storage")
	build("Ts", "storage")
	build("Si", "splitter", 1)
	build("Sc", "splitter", 1)
	build("M", "merger", 1)
	for i in range(7, 11):
		build("J%d" % i, "power_junction")
	walk_to(Vector2(12.5, 7.5))
	build("Kh", "collector")
	_must(model.set_device_enabled(devices.Kh.id, false))
	walk_near(devices.F)
	_must(model.change_recipe(devices.F.id, "mixed_refining"))
	for pair in [["I", "Si"], ["Si", "Ci"], ["Si", "Fd"], ["Ci", "F"], ["Fd", "Td"], ["F", "Ts"],
		["K", "M"], ["Kh", "M"], ["M", "C"], ["C", "Sc"], ["Sc", "IN_N0"], ["Sc", "F"]]:
		connect_line(pair[0], pair[1])

	walk_near(devices.K)
	_must(model.set_device_enabled(devices.K.id, false))
	wait_for(func(): return devices.K.buffer.is_empty(), 180, "ordinary collector buffer drains before comparison")
	walk_near(model.core)
	for row in [["OUT_N0", "catalyst"], ["OUT_E0", "metal_plate"], ["OUT_S0", "carbon_powder"]]:
		_must(model.configure_output(model.core.id, row[0], row[1], true))
	assert(model.kits.belt == 256 + layout.belt_batches * 8 - layout.belts)
	assert(model.material_balance().balanced)
