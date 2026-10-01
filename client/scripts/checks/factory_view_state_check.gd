extends SceneTree

const View := preload("res://scripts/factory/view.gd")
const Fixture := preload("res://scripts/checks/factory_load_fixture.gd")
var failures: Array[String] = []
var checks := 0
var view: Node3D
var model: RefCounted
var ui := {"build": false, "tool": "", "cell": Vector2i(28, 28), "dir": 0,
	"selected": -1, "stroke": Array([], TYPE_VECTOR2I, "", null)}


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)


func _run() -> void:
	var fixture := Fixture.build()
	assert(fixture.ok)
	model = fixture.model
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	root.add_child(viewport)
	view = View.new()
	viewport.add_child(view)
	view.draw(model, model.actor, ui)
	expect(view.models.size() == 1100, "all engineering entities have views")
	model.advance(93.25)
	view.draw(model, model.actor, ui)
	var statuses_match := true
	for entity in model.entities:
		if entity.type != "belt":
			statuses_match = statuses_match and view.models[entity.id].lamp_mat.albedo_color == Color(View.STATUS[model.feedback(entity).kind])
	expect(statuses_match, "each device retains its own feedback with shared status materials")
	var belt: Dictionary = model.entities.filter(func(e): return e.type == "belt" and e.cargo == "crystal")[0]
	var cargo: Node3D = view.models[belt.id].cargo
	expect(cargo.visible, "production reveals previously empty belt cargo")
	var transform := cargo.transform
	view.draw(model, model.actor, ui)
	expect(cargo.transform == transform, "same production state preserves cargo pose")
	model.advance(0.05)
	view.draw(model, model.actor, ui)
	expect(cargo.transform != transform, "next production step moves cargo")
	var reactor: Dictionary = model.entities.filter(func(e): return e.type == "reactor" and e.processing)[0]
	expect(view.models[reactor.id].bar.scale.x > 0.001, "partial processing has visible progress")
	var time_before: float = model.time
	expect(model.salvage(belt.id).ok, "salvage a loaded belt while production is paused")
	view.draw(model, model.actor, ui)
	expect(not view.models.has(belt.id), "paused salvage removes the visible belt")
	var storage: Dictionary = model.entities.filter(func(e): return e.type == "storage")[0]
	var fill_before: float = view.models[storage.id].bar.scale.x
	expect(model.deposit(storage.id).ok, "deposit salvaged material while paused")
	view.draw(model, model.actor, ui)
	expect(view.models[storage.id].bar.scale.x > fill_before and model.time == time_before,
		"paused command refreshes storage fill without advancing time")
	ui.selected = storage.id
	ui.build = true
	ui.tool = "belt"
	view.draw(model, model.actor, ui)
	expect(view.grid.visible and view.selection.get_child_count() > 0 and view.ghost.get_child_count() > 0,
		"selection and building preview update without a production step")
	var actor_angle: float = view.engineer.rotation.y
	model.actor.angle += 0.1
	view.draw(model, model.actor, ui)
	expect(not is_equal_approx(view.engineer.rotation.y, actor_angle), "actor updates without a production step")
	view.invalidate()
	view.draw(model, model.actor, ui)
	expect(view.models.size() == model.entities.size() and view.models[storage.id].bar.scale.x > fill_before,
		"explicit rebuild restores current production visuals")
	# Replacing a model can reuse the same time and revision with different inventory.
	var replacement := Fixture.build()
	assert(replacement.ok)
	replacement.model.advance(93.30)
	var removed: Dictionary = replacement.model.by_id(belt.id)
	assert(replacement.model.salvage(removed.id).ok)
	var other_storage: Dictionary = replacement.model.entities.filter(func(e): return e.type == "storage" and e.id != storage.id)[0]
	assert(replacement.model.deposit(other_storage.id).ok)
	expect(replacement.model.revision == model.revision and replacement.model.time == model.time,
		"replacement fixture reuses revision and production time")
	var replacement_bar: float = view.models[other_storage.id].bar.scale.x
	view.draw(replacement.model, replacement.model.actor, ui)
	expect(view.models[other_storage.id].bar.scale.x > replacement_bar,
		"replacement model refreshes inventory even with matching revision and time")
	viewport.queue_free()
	await process_frame
	await process_frame
	for failure in failures:
		push_error(failure)
	print("Factory view state checks: %d assertions, %d failures." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
