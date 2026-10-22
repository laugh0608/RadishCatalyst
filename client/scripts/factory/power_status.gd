extends RefCounted

## Derived electrical availability, independent of production/idle status.
const COLORS := {"connected": "73ddd0", "disconnected": "b5bcbc", "no_supply": "ef977f", "shortage": "f0c16b"}
const LABELS := {"connected": "电力可用", "disconnected": "未接电网", "no_supply": "电网无供电", "shortage": "供电不足"}
static var textures := {}


static func supports(e: Dictionary) -> bool:
	return e.type in ["power_source", "power_junction", "collector", "reactor", "crusher", "refinery", "assembler"]


static func kind(model: RefCounted, e: Dictionary, state: Dictionary) -> String:
	var node: bool = model.Grid.is_node(e)
	var network: int = model.grid.membership.get(e.id, -1) if node else state.devices[e.id].network
	if not node and e.power_node_id == 0: return "disconnected"
	if e.type == "power_source" and not e.enabled: return "no_supply"
	if network < 0: return "disconnected"
	var group: Dictionary = model.grid.groups[network]
	if e.type == "power_junction" and group.nodes.size() == 1: return "disconnected"
	if group.capacity_kw <= 0: return "no_supply"
	if node:
		return "shortage" if group.request_kw > group.capacity_kw else "connected"
	var device: Dictionary = state.devices[e.id]
	return "shortage" if device.request_kw > 0 and device.fraction < 1 else "connected"


static func texture(key: String) -> Texture2D:
	if textures.has(key): return textures[key]
	# Small dynamic status overlays; device geometry remains imported GLB.
	var marks := {
		"connected": '<path d="M26 29l4 4 8-9"/>',
		"disconnected": '<path d="M27 25l10 10m0-10L27 35"/>',
		"no_supply": '<circle cx="32" cy="30" r="7"/><path d="M27 25l10 10"/>',
		"shortage": '<path d="M32 23v8m0 4v1"/>',
	}
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="44" height="44" viewBox="0 0 44 44"><rect x="1" y="1" width="42" height="42" rx="8" fill="#142e30" stroke="#%s" stroke-width="2"/><path d="M20 6L9 23h9l-3 14 12-19h-9z" fill="#%s"/><g fill="none" stroke="#%s" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">%s</g></svg>' % [COLORS[key], COLORS[key], COLORS[key], marks[key]]
	var image := Image.new()
	var error := image.load_svg_from_string(svg)
	assert(error == OK, "Invalid power status icon")
	textures[key] = ImageTexture.create_from_image(image)
	return textures[key]


static func marker(parent: Node3D, position: Vector3) -> Sprite3D:
	var icon := Sprite3D.new()
	icon.texture = texture("disconnected")
	icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icon.pixel_size = 0.016
	icon.no_depth_test = true
	icon.render_priority = 1
	icon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(icon)
	icon.position = position
	return icon
