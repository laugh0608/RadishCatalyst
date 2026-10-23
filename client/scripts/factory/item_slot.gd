extends Button

## One aggregated material stack. Selecting a slot never transfers stock.
const Items := preload("res://scripts/factory/items.gd")
const Rules := preload("res://data/factory/discovery_rules.gd")
const TEXTURES := {
	"industrial_cell": preload("res://assets/icons/factory_industrial_cell.svg"),
	"iron_ore": preload("res://assets/icons/factory_iron_ore.svg"),
	"carbon_ore": preload("res://assets/icons/factory_carbon_ore.svg"),
	"iron_powder": preload("res://assets/icons/factory_iron_powder.svg"),
	"carbon_powder": preload("res://assets/icons/factory_carbon_powder.svg"),
	"metal_plate": preload("res://assets/icons/factory_metal_plate.svg"),
	"mineral_slag": preload("res://assets/icons/factory_mineral_slag.svg"),
	"porous_carrier": preload("res://assets/icons/factory_porous_carrier.svg"),
	"construction_pack": preload("res://assets/icons/factory_construction_pack.svg"),

	"crystal": preload("res://assets/icons/factory_crystal.svg"),
	"catalyst": preload("res://assets/icons/factory_catalyst.svg"),
	"crust_sample": preload("res://assets/icons/factory_crust_sample.svg"),
	"crust_solvent": preload("res://assets/icons/factory_crust_solvent.svg"),
	"rich_crystal": preload("res://assets/icons/factory_rich_crystal.svg"),
}
const ACCENTS := {"industrial_cell": "edc97e", "iron_ore": "b77b57", "carbon_ore": "87909c", "iron_powder": "d39b79", "carbon_powder": "a1abb4", "metal_plate": "a5cfda", "mineral_slag": "a9ae88", "porous_carrier": "d8c999", "construction_pack": "7cd7c6", "crystal": "7cd7c6", "catalyst": "edc97e", "crust_sample": "bed4b3", "crust_solvent": "eba960", "rich_crystal": "bda0df"}
var item_id := ""
var amount := 0
var artwork := TextureRect.new()
var quantity := Label.new()
var caption := Label.new()


func _ready() -> void:
	custom_minimum_size = Vector2(92, 116)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggle_mode = true
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("304442" if state == "normal" else "425b53")
		style.border_color = Color("dce8ca" if state in ["pressed", "hover_pressed", "focus"] else "58786e")
		style.set_border_width_all(2 if state in ["pressed", "hover_pressed", "focus"] else 1)
		style.border_width_bottom = 4
		style.set_corner_radius_all(4)
		add_theme_stylebox_override(state, style)
	artwork.texture = TEXTURES[item_id]
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(artwork)
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork.offset_left = 10
	artwork.offset_right = -10
	artwork.offset_top = 4
	artwork.offset_bottom = -33
	for label in [quantity, caption]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
	quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity.add_theme_font_size_override("font_size", 22)
	quantity.add_theme_color_override("font_shadow_color", Color("132b2d"))
	quantity.add_theme_constant_override("shadow_offset_x", 1)
	quantity.add_theme_constant_override("shadow_offset_y", 2)
	quantity.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	quantity.offset_top = -50
	quantity.offset_bottom = -22
	quantity.offset_right = -8
	caption.text = Items.NAMES[item_id]
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 14)
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -25
	caption.offset_bottom = -6
	var normal: StyleBoxFlat = get_theme_stylebox("normal").duplicate()
	normal.border_color = Color(ACCENTS[item_id])
	normal.border_width_left = 0
	normal.border_width_right = 0
	normal.border_width_top = 0
	add_theme_stylebox_override("normal", normal)
	update_amount(amount)


func update_amount(value: int, required := 0) -> void:
	amount = value
	quantity.text = str(value) if required == 0 else "%d / %d" % [value, required]
	artwork.modulate.a = 1.0 if value > 0 else 0.35
	tooltip_text = "%s：%d 件" % [Items.NAMES[item_id], value]
	if required > 0:
		tooltip_text += "；每批需 %d 件" % required


func mark_selected(chosen: bool) -> void:
	set_pressed_no_signal(chosen)
