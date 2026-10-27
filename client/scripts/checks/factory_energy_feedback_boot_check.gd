extends "res://scripts/checks/factory_energy_boot_check.gd"

const Target := preload("res://scripts/factory/interaction_target.gd")
const Markers := preload("res://scripts/factory/admission_markers.gd")
var copy_record := {}


func run() -> void:
	if "--copy-standby" in OS.get_cmdline_user_args():
		if not _copy_legacy():
			quit(1)
			return
	await super.run()


func _copy_legacy() -> bool:
	var batch := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="): batch = arg.trim_prefix("--batch=")
	var directory := SliceCheckPaths.repository_root().path_join("tools/runtime-intake/check-runs/factory-energy-and-focus-feedback-v1").path_join(batch)
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("expected.json")))
	var store := preload("res://scripts/factory/save/store.gd").new(directory.path_join("factory"))
	var entries: Array = store.list_worlds()
	var index := entries.find_custom(func(entry): return entry.id == expected.world_id)
	if index < 0 or not entries[index].ok:
		push_error("Standby copy requires a valid, isolated legacy source")
		return false
	var source: Dictionary = entries[index]
	var path: String = directory.path_join("factory").path_join(source.id).path_join("autosave.json")
	var bytes := FileAccess.get_file_as_bytes(path)
	var result: Dictionary = store.copy_energy(source.id, source.sequence, source.hash, "待机耗电 · 自然检查点副本")
	if not result.ok:
		push_error(result.reason)
		return false
	var doc := Codec.snapshot(result.model, store.world_id, store.world_name, store.sequence)
	copy_record = {"source": source.id, "source_sha256": source.hash, "original_unchanged": bytes == FileAccess.get_file_as_bytes(path), "schema": doc.save_schema_version, "standby_history": result.model.statistics.totals.standby_kj}
	for pair in [["legacy-expected.json", expected], ["expected.json", doc], ["standby-copy.json", copy_record]]:
		var file := FileAccess.open(directory.path_join(pair[0]), FileAccess.WRITE)
		file.store_string(JSON.stringify(pair[1], "\t", false, true))
	var released: Dictionary = store.release()
	if not released.ok: push_error(released.reason)
	return released.ok and copy_record.original_unchanged


func _restore() -> void:
	driver.expect(world.model.standby_power and _snapshot().save_schema_version == 8, "Boot continues explicit V8 with standby enabled")
	if not copy_record.is_empty():
		driver.expect(copy_record.original_unchanged and copy_record.standby_history == 0, "legacy copy preserves source bytes and never back-bills idle")
	await super._restore()


