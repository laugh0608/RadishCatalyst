class_name SliceBuildingInstance
extends Node2D

## Runtime identity and shared visual / collision shell for placed buildings.
## Device-specific content remains in narrow subclasses such as SliceCollector
## and SliceStorage.

var instance_id := ""
var building_id := ""
var origin_cell := Vector2i.ZERO
var building_rotation := 0
var definition: SliceBuildingDefinition


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


func apply_definition(next_definition: SliceBuildingDefinition, tile_size: float) -> void:
	definition = next_definition
	_configure_sprite()
	_configure_footprint(tile_size)
	_configure_interaction(tile_size)


func set_adjustment_hidden(hidden: bool) -> void:
	visible = not hidden
	for child in find_children("*", "CollisionShape2D", true, false):
		(child as CollisionShape2D).set_deferred("disabled", hidden)


func content_block_reason() -> String:
	return ""


func interaction_priority() -> int:
	return 0 if definition != null and definition.is_floor else 10


func _configure_sprite() -> void:
	if definition == null or definition.is_floor:
		return
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		add_child(sprite)
	var texture_path := definition.texture_path_for_rotation(building_rotation)
	sprite.texture = (
		null if texture_path.is_empty() else load(texture_path) as Texture2D
	)
	sprite.position = definition.sprite_offset


func _configure_footprint(tile_size: float) -> void:
	if definition == null or not definition.blocks_movement:
		return
	var body := get_node_or_null("Footprint") as StaticBody2D
	if body == null:
		body = StaticBody2D.new()
		body.name = "Footprint"
		add_child(body)
	var collision := body.get_node_or_null("Collision") as CollisionShape2D
	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "Collision"
		body.add_child(collision)
	collision.shape = _footprint_shape(tile_size)


func _configure_interaction(tile_size: float) -> void:
	var existing := get_node_or_null("PickupSite") as Area2D
	if existing != null:
		var pickup_collision := existing.get_node_or_null("Collision") as CollisionShape2D
		if pickup_collision != null:
			pickup_collision.shape = _footprint_shape(tile_size)
		return
	var site := get_node_or_null("InteractionSite") as SliceBuildingInteractionSite
	if site == null:
		site = SliceBuildingInteractionSite.new()
		site.name = "InteractionSite"
		add_child(site)
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
