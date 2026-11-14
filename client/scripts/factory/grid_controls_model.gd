extends "res://scripts/factory/frontier_model.gd"

const Controls := Integrated.Controls


func _init() -> void:
	super(true)
	supply_id = Controls.SUPPLY_ID
	core_upgrades[3] = {"requires": Controls.III_REQUIRES, "cost": Controls.III_COST}
