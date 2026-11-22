extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Route := preload("res://scripts/checks/factory_integrated_first_route.gd")
const Driver := preload("res://scripts/checks/factory_window_driver.gd")
const Materials := preload("res://scripts/prototypes/factory_camera/material_study.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const Compare := preload("res://scripts/checks/factory_expansion_compare.gd")
const Rules := Route.Model.Integrated
const View := preload("res://scripts/factory/view.gd")
const MINIMUM := Vector2i(1100, 720)
const REACTOR_SOURCE := "res://assets/factory/refinement/reactor.glb"
const REACTOR_CURRENT := "res://assets/factory/reactor.glb"

var boot: Node
var world: Control
var model: RefCounted
var driver := Driver.new()
var original: PackedScene
var candidate: PackedScene
var bare_reactor: PackedScene
var subject := "core"
var evidence: String
var art: String
var survey := {}
var comparison_size: Vector2i


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var batch := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="):
			batch = arg.trim_prefix("--batch=")
		elif arg.begins_with("--art="):
			art = arg.trim_prefix("--art=")
		elif arg.begins_with("--subject="):
			subject = arg.trim_prefix("--subject=")
	var art_root := SliceCheckPaths.repository_root().path_join("assets/art-intake")
	evidence = SliceCheckPaths.check_run("factory-r2-%s-v1" % subject, false).path_join(batch)
	if subject not in ["core", "reactor"] or not batch.is_valid_filename() or ".." in batch or DisplayServer.get_name() == "headless" \
			or not art.simplify_path().begins_with(art_root + "/") \
			or not DirAccess.dir_exists_absolute(evidence) or not DirAccess.dir_exists_absolute(art):
		push_error("Use the R2 window runner to prepare both isolated batch directories.")
		quit(2)
		return
	root.mode = Window.MODE_WINDOWED
	comparison_size = Vector2i(1440, 900).min(DisplayServer.screen_get_usable_rect().size - Vector2i(32, 48))
	root.size = comparison_size
	root.move_to_center()
	Engine.max_fps = 60
	driver.shot_root = art
	root.add_child(driver)
	candidate = _make_reactor_candidate() if subject == "reactor" else _make_candidate()
	if candidate != null and await _open_factory():
		if subject == "reactor":
			await _compare_reactor()
		else:
			await _compare()
	_end()


func _make_candidate() -> PackedScene:
	original = load(Rules.MODEL_PATH)
	var instance := original.instantiate() as Node3D
	Materials.new().apply(instance.find_children("*", "MeshInstance3D", true, false), "core", 2)
	var path := art.path_join("core-r2.tscn")
	var reloaded := _save_candidate(instance, path)
	if reloaded == null:
		return null
	var anchor_error := View._check_core_asset(reloaded, 2)
	driver.expect(anchor_error.is_empty(), "reloaded asset agrees with all 16 official anchors and both tiers: " + anchor_error)
	if not anchor_error.is_empty():
		return null
	var probe := reloaded.instantiate() as Node3D
	var surfaces := _surface_materials(probe)
	probe.free()
	var overrides := surfaces.filter(func(row): return not row.texture.is_empty())
	driver.expect(surfaces.size() == 5 and overrides.size() == 4 and overrides.all(func(row): return row.triplanar),
		"same five imported surfaces including the inactive tier, four approved overrides")
	survey.asset = {"baseline": Rules.MODEL_PATH, "candidate": path, "surfaces": surfaces,
		"sha256": FileAccess.get_sha256(path)}
	return reloaded


func _save_candidate(instance: Node3D, path: String) -> PackedScene:
	var packed := PackedScene.new()
	var packed_result := packed.pack(instance)
	instance.free()
	driver.expect(packed_result == OK, "pack R2 mesh and overrides")
	if packed_result != OK:
		return null
	var saved := ResourceSaver.save(packed, path)
	driver.expect(saved == OK, "write isolated R2 scene")
	if saved != OK:
		return null
	var reloaded := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	driver.expect(reloaded != null, "candidate can be loaded back from its own scene")
	return reloaded


func _make_reactor_candidate() -> PackedScene:
	original = load(REACTOR_CURRENT)
	bare_reactor = load(REACTOR_SOURCE)
	var instance := bare_reactor.instantiate() as Node3D
	Materials.new().apply(instance.find_children("*", "MeshInstance3D", true, false), "reactor", 2)
	var path := art.path_join("reactor-r2.tscn")
	var reloaded := _save_candidate(instance, path)
	if reloaded == null:
		return null
	var probe := reloaded.instantiate() as Node3D
	root.add_child(probe)
	var surfaces := _surface_materials(probe)
	var bounds := AABB()
	var first := true
	for part: MeshInstance3D in probe.find_children("*", "MeshInstance3D", true, false):
		var part_bounds := (probe.global_transform.affine_inverse() * part.global_transform) * part.get_aabb()
		bounds = part_bounds if first else bounds.merge(part_bounds)
		first = false
	probe.free()
	var overrides := surfaces.filter(func(row): return not row.texture.is_empty())
	driver.expect(surfaces.size() == 7 and overrides.size() == 4 and overrides.all(func(row): return row.triplanar),
		"reloaded reactor retains seven imported surfaces and four approved overrides")
	driver.expect(bounds.position.x >= -1.5 and bounds.end.x <= 1.5 and bounds.position.z >= -1.5 and bounds.end.z <= 1.5
		and is_zero_approx(bounds.position.y), "reactor stays inside its three-by-three footprint at floor level")
	survey.asset = {"baseline": REACTOR_CURRENT, "geometry_source": REACTOR_SOURCE, "candidate": path,
		"source_sha256": FileAccess.get_sha256(REACTOR_SOURCE), "sha256": FileAccess.get_sha256(path), "surfaces": surfaces,
		"bounds_min": [bounds.position.x, bounds.position.y, bounds.position.z], "bounds_max": [bounds.end.x, bounds.end.y, bounds.end.z]}
	return reloaded


func _surface_materials(asset: Node3D) -> Array[Dictionary]:
	var surfaces: Array[Dictionary] = []
	for part: MeshInstance3D in asset.find_children("*", "MeshInstance3D", true, false):
		for i in part.mesh.get_surface_count():
			var material := part.get_active_material(i) as StandardMaterial3D
			var texture := material.albedo_texture if material != null else null
			surfaces.append({"mesh": String(part.name), "surface": i,
				"texture": texture.resource_path if texture != null else "",
				"triplanar": texture != null and material.uv1_triplanar})
	return surfaces


func _open_factory() -> bool:
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(evidence.path_join("slice"))
	boot.factory_save_root = evidence.path_join("factory")
	root.add_child(boot)
	await driver.settle(12)
	driver.expect(root.has_focus(), "foreground window before test input")
	if not root.has_focus():
		return false
	await driver.click(boot.startup_menu.find_child("FactoryButton", true, false))
	var menu: Control = boot.factory_menu
	var supplies: Array[String] = []
	for i in menu.world_type.item_count:
		supplies.append(menu.world_type.get_item_metadata(i))
	var index := supplies.find(Rules.SUPPLY_ID)
	driver.expect(index >= 0 and Rules.Frontier.SUPPLY_ID not in supplies, "normal menu offers foundation with D1 gated")
	if index < 0:
		return false
	menu.world_ready.connect(func(_store, _model, _save):
		if boot.factory_world != null:
			boot.factory_world._set_paused(true), CONNECT_ONE_SHOT)
	menu.world_type.select(index)
	menu.title_input.text = "R2 基础反应器 · 产线对照" if subject == "reactor" else "R2 核心首件 · 基础整合对照"
	await driver.click(menu.create_button)
	world = boot.factory_world
	driver.expect(world != null and world.initialized, "Boot creates an isolated schema 9 world")
	if world == null or not world.initialized:
		return false
	model = world.model
	driver.world = world
	driver.expect(model.core.level == 1 and model.statistics.ticks == 0 and model.entities.size() == 1,
		"fresh core I and a frozen clock")
	return true


func _compare() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("layout.json")))
	var route := Route.new(model, layout)
	route.prepare_core_upgrade()
	route.walk_to(Vector2(-8, 20.5))
	_use_asset(original)
	await driver.shot("01-current-yard-core-I")
	_set_work_surface()
	await _pair("02-core-I-default", 21)
	if not await _upgrade():
		return
	route.finish_bootstrap()
	route.energy_line()
	route.steady()
	route.walk_to(Vector2(-8, 20.5))
	survey.traffic = route.observe_core_outputs()
	driver.expect(survey.traffic.size() == 4 and model.material_balance().balanced,
		"all four genuine output belts carry their configured item")
	_redraw()
	await _pair("04-core-II-default", 21)
	await _pair("05-core-II-close", 16)
	await _pair("06-core-II-wide", 28)
	root.size = MINIMUM
	root.move_to_center()
	await driver.settle(12)
	driver.expect(root.size == MINIMUM and world.hud.subviewport.size.x == MINIMUM.x, "real minimum window and render width")
	await _pair("07-core-II-minimum", 21)
	_verify_ports()
	await _pick_core()
	root.size = comparison_size
	root.move_to_center()
	await driver.settle(12)
	await _measure()
	await driver.click(world.hud.buttons["return"])
	driver.expect(boot.factory_world == null, "isolated schema 9 world saves and returns normally")


