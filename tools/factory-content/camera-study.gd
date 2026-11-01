extends SceneTree

const Gate := preload("res://scripts/checks/factory_diagnostic_gate.gd")
const Session := preload("res://scripts/prototypes/factory_camera/session.gd")


func _init() -> void:
	call_deferred("_open")


func _open() -> void:
	var session := "review-%d" % int(Time.get_unix_time_from_system())
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: session = args[0]
	if session.is_empty() or not session.is_valid_filename() or "." in session or "/" in session or "\\" in session:
		push_error("Invalid camera study session name")
		quit(2)
		return
	if not await Gate.wait_for_start(self, "异星催化 · 镜头样板准备页",
		"R1-A 镜头与尺度试玩\n独立样板，不读写正式世界。\n准备好后点击开始；关闭窗口即取消。", "开始镜头试玩"):
		quit()
		return
	root.title = "异星催化 · R1-A 镜头与尺度试玩"
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i(1440, 900)
	root.size = Vector2i(1440, 900)
	root.min_size = Vector2i(1100, 720)
	var repo := ProjectSettings.globalize_path("res://..").simplify_path()
	var isolated := repo.path_join("tools/runtime-intake/review-worlds/factory-camera-v1/" + session)
	var shots := repo.path_join("assets/art-intake/factory-camera-v1/" + session)
	var result := await Session.open(self, isolated, shots)
	if result.is_empty(): quit(1)
