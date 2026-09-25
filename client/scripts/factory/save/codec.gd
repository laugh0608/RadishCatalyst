extends "res://scripts/factory/save/codec_v1.gd"

const V1 := preload("res://scripts/factory/save/codec_v1.gd")
const V2 := preload("res://scripts/factory/save/codec_v2.gd")


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	return V2.snapshot(model, id, title, sequence) if model.supply_id == V2.Config.SUPPLY_ID else V1.snapshot(model, id, title, sequence)


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if value is Dictionary and value.get("save_schema_version") == 2:
		return V2.decode(value, expected_id)
	return V1.decode(value, expected_id)