func _compare_reactor() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("layout.json")))
	var route := Route.new(model, layout)
	route.bootstrap()
	route.energy_line()
	route.steady()
	var reactor: Dictionary = route.devices.R
	# Use a real spare kit and leave the unchanged reactor route running on the model.
	route._packs_to_core(model.assembly_costs.reactor)
	route._must(model.assemble("reactor"))
	route.walk_near(reactor)
	_use_asset(candidate)
	if not _reactor_traffic(reactor):
		return
	world.ui.selected = reactor.id
	await _pair("01-reactor-default", 21)
	await _pair("02-reactor-close", 16)
	if not await _inspect_reactor(reactor, true):
		return
	root.size = MINIMUM
	root.move_to_center()
	await driver.settle(12)
	driver.expect(root.size == MINIMUM and world.hud.subviewport.size.x == MINIMUM.x, "native minimum window for reactor comparison")
	await _pair("03-reactor-minimum", 21)
	_verify_reactor_hints(reactor)
	if not await _inspect_reactor(reactor, false):
		return
	root.size = comparison_size
	root.move_to_center()
	await driver.settle(12)
	await _inspect_reactor_preview()
	await _measure()
	var id: String = world.store.world_id
	var state: Dictionary = Store.Codec.snapshot(model, id, world.store.world_name, 1).state
	await driver.click(world.hud.buttons["return"])
	driver.expect(boot.factory_world == null, "the comparison world saves and releases its session")
	var saved := Store.new(boot.factory_save_root).find_candidate(id)
	driver.expect(saved.ok and saved.document.save_schema_version == 9 and Compare.equivalent(state, saved.document.state),
		"the isolated saved state matches the production comparison")


