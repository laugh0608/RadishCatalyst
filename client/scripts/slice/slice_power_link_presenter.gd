class_name SlicePowerLinkPresenter
extends Node

## Chooses when derived power topology is useful to the player. It observes
## presentation state only and never changes power reachability or topology.

var _world: SliceWorld
var _layer: SlicePowerLinkLayer
var _building_panel: SliceBuildingActionPanel


func setup(
	world: SliceWorld,
	layer: SlicePowerLinkLayer,
	building_panel: SliceBuildingActionPanel
) -> void:
	_world = world
	_layer = layer
	_building_panel = building_panel
	_world.placement_changed.connect(_refresh_context)
	_building_panel.open_state_changed.connect(_on_panel_state_changed)
	_refresh_context()


func _on_panel_state_changed(
	_opened: bool,
	_target: SliceBuildingInstance
) -> void:
	_refresh_context()


func _refresh_context(_changed_value = null) -> void:
	if _world == null or _layer == null or _building_panel == null:
		return
	if _world.is_placement_active():
		var placement_definition := SliceBuildingCatalog.find(
			_world.selected_building_id()
		)
		_layer.set_context(
			SlicePowerLinkLayer.CONTEXT_PLACEMENT
			if _definition_uses_power(placement_definition)
			else SlicePowerLinkLayer.CONTEXT_NORMAL
		)
		return
	var target := _building_panel.target_instance()
	_layer.set_context(
		SlicePowerLinkLayer.CONTEXT_DEVICE
		if _building_panel.is_open()
		and target != null
		and _definition_uses_power(target.definition)
		else SlicePowerLinkLayer.CONTEXT_NORMAL
	)


func _definition_uses_power(definition: SliceBuildingDefinition) -> bool:
	return (
		definition != null
		and definition.power_role != SliceBuildingDefinition.POWER_PASSIVE
	)
