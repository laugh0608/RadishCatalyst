extends RefCounted

const Tech := preload("res://data/factory/integrated_progression.gd")
const RULESET_ID := "factory_integrated_grid_controls_v1"
const SUPPLY_ID := "factory_integrated_grid_controls_starter_v1"
const CORE_MODEL_PATH := "res://assets/factory/grid-controls/core-outline.glb"
const III_REQUIRES := [Tech.CELLS, Tech.REUSE]
const III_COST := {"construction_pack": 4, "metal_plate": 4, "porous_carrier": 2, "industrial_cell": 2}
