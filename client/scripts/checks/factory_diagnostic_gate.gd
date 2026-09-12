extends RefCounted


# 临时前台诊断共用此入口；不修改正式 Boot 的窗口配置或性能采样流程。
static func wait_for_start(tree: SceneTree, title: String, message: String,
		button_text := "开始同状态对照诊断") -> bool:
	if DisplayServer.get_name() == "headless":
		push_error("Diagnostic start page requires a visible window.")
		return false
	var window := tree.root
	var original_aspect := window.content_scale_aspect
	var original_auto_quit := tree.auto_accept_quit
	tree.auto_accept_quit = false
	window.title = title
	# 最大化时不再写入小窗口尺寸，避免原生窗口与渲染目标使用不同尺寸。
	window.mode = Window.MODE_MAXIMIZED
	# 准备页填满任意窗口比例；退出准备页时恢复正式入口的留边策略。
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var gate := CenterContainer.new()
	gate.name = "FactoryDiagnosticGate"
	gate.modulate.a = 0.0 # 保留布局计算，尺寸就绪前不显示控件。
	window.add_child(gate)
	gate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	gate.add_child(box)
	var label := Label.new()
	label.text = message
	box.add_child(label)
	var button := Button.new()
	button.name = "StartButton"
	button.text = button_text
	button.custom_minimum_size = Vector2(460, 80)
	button.disabled = true
	box.add_child(button)
	var state := {"clicked": false, "closed": false}
	button.pressed.connect(func(): state.clicked = true, CONNECT_ONE_SHOT)
	var on_close := func(): state.closed = true
	window.close_requested.connect(on_close)
	var started := Time.get_ticks_msec()
	var previous_size := Vector2i.ZERO
	var stable_frames := 0
	while stable_frames < 2 and not state.closed:
		await tree.process_frame
		await RenderingServer.frame_post_draw
		var pixels := window.size
		# ViewportTexture.get_size() 含拉伸变换，不能当作实际帧缓冲像素。
		var rendered := window.get_texture().get_image().get_size()
		var synchronized := pixels == DisplayServer.window_get_size(window.get_window_id()) \
			and rendered == pixels \
			and gate.get_rect().is_equal_approx(window.get_visible_rect()) \
			and window.mode == Window.MODE_MAXIMIZED
		stable_frames = stable_frames + 1 if synchronized and pixels == previous_size else 0
		previous_size = pixels
		if Time.get_ticks_msec() - started > 5000:
			push_error("Diagnostic window sizing timed out: window=%s rendered=%s layout=%s" % [
				pixels, rendered, gate.get_rect()])
			break
	var ready: bool = stable_frames >= 2 and not state.closed
	if ready:
		gate.modulate.a = 1.0
		button.disabled = false
		print("PROFILE_START_WAIT window=", window.size,
			" ready_ms=", Time.get_ticks_msec() - started)
		started = Time.get_ticks_msec()
		while not state.clicked and not state.closed:
			await tree.process_frame
			if Time.get_ticks_msec() - started > 180000:
				print("PROFILE_START_TIMEOUT")
				break
	if state.closed:
		print("PROFILE_CANCELED_BEFORE_START")
	window.close_requested.disconnect(on_close)
	gate.queue_free()
	await tree.process_frame
	window.content_scale_aspect = original_aspect
	tree.auto_accept_quit = original_auto_quit
	return ready and state.clicked and not state.closed
