extends RefCounted

const Layout := preload("res://scripts/checks/factory_engineering_layout.gd")
const Model := Layout.Model
const Config := Layout.Config
const Codec := preload("res://scripts/factory/save/codec.gd")
const Items := preload("res://scripts/factory/items.gd")
var check: SceneTree
var model: RefCounted
var commands: Array = []
var names := {}
var failed := false


func _init(driver: SceneTree) -> void:
	check = driver
	model = Model.new()


func require(result: Dictionary, label: String) -> bool:
	check.expect(result.ok, label + ": " + result.get("reason", ""))
	commands.append({"label": label, "result": result.duplicate(true), "tick": model.statistics.ticks})
	failed = failed or not result.ok
	return result.ok


func near(name: String) -> bool:
	var e: Dictionary = model.by_id(names[name])
	return require(Layout.walk(model, Vector2.ZERO, e), "walk to " + name)


func put(name: String, item: String, putting: bool, all_items := true) -> bool:
	return require(model.transfer(names[name], item, putting, all_items), "%s %s %s" % ["put" if putting else "take", item, name])


func recipe(name: String, value: String) -> bool:
	return require(model.change_recipe(names[name], value), "recipe " + value)


func advance(seconds: float) -> void:
	model.advance(seconds, ceili(seconds / Model.STEP))


func prelude() -> bool:
	if not require(Layout.walk(model, Vector2(2.5, 2.5)), "walk to unique sample"): return false
	if not require(model.survey_sample(true), "pick unique sample"): return false
	# Build only the first ordinary cell's devices; no transport before the manual prelude.
	for row in Layout.cell_entities(0).slice(0, 8):
		var placed: Dictionary = model.place(row.type, Vector2i(row.x, row.z), row.dir)
		if not require(placed, "prelude place " + row.name): return false
		names[row.name] = placed.entity.id
	if not near("solvent") or not recipe("solvent", "solvent_trial") or not put("solvent", "crust_sample", true): return false
	advance(2)
	for batch in 12:
		for catalyst in 2:
			if not near("collector"): return false
			for raw in 2:
				if not put("collector", "crystal", false, false): return false
			if not near("catalyst") or not put("catalyst", "crystal", true): return false
			advance(10)
			if not put("catalyst", "catalyst", false): return false
		if not near("solvent") or not put("solvent", "catalyst", true): return false
		advance(10 if batch == 0 else 8)
		if not put("solvent", "crust_solvent", false): return false
		if batch == 0 and not recipe("solvent", "crust_solvent"): return false
	if not require(Layout.walk(model, Vector2(3.5, 0.5)), "walk outer command anchor"): return false
	if not require(model.open_passage("outer"), "consume four solvent"): return false
	if not require(Layout.walk(model, Vector2(19.5, 0.5)), "walk inner command anchor"): return false
	if not require(model.open_passage("inner"), "consume eight solvent"): return false
	var held: Dictionary = model.material_balance().held
	check.expect(Items.count(held) <= 80 and held.get("rich_crystal", 0) == 0 and model.statistics.totals.consumed.get("crust_solvent") == 12, "prelude <=80 physical items, no rich material, actual 12 consumed")
	return not failed


func full_layout() -> bool:
	for index in 20:
		# Keep the actor in the outside lane while placing global engineering fixtures.
		if not require(Layout.walk(model, Vector2(-31.5, -31.5)), "outside lane before construction %d" % index): return false
		for row in Layout.cell_entities(index):
			var existing: Dictionary = model.entity_at(Vector2i(row.x, row.z))
			if index == 0 and row.name in names: continue
			if not existing.is_empty():
				check.expect(false, "unexpected occupied fixture cell " + str(row))
				return false
			var placed: Dictionary = model.place(row.type, Vector2i(row.x, row.z), row.dir)
			if not require(placed, "layout %d %s" % [index, row.name]): return false
		names = Layout.ids(model, index)
		if index != 0:
			if not near("solvent") or not recipe("solvent", "crust_solvent"): return false
			if model.by_id(names.collector).mineral == "rich_crystal":
				if not near("catalyst") or not recipe("catalyst", "rich_catalyst"): return false
		for gate in ["g1", "g2", "g3"]:
			if not near(gate): return false
			var item: String = model.by_id(names.collector).mineral if gate == "g1" else "catalyst"
			if not require(model.configure_admission(names[gate], item, "quota" if gate == "g3" else "unlimited", 128 if gate == "g3" else 0), "configure " + gate): return false
			if not require(model.set_admission_accepting(names[gate], true), "allow " + gate): return false
	return require(Layout.walk(model, Vector2(-31.5, -31.5)), "outside overview lane")


func audit() -> Dictionary:
	var edges := 0
	var counts := {}
	var routes := []
	var covered := 0
	var outputs_ok := true
	var ownership := {}
	for index in 20:
		for id in Layout.ids(model, index).values(): ownership[id] = index
	var internal_edges := true
	for e in model.entities:
		counts[e.type] = counts.get(e.type, 0) + 1
		if Model.DiscoveryRules.POWER.has(e.type) and e.power_node_id > 0: covered += 1
		var outputs: Array = model.Logistics.ports(model, e, "output")
		var actual := 0
		for output in outputs:
			var connection: Dictionary = model.Logistics.output_connection(model, output)
			if connection.ok:
				actual += 1
				internal_edges = internal_edges and ownership.get(e.id, -1) == ownership.get(connection.target.id, -2)
		if not outputs.is_empty() and actual != (2 if e.type == "splitter" else 1): outputs_ok = false
		edges += actual
		if e.type != "belt":
			var route := Layout.walk(model, Vector2.ZERO, e)
			routes.append({"id": e.id, "type": e.type, "route": route})
			if not require(route, "service route #%d" % e.id): return {}
	check.expect(counts == Config.SUPPLY and model.occupancy.size() == 2100, "exact approved construction and occupied cells")
	check.expect(edges == 1220 and outputs_ok, "all directed logistics ports connected as declared")
	check.expect(internal_edges, "every actual logistics edge stays inside its declared unit")
	check.expect(model.power_links.size() == 198 and model.grid.groups.size() == 1 and covered == 60, "198 real power edges, one grid and 60 covered consumers")
	check.expect(model.power_state().installed_kw == 4800, "40 finite enabled sources")
	for index in 20:
		if index == 0: continue
		var cell := Layout.ids(model, index)
		var held := {}
		for id in cell.values(): Items.merge(held, Items.contents(model.by_id(id)))
		check.expect(held.is_empty(), "all additional cells zero inventory before full-layout clock %d" % index)
	require(Layout.walk(model, Vector2(-31.5, -31.5)), "return to overview after service audit")
	return {"counts": counts, "occupied_cells": model.occupancy.size(), "logistics_edges": edges, "power_edges": model.power_links.size(), "covered_consumers": covered, "service_routes": routes}
