extends RefCounted

const Model := preload("res://scripts/factory/integrated_model.gd")
const P := Model.Progression

var model := Model.new()
var iron: Dictionary
var crystal: Dictionary
var carbon: Dictionary
var refinery: Dictionary
var assembler: Dictionary
var crusher: Dictionary
var reactor: Dictionary


func build() -> void:
	for cell in [Vector2i(-16, 22), Vector2i(-22, 15), Vector2i(-24, 10), Vector2i(-24, 0), Vector2i(-24, -10)]:
		place("power_junction", cell)
	iron = place("collector", Vector2i(-28, -12))
	crystal = place("collector", Vector2i(-20, 11))
	carbon = place("collector", Vector2i(-28, 10))
	refinery = place("refinery", Vector2i(-16, 24))


func place(type: String, cell: Vector2i) -> Dictionary:
	return must(model.place(type, cell)).entity


static func must(result: Dictionary) -> Dictionary:
	assert(result.ok, str(result.get("reason", "command failed")))
	return result


func near(device: Dictionary) -> void:
	model.actor.x = device.x - 0.5
	model.actor.z = device.z + 0.5


func carry(source: Dictionary, target: Dictionary, item: String, amount: int) -> void:
	near(source)
	for piece in amount:
		must(model.transfer(source.id, item, false, false))
	near(target)
	for piece in amount:
		must(model.transfer(target.id, item, true, false))


func recipe(device: Dictionary, id: String) -> void:
	if device.recipe_id != id:
		near(device)
		must(model.change_recipe(device.id, id))


func make(device: Dictionary, id: String, count := 1, store := true) -> void:
	recipe(device, id)
	var spec: Dictionary = model.recipes[id]
	for batch in count:
		for item in spec.input:
			match item:
				"iron_ore": carry(iron, device, item, spec.input[item])
				"crystal": carry(crystal, device, item, spec.input[item])
				"carbon_ore": carry(carbon, device, item, spec.input[item])
				"crust_sample":
					near(device)
					must(model.transfer(device.id, item, true, false))
				_: carry(model.core, device, item, spec.input[item])
		model.advance(spec.seconds + Model.STEP)
		if store:
			for item in spec.output:
				carry(device, model.core, item, spec.output[item])


func find_sample() -> void:
	model.actor.x = 2.5
	model.actor.z = 2.5
	must(model.survey_sample(true))


func prepare_tier_one() -> void:
	build()
	model.advance(40.0)
	make(refinery, "direct_refining", 15)
	make(refinery, "direct_sintering", 6)
	near(model.core)
	must(model.research(P.ASSEMBLY))
	must(model.research(P.POWDERS))
	assembler = place("assembler", Vector2i(-5, 26))
	make(assembler, "construction_assembly", 3)
	find_sample()
	near(model.core)
