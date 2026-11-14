extends "res://scripts/factory/save/codec_v1.gd"

const V10 := preload("res://scripts/factory/save/codec_v10.gd")
const ControlsModel := preload("res://scripts/factory/grid_controls_model.gd")
const Controls := ControlsModel.Controls
const VERSION := 11
const PIN := "3ae6fe727cdc9f98915490a1cc4938b20525444fa096395ef5831acbfaf64d14"


static func definitions_sha256() -> String:
	return JSON.stringify({"frontier": V10.single_inlet_sha256(),
		"core_upgrade_iii": {"requires": Controls.III_REQUIRES, "cost": Controls.III_COST}},
		"", true, true).sha256_text()


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V10.snapshot(model, id, title, sequence)
	doc.save_schema_version = VERSION
	doc.ruleset_id = Controls.RULESET_ID
	doc.definitions_sha256 = definitions_sha256()
	return doc


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary:
		return failure("存档必须是对象。")
	if value.get("world_kind") != "factory_3d" or value.get("save_schema_version") != VERSION or value.get("ruleset_id") != Controls.RULESET_ID or value.get("map_id") != V10.Frontier.MAP_ID or value.get("supply_id") != Controls.SUPPLY_ID:
		return failure("不支持的测控工厂身份。", true)
	if value.get("definitions_sha256") != PIN or definitions_sha256() != PIN:
		return failure("测控工厂定义摘要不匹配。", true)
	return V10.V9.decode_state(value, expected_id, ControlsModel.new())