func _review_energy() -> void:
	if world.ui.build: await native_click(world.hud.buttons.build)
	if world.ui.mission: await native_click(world.hud.buttons.mission)
	var gate_id: int = ids.GF
	var gate: Dictionary = world.model.by_id(gate_id)
	world.view.inspection_target = Vector3(gate.x + 0.5, 0, gate.z + 0.5)
	world.view.yaw = 25
	world.view.zoom = 1.2
	world.view.sync_camera()
	await driver.settle(20)
	var before := _snapshot()
	_annotation_contract(gate)
	for dimensions in [Vector2i(1440, 900), Vector2i(1100, 720)]:
		root.size = dimensions
		await driver.settle(25)
		var at := _marker_point(gate_id)
		driver.expect(at != Vector2.INF, "fuel gate marker visible " + str(dimensions))
		if at == Vector2.INF: check_failures(); return
		await driver.motion(at)
		await driver.settle()
		driver.expect(world.ui.focus_device == gate_id and world.hud.admission_markers.hit(at) == gate_id, "marker hover and click use same gate ID")
		driver.expect(world.view.focus_highlight.target_root == world.view.models[gate_id].root and world.view.focus_highlight.shells.size() == world.view.models[gate_id].focus_parts.size(), "outline is only the focused imported gate")
		driver.expect(world.hud.admission_markers.markers.any(func(m): return m.id == gate_id and m.item == gate.filter_item), "marker shows applied filter, independent of transient cargo")
		driver.expect(root.get_visible_rect().encloses(world.hud.footer.get_global_rect()), "footer within window " + str(dimensions))
		await driver.shot("01-gate-focus-%dx%d" % [dimensions.x, dimensions.y])
		for z in [0.55, 1.5]:
			world.view.zoom = z; world.view.sync_camera()
			await driver.settle()
			driver.expect(_marker_point(gate_id) != Vector2.INF and Markers.HIT_SIZE == 40, "marker retains logical size at zoom " + str(z))
		world.view.zoom = 1.2; world.view.sync_camera()
		await driver.settle()
	root.size = Vector2i(1440, 900)
	await driver.settle(20)
	driver.expect(Compare.equivalent(before, Codec.snapshot(world.model, world.store.world_id, world.store.world_name, before.sequence)), "hover camera and resize leave paused world completely unchanged")
	# Reach the actual gate using the existing collision-aware WASD driver.
	await _go("GF", "")
	if finished: return
	if not world.ui.paused: await native_click(world.hud.buttons.pause)
	world.view.inspection_target = Vector3(gate.x + 0.5, 0, gate.z + 0.5)
	await driver.settle()
	var marker := _marker_point(gate_id)
	driver.expect(marker != Vector2.INF and world.model.near_entity(gate), "real walking reaches gate for marker operation")
	if marker == Vector2.INF: check_failures(); return
	await driver.motion(marker)
	await driver.key(KEY_F)
	driver.expect(world.discovery_panel.visible and world.discovery_panel.selected == gate_id, "F opens the hovered gate")
	var modal_pointer := Vector2(1000, 600)
	await driver.motion(modal_pointer)
	driver.expect(world.mouse_position == modal_pointer and world.ui.focus_device == -1, "modal input updates pointer without competing world focus")
	await driver.shot("02-gate-panel")
	await driver.key(KEY_ESCAPE)
	marker = _marker_point(gate_id)
	await driver.motion(marker)
	await driver.mouse(marker, true); await driver.mouse(marker, false)
	driver.expect(world.discovery_panel.visible and world.discovery_panel.selected == gate_id, "clicking gate annotation opens same gate")
	await driver.key(KEY_ESCAPE)
	await driver.motion(_marker_point(gate_id))
	await driver.key(KEY_TAB)
	var cycled: int = world.ui.focus_device
	driver.expect(cycled != gate_id and world.ui.focus_ready, "Tab cycles to another reachable device")
	world.view.yaw += 15; world.view.sync_camera()
	await driver.settle()
	driver.expect(world.ui.focus_device == cycled, "camera motion cannot steal locked keyboard focus")
	await driver.motion(world.tab_pointer_origin + Vector2(1, 0))
	driver.expect(world.ui.focus_device == cycled, "sub-threshold pointer noise preserves Tab target")
	await driver.key(KEY_F)
	driver.expect(world.discovery_panel.visible and world.discovery_panel.selected == cycled, "F opens exactly the Tab-highlighted device")
	await driver.key(KEY_ESCAPE)
	await driver.motion(world.tab_pointer_origin + Vector2(8, 0))
	await driver.motion(_marker_point(gate_id))
	await driver.settle()
	driver.expect(world.ui.focus_device == gate_id and world.interaction_choice == -1, "deliberate pointer motion restores hover focus")
	# Point to a separate belt/neighbor in the same actual dense production layout.
	var neighbors := Target.candidates(world.model)
	var neighbor_found := false
	for target in neighbors:
		if target.kind != "device" or target.id == gate_id: continue
		var at := _visible_hit(target.id)
		if at == Vector2.INF: continue
		await driver.motion(at)
		await driver.settle()
		driver.expect(world.ui.focus_device == target.id and world.view.focus_highlight.target_root == world.view.models[target.id].root, "exact mesh hover selects individual nearby module " + str(target.id))
		await driver.shot("03-neighbor-" + str(target.id))
		neighbor_found = true
		break
	driver.expect(neighbor_found, "dense layout contains a separately pickable neighbor")
	# A distant furnace is visible/selectable, never actionable through the annotation.
	var remote_id: int = ids.F1 if ids.has("F1") else ids.F
	var remote: Dictionary = world.model.by_id(remote_id)
	world.view.inspection_target = Vector3(remote.x + 1, 0, remote.z + 1)
	await driver.settle()
	var remote_at := _visible_hit(remote_id)
	driver.expect(remote_at != Vector2.INF and not world.model.near_entity(remote), "remote test has visible, unreachable furnace")
	if remote_at != Vector2.INF:
		await driver.motion(remote_at); await driver.settle()
		driver.expect(world.ui.focus_device == remote_id and not world.ui.focus_ready and not world.hud.interaction_button.text.begins_with("F"), "distant highlight explains approach without usable F")
		await driver.key(KEY_F)
		driver.expect(not world.discovery_panel.visible and world.ui.selected == remote_id, "F never opens another nearby device when pointing far away")
		await driver.shot("04-remote-focus")
	await _dense_modules()
	# Use real local stop/resume and show the current standby/working power UI.
	await _go("E", "")
	if finished: return
	if not world.ui.paused: await native_click(world.hud.buttons.pause)
	await _open_nearby("E")
	if finished: return
	driver.expect("运行额定" in world.discovery_panel.device_summary.power.text and "待机额定 4" in world.discovery_panel.device_summary.power.text, "device panel distinguishes running and standby ratings")
	await driver.shot("05-energy-device")
	await native_click(world.discovery_panel.buttons.device_toggle)
	driver.expect(world.model.power_state().devices[int(ids.E)].request_kw == 0 and "已停机" in world.discovery_panel.device_summary.production.text and "供电：已停机" in world.discovery_panel.device_summary.power.text, "manual off reads zero without discarding batch")
	await driver.shot("06-device-off")
	await native_click(world.discovery_panel.buttons.device_toggle)
	await driver.key(KEY_ESCAPE)
	await native_click(world.hud.buttons.statistics)
	world.statistics_panel.page.select(1)
	world.statistics_panel.refresh()
	driver.expect("累计运行" in world.statistics_panel.power_summary.text and "待机" in world.statistics_panel.power_legend.text, "power overview exposes work and standby totals")
	await driver.shot("07-standby-statistics")
	world.statistics_panel.hide()
	stage("feedback-reviewed", "V7 source copied to V8; paused mesh/marker/zoom checks; real routed WASD, mouse and F/Tab; device and statistics UI; screenshots separate from natural throughput")
	await _save_checkpoint("feedback-reviewed")