func _reactor_traffic(reactor: Dictionary) -> bool:
	var logistics = model.Logistics
	var input: Dictionary = logistics.ports(model, reactor, "input")[0]
	var output: Dictionary = logistics.ports(model, reactor, "output")[0]
	var feed: Dictionary = logistics.input_connection(model, reactor, input)
	var discharge: Dictionary = logistics.output_connection(model, output)
	var core_port: Dictionary = logistics.ports(model, model.core, "input").filter(func(port): return port.id == "IN_W0")[0]
	var delivery: Dictionary = logistics.input_connection(model, model.core, core_port)
	var linked: bool = feed.ok and feed.source.type == "belt" and discharge.ok and discharge.target.type == "belt" and delivery.ok
	driver.expect(linked, "connected input and output belts lead to the real core receiver")
	if not linked:
		return false
	var tracked_batch := 0
	var events := {}
	for i in 2400:
		var offered: bool = feed.source.cargo == "crystal"
		var in_process: int = reactor.input.get("crystal", 0) + reactor.invested.get("crystal", 0)
		var active_before: int = reactor.active_batch
		var cargo_at_core: bool = tracked_batch > 0 and delivery.source.cargo == "catalyst" and delivery.source.batch == tracked_batch
		model.advance(Route.STEP, 1)
		var tick: int = model.statistics.ticks
		if not events.has("crystal_received") and offered and feed.source.cargo.is_empty() \
			and reactor.input.get("crystal", 0) + reactor.invested.get("crystal", 0) > in_process:
			events.crystal_received = tick
		if tracked_batch == 0 and events.get("crystal_received", tick) < tick and reactor.active_batch > 0 and reactor.active_batch != active_before:
			tracked_batch = reactor.active_batch
			events.batch_started = tick
		if not events.has("catalyst_out") and tracked_batch > 0 and discharge.target.cargo == "catalyst" and discharge.target.batch == tracked_batch:
			events.catalyst_out = tick
		if cargo_at_core and delivery.source.cargo.is_empty():
			events.catalyst_received_by_core = tick
			break
	var passed: bool = events.size() == 4 and model.material_balance().balanced
	driver.expect(passed, "actual crystal receipt and a new catalyst batch from the reactor to the core")
	survey.traffic = {"events": events, "device_id": reactor.id,
		"input_cell": [input.x + input.dx, input.z + input.dz], "output_cell": [output.x + output.dx, output.z + output.dz],
		"catalyst_batch": tracked_batch}
	return passed


