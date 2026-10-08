extends "res://scripts/factory/save/codec_v2.gd"

const V2 := preload("res://scripts/factory/save/codec_v2.gd")


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V2.snapshot(model, id, title, sequence)
	doc.save_schema_version = 3
	doc.ruleset_id = Config.AUTO_RULESET_ID
	return doc


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary:
		return failure("存档必须是对象。")
	if value.get("save_schema_version") != 3 or value.get("ruleset_id") != Config.AUTO_RULESET_ID:
		return failure("不支持的范围供电规则或存档版本。", true)
	# Reuse strict field, inventory, batch, statistics and geometry validation before
	# checking the stronger automatic-topology invariant. Never repair a bad cache.
	var legacy: Dictionary = value.duplicate(true)
	legacy.save_schema_version = 2
	legacy.ruleset_id = Config.RULESET_ID
	var result := V2.decode(legacy, expected_id)
	if not result.ok:
		return result
	return verify_automatic(result, value)


static func verify_automatic(result: Dictionary, value: Dictionary) -> Dictionary:
	var model: RefCounted = result.model
	var links: Array = model.power_links.duplicate(true)
	var attachments := {}
	for e in model.entities:
		if e.has("power_node_id"):
			attachments[e.id] = e.power_node_id
	enable_automatic(model)
	if links != model.power_links:
		return failure("范围电网连接与布局不一致。")
	for id in attachments:
		if attachments[id] != model.by_id(id).power_node_id:
			return failure("范围供电设备归属与布局不一致。")
	result.document = value
	return result


static func enable_automatic(model: RefCounted) -> void:
	model.automatic_power = true
	model.revision += 1
	model._refresh_automatic_power()
