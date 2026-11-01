extends SceneTree

const Session := preload("res://scripts/prototypes/factory_camera/session.gd")
var checks := 0
var failures: Array[String] = []
var probe_results: Array[Dictionary] = []


func _init() -> void:
	call_deferred("run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func geometry_bounds(core: Node3D) -> AABB:
	var bounds := AABB()
	var started := false
	for part in core.parts:
		if not part.is_visible_in_tree(): continue
		var shape: AABB = part.global_transform * part.get_aabb()
		bounds = bounds.merge(shape) if started else shape
		started = true
	return bounds


func run() -> void:
	root.size = Vector2i(1440, 900)
	root.content_scale_size = Vector2i(1440, 900)
	var repo := ProjectSettings.globalize_path("res://..").simplify_path()
	var args := OS.get_cmdline_user_args()
	var batch := "geometry-%d" % int(Time.get_unix_time_from_system()) if args.is_empty() else args[0]
	if not batch.is_valid_filename() or "." in batch or "/" in batch or "\\" in batch:
		quit(2)
		return
	var path := repo.path_join("tools/runtime-intake/check-runs/factory-core-outline-v1/" + batch)
	var result := await Session.open(self, path.path_join("isolated"), path.path_join("screenshots"), true)
	if result.is_empty():
		quit(1)
		return
	var demo: Control = result.demo
	demo.paused = true
	await process_frame
	var core: Node3D = demo.view.core
	expect(result.boot.factory_save_root == path.path_join("isolated/factory"), "Factory root isolated")
	expect(result.boot.slice_save_catalog._root_dir == path.path_join("isolated/slice"), "Slice root isolated")
	expect(demo.view.preset == 2 and demo.view.follow and demo.view.span == 21, "C2 default retained")
	expect(core.ports.size() == 12 and core.parts.size() == 5, "Imported anchors and both variant batches")
	var expected := {}
	for i in 4: expected["IN_N%d" % i] = Vector3(-1.5 + i, 0.31, -3)
	for i in 2: expected["IN_W%d" % i] = Vector3(-3, 0.31, -1.5 + 3 * i)
	for i in 4: expected["OUT_E%d" % i] = Vector3(3, 0.31, -1.5 + i)
	for i in 2: expected["OUT_W%d" % i] = Vector3(-3, 0.31, -0.5 + i)
	for port in core.ports:
		expect(expected.has(port.id) and port.anchor.global_position.is_equal_approx(expected[port.id]), "Imported port " + port.id)
		var at: Vector3 = port.anchor.global_position
		var normal: Vector2 = port.normal
		var cell := Vector2i(floori(at.x + normal.x * 0.5), floori(at.z + normal.y * 0.5))
		var belt: Dictionary = demo.board.entity_at(cell)
		var travel: Vector2 = normal if port.role == "output" else -normal
		expect(not belt.is_empty() and belt.type == "belt" and Vector2(demo.board.DIRS[belt.dir]) == travel, "Belt alignment " + port.id)
	var tier_bounds: Array[AABB] = []
	for tier in [1, 2]:
		demo.act("tier", tier)
		await process_frame
		var bounds := geometry_bounds(core)
		tier_bounds.append(bounds)
		expect(bounds.position.x >= -3.001 and bounds.end.x <= 3.001 and bounds.position.z >= -3.001
			and bounds.end.z <= 3.001 and bounds.position.y >= -0.001 and bounds.end.y <= 3.6, "Imported bounds tier " + str(tier))
		var surfaces := 0
		var triangles := 0
		for part in core.parts:
			if not part.is_visible_in_tree(): continue
			surfaces += part.mesh.get_surface_count()
			triangles += part.mesh.get_faces().size() / 3
		expect(surfaces == 4 and triangles <= 12000, "Visible mesh budget tier " + str(tier))
		var positions := {"S": Vector2(0, 4.6), "N": Vector2(0, -4.6), "W": Vector2(-4.6, 0), "E": Vector2(4.6, 0),
			"START": Vector2(-1, 5), "SW": Vector2(-5, 5), "SE": Vector2(4, 5),
			"NW": Vector2(-5, -5), "NE": Vector2(4, -5), "S_NEAR": Vector2(-1, 3.3), "S_RIGHT": Vector2(1, 5)}
		for side in positions:
			demo.board.actor.x = positions[side].x
			demo.board.actor.z = positions[side].y
			for span in [16, 21, 28]:
				demo.act("span", span)
				await process_frame
				var review: Dictionary = core.review(demo.view.camera, demo.board.actor)
				review["side"] = side
				review["span"] = span
				probe_results.append(review)
				for id in review.ports:
					expect(not review.ports[id].probe_blocked_by_core, "%s span%d tier%d port %s visible" % [side, span, tier, id])
				for id in review.actor_probes_blocked_by_core:
					expect(not review.actor_probes_blocked_by_core[id], "%s span%d tier%d actor %s clear" % [side, span, tier, id])
		expect(demo.view.hit(demo.view.project(Vector3(0, 1.8, 0.6))) == -2, "Core triangle picking tier " + str(tier))
	expect(tier_bounds[0].is_equal_approx(tier_bounds[1]), "I / II share full envelope")
	demo.act("approach", "N")
	demo.act("nearest", null)
	expect(demo.selected == -2, "F selects core within two cells")
	var position_before := Vector2(demo.board.actor.x, demo.board.actor.z)
	demo.act("core_belts", null)
	await process_frame
	expect(demo.board.entities.size() == 5 and demo.view.models.size() == 5, "Empty ports remove only neighbor belts")
	expect(Vector2(demo.board.actor.x, demo.board.actor.z).is_equal_approx(position_before), "Belt toggle preserves actor")
	demo.act("core_belts", null)
	await process_frame
	expect(demo.board.entities.size() == 17 and demo.view.models.size() == 17, "Neighbor belts restored")
	demo.act("core_names", null)
	expect(core.names_visible and core.labels.size() == 12, "12 port names")
	for label in core.labels: expect(not label.no_depth_test, "Port label is depth tested")
	demo.act("reset", null)
	for destination in [Vector2(-5, 5), Vector2(-5, -5), Vector2(4, -5), Vector2(4, 5), Vector2(-1, 5)]:
		for step in 1000:
			var delta: Vector2 = destination - Vector2(demo.board.actor.x, demo.board.actor.z)
			if delta.length() < 0.08: break
			delta = delta.normalized()
			demo.board.move_actor(demo.board.actor, delta.x, delta.y, 1.0 / 60)
		expect(destination.distance_to(Vector2(demo.board.actor.x, demo.board.actor.z)) < 0.08, "Geometry walking route " + str(destination))
	demo.board.actor.x = 0
	demo.board.actor.z = 3.7
	for step in 60: demo.board.move_actor(demo.board.actor, 0, -1, 1.0 / 60)
	expect(demo.board.actor.z >= 3.28, "Six-cell footprint blocks crossing")
	demo.act("board", "D")
	await process_frame
	expect(not core.visible and demo.view.models.size() == 31, "Dense board keeps core hidden")
	demo.act("board", "P")
	await process_frame
	expect(core.visible and demo.board.entities.size() == 17, "Core restored with main board")
	expect(not DirAccess.dir_exists_absolute(path.path_join("isolated/factory"))
		and not DirAccess.dir_exists_absolute(path.path_join("isolated/slice")), "Neither world save root created")
	DirAccess.make_dir_recursive_absolute(path)
	var file := FileAccess.open(path.path_join("geometry-results.json"), FileAccess.WRITE)
	if file == null:
		push_error("Cannot write core geometry evidence")
		quit(1)
		return
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "probes": probe_results}, "\t") + "\n")
	print("CORE_OUTLINE_CHECKS checks=", checks, " failures=", failures.size())
	result.boot.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
