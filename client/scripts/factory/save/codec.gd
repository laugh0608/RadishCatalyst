extends "res://scripts/factory/save/codec_v1.gd"

const V1 := preload("res://scripts/factory/save/codec_v1.gd")
const V2 := preload("res://scripts/factory/save/codec_v2.gd")
const V4 := preload("res://scripts/factory/save/codec_v4.gd")
const V3 := preload("res://scripts/factory/save/codec_v3.gd")
const V10 := preload("res://scripts/factory/save/codec_v10.gd")
const V11 := preload("res://scripts/factory/save/codec_v11.gd")
const V16 := preload("res://scripts/factory/save/codec_v16.gd")
const V15 := preload("res://scripts/factory/save/codec_v15.gd")
const V14 := preload("res://scripts/factory/save/codec_v14.gd")
const V13 := preload("res://scripts/factory/save/codec_v13.gd")
const V12 := preload("res://scripts/factory/save/codec_v12.gd")
const V9 := preload("res://scripts/factory/save/codec_v9.gd")
const V8 := preload("res://scripts/factory/save/codec_v8.gd")
const V7 := preload("res://scripts/factory/save/codec_v7.gd")
const V6 := preload("res://scripts/factory/save/codec_v6.gd")
const V5 := preload("res://scripts/factory/save/codec_v5.gd")
const INTEGRATED_VERSIONS := [V9.VERSION, V10.VERSION, V11.VERSION, V12.VERSION, V13.VERSION, V14.VERSION, V15.VERSION, V16.VERSION]


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	if model.supply_id == V16.Interlocks.SUPPLY_ID:
		return V16.snapshot(model, id, title, sequence)
	if model.supply_id == V15.Loads.SUPPLY_ID:
		return V15.snapshot(model, id, title, sequence)
	if model.supply_id == V14.Feedback.SUPPLY_ID:
		return V14.snapshot(model, id, title, sequence)
	if model.supply_id == V13.Dispatch.SUPPLY_ID:
		return V13.snapshot(model, id, title, sequence)
	if model.supply_id == V12.Buffer.SUPPLY_ID:
		return V12.snapshot(model, id, title, sequence)
	if model.supply_id == V11.Controls.SUPPLY_ID:
		return V11.snapshot(model, id, title, sequence)
	if model.supply_id == V10.Frontier.SUPPLY_ID:
		return V10.snapshot(model, id, title, sequence)
	if model.supply_id == V9.Integrated.SUPPLY_ID:
		return V9.snapshot(model, id, title, sequence)
	if model.supply_id == V7.Energy.SUPPLY_ID:
		return V8.snapshot(model, id, title, sequence) if model.standby_power else V7.snapshot(model, id, title, sequence)
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
	if value is Dictionary and value.get("save_schema_version") == V16.VERSION:
		return V16.decode(value, expected_id)
	if value is Dictionary and value.get("save_schema_version") == V15.VERSION:
		return V15.decode(value, expected_id)
	if value is Dictionary and value.get("save_schema_version") == V14.VERSION:
		return V14.decode(value, expected_id)
	if value is Dictionary and value.get("save_schema_version") == V13.VERSION:
		return V13.decode(value, expected_id)
	if value is Dictionary and value.get("save_schema_version") == V12.VERSION:
		return V12.decode(value, expected_id)
	if value is Dictionary and value.get("save_schema_version") == V11.VERSION:
		return V11.decode(value, expected_id)
	if value is Dictionary and value.get("save_schema_version") == V10.VERSION:
		return V10.decode(value, expected_id)
	if value is Dictionary and value.get("save_schema_version") == 9:
		return V9.decode(value, expected_id)
	if value is Dictionary and value.get("save_schema_version") == 8:
		return V8.decode(value, expected_id)
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
