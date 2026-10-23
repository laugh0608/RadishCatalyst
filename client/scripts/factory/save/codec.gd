extends "res://scripts/factory/save/codec_v1.gd"

const V1 := preload("res://scripts/factory/save/codec_v1.gd")
const V2 := preload("res://scripts/factory/save/codec_v2.gd")
const V4 := preload("res://scripts/factory/save/codec_v4.gd")
const V3 := preload("res://scripts/factory/save/codec_v3.gd")
const V7 := preload("res://scripts/factory/save/codec_v7.gd")
const V6 := preload("res://scripts/factory/save/codec_v6.gd")
const V5 := preload("res://scripts/factory/save/codec_v5.gd")


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	if model.supply_id == V7.Energy.SUPPLY_ID:
		return V7.snapshot(model, id, title, sequence)
	if model.supply_id == V6.Expansion.SUPPLY_ID:
		return V6.snapshot(model, id, title, sequence)
	if V2.Config.admission_world(model.supply_id):
		return V5.snapshot(model, id, title, sequence)
	if model.supply_id == V2.Config.ROUTING_SUPPLY_ID:
		return V4.snapshot(model, id, title, sequence)
	if model.has_method("power_state") and model.automatic_power:
		return V3.snapshot(model, id, title, sequence)
	return V2.snapshot(model, id, title, sequence) if model.supply_id == V2.Config.SUPPLY_ID else V1.snapshot(model, id, title, sequence)


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if value is Dictionary and value.get("save_schema_version") == 7:
		return V7.decode(value, expected_id)
	if value is Dictionary and value.get("save_schema_version") == 6:
		return V6.decode(value, expected_id)
	if value is Dictionary and value.get("save_schema_version") == 5:
		return V5.decode(value, expected_id)
	if value is Dictionary and value.get("save_schema_version") == 4:
		return V4.decode(value, expected_id)
	if value is Dictionary and value.get("save_schema_version") == 3:
		return V3.decode(value, expected_id)
	if value is Dictionary and value.get("save_schema_version") == 2:
		return V2.decode(value, expected_id)
	return V1.decode(value, expected_id)
