extends "res://scripts/factory/save/codec_v1.gd"

const V14 := preload("res://scripts/factory/save/codec_v14.gd")
const LoadModel := preload("res://scripts/factory/load_groups_model.gd")
const Validator := preload("res://scripts/factory/save/load_group_validator.gd")
const Loads := LoadModel.Loads
const VERSION := 15
const PIN := "ae8c6cbb3ca7708ce8415af1c2906633b4392cf1327d806c8647d6540fd3635d"


static func definitions_sha256() -> String:
	var research := Loads.NODE.duplicate()
	research.erase("name")
	research.erase("effect")
	return JSON.stringify({"storage_feedback": V14.definitions_sha256(), "load_groups": {
		"version": Loads.BEHAVIOR_VERSION, "defaults": Loads.defaults(), "max_members": Loads.MAX_MEMBERS,
		"interval": Loads.INTERVAL, "resume_w": Loads.RESUME_W, "precision_j": Loads.PRECISION_J,
		"capacity_j": Loads.Storage.CAPACITY_J, "member_types": Loads.MEMBER_TYPES,
		"excluded_recipe": Loads.EXCLUDED_RECIPE, "research_id": Loads.RESEARCH, "research": research}},
		"", true, true).sha256_text()


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V14.snapshot(model, id, title, sequence)
	doc.save_schema_version = VERSION
	doc.ruleset_id = Loads.RULESET_ID
	doc.definitions_sha256 = definitions_sha256()
	return doc


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary:
		return failure("存档必须是对象。")
	if value.get("world_kind") != "factory_3d" or value.get("save_schema_version") != VERSION or value.get("ruleset_id") != Loads.RULESET_ID or value.get("map_id") != V14.V13.V12.V11.V10.Frontier.MAP_ID or value.get("supply_id") != Loads.SUPPLY_ID:
		return failure("不支持的负载组工厂身份。", true)
	if value.get("definitions_sha256") != PIN or definitions_sha256() != PIN:
		return failure("负载组工厂定义摘要不匹配。", true)
	var result := V14.V13.V12.V11.V10.V9.decode_state(value, expected_id, LoadModel.new())
	if not result.ok:
		return result
	for validator in [V14.Validator, Validator]:
		var references: Dictionary = validator.restore_references(result.model)
		if not references.ok:
			return references
	return result
