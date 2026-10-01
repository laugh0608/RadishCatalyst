extends "res://production/verify-window.gd"

## Native window resize, displayed pixel resolution and input alignment.
func run(app: Control) -> void:
	prepare(app, 120)
	verification_scope = "Independent Production entry; native window resize; synthesized mouse/key input; render resolution and alignment only"
	get_window().grab_focus()
	await _settle(30)
	_check_resolution("windowed")
	await _shot("resolution-01-windowed")
	get_window().mode = Window.MODE_MAXIMIZED
	await _seconds(0.6)
	await _settle(10)
	_check_resolution("maximized")
	await _shot("resolution-02-maximized")
	# Place and drag at the enlarged size through the same visible input chain.
	await _choose("collector")
	await _world_click(Vector2i(-8, -1))
	_expect(world.model.entity_at(Vector2i(-8, -1)).get("type") == "collector", "maximized mouse places collector on ore")
	await _choose("reactor")
	await _world_click(Vector2i(-1, -2))
	_expect(world.model.entity_at(Vector2i(-1, -2)).get("type") == "reactor", "maximized mouse places reactor")
	await _choose("storage")
	await _world_click(Vector2i(6, -1))
	_expect(world.model.entity_at(Vector2i(6, -1)).get("type") == "storage", "maximized mouse places storage")
	await _choose("belt")
	await _start_drag(Vector2i(-6, 0))
	await _drag_to(Vector2i(-2, 0))
	await _mouse_up(_cell_screen(Vector2i(-2, 0)))
	_expect(world.model.kits.belt == 19, "maximized cross-cell drag places five belts")
	await _key(KEY_ESCAPE)
	await _world_click(Vector2i(-4, 0), 0.1)
	_expect(world.model.by_id(world.ui.selected).get("type") == "belt", "maximized mouse selects rendered belt")
	_check_resolution("maximized-detail")
	await _shot("resolution-03-maximized-build")
	# A different aspect ratio and the original window exercise both resize signals.
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1920, 1080)
	await _seconds(0.3)
	await _settle(10)
	_check_resolution("wide")
	await _key(KEY_ESCAPE)
	await _key(KEY_Q)
	await _world_click(Vector2i(0, -1), 1.0)
	_expect(world.model.by_id(world.ui.selected).get("type") == "reactor", "wide rotated camera selects reactor")
	await _shot("resolution-04-wide-rotated")
	get_window().size = Vector2i(1440, 900)
	await _seconds(0.3)
	await _settle(10)
	_check_resolution("restored")
	await _key(KEY_ESCAPE)
	await _choose("belt")
	await _start_drag(Vector2i(-5, 3))
	await _drag_to(Vector2i(-3, 3))
	await _key(KEY_ESCAPE)
	_expect(world.model.kits.belt == 19 and world.ui.stroke.is_empty(), "restored window cancels drag without spending kits")
	_finish()


func _check_resolution(label: String) -> void:
	# Read the rendered image: ViewportTexture's reported size can include
	# additional canvas oversampling that is absent from the actual framebuffer.
	var root_pixels := Vector2(get_viewport().get_texture().get_image().get_size())
	var layout: Vector2 = get_viewport().get_visible_rect().size
	var displayed: Vector2 = root_pixels * world.hud.world_image.size / layout
	var rendered := Vector2(world.hud.subviewport.get_texture().get_image().get_size())
	_expect((rendered - displayed).abs().x <= 1 and (rendered - displayed).abs().y <= 1,
		label + ": 3D target matches displayed pixels within rounding")
	_expect(is_equal_approx(world.hud.subviewport.scaling_3d_scale, 1.0), label + ": no internal 3D downscaling")
	observations.append({"label": label, "window": str(get_window().size), "root_pixels": str(root_pixels),
		"logical_world": str(world.hud.world_image.size), "displayed_world_pixels": str(displayed), "rendered_world_pixels": str(rendered)})
	print("Resolution evidence: ", observations.back())