func _verify_reactor_hints(reactor: Dictionary) -> void:
	var visible := {}
	var viewport: SubViewport = world.hud.subviewport
	for hint in world.view.port_hints.get_children():
		if hint.get_meta("entity_id") != reactor.id or not hint.is_visible_in_tree():
			continue
		var cell: Vector2i = hint.get_meta("cell")
		var point := Vector3(cell.x + 0.5, 0.4, cell.y + 0.5)
		if viewport.get_visible_rect().has_point(world.view.project(point)):
			visible[hint.get_meta("role")] = [cell.x, cell.y]
	driver.expect(visible.get("input", []) == survey.traffic.input_cell and visible.get("output", []) == survey.traffic.output_cell,
		"both minimum-window port hints mark the same cells as live logistics")
	survey.traffic.visible_hints = visible


func _inspect_reactor(reactor: Dictionary, use_key: bool) -> bool:
	var center: Vector2 = model.Grid.center(reactor)
	var point := Vector3(center.x - 0.25, 2.0, center.y - 0.2)
	var projected: Vector2 = world.view.project(point)
	driver.expect(world.view.hit(projected) == reactor.id and model.near_entity(reactor), "visible reactor geometry is pickable nearby")
	var mouse: Vector2 = world.hud.viewport_to_screen(projected)
	await driver.motion(mouse)
	if use_key:
		await driver.key(KEY_F)
	else:
		await driver.mouse(mouse, true)
		await driver.mouse(mouse, false)
		await driver.settle()
	var opened: bool = world.discovery_panel.visible and world.discovery_panel.selected == reactor.id
	driver.expect(opened, "reactor opens its device panel by " + ("F" if use_key else "mouse at minimum window"))
	if not opened:
		return false
	await driver.shot("reactor-panel-f" if use_key else "reactor-panel-minimum-click")
	await driver.click(world.discovery_panel.buttons.close)
	return true


func _inspect_reactor_preview() -> void:
	var cell := Vector2i(-18, 28)
	await driver.click(world.hud.buttons.reactor)
	await driver.motion(driver.cell_screen(cell))
	await driver.settle()
	driver.expect(world.ui.tool == "reactor" and world.ui.cell == cell and model.placement("reactor", cell, model.actor).ok,
		"normal build bar shows a valid free reactor placement")
	var preview: Node3D = world.view.build_model
	var expected := Vector3(cell.x + 1.5, 0.06, cell.y + 1.5)
	driver.expect(preview.visible and preview.position.is_equal_approx(expected)
		and _surface_materials(preview).filter(func(row): return not row.texture.is_empty()).size() == 4,
		"construction preview uses the candidate materials at the correct footprint")
	await driver.shot("04-reactor-construction-preview")
	await driver.key(KEY_ESCAPE)


