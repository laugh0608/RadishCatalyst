extends RefCounted

const Tech := preload("res://data/factory/integrated_progression.gd")
const SUPPLY_ID := "factory_integrated_grid_storage_starter_v1"
const RULESET_ID := "factory_integrated_grid_storage_v1"
const TYPE := "grid_buffer"
const SHAPE := {"name": "电网储能", "w": 2, "d": 2}
const MODEL_PATH := "res://assets/factory/grid-controls/grid-buffer.glb"
const CAPACITY_J := 3600000
const CHARGE_KW := 60
const DISCHARGE_KW := 60
const CHARGE_INPUT_J := 10
const CHARGE_STORED_J := 9
const ASSEMBLY_PACKS := 2
const ASSEMBLY_CELLS := 1
const NODE := {"name": "电网缓冲", "level": 3, "requires": [Tech.CELLS], "sample": false,
	"cost": {"construction_pack": 2, "metal_plate": 2, "industrial_cell": 1},
	"recipes": [], "devices": [TYPE], "effect": "装配电网储能，保存低负载时的发电余电，供电不足时自动补缺。"}
