extends SceneTree

const PowerCheck := preload("res://scripts/checks/factory_power_check.gd")
const Summary := preload("res://scripts/factory/device_summary.gd")
const DevicePanel := preload("res://scripts/factory/discovery_panel.gd")
const Hud := preload("res://scripts/factory/hud.gd")
const View := preload("res://scripts/factory/view.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
var checks := 0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("run")


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error(label)


func snapshot(model: RefCounted) -> Dictionary:
	return Codec.snapshot(model, PowerCheck.ID, "设备交互定向验证", 1)


func run() -> void:
	var model := PowerCheck.line()
	var summary := Summary.new()
	root.add_child(summary)
	var reactor: Dictionary = model.by_id(2)
	var before := snapshot(model)
	summary.refresh(model, reactor)
	expect(summary.production.text == "还需：晶体 ×2", "empty reactor explains exact material shortage")
	expect("未接线" in summary.power.text, "material shortage does not conceal disconnected power")
	expect("传送带 #8" in summary.ports.text and "传送带 #9" in summary.ports.text, "actual input and output belt identities shown")
	expect(snapshot(model) == before, "viewing does not change authoritative state or statistics")
	model.connect_power(13, 1)
	model.connect_power(14, 2)
	model.advance(9.35)
	summary.refresh(model, reactor)
	expect(reactor.processing and summary.progress.value > 0 and summary.progress.value < 100, "natural half batch renders fractional progress")
	expect("本批已投入：晶体 ×2" == summary.production.text, "in-process inputs distinguished from next batch buffer")
	var progress: float = summary.progress.value
	model.set_source_enabled(13, false)
	model.advance(1)
	summary.refresh(model, reactor)
	expect(summary.progress.value == progress and "无启用电源" in summary.power.text, "blackout preserves and explains partial batch")
	model.set_source_enabled(13, true)
	model.salvage(9)
	model.advance(12)
	summary.refresh(model, reactor)
	expect(reactor.output.get("catalyst", 0) == 1 and "输出尚未清空" in summary.production.text, "actual blocked output explains recovery action")
	expect("输出接带 (-10, 0)：未接带" in summary.ports.text, "missing output identifies exact repair cell")
	model.place("belt", Vector2i(-10, 0), 2)
	summary.refresh(model, reactor)
	expect("方向不接通" in summary.ports.text, "reverse output belt diagnosed")
	model.rotate(model.entity_at(Vector2i(-10, 0)).id)
	summary.refresh(model, reactor)
	expect(not "方向不接通" in summary.ports.text, "perpendicular output belt remains accepted by logistics")
	# Signal-driven operations verify command wiring; real hit testing is covered by the Boot check.
	var panel := DevicePanel.new()
	root.add_child(panel)
	model.actor.x = 0
	model.actor.z = 5
	panel.show_device(model, reactor.id)
	expect(panel.device_only and not panel.discovery_content.visible, "selected-device entry isolates device actions")
	expect(panel.buttons.catalyst_take_all.disabled and "远程查看" in panel.inventory.text, "remote viewer sees explicit proximity restriction")
	before = snapshot(model)
	var rejected: Dictionary = model.transfer(reactor.id, "catalyst", false, true)
	expect(not rejected.ok and snapshot(model) == before, "authority still rejects remote transfer without mutation")
	model.actor.x = -14
	model.actor.z = -1
	panel.refresh()
	expect(not panel.buttons.catalyst_take_all.disabled, "nearby transfer enabled")
	panel.buttons.catalyst_take_all.pressed.emit()
	expect(reactor.output.is_empty() and model.bag.get("catalyst", 0) == 1, "device take-all transfers actual product")
	expect("已转移 1 件" in panel.result_label.text, "transfer reports actual amount")
	model.advance(0.5)
	panel.refresh()
	var balance: int = model.material_balance().equivalent
	var consumed: Dictionary = model.statistics.totals.consumed.duplicate()
	expect(reactor.processing and not panel.buttons.cancel_batch.disabled, "new partial batch offers cancellation")
	panel.buttons.cancel_batch.pressed.emit()
	expect(not reactor.processing and model.material_balance().equivalent == balance, "cancel from device panel returns complete invested batch")
	expect(model.statistics.totals.consumed == consumed, "cancel does not fabricate completed consumption")
	panel.buttons.crystal_take_all.pressed.emit()
	model.actor.x = 2.5
	model.actor.z = 3.5
	expect(model.survey_sample(true).ok, "legal unique sample acquisition prepares alternate recipe")
	model.actor.x = -14
	model.actor.z = -1
	panel.refresh()
	panel.recipe.select(panel.recipe_ids.find("solvent_trial"))
	panel.buttons.recipe.pressed.emit()
	expect(reactor.recipe_id == "solvent_trial" and panel.device_summary.values.process.text.begins_with("矿壳试制"), "recipe command and visible recipe update together")
	panel.buttons.crust_sample_put_one.pressed.emit()
	expect(reactor.input.get("crust_sample", 0) == 1 and not model.bag.has("crust_sample"), "device deposit moves unique sample once")
	before = snapshot(model)
	panel.recipe.select(panel.recipe_ids.find("basic_catalyst"))
	panel.buttons.recipe.pressed.emit()
	expect(snapshot(model) == before and "取空输入和输出" in panel.result_label.text, "blocked recipe change retains actual state and reason")
	panel.hide()
	await _views(model)
	await _power_preview()
	await _ground_sample()
	var saved := snapshot(model)
	var restored := Codec.decode(JSON.parse_string(JSON.stringify(saved, "", false, true)), PowerCheck.ID)
	expect(restored.ok and saved.save_schema_version == 2, "device operations remain inside existing schema 2 contract")
	_capacity(panel)
	summary.queue_free()
	panel.queue_free()
	await process_frame
	await process_frame
	print("Factory device interaction: %d assertions, %d failures." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _capacity(panel: AcceptDialog) -> void:
	# Synthetic full inventories test presentation and rejection only, not natural progression.
	var model := PowerCheck.line()
	var warehouse: Dictionary = model.by_id(3)
	warehouse.items = {"crystal": 200}
	model.bag = {"catalyst": 200}
	model.actor.x = -5
	model.actor.z = 2
	panel.show_device(model, warehouse.id)
	expect(panel.device_summary.status.text == "仓储已满" and "200 / 200" in panel.device_summary.values.input.text, "full warehouse displays its actual capacity and blockage")
	var before := snapshot(model)
	panel.buttons.crystal_take_all.pressed.emit()
	expect(snapshot(model) == before and "容量不足" in panel.result_label.text, "full bag rejects withdrawal and shows command reason without mutation")
	panel.buttons.catalyst_put_one.pressed.emit()
	expect(snapshot(model) == before and "容量不足" in panel.result_label.text, "full warehouse rejects deposit without mutation")
	panel.hide()
	panel.show_device(model, warehouse.id)
	expect(not panel.result_label.has_theme_color_override("font_color"), "reopening resets obsolete failure feedback")
	panel.hide()


func _views(model: RefCounted) -> void:
	var hud := Hud.new()
	root.size = Vector2i(1440, 900)
	root.add_child(hud)
	var ui := {"build": true, "tool": "reactor", "cell": Vector2i(-13, 5), "dir": 0,
		"selected": -1, "stroke": Array([], TYPE_VECTOR2I, "", null), "paused": false, "mission": false}
	hud.refresh(model, model.actor, ui, true)
	var view := View.new()
	view.world_model = model
	hud.subviewport.add_child(view)
	view.draw(model, model.actor, ui)
	expect(view.build_model.visible and view.build_model.get_child_count() == 1, "formal placement preview uses imported device model")
	var hints: Array = view.port_hints.get_children().filter(func(h): return h.get_meta("entity_id") == -1)
	expect(hints.size() == 2 and view.port_hints.find_children("*", "Label3D", true, false).is_empty(), "preview shows both reactor ports without floating text")
	var displayed := {}
	for hint in hints:
		displayed[hint.get_meta("role")] = hint.get_meta("cell")
	expect(displayed == {"input": Vector2i(-14, 7), "output": Vector2i(-10, 7)}, "preview marks outside docking cells, not occupied footprint")
	var placed: Dictionary = model.place("reactor", ui.cell).entity
	model.place("belt", displayed.input, 0)
	model.place("belt", displayed.output, 0)
	expect(model._sink_accepts(placed, model.entity_at(displayed.input), "crystal"), "input preview cell actually accepts eastbound material")
	model.actor.x = -14
	model.actor.z = 6
	expect(model.transfer(placed.id, "crystal", true, true).ok, "preview fixture uses real recovered crystal")
	# Drive a new line with existing authoritative power commands, then verify the displayed exit.
	var source: Dictionary = model.place("power_source", Vector2i(-18, 3)).entity
	expect(model.connect_power(source.id, placed.id).ok, "preview fixture gets legal power")
	model.advance(10)
	expect(model.entity_at(displayed.output).cargo == "catalyst", "real production exits through the displayed output cell")
	ui.tool = ""
	ui.selected = placed.id
	hud.refresh(model, model.actor, ui, true)
	view.draw(model, model.actor, ui)
	var node_id: int = view.port_hints.get_child(0).get_instance_id()
	view.yaw += 90
	view.zoom = 0.6
	view.sync_camera()
	view.draw(model, model.actor, ui)
	expect(view.port_hints.get_child(0).get_instance_id() == node_id, "camera changes preserve actual world-space port cues")
	model.advance(0.05)
	view.draw(model, model.actor, ui)
	expect(view.port_hints.get_child(0).get_instance_id() == node_id, "simulation ticks do not rebuild port cues")
	expect(hud.device_summary.visible and hud.buttons.device.visible, "selected production device exposes summary and operations")
	ui.selected = 3
	hud.refresh(model, model.actor, ui, true)
	expect(hud.device_summary.cards.input.visible and not hud.device_summary.cards.output.visible, "terminal inventory has no false output")
	ui.tool = "belt"
	ui.cell = Vector2i(-14, 0)
	view.draw(model, model.actor, ui)
	expect(view.port_hints.get_children().any(func(h): return h.get_meta("entity_id") == 2), "dragging near a device retains docking guidance")
	ui.tool = ""
	ui.selected = -1
	view.draw(model, model.actor, ui)
	expect(view.port_hints.get_child_count() == 0 and not view.build_model.visible, "cancel removes all transient affordances")
	var legacy := preload("res://scripts/factory/model.gd").new()
	var old: Dictionary = legacy.place("reactor", Vector2i(-13, -2)).entity
	ui.selected = old.id
	hud.refresh(legacy, legacy.actor, ui, true)
	await process_frame
	expect(hud.details.visible and not hud.device_summary.visible and not hud.buttons.device.visible, "foundation keeps original inspector and operations")
	view.queue_free()
	await process_frame
	await _foundation_preview(hud, legacy, ui)
	hud.queue_free()
	await process_frame


func _foundation_preview(hud: Control, model: RefCounted, ui: Dictionary) -> void:
	var view := View.new()
	view.world_model = model
	hud.subviewport.add_child(view)
	ui.selected = -1
	var before := snapshot(model)
	var expected := {"collector": [Vector2i(-6, 0)], "reactor": [Vector2i(-2, 0), Vector2i(2, 0)], "storage": [Vector2i(5, 0)]}
	for type in expected:
		ui.tool = type
		ui.cell = model.REFERENCE[type]
		view.draw(model, model.actor, ui)
		expect(view.build_model.visible and view.build_model.get_child_count() == 1, "foundation previews imported " + type + " before placement")
		var previews := view.port_hints.get_children().filter(func(h): return h.get_meta("entity_id") == -1)
		var cells := previews.map(func(h): return h.get_meta("cell"))
		expect(view.port_hints.visible and cells == expected[type], "foundation previews actual docking cells for " + type)
		expect(snapshot(model) == before, "foundation " + type + " preview leaves inventory and save state unchanged")
	ui.tool = "collector"
	ui.cell = Vector2i(-6, 3)
	view.draw(model, model.actor, ui)
	expect(not model.placement(ui.tool, ui.cell).ok and view.build_model.visible, "invalid foundation position still shows device outline")
	ui.tool = ""
	view.draw(model, model.actor, ui)
	expect(not view.build_model.visible and view.port_hints.get_child_count() == 0, "foundation cancel removes preview and port hints")
	expect(not view.power_range.visible, "foundation world has no explicit power range overlay")


func _power_preview() -> void:
	var model := PowerCheck.line()
	var grid: GDScript = model.Grid
	var from := {"type": "power_junction", "x": -13, "z": -5}
	var consumer := {"type": "reactor", "x": -8.0, "z": -6}
	expect(grid.reachability(from, consumer, model.discovery.passages).ok, "consumer at exactly six center-to-center cells is reachable")
	consumer.x += 0.01
	expect(not grid.reachability(from, consumer, model.discovery.passages).ok, "consumer beyond six cells is rejected")
	var node := {"type": "power_junction", "x": -1.0, "z": -5}
	expect(grid.reachability(from, node, model.discovery.passages).ok, "node at exactly twelve center-to-center cells is reachable")
	node.x += 0.01
	expect(not grid.reachability(from, node, model.discovery.passages).ok, "node beyond twelve cells is rejected")
	var left := {"type": "power_junction", "x": -1, "z": 0}
	var right := {"type": "power_junction", "x": 8, "z": 0}
	expect(not grid.reachability(left, right, {"outer": false, "inner": false}).ok, "closed mineral shell blocks nearby nodes")
	expect(grid.reachability(left, right, {"outer": true, "inner": false}).ok, "opened corridor permits same connection")
	var hud := Hud.new()
	root.add_child(hud)
	var view := View.new()
	view.world_model = model
	hud.subviewport.add_child(view)
	var ui := {"build": true, "tool": "power_junction", "cell": Vector2i(-17, -3), "dir": 0,
		"selected": -1, "stroke": Array([], TYPE_VECTOR2I, "", null), "paused": true, "mission": false}
	var before := snapshot(model)
	view.draw(model, model.actor, ui)
	hud.refresh(model, model.actor, ui, true)
	var guide: Node3D = view.power_range
	expect(guide.visible and hud.power_help.visible and "6 格" in hud.power_help.text and "12 格" in hud.power_help.text, "power placement exposes both ranges and their legend")
	expect(guide.get_node("ConsumerRange").get_meta("radius") == 6.0 and guide.get_node("NodeRange").get_meta("radius") == 12.0, "rendered circles use authoritative radii")
	expect(guide.get_node("ConsumerRange").position == Vector3(-16.5, 0.105, -2.5), "junction circles originate at footprint center")
	var eligible: Array = guide.targets.get_children().map(func(h): return h.get_meta("entity_id"))
	expect(eligible == [1, 2, 13, 14], "nearby consumers and nodes highlighted; passive facilities excluded")
	expect(snapshot(model) == before, "power preview neither wires devices nor changes save state")
	var ring_id: int = guide.get_node("ConsumerRange").get_instance_id()
	model.advance(0.05)
	view.yaw += 90
	view.zoom = 0.6
	view.draw(model, model.actor, ui)
	expect(guide.get_node("ConsumerRange").get_instance_id() == ring_id, "production ticks and camera changes retain range geometry")
	ui.cell = Vector2i(-28, 10)
	view.draw(model, model.actor, ui)
	expect(guide.targets.get_child_count() == 0, "moving outside both ranges removes target highlights")
	ui.cell = Vector2i(-6, -1)
	view.draw(model, model.actor, ui)
	expect(not guide.get_node("ConsumerRange").get_meta("valid") and guide.targets.get_child_count() == 0, "invalid occupied placement has invalid rings and no targets")
	ui.cell = Vector2i(2, -1)
	view.draw(model, model.actor, ui)
	expect(guide.get_node("ConsumerRange").get_meta("blocked_segments") > 0, "closed shell marks blocked circle segments")
	ui.tool = "power_source"
	ui.cell = Vector2i(-25, -8)
	view.draw(model, model.actor, ui)
	expect(guide.get_node("ConsumerRange").position == Vector3(-23.5, 0.105, -6.5), "three-cell source centers its circles correctly")
	ui.tool = ""
	ui.selected = 14
	view.draw(model, model.actor, ui)
	expect(guide.visible and guide.get_node("ConsumerRange").position == Vector3(-12.5, 0.105, -4.5), "selected existing node retains correct ranges")
	eligible = guide.targets.get_children().map(func(h): return h.get_meta("entity_id"))
	for candidate in model.entities:
		expect(eligible.has(candidate.id) == grid.connection(model, 14, candidate.id).ok, "highlight matches actual connection command for entity %d" % candidate.id)
	ui.selected = 1
	ui.power_from = 13
	view.draw(model, model.actor, ui)
	expect(guide.visible and guide.get_node("ConsumerRange").position == Vector3(-18.5, 0.105, -4.5), "wiring mode uses origin node rather than selected consumer")
	ui.tool = "belt"
	view.draw(model, model.actor, ui)
	hud.refresh(model, model.actor, ui, true)
	expect(not guide.visible and not hud.power_help.visible and guide.targets.get_child_count() == 0, "switching to logistics tool clears power guidance")
	ui.tool = "power_junction"
	view.device_affordances = false
	view.draw(model, model.actor, ui)
	expect(not guide.visible, "independent demo can disable formal range guidance")
	hud.queue_free()
	await process_frame


func _ground_sample() -> void:
	var model := PowerCheck.Model.new(true)
	var hud := Hud.new()
	root.add_child(hud)
	var view := View.new()
	view.world_model = model
	hud.subviewport.add_child(view)
	var ui := {"build": true, "tool": "", "cell": Vector2i.ZERO, "dir": 0, "selected": -1,
		"stroke": Array([], TYPE_VECTOR2I, "", null), "paused": true, "mission": false, "power_from": 0}
	view.draw(model, model.actor, ui)
	hud.sync_sample(view, model, ui)
	expect(view.sample_icon.visible and not hud.sample_button.visible and view.barriers.find_children("*", "Label3D", true, false).is_empty(), "distant sample has shape and icon without name text")
	expect(view.hit_sample(view.sample_screen()), "sample icon is directly hittable at its rendered screen position")
	model.actor.x = 1
	model.actor.z = 2.5
	view.draw(model, model.actor, ui)
	hud.sync_sample(view, model, ui)
	await process_frame
	expect(hud.sample_button.visible and "矿壳样本" in hud.sample_button.text and "F" in hud.sample_button.text, "approaching sample reveals its name and pickup key")
	expect(hud.world_point(hud.sample_button.get_global_rect().get_center()) == null, "pickup button blocks click-through to world placement")
	var icon_id: int = view.sample_icon.get_instance_id()
	view.zoom = 0.6
	view.draw(model, model.actor, ui)
	expect(view.sample_icon.get_instance_id() == icon_id, "camera movement retains sample visual rather than rebuilding terrain")
	ui.tool = "reactor"
	hud.sync_sample(view, model, ui)
	expect(not hud.sample_button.visible, "placement mode does not offer a conflicting pickup action")
	ui.tool = ""
	model.actor.x = 4.25
	hud.sync_sample(view, model, ui)
	expect(not hud.sample_button.visible, "closed shell prevents a nearby-looking pickup prompt")
	model.actor.x = 1
	model.survey_sample(true)
	view.draw(model, model.actor, ui)
	hud.sync_sample(view, model, ui)
	await process_frame
	expect(not hud.sample_button.visible and not view.hit_sample(view.sample_screen()) and not is_instance_valid(view.sample_icon), "pickup removes icon, name and ground hit target")
	hud.queue_free()
	await process_frame
