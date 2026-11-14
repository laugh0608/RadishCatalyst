extends SceneTree

const Session := preload("res://scripts/prototypes/factory_camera/session.gd")
var checks := 0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func run() -> void:
	root.size = Vector2i(1440, 900)
	root.content_scale_size = Vector2i(1440, 900)
	var repo := ProjectSettings.globalize_path("res://..").simplify_path()
	var path := repo.path_join("tools/runtime-intake/check-runs/factory-camera-v1/geometry-" + str(int(Time.get_unix_time_from_system())))
	var result := await Session.open(self, path, path.path_join("screenshots"))
	if result.is_empty():
		quit(1)
		return
	var demo: Control = result.demo
	await process_frame
	expect(demo.view.preset == 2 and demo.view.camera.projection == Camera3D.PROJECTION_PERSPECTIVE,
		"Selected default is front perspective")
	expect(demo.view.span == 21 and demo.view.follow, "Selected default span and follow")
	var focus: Vector3 = demo.view.target
	var base_height: float = demo.view.camera.position.y
	var base_rotation: Vector3 = demo.view.camera.rotation
	var base_fov: float = demo.view.camera.fov
	for values in [[-100, 16], [100, 28], [21, 21]]:
		demo.act("span", values[0])
		await process_frame
		expect(demo.view.span == values[1], "Zoom range and restoring default")
		expect(demo.view.target.is_equal_approx(focus) and demo.view.camera.rotation.is_equal_approx(base_rotation)
			and is_equal_approx(demo.view.camera.fov, base_fov), "Distance adjustment preserves focus, pitch and FOV")
		var height: float = demo.view.camera.position.y
		expect((height < base_height if values[1] < 21 else height > base_height) if values[1] != 21
			else is_equal_approx(height, base_height), "Zoom changes and restores actual camera height")
		var anchor := Vector3(-8, 0, -1)
		var ground: Vector3 = demo.view.ground(demo.view.project(anchor))
		expect(ground.distance_to(anchor) < 0.001, "Zoomed perspective ground mapping")
	demo.act("follow", null)
	await process_frame
	expect(result.boot.factory_save_root == path.path_join("factory"), "Factory root isolation")
	expect(result.boot.slice_save_catalog._root_dir == path.path_join("slice"), "Slice root isolation")
	expect(demo.board.entities.size() == 17, "P fixture count")
	expect(demo.board.blocked_for_actor(0, 0), "Reserved core blocks movement")
	expect(demo.board.blocked_for_actor(6, 0), "Reactor blocks movement")
	expect(not demo.board.blocked_for_actor(-1, 5), "Actor start is walkable")
	expect(demo.board.measure_cell(Vector2i(0, 0)) == "核心预留占地", "Measurement recognizes reserved core")
	expect(demo.board.measure_cell(Vector2i(12, 0)) == "评估区外", "Measurement boundary")
	expect(demo.board.nearest_sample() == -1, "F cannot reach distant sample")
	var initial := Vector2(demo.board.actor.x, demo.board.actor.z)
	var count: int = demo.board.entities.size()
	for preset in 3:
		demo.act("camera", preset)
		await process_frame
		expect(Vector2(demo.board.actor.x, demo.board.actor.z).is_equal_approx(initial), "Camera switch preserves actor")
		expect(demo.view.target.is_equal_approx(Vector3(0, 0.25, 1)), "Fixed P target")
		var center: Vector2 = demo.view.project(demo.view.target)
		expect(center.distance_to(Vector2(demo.hud.viewport.size) * 0.5) < 0.1, "Target projects to center")
		var up: Vector3 = demo.view.camera.global_basis.y
		var a: Vector2 = demo.view.project(demo.view.target + up * 10.5)
		var b: Vector2 = demo.view.project(demo.view.target - up * 10.5)
		expect(absf(a.distance_to(b) - demo.hud.viewport.size.y) < 0.2, "Matched 21-span center plane")
		var anchor := Vector3(-8, 0, -1)
		var point: Vector2 = demo.view.project(anchor)
		var ground: Vector3 = demo.view.ground(point)
		expect(ground.distance_to(anchor) < 0.001, "Projection / ground roundtrip")
		expect(demo.hud.world_point(demo.hud.ui_point(point)).distance_to(point) < 0.001, "UI / viewport roundtrip")
		var picked: int = demo.view.hit(demo.view.project(Vector3(-8, 0.8, -1)))
		expect(picked == 1, "Geometric collector hit for preset " + str(preset))
	demo.act("measure", null)
	demo.act("rotate", null)
	await process_frame
	expect(demo.board.entities.size() == count, "Measurement cannot mutate board")
	expect(demo.direction == 1, "Measurement rotation")
	demo.act("follow", null)
	await process_frame
	expect(demo.view.target.is_equal_approx(Vector3(-1, 0.25, 5.3)), "Follow target")
	demo.act("board", "D")
	await process_frame
	expect(demo.board.entities.size() == 31 and demo.view.models.size() == 31, "Dense replaces P")
	expect(demo.view.reserved.get_child_count() == 0, "Dense has no reserved core")
	expect(not demo.board.blocked_for_actor(-0.5, 0.5), "Dense one-cell aisle is walkable")
	expect(demo.board.blocked_for_actor(0.5, 0.5), "Dense reactor collision")
	demo.board.actor.x = 0.0
	demo.board.actor.z = 7.35
	for step in 60: demo.board.move_actor(demo.board.actor, 0, -1, 1.0 / 60)
	expect(demo.board.actor.z >= 7.28, "Movement cannot cross reactor boundary")
	demo.act("board", "P")
	await process_frame
	expect(demo.board.entities.size() == 17 and demo.view.models.size() == 17, "P restoration")
	expect(not DirAccess.dir_exists_absolute(path.path_join("factory")), "No factory save written")
	print("CAMERA_STUDY_CHECKS checks=", checks, " failures=", failures.size())
	result.boot.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
