extends Node3D

const Specimen := preload("res://specimen.gd")
const Character := preload("res://character.gd")
const MOVE_KEYS := {
	"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
	"up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
}
var specimen: Node3D
var player: CharacterBody3D
var camera := Camera3D.new()
var sun := DirectionalLight3D.new()
var yaw := 22.0
var zoomed_out := false
var glass_enabled := true
var filled := true
var shadows := true
var alternate_light := false
var status := Label.new()
var buttons: Dictionary = {}
var environment: Environment


func _ready() -> void:
	for action in MOVE_KEYS:
		InputMap.add_action(action)
		for key in MOVE_KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	_build_lighting()
	specimen = Specimen.new()
	add_child(specimen)
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	camera.near = 0.1
	camera.far = 80.0
	_update_camera()
	player = Character.new()
	player.camera = camera
	player.position = Vector3(0.15, 0.05, 2.4)
	add_child(player)
	_build_ui()
	if "--verify" in OS.get_cmdline_user_args():
		var review := preload("res://verify.gd").new()
		add_child(review)
		review.call_deferred("run", self)


func _build_lighting() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("202e35")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b9d3de")
	environment.ambient_light_energy = 0.4
	environment.ssao_enabled = true
	environment.ssao_radius = 0.65
	environment.ssao_intensity = 1.6
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("88a4b2")
	sky_material.sky_horizon_color = Color("dedac2")
	sky_material.ground_bottom_color = Color("34444b")
	sky_material.ground_horizon_color = Color("a3aaa1")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.light_color = Color("fff1d1")
	sun.light_energy = 1.0
	sun.light_angular_distance = 1.5
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 60.0
	sun.shadow_bias = 0.025
	sun.shadow_normal_bias = 0.1
	add_child(sun)


func _update_camera() -> void:
	var target := Vector3(0, 0.5, 0)
	var angle := deg_to_rad(yaw)
	camera.position = target + Vector3(sin(angle) * 17, 18, cos(angle) * 17)
	camera.look_at(target)
	camera.size = 18.5 if zoomed_out else 14.5


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["PingFang SC", "Noto Sans CJK SC"])
	theme.default_font = font
	theme.default_font_size = 16
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 22)
	panel.theme = theme
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.10, 0.12, 0.92)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)
	var stack := VBoxContainer.new()
	panel.add_child(stack)
	var title := Label.new()
	title.text = "异星催化  /  俯视角 3D 对照"
	title.add_theme_font_size_override("font_size", 22)
	stack.add_child(title)
	var hint := Label.new()
	hint.text = "WASD / 方向键移动    Q / E 旋转视角    R 复位\n绕设备与支架行走，观察玻璃透视、落地阴影和前后遮挡"
	hint.add_theme_color_override("font_color", Color("adc1c5"))
	stack.add_child(hint)
	var footer := PanelContainer.new()
	footer.theme = theme
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 24
	footer.offset_right = -24
	footer.offset_top = -101
	footer.offset_bottom = -22
	footer.add_theme_stylebox_override("panel", style)
	canvas.add_child(footer)
	var rows := VBoxContainer.new()
	footer.add_child(rows)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	rows.add_child(row)
	for entry in [["glass", "G  玻璃 / 实心", toggle_glass], ["filled", "F  有料 / 空管", toggle_filled], ["shadows", "H  投影开关", toggle_shadows], ["light", "L  改变光向", toggle_light], ["zoom", "B  拉远对照", toggle_zoom]]:
		var button := Button.new()
		button.text = entry[1]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(entry[2])
		row.add_child(button)
		buttons[entry[0]] = button
	rows.add_child(status)
	_refresh_status()


func _refresh_status() -> void:
	status.text = "%s  ·  %s  ·  %s  |  独立视觉试验，等待路线选择" % ["透明管壁" if glass_enabled else "不透明管壁", "青色内容" if filled else "空管", "实时投影" if shadows else "投影关闭"]
	status.add_theme_color_override("font_color", Color("a3b8b9"))


func toggle_glass() -> void:
	glass_enabled = not glass_enabled
	specimen.set_glass(glass_enabled)
	_refresh_status()


func toggle_filled() -> void:
	filled = not filled
	specimen.set_filled(filled)
	_refresh_status()


func toggle_shadows() -> void:
	shadows = not shadows
	sun.shadow_enabled = shadows
	_refresh_status()


func toggle_light() -> void:
	alternate_light = not alternate_light
	sun.rotation_degrees.y = 110.0 if alternate_light else -38.0


func toggle_zoom() -> void:
	zoomed_out = not zoomed_out
	_update_camera()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_G: toggle_glass()
		KEY_F: toggle_filled()
		KEY_H: toggle_shadows()
		KEY_L: toggle_light()
		KEY_B: toggle_zoom()
		KEY_Q:
			yaw -= 15
			_update_camera()
		KEY_E:
			yaw += 15
			_update_camera()
		KEY_R:
			yaw = 22.0
			zoomed_out = false
			_update_camera()
			player.position = Vector3(0.15, 0.05, 2.4)
			player.velocity = Vector3.ZERO
		KEY_ESCAPE: get_tree().quit()
