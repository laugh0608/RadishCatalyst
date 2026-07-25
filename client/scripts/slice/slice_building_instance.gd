class_name SliceBuildingInstance
extends Node2D

## Runtime identity shared by placed floors and devices. Device-specific
## behavior remains in narrow subclasses such as SliceCollector.

var instance_id := ""
var building_id := ""
var origin_cell := Vector2i.ZERO
var building_rotation := 0


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
