extends "res://scripts/factory/save/codec_v1.gd"

const V15 := preload("res://scripts/factory/save/codec_v15.gd")
const V14 := V15.V14
const V9 := V14.V13.V12.V11.V10.V9
const InterlockModel := preload("res://scripts/factory/load_interlocks_model.gd")
const Interlocks := InterlockModel.Interlocks
const VERSION := 16
const PIN := "723a749cb7c5731cc99afa32d9880a0d76f438da7e7342dc3e18b4c12bba8b08"
const CONTRACT := {"version": 1, "condition": Interlocks.CONDITION, "max_per_member": 1,
	"source": "same_grid_ungrouped_processor", "outcomes": Interlocks.OUTCOMES, "default_outcome": "none",
	"reset_on_enable_or_start": true, "check_each_start": true, "budget_includes_waiting": true,
	"source_disconnect": "block_member", "source_salvage": "require_unbind"}


static func definitions_sha256() -> String:
	return JSON.stringify({"load_groups": V15.definitions_sha256(), "interlocks": CONTRACT}, "", true, true).sha256_text()


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V15.snapshot(model, id, title, sequence)
	doc.save_schema_version = VERSION
	doc.ruleset_id = Interlocks.RULESET_ID
	doc.definitions_sha256 = definitions_sha256()
	return doc


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary:
		return failure("存档必须是对象。")
	if value.get("world_kind") != "factory_3d" or value.get("save_schema_version") != VERSION \
		or value.get("ruleset_id") != Interlocks.RULESET_ID or value.get("map_id") != V14.V13.V12.V11.V10.Frontier.MAP_ID \
		or value.get("supply_id") != Interlocks.SUPPLY_ID:
		return failure("不支持的开工联锁工厂身份。", true)
	if value.get("definitions_sha256") != PIN or definitions_sha256() != PIN:
		return failure("开工联锁工厂定义摘要不匹配。", true)
	var result := V9.decode_state(value, expected_id, InterlockModel.new())
	if not result.ok:
		return result
	for validator in [V14.Validator, V15.Validator]:
		var references: Dictionary = validator.restore_references(result.model)
		if not references.ok:
			return references
	return result
