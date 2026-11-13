extends "res://scripts/factory/save/codec_v1.gd"

const V13 := preload("res://scripts/factory/save/codec_v13.gd")
const FeedbackModel := preload("res://scripts/factory/storage_feedback_model.gd")
const Validator := preload("res://scripts/factory/save/storage_feedback_validator.gd")
const Feedback := FeedbackModel.Feedback
const VERSION := 14
const PIN := "2eeef3ba9b92dced692225fdb28adc2491ea84e45ee08f9e2f774029b9a314df"


static func definitions_sha256() -> String:
	var research := Feedback.NODE.duplicate()
	research.erase("name")
	research.erase("effect")
	return JSON.stringify({"timed_dispatch": V13.definitions_sha256(), "feedback": {
		"version": Feedback.BEHAVIOR_VERSION, "defaults": Feedback.defaults(),
		"precision_j": Feedback.PRECISION_J, "capacity_j": Feedback.Storage.CAPACITY_J,
		"modes": ["timed", "storage"], "latches": ["pending", "allow", "block"],
		"research_id": Feedback.RESEARCH, "research": research}}, "", true, true).sha256_text()


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V13.snapshot(model, id, title, sequence)
	doc.save_schema_version = VERSION
	doc.ruleset_id = Feedback.RULESET_ID
	doc.definitions_sha256 = definitions_sha256()
	return doc


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary:
		return failure("存档必须是对象。")
	if value.get("world_kind") != "factory_3d" or value.get("save_schema_version") != VERSION or value.get("ruleset_id") != Feedback.RULESET_ID or value.get("map_id") != V13.V12.V11.V10.Frontier.MAP_ID or value.get("supply_id") != Feedback.SUPPLY_ID:
		return failure("不支持的储能反馈工厂身份。", true)
	if value.get("definitions_sha256") != PIN or definitions_sha256() != PIN:
		return failure("储能反馈工厂定义摘要不匹配。", true)
	var result := V13.V12.V11.V10.V9.decode_state(value, expected_id, FeedbackModel.new())
	if not result.ok:
		return result
	var references := Validator.restore_references(result.model)
	return result if references.ok else references
