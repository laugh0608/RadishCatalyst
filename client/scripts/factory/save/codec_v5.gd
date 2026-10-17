extends "res://scripts/factory/save/codec_v2.gd"

const V2 := preload("res://scripts/factory/save/codec_v2.gd")
const V3 := preload("res://scripts/factory/save/codec_v3.gd")
const V4 := preload("res://scripts/factory/save/codec_v4.gd")
const EngineeringModel := preload("res://scripts/factory/engineering_model.gd")
const AdmissionModel := preload("res://scripts/factory/admission_model.gd")


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V2.snapshot(model, id, title, sequence)
	doc.save_schema_version = 5
	doc.ruleset_id = Config.Engineering.RULESET_ID if model.supply_id == Config.Engineering.SUPPLY_ID else Config.ADMISSION_RULESET_ID
	doc.state.entities.sort_custom(func(a, b): return a.id < b.id)
	return doc


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary:
		return failure("存档必须是对象。")
	var engineering := value is Dictionary and Config.Engineering.matches(value)
	var ordinary: bool = value.get("world_kind") == "factory_3d" and value.get("save_schema_version") == 5 and value.get("ruleset_id") == Config.ADMISSION_RULESET_ID and value.get("map_id") == Config.MAP_ID and value.get("supply_id") == Config.ADMISSION_SUPPLY_ID
	if not engineering and not ordinary:
		return failure("不支持的 V5 世界、规则、地图或供给身份组合。", true)
	var ruleset: String = Config.Engineering.RULESET_ID if engineering else Config.ADMISSION_RULESET_ID
	var model: RefCounted = EngineeringModel.new() if engineering else AdmissionModel.new()
	model.automatic_power = false
	var result := V2.decode_world(value, expected_id, 5, ruleset, model)
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
