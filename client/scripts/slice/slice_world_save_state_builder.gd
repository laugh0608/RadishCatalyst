class_name SliceWorldSaveStateBuilder
extends RefCounted

## Serializes one authoritative SliceWorld snapshot on demand. It owns no
## mutable state and does not decide when or where the snapshot is written.


static func build(world: SliceWorld) -> Dictionary:
	var player_position := (
		world.player.position
		if world.player != null
		else SliceWorld.START_SPAWN
	)
	var combat_state := (
		world.combat_controller.durable_state()
		if world.combat_controller != null
		else {
			"player_health": 100,
			"field_encounter": {
				"state": "hostile" if world.is_core_charged() else "locked",
				"enemy_health": SliceFieldEnemy.MAX_HEALTH,
			},
		}
	)
	var state := {
		"pocket": world.pocket.to_dict(),
		"core_storage": world.core_storage.to_dict(),
		"core_repaired": world.core_repaired,
		"core_energy": world.core_energy,
		"harvested_clusters": world.harvested_clusters,
		"buildings": SliceBuildingSaveCodec.serialize_instances(
			world._building_instances
		),
		"next_building_serial": world._next_building_serial,
		"player_x": player_position.x,
		"player_y": player_position.y,
		"player_health": combat_state["player_health"],
		"field_encounter": combat_state["field_encounter"],
	}
	state.merge(
		world.first_journey.durable_data()
		if world.first_journey != null
		else SliceFirstJourneyController.default_durable_data(),
		true
	)
	return state
