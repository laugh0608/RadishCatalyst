extends "res://scripts/factory/save/codec_v2.gd"

const V2 := preload("res://scripts/factory/save/codec_v2.gd")
const V3 := preload("res://scripts/factory/save/codec_v3.gd")
const V4 := preload("res://scripts/factory/save/codec_v4.gd")
const AdmissionModel := preload("res://scripts/factory/admission_model.gd")


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V2.snapshot(model, id, title, sequence)
	doc.save_schema_version = 5
	doc.ruleset_id = Config.ADMISSION_RULESET_ID
	doc.state.entities.sort_custom(func(a, b): return a.id < b.id)
	return doc


static func decode(value: Variant, expected_id: String) -> Dictionary:
	var model := AdmissionModel.new()
	model.automatic_power = false
	var result := V2.decode_world(value, expected_id, 5, Config.ADMISSION_RULESET_ID, model)
	return V3.verify_automatic(result, value) if result.ok else result


static func upgrade(value: Dictionary) -> Dictionary:
	var original := V4.decode(value, value.world_id)
	if not original.ok: return original
	var doc: Dictionary = value.duplicate(true)
	doc.save_schema_version = 5
	doc.ruleset_id = Config.ADMISSION_RULESET_ID
	doc.supply_id = Config.ADMISSION_SUPPLY_ID
	doc.state.kits.admission_gate = 8
	return decode(doc, doc.world_id)