func _dense_modules() -> void:
	# Pick actual imported meshes in the same natural layout; no fixture geometry.
	for type in ["splitter", "belt"]:
		var found := false
		var entities: Array = world.model.entities.filter(func(e): return e.type == type)
		var center: Vector2 = world.hud.world_image.get_global_rect().get_center()
		entities.sort_custom(func(a, b):
			var pa: Vector2 = world.hud.viewport_to_screen(world.view.project(Vector3(a.x + 0.5, 0, a.z + 0.5)))
			var pb: Vector2 = world.hud.viewport_to_screen(world.view.project(Vector3(b.x + 0.5, 0, b.z + 0.5)))
			return pa.distance_squared_to(center) < pb.distance_squared_to(center))
		for entity in entities:
			var at := _visible_hit(entity.id)
			if at == Vector2.INF: continue
			await driver.motion(at); await driver.settle()
			driver.expect(world.ui.focus_device == entity.id and world.view.focus_highlight.target_root == world.view.models[entity.id].root, "dense exact mesh focus " + type)
			await driver.shot("04-dense-" + type)
			found = true
			break
		driver.expect(found, "dense view exposes a pickable " + type)


func _annotation_contract(gate: Dictionary) -> void:
	# Explicit view-only fixtures; never alter the authoritative entity or cargo.
	var probe: Dictionary = gate.duplicate(true)
	probe.filter_item = ""
	driver.expect(Markers.status(probe) == "configure", "unconfigured gate has no invented item")
	probe.filter_item = "industrial_cell"; probe.quota_mode = "unlimited"; probe.accepting = true
	for cargo in ["", "industrial_cell"]:
		probe.cargo = cargo
		driver.expect(Markers.status(probe) == "open", "applied item remains valid with empty or occupied slot")
	probe.accepting = false
	driver.expect(Markers.status(probe) == "closed", "stopped admission keeps applied item")
	probe.quota_mode = "quota"; probe.quota_limit = 2; probe.quota_used = 2
	driver.expect(Markers.status(probe) == "complete", "completed quota takes precedence over closed state including tail cargo")
	var layer: Control = world.hud.admission_markers
	var occupied: Array[Rect2] = []
	layer.markers.clear()
	var anchor := layer.size * Vector2(0.55, 0.7)
	var placed := 0
	for i in 5:
		if layer._place({"id": 900 + i, "item": "industrial_cell", "state": "open", "anchor": anchor}, occupied, world.hud): placed += 1
	driver.expect(placed >= 1 and placed <= 3, "overlap layout is bounded to three levels")
	for a in range(occupied.size()):
		for b in range(a + 1, occupied.size()): driver.expect(not occupied[a].intersects(occupied[b]), "displayed annotation click areas never overlap")
	driver.expect(not layer._place({"anchor": Vector2(-100, -100)}, occupied, world.hud), "offscreen marker cannot become a remote button")
	world.hud.sync_markers(world.view, world.model, world.ui)


func _marker_point(id: int) -> Vector2:
	for marker in world.hud.admission_markers.markers:
		if marker.id == id: return world.hud.admission_markers.global_position + marker.center
	return Vector2.INF


func _visible_hit(id: int) -> Vector2:
	for part in world.view.models[id].focus_parts:
		var faces: PackedVector3Array = part.mesh.get_faces()
		for i in range(0, faces.size(), 3):
			var point: Vector3 = part.global_transform * ((faces[i] + faces[i + 1] + faces[i + 2]) / 3.0)
			var screen: Vector2 = world.view.project(point)
			var at: Vector2 = world.hud.viewport_to_screen(screen)
			if world.hud.world_point(at) != null and world.hud.admission_markers.hit(at) == -1 and world.view.hit(screen) == id:
				return at
	return Vector2.INF