func _set_work_surface() -> void:
	for child in world.view.get_children():
		if child.scene_file_path != world.view.assets.yard.resource_path:
			continue
		Materials.new().apply(child.find_children("*", "MeshInstance3D", true, false), "yard", 2)
		var surfaces := _surface_materials(child)
		driver.expect(surfaces.filter(func(row): return not row.texture.is_empty()).size() == 3,
			"same approved work surface for both variants")
		return
	driver.expect(false, "find the actual imported yard")


func _redraw() -> void:
	world._refresh()
	world.view.draw(model, model.actor, world.ui)


func _use_asset(asset: PackedScene) -> void:
	world.view.assets["reactor" if subject == "reactor" else "base_core"] = asset
	world.view.invalidate()
	_redraw()


func _pair(label: String, span: float) -> void:
	world.view.core_span = span
	_use_asset(original)
	world.view.sync_camera()
	await driver.settle()
	var transform: Transform3D = world.view.camera.global_transform
	# A wall-clock autosave can advance the file sequence while production is paused.
	var state: Dictionary = Store.Codec.snapshot(model, world.store.world_id, world.store.world_name, 1).state
	await driver.shot(label + "-current")
	if bare_reactor != null:
		_use_asset(bare_reactor)
		await driver.shot(label + "-geometry")
	_use_asset(candidate)
	await driver.shot(label + "-r2")
	driver.expect(world.view.camera.global_transform == transform and world.view.yaw == 0.0
		and world.view.camera.fov == 35.0 and world.view.inspection_target == null,
		label + " same C2 camera pose and actor follow")
	var after: Dictionary = Store.Codec.snapshot(model, world.store.world_id, world.store.world_name, 1).state
	driver.expect(Compare.equivalent(state, after), label + " same fixed simulation snapshot")
	if not survey.has("pairs"):
		survey.pairs = {}
	survey.pairs[label] = {"tick": state.simulation_tick, "span": span,
		"window": [root.size.x, root.size.y], "viewport": [world.hud.subviewport.size.x, world.hud.subviewport.size.y]}


func _upgrade() -> bool:
	await driver.motion(driver.cell_screen(Vector2i(-8, 24), 2.5))
	await driver.key(KEY_F)
	var panel: Control = world.core_panel
	driver.expect(panel.visible and world.ui.selected == model.core.id, "nearby F opens the candidate core")
	if not panel.visible:
		return false
	var bar: TabBar = panel.tabs.get_tab_bar()
	var at := bar.global_position + bar.get_tab_rect(3).get_center()
	await driver.motion(at)
	await driver.mouse(at, true)
	await driver.mouse(at, false)
	await driver.settle()
	driver.expect(panel.tabs.current_tab == 3 and not panel.upgrade_button.disabled, "upgrade shows actual constructed packs")
	if panel.tabs.current_tab != 3 or panel.upgrade_button.disabled:
		return false
	await driver.shot("03a-upgrade-ready")
	var before: int = model.core.items.get("construction_pack", 0)
	await driver.click(panel.upgrade_button)
	driver.expect(model.core.level == 2 and model.core.items.get("construction_pack", 0) == before - 2
		and model.material_balance().balanced, "real core upgrade debits two packs")
	if model.core.level != 2:
		return false
	await driver.click(panel.close_button)
	var core: Node3D = world.view.models[model.core.id].root
	var tiers := core.find_child("TierModules", true, false)
	driver.expect(tiers.get_node("II").visible and not tiers.get_node("I").visible
		and _surface_materials(core).filter(func(row): return not row.texture.is_empty()).size() == 4,
		"tier II rebuild retains the candidate materials")
	await driver.shot("03b-after-upgrade-r2")
	await driver.key(KEY_ESCAPE)
	return true


