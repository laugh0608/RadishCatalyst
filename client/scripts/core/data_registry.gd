extends Node
class_name DataRegistry

const DATA_FILES := {
	"items": "res://data/items.json",
	"fluids": "res://data/fluids.json",
	"recipes": "res://data/recipes.json",
	"buildings": "res://data/buildings.json",
	"equipment": "res://data/equipment.json",
	"enemies": "res://data/enemies.json",
	"regions": "res://data/regions.json",
	"map_objects": "res://data/map_objects.json",
	"pollution_types": "res://data/pollution_types.json",
	"weather_types": "res://data/weather_types.json",
	"quests": "res://data/quests.json"
}

const LOCALIZATION_FILES := {
	"zh_cn": "res://data/localization/zh_cn.json"
}

const REQUIRED_ENTRY_FIELDS := ["id", "display_name_key", "description_key", "public_level"]

var definitions: Dictionary = {}
var definitions_by_id: Dictionary = {}
var localization: Dictionary = {}


func load_all() -> bool:
	definitions.clear()
	definitions_by_id.clear()
	localization.clear()

	for table_name in DATA_FILES:
		var loaded_entries := _load_entries_file(DATA_FILES[table_name], table_name)
		if loaded_entries.is_empty():
			return false

		definitions[table_name] = loaded_entries
		for entry in loaded_entries:
			var entry_id := String(entry.get("id", ""))
			if definitions_by_id.has(entry_id):
				push_error("Duplicate static data id: %s" % entry_id)
				return false
			definitions_by_id[entry_id] = entry

	for locale in LOCALIZATION_FILES:
		var locale_entries := _load_localization_file(LOCALIZATION_FILES[locale])
		if locale_entries.is_empty():
			return false
		localization[locale] = locale_entries

	return true


func get_table(table_name: String) -> Array:
	return definitions.get(table_name, [])


func get_definition(definition_id: String) -> Dictionary:
	return definitions_by_id.get(definition_id, {})


func has_definition(definition_id: String) -> bool:
	return definitions_by_id.has(definition_id)


func get_text(text_key: String, locale: String = "zh_cn") -> String:
	var locale_entries: Dictionary = localization.get(locale, {})
	return String(locale_entries.get(text_key, text_key))


func get_summary() -> Dictionary:
	var summary := {}
	for table_name in definitions:
		summary[table_name] = definitions[table_name].size()
	return summary


func _load_entries_file(path: String, table_name: String) -> Array:
	var parsed := _load_json_dictionary(path)
	if parsed.is_empty():
		return []

	var entries: Array = parsed.get("entries", [])
	if entries.is_empty():
		push_error("Static data table has no entries: %s" % path)
		return []

	for raw_entry in entries:
		if not raw_entry is Dictionary:
			push_error("Static data entry is not a Dictionary in %s" % path)
			return []
		if not _validate_entry(raw_entry, table_name, path):
			return []

	return entries


func _load_localization_file(path: String) -> Dictionary:
	var parsed := _load_json_dictionary(path)
	if parsed.is_empty():
		return {}

	var entries: Dictionary = parsed.get("entries", {})
	if entries.is_empty():
		push_error("Localization file has no entries: %s" % path)
		return {}
	return entries


func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing JSON file: %s" % path)
		return {}

	var json_text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(json_text)
	if not parsed is Dictionary:
		push_error("Invalid JSON dictionary: %s" % path)
		return {}
	return parsed


func _validate_entry(entry: Dictionary, table_name: String, path: String) -> bool:
	for field_name in REQUIRED_ENTRY_FIELDS:
		if table_name in ["recipes", "weather_types"] and field_name == "category":
			continue
		if not entry.has(field_name):
			push_error("Missing field '%s' in %s" % [field_name, path])
			return false

	var entry_id := String(entry.get("id", ""))
	if entry_id.is_empty():
		push_error("Static data entry has empty id in %s" % path)
		return false
	if not entry_id.contains("."):
		push_error("Static data id should use category.name format: %s" % entry_id)
		return false
	return true
