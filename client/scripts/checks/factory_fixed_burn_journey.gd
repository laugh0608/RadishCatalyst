extends "res://scripts/checks/factory_progression_journey.gd"

const G_CELL := Vector2i(-5, 18)
var generator: Dictionary


func prepare_generator() -> void:
	prepare_fuel_and_kit()
	generator = place("cell_generator", G_CELL)
	connect_generator()


func prepare_fuel_and_kit() -> void:
	prepare_tier_one()
	must(model.research(P.SAMPLE))
	must(model.upgrade_core())
	crusher = place("crusher", Vector2i(-10, 28))
	reactor = place("reactor", Vector2i(-5, 21))
	make(refinery, "direct_refining", 9)
	make(refinery, "direct_sintering", 3)
	make(crusher, "carbon_crushing", 3)
	make(reactor, "basic_catalyst", 4)
	near(model.core)
	must(model.research(P.CELLS))
	make(assembler, "construction_assembly", 2)
	near(model.core)
	must(model.assemble("cell_generator"))
	make(assembler, "cell_assembly", 2)


func connect_generator() -> void:
	var path: Array[Vector2i] = [Vector2i(-7, 21), Vector2i(-7, 20), Vector2i(-7, 19), Vector2i(-6, 19)]
	must(model.place_path(path, 0))
	near(model.core)
	must(model.configure_output(model.core.id, "OUT_N0", "industrial_cell", true))
	model.advance(8.0)
	assert(generator.fuel.get("industrial_cell", 0) == 2 and not generator.enabled)


func prepare_tail() -> void:
	near(generator)
	must(model.set_device_enabled(generator.id, true))
	model.advance(59.95)
	assert(generator.burn_remaining_ticks == 1 and generator.fuel.industrial_cell == 1)
	for item in model.recipes.cell_assembly.input:
		carry(model.core, assembler, item, model.recipes.cell_assembly.input[item])
	near(model.core)
	must(model.configure_output(model.core.id, "OUT_W0", "metal_plate", true))
	# Load the R12 batch and end the step with a tail tick still pending.
	near(generator)
	must(model.set_device_enabled(generator.id, false))
	model.advance(2.0)
	near(model.core)
	must(model.configure_output(model.core.id, "OUT_W0", "metal_plate", false))
	must(model.configure_output(model.core.id, "OUT_E0", "crystal", true))
	model.advance(0.2)
	must(model.configure_output(model.core.id, "OUT_S0", "crystal", true))
	near(generator)
	must(model.set_device_enabled(generator.id, true))
