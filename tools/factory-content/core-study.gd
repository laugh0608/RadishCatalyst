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
		push_error("Invalid core study session name")
		quit(2)
		return
	if not await Gate.wait_for_start(self, "异星催化 · 核心轮廓准备页",
		"R1-B 新核心轮廓样板\nC2 / 21 格 / 跟随，验证占地、端口与遮挡。\n无核心玩法，不读写正式世界。", "开始核心轮廓试玩"):
		quit()
		return
	root.title = "异星催化 · R1-B 新核心轮廓"
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i(1440, 900)
	root.size = Vector2i(1440, 900)
	root.min_size = Vector2i(1100, 720)
	var repo := ProjectSettings.globalize_path("res://..").simplify_path()
	var isolated := repo.path_join("tools/runtime-intake/review-worlds/factory-core-outline-v1/" + session)
	var shots := repo.path_join("assets/art-intake/factory-core-outline-v1/" + session)
	var result := await Session.open(self, isolated, shots, true)
	if result.is_empty(): quit(1)
