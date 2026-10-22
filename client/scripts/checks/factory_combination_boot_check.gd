extends "res://scripts/checks/factory_routing_boot_check.gd"

const Journey := preload("res://scripts/checks/factory_combination_journey.gd")
const Faults := preload("res://scripts/checks/factory_combination_faults.gd")
const Trace := preload("res://scripts/checks/factory_combination_trace.gd")
var journey: RefCounted
var source_trace: Node
var complete_read := false
var visual_only := false
var fault_id := ""


func run() -> void:
	evidence_topic = "factory-conveyor-combination-v1"
	screenshot_topic = "2026-10-17-factory-conveyor-combination-preview"
	complete_read = "--complete-read" in OS.get_cmdline_user_args()
	visual_only = "--visual-only" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fault="): fault_id = arg.trim_prefix("--fault=")
	journey = Journey.new(self)
	# Routing startup preserves the explicit C evidence topic. No B journey runs.
	await super.run()


func _first_line() -> void:
	world.view.yaw = 0 # Camera-only axis alignment for narrow verified WASD routes.
	world.view.sync_camera()
	await journey.write_journey()


func _restore() -> void:
	world.view.yaw = 0 # Preserve the actor/model; align only the input-facing camera.
	world.view.sync_camera()
	if not fault_id.is_empty():
		await Faults.new(self, journey).run(fault_id)
	else:
		await journey.restore_journey(complete_read, visual_only)


func start_trace() -> void:
	source_trace = Trace.new()
	root.add_child(source_trace)
	source_trace.attach(world.model, ids)


func finish() -> void:
	if finished: return
	finished = true
	for code in held_keys: push_key(code, false)
	held_keys.clear()
	if is_instance_valid(source_trace):
		write_json("source-trace.json", source_trace.report())
		source_trace.enabled = false
	var name := "faults-result.json" if not fault_id.is_empty() else "review-result.json" if visual_only else "complete-read-result.json" if complete_read else "read-result.json" if read_mode else "write-result.json"
	var input_text := "Formal Boot/new ordinary V5; precision HUD placement/button signals; exact recipe/gate setters; routed WASD/F/Tab/Escape; synthetic mouse transfer/cancel/salvage/pause/save; natural production clock, no stock/unlock/actor-position/time injection"
	if read_mode: input_text = "Formal Boot/continue by stable world ID; first-frame same-sequence snapshot; routed WASD/F/Tab/Escape and synthetic mouse pause/transfer/passage/save; no stock/unlock/actor-position/time injection"
	if not fault_id.is_empty(): input_text += "; independent C3 copy fault=" + fault_id + "; actual commands and natural recovery only"
	if visual_only: input_text = "Formal Boot/continue C3 copy; initially paused read-only original framing, 1100x720/1440x900 gate layouts, Tab/F/I/Escape/W interception, rotated ghost and statistics locate; then real warehouse salvage/refund/repair, held-item UI rejection and short natural blocked/eighth-drain demonstration only; no C0-C4 journey or ordinary first-play duration claim"
	write_json(name, {"assertions": driver.assertions, "failures": driver.failures, "stages": stages, "input": input_text, "foreground_seconds": foreground_seconds, "focus_pauses": focus_pauses, "pending_focus_pause": focus_pause}.merged(execution_evidence()))
	print("Combination Boot: %d assertions, %d failures" % [driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)


func _configure(name: String, item: String, quota: int) -> void:
	await _open_nearby(name)
	if finished: return
	var controls: Control = world.discovery_panel.admission_controls
	controls.item.select(world.model.Admission.ALLOWED_ITEMS.find(item) + 1)
	controls.mode.select(1 if quota > 0 else 0)
	controls.limit.value = maxi(1, quota)
	await driver.settle()
	await native_click(controls.apply_button)
	var gate: Dictionary = world.model.by_id(ids[name])
	driver.expect(gate.filter_item == item and gate.quota_limit == quota and gate.quota_used == 0, "exact C gate configuration " + name)
	if not gate.accepting: await native_click(controls.accepting_button)
	driver.expect(gate.accepting, "explicit C gate enable " + name)
	await driver.key(KEY_ESCAPE)


func _gate_layout() -> void:
	for dimensions in [Vector2i(1100, 720), Vector2i(1440, 900)]:
		root.size = dimensions
		await driver.settle(25)
		var bounds: Rect2 = root.get_visible_rect()
		var panel: Control = world.discovery_panel
		var controls: Control = panel.admission_controls
		driver.expect(bounds.encloses(panel.frame.get_global_rect()), "C gate panel fits " + str(dimensions))
		driver.expect(panel.frame.get_global_rect().encloses(panel.result_label.get_global_rect()) and panel.frame.get_global_rect().encloses(panel.buttons.close.get_global_rect()), "C gate result/close reachable " + str(dimensions))
		driver.expect(controls.visible and bounds.encloses(controls.get_global_rect()), "C gate controls visible outside summary scroll " + str(dimensions))
		for button in [controls.apply_button, controls.accepting_button, controls.reset_button]:
			driver.expect(controls.get_global_rect().encloses(button.get_global_rect()) and bounds.encloses(button.get_global_rect()), "C gate main action reachable at " + str(dimensions) + ": " + button.text)
		await native_shot("gate-layout-%dx%d" % [dimensions.x, dimensions.y])
