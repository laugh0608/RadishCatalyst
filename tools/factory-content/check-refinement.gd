extends SceneTree

const DemoModel := preload("res://scripts/prototypes/factory_refinement/model.gd")
const Demo := preload("res://scripts/prototypes/factory_refinement/demo.gd")
var assertions := 0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("run")


func expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)


func place(model: RefCounted, type: String, cell: Vector2i) -> Dictionary:
	var result: Dictionary = model.place(type, cell)
	expect(result.ok, "placement " + type + str(cell))
	return result.get("entity", {})


func run() -> void:
	root.content_scale_size = Vector2i(1440, 900)
	root.size = Vector2i(1440, 900)
	var model := DemoModel.new()
	var source := place(model, "power_source", Vector2i(-20, 4))
	var collector := place(model, "collector", Vector2i(-20, -1))
	var reactor := place(model, "reactor", Vector2i(-14, -2))
	var warehouse := place(model, "storage", Vector2i(-8, -1))
	expect(collector.power_node_id == source.id, "consumer placed after source auto-connects")
	expect(reactor.power_node_id == 0, "outside coverage remains unpowered")
	var node := place(model, "power_junction", Vector2i(-15, 3))
	expect(reactor.power_node_id == node.id, "node placed after device auto-connects")
	expect(model.power_links.size() == 1, "source and junction link once")
	for x in [-18, -17, -16, -15, -11, -10, -9]:
		place(model, "belt", Vector2i(x, 0))
	model.advance(30)
	expect(warehouse.items.get("catalyst", 0) > 0, "real model production reaches warehouse")
	model.set_source_enabled(source.id, false)
	var generated: int = model.generated
	var completed: int = model.completed
	model.advance(5)
	expect(model.generated == generated and model.completed == completed, "power off stops work")
	model.set_source_enabled(source.id, true)
	model.advance(15)
	expect(model.completed > completed, "power resumes without resetting batches")
	model.salvage(node.id, true)
	expect(reactor.power_node_id == 0, "removing junction disconnects reactor")
	expect(model.covers({"type": "power_junction", "x": -15, "z": 3}, {"type": "power_junction", "x": -9, "z": 3}), "radius includes exact boundary")
	expect(not model.covers({"type": "power_junction", "x": -15, "z": 3}, {"type": "power_junction", "x": -8, "z": 3}), "radius excludes outside boundary")
	expect(not model.covers({"type": "power_junction", "x": 3, "z": 0}, {"type": "power_junction", "x": 8, "z": 0}), "closed mineral shell blocks coverage")
	var overlap := DemoModel.new()
	var a := place(overlap, "power_source", Vector2i(-24, -7))
	var b := place(overlap, "power_source", Vector2i(-16, -7))
	var c := place(overlap, "reactor", Vector2i(-20, -5))
	expect(c.power_node_id == a.id and overlap.power_links.is_empty(), "equal distance uses stable id; consumer does not bridge networks")
	overlap.set_source_enabled(a.id, false)
	expect(c.power_node_id == b.id, "enabled network takes priority")
	var ui := Demo.new()
	root.add_child(ui)
	await process_frame
	expect(ui.view.prepared and ui.model.entities.size() == 3, "demo scene constructs with real imported assets")
	expect(ui.guide_index == 0, "guide starts with reactor placement")
	ui.ui.selected = ui.find_type("power_source").id
	ui.refresh_panel()
	await process_frame
	await process_frame
	expect(ui.notice.get_global_rect().end.y <= 900, "power panel fits 1440x900 including footer")
	ui.toggle_source()
	expect("重新开启" in ui.guide.text, "guide distinguishes stopped source from missing coverage")
	ui.free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("REFINEMENT_CHECK_PASSED assertions=", assertions)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
