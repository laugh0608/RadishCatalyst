extends "res://scripts/factory/save/codec_v1.gd"

const V9 := preload("res://scripts/factory/save/codec_v9.gd")
const FrontierModel := preload("res://scripts/factory/frontier_model.gd")
const Frontier := FrontierModel.Frontier
const VERSION := 10
const PIN := "ef39f986b612a5e6ae4545d0b130e8fdd98c065e105fd53f051eb1b8ae8425e6"
static var digest := ""


static func definitions_sha256() -> String:
	if not digest.is_empty():
		return digest
	var recipes := Frontier.RECIPES.duplicate(true)
	for recipe in recipes.values():
		recipe.erase("name")
	var node := Frontier.NODE.duplicate(true)
	node.erase("name")
	node.erase("effect")
	var masks: Array[String] = []
	for outer in [false, true]:
		for inner in ([false, true] if outer else [false]):
			for opened in ([false, true] if outer else [false]):
				var flags := {"outer": outer, "inner": inner, Frontier.PASSAGE: opened}
				var mask := PackedByteArray()
				for z in range(-32, 32):
					for x in range(-32, 32):
						mask.append(int(FrontierModel.DiscoveryRules.open_cell(Vector2i(x, z), flags, Frontier.MAP_ID)))
				var hash := HashingContext.new()
				hash.start(HashingContext.HASH_SHA256)
				hash.update(mask)
				masks.append(hash.finish().hex_encode())
	digest = JSON.stringify({
		"foundation": V9.Definitions.sha256(),
		"masks": masks,
		"ore": [Frontier.ORE.x, Frontier.ORE.y, "carbon_ore", Frontier.ORE_SECONDS],
		"passage": [Frontier.PASSAGE, Frontier.CAPSULE, Frontier.OPEN_COST],
		"research": [Frontier.RESEARCH, "solvent_trial", node],
		"recipes": recipes,
	}, "", true, true).sha256_text()
	return digest


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V9.snapshot(model, id, title, sequence)
	doc.save_schema_version = VERSION
	doc.ruleset_id = Frontier.RULESET_ID
	doc.definitions_sha256 = definitions_sha256()
	doc.state.frontier_extracted = model.frontier_extracted
	return doc


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary:
		return failure("存档必须是对象。")
	if value.get("world_kind") != "factory_3d" or value.get("save_schema_version") != VERSION or value.get("ruleset_id") != Frontier.RULESET_ID or value.get("map_id") != Frontier.MAP_ID or value.get("supply_id") != Frontier.SUPPLY_ID:
		return failure("不支持的开拓工厂身份。", true)
	if value.get("definitions_sha256") != PIN or definitions_sha256() != PIN:
		return failure("开拓工厂定义摘要不匹配。", true)
	return V9.decode_state(value, expected_id, FrontierModel.new())
