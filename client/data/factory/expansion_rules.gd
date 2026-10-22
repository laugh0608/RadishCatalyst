extends RefCounted

## E1 content is opt-in; legacy worlds keep their own supply and recipe lists.
const RULESET_ID := "factory_expansion_e1_v1"
const MAP_ID := "factory_expansion_yard_64_v1"
const SUPPLY_ID := "factory_expansion_starter_v1"
const MAX_OWNED := 326
const SUPPLY := {"collector": 3, "reactor": 1, "storage": 4, "crusher": 1, "refinery": 1, "assembler": 1, "power_source": 2, "power_junction": 12, "belt": 128, "splitter": 4, "merger": 4, "admission_gate": 4}
const NAMES := {"iron_ore": "铁矿", "carbon_ore": "炭矿", "iron_powder": "铁粉", "carbon_powder": "炭粉", "metal_plate": "金属板", "mineral_slag": "矿渣", "porous_carrier": "多孔载体", "construction_pack": "构件包"}
const PROCESSORS := ["crusher", "refinery", "assembler"]
const DEFAULTS := {"crusher": "iron_crushing", "refinery": "direct_refining", "assembler": "construction_assembly"}
const RECIPES := {
	"direct_refining": {"name": "直接冶炼", "machine": "refinery", "input": {"iron_ore": 2}, "output": {"metal_plate": 1}, "seconds": 8.0, "kw": 60.0},
	"iron_crushing": {"name": "铁矿粉碎", "machine": "crusher", "input": {"iron_ore": 2}, "output": {"iron_powder": 3}, "seconds": 6.0, "kw": 20.0},
	"carbon_crushing": {"name": "炭矿粉碎", "machine": "crusher", "input": {"carbon_ore": 1}, "output": {"carbon_powder": 2}, "seconds": 6.0, "kw": 20.0},
	"mixed_refining": {"name": "混料冶炼", "machine": "refinery", "input": {"iron_powder": 3, "carbon_powder": 1}, "output": {"metal_plate": 2, "mineral_slag": 1}, "seconds": 10.0, "kw": 60.0},
	"slag_sintering": {"name": "矿渣烧结", "machine": "refinery", "input": {"mineral_slag": 2, "crystal": 1}, "output": {"porous_carrier": 2}, "seconds": 8.0, "kw": 60.0},
	"direct_sintering": {"name": "直接烧结", "machine": "refinery", "input": {"crystal": 3}, "output": {"porous_carrier": 1}, "seconds": 8.0, "kw": 60.0},
	"construction_assembly": {"name": "构件包组装", "machine": "assembler", "input": {"metal_plate": 2, "porous_carrier": 1}, "output": {"construction_pack": 1}, "seconds": 10.0, "kw": 40.0},
}
const ASSEMBLY_COST := {"belt": 1, "splitter": 1, "merger": 1, "admission_gate": 1, "power_junction": 1, "collector": 2, "reactor": 2, "storage": 2, "crusher": 2, "refinery": 2, "assembler": 2}
# Local cell, outward normal; rendering and simulation consume this same table.
const PORTS := {
	"crusher": {"input": [[0, 1, -1, 0]], "output": [[1, 1, 1, 0]]},
	"refinery": {"input": [[0, 0, -1, 0], [0, 2, -1, 0]], "output": [[1, 0, 1, 0], [1, 2, 1, 0]]},
	"assembler": {"input": [[0, 0, -1, 0], [0, 1, -1, 0], [1, 0, 0, -1]], "output": [[2, 1, 1, 0]]},
}

static func yield_for(type: String) -> int:
	return 8 if type == "belt" else 1

static func cycle(mineral: String) -> float:
	return 20.0 if mineral == "carbon_ore" else 1.0
