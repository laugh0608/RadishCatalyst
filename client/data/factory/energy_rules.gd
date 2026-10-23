extends RefCounted

const RULESET_ID := "factory_expansion_e2_v1"
const SUPPLY_ID := "factory_expansion_energy_starter_v1"
const CELL := "industrial_cell"
const RECIPE := "cell_assembly"
const GENERATOR := "cell_generator"
const CELL_KJ := 7200.0
const GENERATOR_KW := 120.0
const FUEL_CAPACITY := 5
const NAMES := {"industrial_cell": "工业电芯"}
const RECIPES := {
	"cell_assembly": {"name": "工业电芯组装", "machine": "assembler", "input": {"metal_plate": 1, "carbon_powder": 2, "catalyst": 1}, "output": {"industrial_cell": 1}, "seconds": 12.0, "kw": 40.0},
}
const EXTRA_ENERGY := ["enabled_kj", "base_supplied_kj", "cell_supplied_kj", "discarded_kj"]
const EXTRA_COUNTS := ["cells_activated"]
