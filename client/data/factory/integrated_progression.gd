extends RefCounted

const BASE := "base_deployment"
const ASSEMBLY := "precision_assembly"
const POWDERS := "powder_processing"
const SAMPLE := "sample_processing"
const CELLS := "industrial_cells"
const MIXED := "mixed_refining"
const REUSE := "slag_reuse"
const II_REQUIRES := [ASSEMBLY, POWDERS, SAMPLE]
const II_COST := {"construction_pack": 2}
const TIER_LABELS := ["", "I", "II", "III"]
const MAX_OWNED := 512

const NODES := {
	BASE: {"name": "基础部署", "level": 1, "requires": [], "sample": false, "cost": {},
		"recipes": ["direct_refining", "direct_sintering"], "devices": ["collector", "belt", "splitter", "merger", "admission_gate", "power_junction", "storage", "refinery"],
		"effect": "建设基础产线，直炼金属板或直接烧结多孔载体。"},
	ASSEMBLY: {"name": "精密装配", "level": 1, "requires": [BASE], "sample": false,
		"cost": {"metal_plate": 4, "porous_carrier": 1}, "recipes": ["construction_assembly"], "devices": ["assembler"],
		"effect": "用组装机生产构件包，在核心装配已解锁构件。"},
	POWDERS: {"name": "粉体加工", "level": 1, "requires": [BASE], "sample": false,
		"cost": {"metal_plate": 3, "porous_carrier": 2}, "recipes": ["iron_crushing", "carbon_crushing"], "devices": ["crusher"],
		"effect": "用粉碎机制备铁粉和炭粉，为混料冶炼与电芯备料。"},
	SAMPLE: {"name": "样本工艺", "level": 1, "requires": [BASE], "sample": true,
		"cost": {"metal_plate": 2}, "recipes": ["basic_catalyst", "solvent_trial", "crust_solvent", "rich_catalyst"], "devices": ["reactor"],
		"effect": "用反应器制备催化剂和解壳剂。样本用于一次试制，内矿道开放后可加工富集晶体。"},
	CELLS: {"name": "工业电芯", "level": 2, "requires": II_REQUIRES, "sample": false,
		"cost": {"metal_plate": 2, "porous_carrier": 1, "catalyst": 1}, "recipes": ["cell_assembly"], "devices": ["cell_generator"],
		"effect": "用组装机生产工业电芯。装配并安装电芯发电机，接入燃料后可启用固定燃烧。"},
	MIXED: {"name": "混料冶炼", "level": 2, "requires": [ASSEMBLY, POWDERS], "sample": false,
		"cost": {"metal_plate": 4, "carbon_powder": 2}, "recipes": ["mixed_refining"], "devices": [],
		"effect": "铁粉和炭粉联产。精炼炉主口出金属板，副口出矿渣。"},
	REUSE: {"name": "矿渣回用", "level": 2, "requires": [MIXED], "sample": false,
		"cost": {"mineral_slag": 2, "crystal": 1}, "recipes": ["slag_sintering"], "devices": [],
		"effect": "用矿渣与晶体烧结多孔载体，精炼炉仍可选直接烧结。"},
}
