extends "res://scripts/factory/admission_model.gd"

const Engineering := preload("res://data/factory/engineering_rules.gd")


func _init() -> void:
	super()
	supply_id = Engineering.SUPPLY_ID
	map_id = Engineering.MAP_ID
	kits = Engineering.SUPPLY.duplicate()
