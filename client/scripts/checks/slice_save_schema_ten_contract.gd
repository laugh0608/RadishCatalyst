class_name SliceSaveSchemaTenContract
extends RefCounted

## Schema 10 is schema 9 plus one explicit, cross-validated weapon selection.
## Reuse the frozen schema-9 contract for every unchanged field.


static func validate(data: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	if not data.has("equipped_weapon_id"):
		failures.append("root is missing equipped_weapon_id")
		return failures
	var weapon_value = data["equipped_weapon_id"]
	if not (weapon_value is String):
		failures.append("equipped_weapon_id must be a string")
	else:
		var weapon_id := String(weapon_value)
		if weapon_id not in [
			SliceCombatController.WEAPON_CUTTER,
			SliceCombatController.WEAPON_PULSE_RIFLE,
		]:
			failures.append("equipped_weapon_id is unknown")
		elif weapon_id == SliceCombatController.WEAPON_PULSE_RIFLE:
			var pocket = data.get("pocket", {})
			var contents = (
				pocket.get("contents", {}) if pocket is Dictionary else {}
			)
			if (
				not (contents is Dictionary)
				or int(contents.get(SliceItemCatalog.PULSE_RIFLE_ID, 0)) != 1
			):
				failures.append("equipped rifle must be in pocket")
	var schema_nine_shape := data.duplicate(true)
	schema_nine_shape.erase("equipped_weapon_id")
	schema_nine_shape["save_schema_version"] = 9
	schema_nine_shape["game_version"] = "prototype-slice-09"
	failures.append_array(SliceSaveSchemaNineContract.validate(schema_nine_shape))
	return failures
