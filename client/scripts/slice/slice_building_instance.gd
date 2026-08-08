class_name SliceBuildingInstance
extends Node2D

## Runtime identity and shared visual / collision shell for placed buildings.
## Device-specific content remains in narrow subclasses such as SliceCollector
## and SliceStorage.

const GROUND_SHADOW_SCENE := preload("res://scenes/components/GroundShadow.tscn")

var instance_id := ""
var building_id := ""
var origin_cell := Vector2i.ZERO
var building_rotation := 0
var definition: SliceBuildingDefinition
var powered := false
var _tile_size := 32.0


func configure_building(
	id: String,
	definition_id: String,
	cell: Vector2i,
	building_rotation: int
) -> void:
	instance_id = id
	building_id = definition_id
	origin_cell = cell
	self.building_rotation = posmod(building_rotation, 4)


func state_dict(_allowed_keys: Array[String]) -> Dictionary:
	return {}


func logistics_endpoints() -> Array[SliceLogisticsEndpoint]:
	return []


func apply_definition(next_definition: SliceBuildingDefinition, tile_size: float) -> void:
	definition = next_definition
	_tile_size = tile_size
	_configure_sprite()
	_configure_ground_shadow()
	_configure_footprint(tile_size)
	_configure_interaction(tile_size)
	_configure_power_indicator(tile_size)


func set_adjustment_hidden(hidden: bool) -> void:
	visible = not hidden
	for child in find_children("*", "CollisionShape2D", true, false):
		(child as CollisionShape2D).set_deferred("disabled", hidden)


func content_block_reason() -> String:
	return ""


func interaction_priority() -> int:
	return 0 if definition != null and definition.is_floor else 10


func set_powered(next_powered: bool) -> void:
	powered = next_powered
	_configure_sprite()
	var indicator := get_node_or_null("PowerIndicator") as Polygon2D
	if indicator != null:
		indicator.color = (
			Color(0.25, 1.0, 0.9, 1.0)
			if powered
			else Color(0.95, 0.2, 0.16, 1.0)
		)


func power_status_text() -> String:
	if definition == null:
		return ""
	if definition.power_role == SliceBuildingDefinition.POWER_RELAY:
		return "通电" if powered else "断电：未接入核心电网"
	if definition.power_role == SliceBuildingDefinition.POWER_CONSUMER:
		return "通电" if powered else "断电：未接入核心电网"
	return ""


func power_visual_anchor_world_position() -> Vector2:
	if definition == null:
		return position
	return definition.power_visual_anchor_world_position(
		origin_cell, _tile_size, building_rotation
	)


func _configure_sprite() -> void:
	if definition == null or definition.is_floor:
		return
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		add_child(sprite)
	var texture_path := definition.texture_path_for_rotation(building_rotation)
	if (
		definition.power_role == SliceBuildingDefinition.POWER_RELAY
		and powered
		and not definition.powered_texture_path.is_empty()
	):
		texture_path = definition.powered_texture_path
	sprite.texture = (
		null if texture_path.is_empty() else load(texture_path) as Texture2D
	)
	sprite.position = (
		definition.local_footprint_center_offset(
			_tile_size, building_rotation
		)
		+ definition.sprite_offset
	)


func _configure_ground_shadow() -> void:
	if definition == null or definition.is_floor:
		return
	var shadow := get_node_or_null("GroundShadow") as GroundShadow
	if shadow == null:
		shadow = GROUND_SHADOW_SCENE.instantiate() as GroundShadow
		shadow.name = "GroundShadow"
		shadow.target_path = NodePath("../Sprite")
		shadow.z_index = 0
		shadow.z_as_relative = true
		shadow.show_behind_parent = true
		shadow.vertical_compression = 0.18
		shadow.horizontal_offset_ratio = 0.06
		shadow.ground_offset = Vector2(1.0, 1.0)
		shadow.shadow_color = Color(0.08, 0.11, 0.12, 0.24)
		add_child(shadow)
		move_child(shadow, 0)


func _configure_power_indicator(tile_size: float) -> void:
	if (
		definition == null
		or (
			definition.power_role != SliceBuildingDefinition.POWER_CONSUMER
			and definition.power_role != SliceBuildingDefinition.POWER_RELAY
		)
	):
		return
	var indicator := get_node_or_null("PowerIndicator") as Polygon2D
	if indicator == null:
		indicator = Polygon2D.new()
		indicator.name = "PowerIndicator"
		indicator.polygon = PackedVector2Array([
			Vector2(0, -4),
			Vector2(4, 0),
			Vector2(0, 4),
			Vector2(-4, 0),
		])
		# Fixed device bodies never swap or derive a powered sprite. Keep the
		# small runtime lamp above the body but on its y-sorted plane.
		indicator.z_index = 0
		add_child(indicator)
	var size := Vector2(definition.rotated_footprint(building_rotation))
	indicator.position = (
		definition.local_footprint_center_offset(
			tile_size, building_rotation
		)
		+ size * tile_size * 0.5
		+ definition.power_indicator_offset
	)
	indicator.color = (
		Color(0.25, 1.0, 0.9, 1.0)
		if powered
		else Color(0.95, 0.2, 0.16, 1.0)
	)


func _configure_footprint(tile_size: float) -> void:
	if definition == null or not definition.blocks_movement:
		return
	var body := get_node_or_null("Footprint") as StaticBody2D
	if body == null:
		body = StaticBody2D.new()
		body.name = "Footprint"
		add_child(body)
	body.position = definition.local_footprint_center_offset(
		tile_size, building_rotation
	)
	var collision := body.get_node_or_null("Collision") as CollisionShape2D
	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "Collision"
		body.add_child(collision)
	collision.shape = _footprint_shape(tile_size)


func _configure_interaction(tile_size: float) -> void:
	var existing := get_node_or_null("PickupSite") as Area2D
	if existing != null:
		existing.position = definition.local_footprint_center_offset(
			tile_size, building_rotation
		)
		var pickup_collision := existing.get_node_or_null("Collision") as CollisionShape2D
		if pickup_collision != null:
			pickup_collision.shape = _footprint_shape(tile_size)
		return
	var site := get_node_or_null("InteractionSite") as SliceBuildingInteractionSite
	if site == null:
		site = SliceBuildingInteractionSite.new()
		site.name = "InteractionSite"
		add_child(site)
	site.position = definition.local_footprint_center_offset(
		tile_size, building_rotation
	)
	var collision := site.get_node_or_null("Collision") as CollisionShape2D
	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "Collision"
		site.add_child(collision)
	collision.shape = _footprint_shape(tile_size)


func _footprint_shape(tile_size: float) -> RectangleShape2D:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(definition.rotated_footprint(building_rotation)) * tile_size
	return shape
