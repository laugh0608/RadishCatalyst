extends "res://scripts/factory/save/codec_v1.gd"

const V6 := preload("res://scripts/factory/save/codec_v6.gd")
const Energy := preload("res://data/factory/energy_rules.gd")
const EnergyModel := preload("res://scripts/factory/energy_model.gd")


static func snapshot(model: RefCounted, id: String, title: String, sequence: int) -> Dictionary:
	var doc := V6.snapshot(model, id, title, sequence)
	doc.save_schema_version = 7
	doc.ruleset_id = Energy.RULESET_ID
	doc.state.energy_origin = model.energy_origin.duplicate()
	return doc


static func decode(value: Variant, expected_id: String) -> Dictionary:
	if not value is Dictionary: return failure("存档必须是对象。")
	if value.get("world_kind") != "factory_3d" or value.get("save_schema_version") != 7 or value.get("ruleset_id") != Energy.RULESET_ID or value.get("map_id") != V6.Expansion.MAP_ID or value.get("supply_id") != Energy.SUPPLY_ID:
		return failure("不支持的 E2 世界、规则、地图或供给组合。", true)
	return V6.decode_content(value, expected_id, EnergyModel.new(), true)


## Explicit copy only. The Store verifies the selected source bytes under its lock.
static func copy_from_e1(source: Dictionary, id: String, title: String, source_hash: String) -> Dictionary:
	var valid := V6.decode(source, str(source.get("world_id", "")))
	if not valid.ok: return valid
	if id == source.world_id: return failure("能源世界必须使用独立身份。")
	var doc: Dictionary = source.duplicate(true)
	doc.save_schema_version = 7
	doc.ruleset_id = Energy.RULESET_ID
	doc.supply_id = Energy.SUPPLY_ID
	doc.world_id = id
	doc.name = title
	doc.sequence = 1
	var s: Dictionary = doc.state
	s.energy_origin = {"source_id": source.world_id, "source_sequence": source.sequence, "source_sha256": source_hash}
	s.kits[Energy.GENERATOR] = 0
	s.assembly_counts[Energy.GENERATOR] = 0
	s.completed_by_recipe[Energy.RECIPE] = 0
	for e in s.entities:
		if V6.V2.Config.POWER.has(e.type): e.enabled = true
	for r in [s.statistics.totals] + s.statistics.buckets + [s.statistics.current]:
		r.enabled_kj = r.available_kj
		r.base_supplied_kj = r.supplied_kj
		r.cell_supplied_kj = 0.0
		r.discarded_kj = 0.0
		r.cells_activated = 0
	return decode(doc, id)