func _verify_ports() -> void:
	var ports := {"connected_inputs": [], "open_inputs": [], "connected_outputs": [], "onscreen_icons": []}
	var icons: Dictionary = world.view.models[model.core.id].output_icons
	var icon_rects: Array[Rect2] = []
	for port in Rules.ports(Vector2i(model.core.x, model.core.z), "input"):
		var next: Dictionary = model.entity_at(Vector2i(port.x + port.dx, port.z + port.dz))
		if next.get("type") == "belt" and model.DIRS[next.dir] == Vector2i(-port.dx, -port.dz):
			ports.connected_inputs.append(port.id)
		else:
			ports.open_inputs.append(port.id)
	for port in Rules.ports(Vector2i(model.core.x, model.core.z), "output"):
		var connection: Dictionary = model.Logistics.output_connection(model, port)
		if connection.ok and connection.target.type == "belt":
			ports.connected_outputs.append(port.id)
		var marker: Sprite3D = icons[port.id]
		if not marker.visible or marker.texture == null:
			continue
		var half_size := marker.texture.get_size() * marker.pixel_size * 0.5
		var camera: Camera3D = world.view.camera
		var diagonal := camera.global_basis.x * half_size.x + camera.global_basis.y * half_size.y
		var top_left: Vector2 = world.view.project(marker.global_position - diagonal)
		var opposite: Vector2 = world.view.project(marker.global_position + diagonal)
		var rect := Rect2(top_left, opposite - top_left).abs()
		if world.hud.subviewport.get_visible_rect().encloses(rect):
			ports.onscreen_icons.append(port.id)
			driver.expect(not icon_rects.any(func(other): return other.intersects(rect)), "minimum-window icon does not overlap: " + port.id)
			icon_rects.append(rect)
	driver.expect(ports.connected_outputs.size() == 4 and ports.onscreen_icons.size() == 4
		and ports.connected_inputs.size() >= 4 and not ports.open_inputs.is_empty(), "connected and open ports and four output icons at minimum window")
	survey.ports = ports


func _pick_core() -> void:
	await driver.world_click(Vector2i(-8, 24), 2.5)
	driver.expect(world.core_panel.visible and world.ui.selected == model.core.id
		and model.near_entity(model.core), "nearby mouse selection at minimum window")
	if not world.core_panel.visible:
		return
	world.core_panel.tabs.current_tab = 1
	await driver.shot("08-minimum-core-interfaces")
	await driver.click(world.core_panel.close_button)
	await driver.key(KEY_ESCAPE)


func _measure() -> void:
	world.view.core_span = 21
	var viewport: SubViewport = world.hud.subviewport
	var rid := viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	survey.performance = []
	var order := [original, candidate, candidate, original]
	if bare_reactor != null:
		order = [original, bare_reactor, candidate, candidate, bare_reactor, original]
	for asset in order:
		_use_asset(asset)
		world.view.sync_camera()
		await driver.settle(35)
		var samples := []
		var before := Time.get_ticks_usec()
		for i in 60:
			await RenderingServer.frame_post_draw
			if not root.has_focus():
				driver.expect(false, "paired frame sample interrupted by window focus loss")
				RenderingServer.viewport_set_measure_render_time(rid, false)
				return
			var now := Time.get_ticks_usec()
			samples.append({"wall_ms": (now - before) / 1000.0,
				"render_cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(rid),
				"render_gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(rid),
				"draw_calls": viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
				"triangles": viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)})
			before = now
		var label := "current" if asset == original else "geometry" if asset == bare_reactor else "r2"
		survey.performance.append({"asset": label,
			"viewport": [viewport.size.x, viewport.size.y], "samples": samples})
	RenderingServer.viewport_set_measure_render_time(rid, false)
	driver.expect(survey.performance.size() == order.size(), "paired frame samples complete")


func _end() -> void:
	if is_instance_valid(boot) and boot.factory_world != null and boot.factory_world.store != null:
		boot.factory_world.store.release()
	survey.checks = driver.assertions
	survey.failures = driver.failures
	var file := FileAccess.open(evidence.path_join("result.json"), FileAccess.WRITE)
	if file == null:
		push_error("Cannot retain R2 result.")
		quit(2)
		return
	file.store_string(JSON.stringify(survey, "\t"))
	file.close()
	print("Factory R2: %d checks, %d failures" % [driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)
