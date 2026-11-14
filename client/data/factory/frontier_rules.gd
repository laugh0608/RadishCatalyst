extends RefCounted

const Tech := preload("res://data/factory/integrated_progression.gd")
const RULESET_ID := "factory_integrated_frontier_v1"
const SINGLE_INLET_RULESET_ID := "factory_integrated_frontier_single_inlet_v1"
const MAP_ID := "factory_integrated_frontier_yard_64_v1"
const SUPPLY_ID := "factory_integrated_frontier_starter_v1"
const PASSAGE := "carbon_frontier"
const POCKET := Rect2i(8, 4, 8, 8)
const MOUTH := Rect2i(10, 4, 4, 2)
const INTERIOR := Rect2i(9, 6, 6, 5)
const ORE := Vector2i(10, 7)
const ORE_SECONDS := 5.0
const CAPSULE := "boring_capsule"
const OPEN_COST := 4
const RESEARCH := "frontier_tools"
const NODE := {"name": "开拓工具", "level": 2, "requires": [Tech.ASSEMBLY, Tech.SAMPLE, Tech.CELLS],
	"sample": false, "cost": {"metal_plate": 4, "porous_carrier": 2, "crust_solvent": 2, "industrial_cell": 2},
	"recipes": ["boring_capsule_assembly", "carrier_solvent"], "devices": [],
	"effect": "完成矿壳试制后可研究。用破岩胶囊打开高产炭矿支路；载体解壳剂保留原配方供选择。"}
const RECIPES := {
	"boring_capsule_assembly": {"name": "破岩胶囊组装", "machine": "assembler",
		"input": {"porous_carrier": 1, "carbon_powder": 2, "crust_solvent": 1},
		"output": {CAPSULE: 1}, "seconds": 12.0, "kw": 40.0},
	"carrier_solvent": {"name": "载体解壳剂", "machine": "reactor",
		"input": {"catalyst": 1, "porous_carrier": 1},
		"output": {"crust_solvent": 1}, "seconds": 8.0, "kw": 60.0},
}
