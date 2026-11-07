extends SceneTree

const Gate := preload("res://scripts/checks/factory_diagnostic_gate.gd")
const Session := preload("res://scripts/prototypes/factory_camera/session.gd")


func _init() -> void:
	call_deferred("_open")


func _open() -> void:
	var session := "review-%d" % int(Time.get_unix_time_from_system())
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: session = args[0]
	var material_study := args.size() == 2 and args[1] == "--materials"
	if args.size() > 1 and not material_study:
		push_error("Expected an optional --materials flag")
		quit(2)
		return
	if session.is_empty() or not session.is_valid_filename() or "." in session or "/" in session or "\\" in session:
		push_error("Invalid core study session name")
		quit(2)
		return
	var label := "代表材质对照" if material_study else "核心轮廓"
	var message := "R1-C / D 代表材质\n同场切换 M0、M1 岩土与 M1 工作面。" if material_study \
		else "R1-B 新核心轮廓样板\nC2 / 21 格 / 跟随，验证占地、端口与遮挡。"
	if not await Gate.wait_for_start(self, "异星催化 · " + label + "准备页",
		message + "\n无核心玩法，不读写正式世界。", "开始" + label + "试玩"):
		quit()
		return
	root.title = "异星催化 · " + label
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i(1440, 900)
	root.size = Vector2i(1440, 900)
	root.min_size = Vector2i(1100, 720)
	var repo := ProjectSettings.globalize_path("res://..").simplify_path()
	var topic := "factory-material-study-v1" if material_study else "factory-core-outline-v1"
	var isolated := repo.path_join("tools/runtime-intake/review-worlds/" + topic + "/" + session)
	var shots := repo.path_join("assets/art-intake/" + topic + "/" + session)
	var result := await Session.open(self, isolated, shots, true, material_study)
	if result.is_empty(): quit(1)
