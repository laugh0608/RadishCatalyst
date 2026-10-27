extends RefCounted

## A depth-tested shell of the selected imported meshes, excluded from picking.
const OUTLINE := preload("res://scripts/factory/focus_outline.gdshader")
var target_root: Node3D
var shells: Array[MeshInstance3D] = []
var originals: Array[Dictionary] = []
var material := ShaderMaterial.new()
var tint := StandardMaterial3D.new()


func _init() -> void:
	material.shader = OUTLINE
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.albedo_color = Color(0.75, 1.0, 0.95, 0.08)


func clear() -> void:
	for entry in originals:
		if is_instance_valid(entry.part): entry.part.material_overlay = entry.overlay
	for shell in shells:
		if is_instance_valid(shell): shell.free()
	originals.clear()
	shells.clear()
	target_root = null


func sync(visual: Dictionary, pixel_scale: float) -> void:
	material.set_shader_parameter("width_pixels", 2.0 * pixel_scale)
	var next: Node3D = visual.get("root")
	if is_instance_valid(target_root) and target_root == next: return
	clear()
	if next == null: return
	target_root = next
	for part in visual.focus_parts:
		var shell := MeshInstance3D.new()
		shell.mesh = part.mesh
		shell.material_override = material
		shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		part.add_child(shell)
		shells.append(shell)
		originals.append({"part": part, "overlay": part.material_overlay})
		part.material_overlay = tint
