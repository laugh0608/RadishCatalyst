extends RefCounted

## Instance-local overrides on imported meshes. M0 restores their source surfaces.
const ENAMEL := preload("res://assets/prototypes/factory_material_study/enamel.png")
const TRIM := preload("res://assets/prototypes/factory_material_study/trim.png")
const ROCK := preload("res://assets/prototypes/factory_material_study/rock.png")
const ROCK_NORMAL := preload("res://assets/prototypes/factory_material_study/rock-normal.png")
const WORK_SURFACE := preload("res://assets/prototypes/factory_material_study/work-surface.png")
const MODES := ["M0", "M1_ROCK", "M1_WORK"]
const PROFILES := {
	"core": {
		"c9cbbb": ["enamel", "ddd9c0", 0.0, 0.66],
		"293f43": ["trim", "3d5158", 0.20, 0.62],
		"497e79": ["enamel", "508584", 0.0, 0.64],
	},
	"reactor": {
		"273b40": ["trim", "394d53", 0.26, 0.60],
		"788e8e": ["trim", "a0acad", 0.54, 0.44],
		"c7c9ab": ["enamel", "ded9bd", 0.0, 0.58],
		"377b7c": ["enamel", "4b8587", 0.0, 0.62],
	},
	"shared": {
		"273b40": ["trim", "35484d", 0.26, 0.64],
		"788e8e": ["trim", "8da2a3", 0.50, 0.48],
	},
}
const YARD_COLORS := ["78857d", "7c877e", "738178"]
var candidates := {}


func apply(parts: Array, group: String, mode: int) -> void:
	for part: MeshInstance3D in parts:
		for index in part.mesh.get_surface_count():
			if mode == 0:
				part.set_surface_override_material(index, null)
				continue
			var source := part.mesh.surface_get_material(index) as StandardMaterial3D
			if source == null: continue
			var color := source.albedo_color.to_html(false)
			var material := _ground(color, mode) if group == "yard" else _equipment(group, color)
			if material != null:
				part.set_surface_override_material(index, material)


func _ground(color: String, mode: int) -> StandardMaterial3D:
	if color not in YARD_COLORS: return null
	var rock := mode == 1
	var key := "ground:" + str(mode)
	if not candidates.has(key):
		var material := _textured(ROCK if rock else WORK_SURFACE, Color.WHITE, 0.0,
			0.96 if rock else 0.86, 0.29 if rock else 0.47)
		material.uv1_world_triplanar = true
		if rock:
			material.normal_enabled = true
			material.normal_texture = ROCK_NORMAL
			material.normal_scale = 0.25
		candidates[key] = material
	return candidates[key]


func _equipment(group: String, color: String) -> StandardMaterial3D:
	var profile: Array = PROFILES[group].get(color, [])
	if profile.is_empty(): return null
	var key := group + ":" + color
	if not candidates.has(key):
		var enamel: bool = profile[0] == "enamel"
		candidates[key] = _textured(ENAMEL if enamel else TRIM, Color(profile[1]),
			profile[2], profile[3], 0.71 if enamel else 1.16)
	return candidates[key]


func _textured(texture: Texture2D, tint: Color, metallic: float, roughness: float,
		scale_factor: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.metallic = metallic
	material.roughness = roughness
	material.uv1_triplanar = true
	material.uv1_triplanar_sharpness = 5.0
	material.uv1_scale = Vector3.ONE * scale_factor
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material
