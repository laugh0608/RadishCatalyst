class_name SliceSaveService
extends RefCounted

## Lightweight save service for the slice world. Physically isolated from the
## frozen legacy SaveService: its own directory, schema and JSON layout, no
## shared code or state. Persists one slice world as plain JSON with atomic
## temp-then-rename writes. Legacy callers keep one backup; multi-world callers
## use autosave.json plus three rotated backups and lightweight metadata.
##
## Schema 9 adds first-journey acknowledgements and a compact exploration map.
## Loading is read-only: schema 2–8
## candidates migrate in memory and return a publication context. SliceWorld
## may publish that state only after complete world reconstruction.

const SAVE_SCHEMA_VERSION := 9
const MIN_SUPPORTED_SCHEMA_VERSION := 2
const GAME_VERSION := "prototype-slice-09"
const DEFAULT_SAVE_DIR := "user://saves/slice"
const LEGACY_CORE_STORAGE_CAPACITY := 120
const LEGACY_SAVE_FILE_NAME := "slice_world.json"
const WORLD_SAVE_FILE_NAME := "autosave.json"
const WORLD_BACKUP_COUNT := 3
const WORLD_METADATA_SCHEMA_VERSION := 1
const FIELD_ENEMY_MAX_HEALTH := 60
const ENCOUNTER_STATES := [
	"locked",
	"hostile",
	"dropped",
	"carried",
	"delivered",
]
const ROOT_KEYS := [
	"buildings", "core_energy", "core_repaired", "core_storage",
	"explored_map_bits", "field_encounter", "first_journey_flags",
	"game_version", "harvested_clusters",
	"next_building_serial", "player_health", "player_x", "player_y",
	"pocket", "save_schema_version", "updated_at",
]

var _save_dir: String
var _save_file: String
var _save_temp_file: String
var _save_backup_files: Array[String] = []
var _world_id := ""
var _metadata_file := ""
var _metadata_temp_file := ""
var _pending_publish_context: Dictionary = {}


func _init(
	save_dir: String = DEFAULT_SAVE_DIR,
	save_file_name: String = LEGACY_SAVE_FILE_NAME,
	backup_count: int = 1,
	world_id: String = ""
) -> void:
	_save_dir = save_dir.trim_suffix("/")
	_save_file = _save_dir.path_join(save_file_name)
	var stem := save_file_name.trim_suffix(".json")
	_save_temp_file = _save_dir.path_join("%s.tmp.json" % stem)
	_world_id = world_id
	if not _world_id.is_empty():
		_metadata_file = _save_dir.path_join("metadata.json")
		_metadata_temp_file = _save_dir.path_join("metadata.tmp.json")
	if save_file_name == LEGACY_SAVE_FILE_NAME and backup_count == 1:
		_save_backup_files.append(
			_save_dir.path_join("slice_world.bak.json")
		)
		return
	var backups_dir := _save_dir.path_join("backups")
	for index in range(1, maxi(backup_count, 0) + 1):
		_save_backup_files.append(
			backups_dir.path_join("%s.bak.%d.json" % [stem, index])
		)


static func for_world(
	world_dir: String,
	world_id: String
) -> SliceSaveService:
	return SliceSaveService.new(
		world_dir,
		WORLD_SAVE_FILE_NAME,
		WORLD_BACKUP_COUNT,
		world_id
	)


func save_directory() -> String:
	return _save_dir


func save_file_path() -> String:
	return _save_file


func backup_file_paths() -> Array[String]:
	return _save_backup_files.duplicate()


func has_save() -> bool:
	if FileAccess.file_exists(_save_file):
		return true
	for backup_file in _save_backup_files:
		if FileAccess.file_exists(backup_file):
			return true
	return false


func save_state(state: Dictionary) -> Dictionary:
	if not _pending_publish_context.is_empty():
		return _failure(
			"载入的迁移或备份状态尚未在世界重建后发布；"
			+ "请先调用 commit_loaded_state。"
		)
	var data_result := _schema_nine_save_data(state)
	if not bool(data_result.get("success", false)):
		return data_result
	return _publish_save_data(data_result["data"], true)


## Publishes a load result after SliceWorld has reconstructed every durable
## object and rebuilt derived grids. The caller must retain load_context until
## this succeeds; failures leave the context pending and retryable.
func commit_loaded_state(
	state: Dictionary,
	load_context: Dictionary
) -> Dictionary:
	var context_result := _validate_load_context(load_context)
	if not bool(context_result.get("success", false)):
		return context_result
	var context: Dictionary = context_result["data"]
	if not bool(context["publish_required"]):
		return _success("当前主档已经是 schema 9，无需迁移发布。")
	if (
		_pending_publish_context.is_empty()
		or not _load_contexts_match(
			_pending_publish_context, context
		)
	):
		return _failure("载入上下文已失效，请重新读取存档后再发布。")
	var source_path := String(context["source_path"])
	if (
		not FileAccess.file_exists(source_path)
		or FileAccess.get_sha256(source_path)
		!= String(context["source_sha256"])
	):
		return _failure("载入候选在世界重建期间发生变化，请重新读取。")
	var data_result := _schema_nine_save_data(state)
	if not bool(data_result.get("success", false)):
		return data_result
	var rotate_backups := source_path == _save_file
	var publish_result := _publish_save_data(
		data_result["data"], rotate_backups
	)
	if bool(publish_result.get("success", false)):
		_pending_publish_context = {}
	return publish_result


func has_pending_loaded_state() -> bool:
	return not _pending_publish_context.is_empty()


func _schema_nine_save_data(state: Dictionary) -> Dictionary:
	var pocket_result := _canonical_inventory_input(
		state.get("pocket", {}),
		SliceInventoryProfiles.category_pocket(),
		"pocket"
	)
	if not bool(pocket_result.get("success", false)):
		return pocket_result
	var core_result := _canonical_inventory_input(
		state.get("core_storage", {}),
		SliceInventoryProfiles.category_core_storage(),
		"core_storage"
	)
	if not bool(core_result.get("success", false)):
		return core_result

	var core_energy := int(state.get("core_energy", 0))
	var combat_result := _validate_combat_state(
		state.get("player_health", 100),
		state.get(
			"field_encounter",
			_default_encounter(core_energy)
		),
		core_energy
	)
	if not bool(combat_result.get("success", false)):
		return combat_result
	var combat_data: Dictionary = combat_result["data"]
	var journey_result := _validate_first_journey_flags(
		state.get("first_journey_flags", {})
	)
	if not bool(journey_result.get("success", false)):
		return journey_result
	var exploration_result := _validate_explored_map_bits(
		state.get("explored_map_bits", "")
	)
	if not bool(exploration_result.get("success", false)):
		return exploration_result
	var save_data := {
		"save_schema_version": SAVE_SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"updated_at": _local_time_text(),
		"pocket": pocket_result["data"],
		"core_storage": core_result["data"],
		"core_repaired": bool(state.get("core_repaired", false)),
		"core_energy": core_energy,
		"harvested_clusters": canonical_string_array(
			state.get("harvested_clusters", [])
		),
		"buildings": state.get("buildings", []),
		"next_building_serial": int(
			state.get("next_building_serial", 1)
		),
		"player_x": float(state.get("player_x", 0.0)),
		"player_y": float(state.get("player_y", 0.0)),
		"player_health": combat_data["player_health"],
		"field_encounter": combat_data["field_encounter"],
		"first_journey_flags": journey_result["data"],
		"explored_map_bits": exploration_result["data"],
	}
	return _validate_schema_nine_payload(save_data)


func _publish_save_data(
	save_data: Dictionary,
	rotate_backups: bool
) -> Dictionary:
	var absolute_save_dir := ProjectSettings.globalize_path(_save_dir)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute_save_dir)
	if dir_error != OK and not DirAccess.dir_exists_absolute(absolute_save_dir):
		return _failure("创建切片存档目录失败：%s。" % error_string(dir_error))
	if not _save_backup_files.is_empty():
		var backup_dir := ProjectSettings.globalize_path(
			_save_backup_files[0].get_base_dir()
		)
		var backup_dir_error := DirAccess.make_dir_recursive_absolute(backup_dir)
		if (
			backup_dir_error != OK
			and not DirAccess.dir_exists_absolute(backup_dir)
		):
			return _failure(
				"创建切片备份目录失败：%s。"
				% error_string(backup_dir_error)
			)

	var temp := FileAccess.open(_save_temp_file, FileAccess.WRITE)
	if temp == null:
		return _failure("打开切片存档临时文件失败：%s。" % error_string(FileAccess.get_open_error()))
	temp.store_string(JSON.stringify(save_data, "\t"))
	temp.close()

	if rotate_backups:
		var backup_error := _rotate_backups()
		if backup_error != OK:
			return _failure(
				"备份切片存档失败：%s。当前主档未被覆盖。"
				% error_string(backup_error)
			)

	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(_save_temp_file),
		ProjectSettings.globalize_path(_save_file)
	)
	if rename_error != OK:
		return _failure("写入切片存档失败：%s。" % error_string(rename_error))
	var metadata_error := _update_world_metadata(save_data)
	if not metadata_error.is_empty():
		return {
			"success": true,
			"message": "已保存世界状态，但更新列表摘要失败：%s。" % metadata_error,
			"warning": metadata_error,
		}
	return _success("已保存切片存档。")


func load_state() -> Dictionary:
	var last_failure: Dictionary = {}
	var candidates: Array[String] = [_save_file]
	candidates.append_array(_save_backup_files)
	for save_file in candidates:
		if not FileAccess.file_exists(save_file):
			continue
		var read_result := _read_file(save_file)
		if bool(read_result.get("success", false)):
			var source_schema_version := int(
				read_result.get("source_schema_version", -1)
			)
			var context := {
				"source_path": save_file,
				"source_sha256": FileAccess.get_sha256(save_file),
				"source_schema_version": source_schema_version,
				"source_game_version": String(
					read_result.get("source_game_version", "")
				),
				"migration_required": source_schema_version < SAVE_SCHEMA_VERSION,
				"publish_required": (
					source_schema_version < SAVE_SCHEMA_VERSION
					or save_file != _save_file
				),
			}
			read_result["source_path"] = save_file
			read_result["migration_required"] = context["migration_required"]
			read_result["publish_required"] = context["publish_required"]
			read_result["load_context"] = context.duplicate(true)
			_pending_publish_context = (
				context.duplicate(true)
				if bool(context["publish_required"])
				else {}
			)
			return read_result
		last_failure = read_result
	if not last_failure.is_empty():
		return last_failure
	return _failure("读取切片存档失败：未找到可用存档，当前运行状态已保留。")


func get_summary() -> Dictionary:
	var result := load_state()
	var display_name := "切片存档"
	var metadata := _read_world_metadata()
	if not metadata.is_empty():
		display_name = String(metadata.get("display_name", display_name))
	if not bool(result.get("success", false)):
		var status := "存档不可读取" if has_save() else "空存档"
		var details := String(result.get("message", "")) if has_save() else "尚未保存切片进度。"
		return {
			"has_loadable_save": false,
			"display_name": display_name,
			"status": status,
			"details": details
		}

	var data: Dictionary = result.get("data", {})
	var repaired_text := "核心已修复" if bool(data.get("core_repaired", false)) else "核心未修复"
	var pocket_dict: Dictionary = data.get("pocket", {})
	var core_storage_dict: Dictionary = data.get("core_storage", {})
	var contents = pocket_dict.get("contents", {})
	var core_contents = core_storage_dict.get("contents", {})
	var crystal := int(contents.get(SliceWorld.ITEM_CRYSTAL, 0)) if contents is Dictionary else 0
	var field_encounter: Dictionary = data.get("field_encounter", {})
	var encounter_text := _encounter_summary_text(
		String(field_encounter.get("state", "locked"))
	)
	var stored := 0
	if core_contents is Dictionary:
		for amount in core_contents.values():
			stored += int(amount)
	var details := "背包晶体 %d；核心仓库 %d；%s；外勤%s；最近保存 %s" % [
		crystal,
		stored,
		repaired_text,
		encounter_text,
		String(data.get("updated_at", "未知时间"))
	]
	return {
		"has_loadable_save": true,
		"display_name": display_name,
		"status": "可读取",
		"details": details
	}


func _rotate_backups() -> Error:
	if not FileAccess.file_exists(_save_file):
		return OK
	for index in range(_save_backup_files.size() - 1, 0, -1):
		var source := _save_backup_files[index - 1]
		if not FileAccess.file_exists(source):
			continue
		var copy_error := DirAccess.copy_absolute(
			ProjectSettings.globalize_path(source),
			ProjectSettings.globalize_path(_save_backup_files[index])
		)
		if copy_error != OK:
			return copy_error
	if _save_backup_files.is_empty():
		return OK
	return DirAccess.copy_absolute(
		ProjectSettings.globalize_path(_save_file),
		ProjectSettings.globalize_path(_save_backup_files[0])
	)


func _update_world_metadata(save_data: Dictionary) -> String:
	if _metadata_file.is_empty():
		return ""
	var metadata := _read_world_metadata()
	var now := String(save_data.get("updated_at", _local_time_text()))
	if metadata.is_empty():
		metadata = {
			"metadata_schema_version": WORLD_METADATA_SCHEMA_VERSION,
			"world_id": _world_id,
			"display_name": "未命名世界",
			"created_at": now,
			"play_time_seconds": 0,
		}
	metadata["metadata_schema_version"] = WORLD_METADATA_SCHEMA_VERSION
	metadata["world_id"] = _world_id
	metadata["updated_at"] = now
	metadata["game_version"] = GAME_VERSION
	metadata["save_schema_version"] = SAVE_SCHEMA_VERSION
	metadata["core_repaired"] = bool(save_data.get("core_repaired", false))
	var buildings = save_data.get("buildings", [])
	metadata["building_count"] = buildings.size() if buildings is Array else 0
	metadata["catalyst_count"] = _saved_item_count(
		save_data,
		SliceWorld.ITEM_CATALYST
	)
	metadata["player_health"] = int(save_data.get("player_health", 100))
	var field_encounter: Dictionary = save_data.get("field_encounter", {})
	metadata["field_encounter_state"] = String(
		field_encounter.get("state", "locked")
	)
	var file := FileAccess.open(_metadata_temp_file, FileAccess.WRITE)
	if file == null:
		return error_string(FileAccess.get_open_error())
	file.store_string(JSON.stringify(metadata, "\t"))
	file.close()
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(_metadata_temp_file),
		ProjectSettings.globalize_path(_metadata_file)
	)
	return "" if rename_error == OK else error_string(rename_error)


func _read_world_metadata() -> Dictionary:
	if _metadata_file.is_empty() or not FileAccess.file_exists(_metadata_file):
		return {}
	var file := FileAccess.open(_metadata_file, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func _saved_item_count(save_data: Dictionary, item_id: String) -> int:
	var total := _inventory_item_count(save_data.get("pocket", {}), item_id)
	total += _inventory_item_count(save_data.get("core_storage", {}), item_id)
	var buildings = save_data.get("buildings", [])
	if not (buildings is Array):
		return total
	for building in buildings:
		if not (building is Dictionary):
			continue
		var state = building.get("state", {})
		if not (state is Dictionary):
			continue
		total += _inventory_item_count(state.get("inventory", {}), item_id)
		total += _inventory_item_count(
			state.get("input_inventory", {}),
			item_id
		)
		total += _inventory_item_count(
			state.get("output_inventory", {}),
			item_id
		)
		var cargo = state.get("cargo", {})
		if cargo is Dictionary and String(cargo.get("item_id", "")) == item_id:
			total += 1
	return total


func _inventory_item_count(value, item_id: String) -> int:
	if not (value is Dictionary):
		return 0
	var contents = value.get("contents", {})
	return int(contents.get(item_id, 0)) if contents is Dictionary else 0


func _encounter_summary_text(encounter_state: String) -> String:
	match encounter_state:
		"hostile":
			return "交战中"
		"dropped":
			return "样本待拾取"
		"carried":
			return "样本待交付"
		"delivered":
			return "内衬已安装"
		_:
			return "未充能"


func _read_file(save_file: String) -> Dictionary:
	var file := FileAccess.open(save_file, FileAccess.READ)
	if file == null:
		return _failure("打开切片存档失败：%s。当前运行状态已保留。" % error_string(FileAccess.get_open_error()))
	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		return _failure("切片存档 JSON 解析失败：%s（第 %d 行）。当前运行状态已保留。" % [
			json.get_error_message(), json.get_error_line()
		])
	if not (json.data is Dictionary):
		return _failure("切片存档根对象格式无效，当前运行状态已保留。")

	var save_data: Dictionary = json.data
	var version := int(save_data.get("save_schema_version", -1))
	if version < MIN_SUPPORTED_SCHEMA_VERSION or version > SAVE_SCHEMA_VERSION:
		return _failure("切片存档版本不兼容（文件版本 %d，当前支持 %d），当前运行状态已保留。" % [
			version, SAVE_SCHEMA_VERSION
		])

	var payload_result: Dictionary
	if version == SAVE_SCHEMA_VERSION:
		payload_result = _validate_schema_nine_payload(save_data)
	else:
		payload_result = _migrate_legacy_payload(save_data, version)
	if not bool(payload_result.get("success", false)):
		return payload_result
	var payload: Dictionary = payload_result["data"]
	return {
		"success": true,
		"message": "已读取切片存档。",
		"source_schema_version": version,
		"source_game_version": String(
			save_data.get("game_version", "")
		),
		"data": _runtime_data_from_payload(payload),
	}


func _migrate_legacy_payload(
	save_data: Dictionary,
	version: int
) -> Dictionary:
	var pocket := _legacy_inventory_dict(save_data.get("pocket", {}))
	var core_storage := _legacy_inventory_dict(
		save_data.get("core_storage", {})
	)
	var building_result: Dictionary
	if version >= 8:
		building_result = SliceBuildingSaveCodec.validate_schema_eight(
			save_data.get("buildings", null),
			save_data.get("next_building_serial", null)
		)
	elif version >= 6:
		building_result = SliceBuildingSaveCodec.validate_schema_seven(
			save_data.get("buildings", null),
			save_data.get("next_building_serial", null)
		)
	elif version >= 4:
		building_result = SliceBuildingSaveCodec.migrate_schema_five(
			save_data.get("buildings", null),
			save_data.get("next_building_serial", null)
		)
	else:
		building_result = SliceBuildingSaveCodec.migrate_legacy_collectors(
			save_data.get("collectors", [])
		)
		if bool(save_data.get("carrying_collector", false)):
			pocket = SliceBuildingSaveCodec.add_legacy_carried_collector(pocket)
		if version == 2:
			core_storage = {
				"capacity": LEGACY_CORE_STORAGE_CAPACITY,
				"contents": {},
			}
	if version <= 5:
		core_storage = _restore_legacy_item(
			core_storage,
			SliceWorld.ITEM_CATALYST,
			int(save_data.get("catalyst_count", 0))
		)
	if not bool(building_result.get("success", false)):
		return building_result
	var building_data: Dictionary = building_result["data"]
	if version < 8:
		var migrated_buildings := (
			SliceBuildingSaveCodec.migrate_schema_seven_to_eight(
				building_data["buildings"],
				building_data["next_building_serial"]
			)
		)
		if not bool(migrated_buildings.get("success", false)):
			return migrated_buildings
		building_data = migrated_buildings["data"]
	var combat_result: Dictionary
	if version >= 7:
		combat_result = _validate_combat_state(
			save_data.get("player_health", null),
			save_data.get("field_encounter", null),
			int(save_data.get("core_energy", 0))
		)
	else:
		var migrated_encounter := _default_encounter(
			int(save_data.get("core_energy", 0))
		)
		combat_result = _validate_combat_state(
			100,
			migrated_encounter,
			int(save_data.get("core_energy", 0))
		)
	if not bool(combat_result.get("success", false)):
		return combat_result
	var combat_data: Dictionary = combat_result["data"]
	var player_position := Vector2(
		float(save_data.get("player_x", SliceExplorationState.START_SPAWN.x)),
		float(save_data.get("player_y", SliceExplorationState.START_SPAWN.y))
	)
	var migrated_payload := {
		"save_schema_version": SAVE_SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"updated_at": String(save_data.get("updated_at", "")),
		"pocket": _without_legacy_inventory_capacity(pocket),
		"core_storage": _without_legacy_inventory_capacity(core_storage),
		"core_repaired": bool(save_data.get("core_repaired", false)),
		"core_energy": int(save_data.get("core_energy", 0)),
		"harvested_clusters": canonical_string_array(
			save_data.get("harvested_clusters", [])
		),
		"buildings": building_data["buildings"],
		"next_building_serial": building_data["next_building_serial"],
		"player_x": float(save_data.get("player_x", 0.0)),
		"player_y": float(save_data.get("player_y", 0.0)),
		"player_health": combat_data["player_health"],
		"field_encounter": combat_data["field_encounter"],
		"first_journey_flags": _migrated_first_journey_flags(
			save_data, pocket, core_storage, player_position
		),
		"explored_map_bits": (
			SliceExplorationState.default_bits_for_position(player_position)
		),
	}
	return _validate_schema_nine_payload(migrated_payload)


func _runtime_data_from_payload(payload: Dictionary) -> Dictionary:
	return {
		"pocket": (payload["pocket"] as Dictionary).duplicate(true),
		"core_storage": (
			payload["core_storage"] as Dictionary
		).duplicate(true),
		"catalyst_count": 0,
		"core_repaired": bool(payload["core_repaired"]),
		"core_energy": int(payload["core_energy"]),
		"reactor_active": false,
		"harvested_clusters": (
			payload["harvested_clusters"] as Array
		).duplicate(),
		"buildings": (payload["buildings"] as Array).duplicate(true),
		"next_building_serial": int(payload["next_building_serial"]),
		"player_x": float(payload["player_x"]),
		"player_y": float(payload["player_y"]),
		"player_health": int(payload["player_health"]),
		"field_encounter": (
			payload["field_encounter"] as Dictionary
		).duplicate(true),
		"first_journey_flags": (
			payload["first_journey_flags"] as Dictionary
		).duplicate(true),
		"explored_map_bits": String(payload["explored_map_bits"]),
		"updated_at": String(payload["updated_at"]),
	}


func _default_encounter(core_energy: int) -> Dictionary:
	return {
		"state": "hostile" if core_energy >= SliceWorld.CORE_CHARGE_TARGET else "locked",
		"enemy_health": FIELD_ENEMY_MAX_HEALTH,
	}


func _validate_combat_state(
	player_health_value,
	field_encounter_value,
	core_energy: int
) -> Dictionary:
	if not _is_integral_number(player_health_value):
		return _failure("切片存档 player_health 必须是整数。")
	if not (field_encounter_value is Dictionary):
		return _failure("切片存档 field_encounter 必须是对象。")
	var field_encounter: Dictionary = field_encounter_value
	if (
		field_encounter.keys().size() != 2
		or not field_encounter.has("state")
		or not field_encounter.has("enemy_health")
	):
		return _failure(
			"切片存档 field_encounter 必须且只能包含 state 与 enemy_health。"
		)
	if not (field_encounter["state"] is String):
		return _failure("切片存档 field_encounter.state 必须是字符串。")
	if not _is_integral_number(field_encounter["enemy_health"]):
		return _failure("切片存档 field_encounter.enemy_health 必须是整数。")
	var encounter_state := String(field_encounter["state"])
	if not ENCOUNTER_STATES.has(encounter_state):
		return _failure(
			"切片存档 field_encounter.state 未知：%s。" % encounter_state
		)
	if (
		core_energy < SliceWorld.CORE_CHARGE_TARGET
		and encounter_state != "locked"
	):
		return _failure("切片存档未充能核心只能对应 locked 遭遇状态。")
	if (
		core_energy >= SliceWorld.CORE_CHARGE_TARGET
		and encounter_state == "locked"
	):
		return _failure("切片存档已充能核心不能对应 locked 遭遇状态。")
	var player_health := int(player_health_value)
	var player_max_health := 120 if encounter_state == "delivered" else 100
	if player_health < 1 or player_health > player_max_health:
		return _failure(
			"切片存档 player_health 必须在 1–%d 之间。" % player_max_health
		)
	var enemy_health := int(field_encounter["enemy_health"])
	if encounter_state in ["locked", "hostile"]:
		if enemy_health < 1 or enemy_health > FIELD_ENEMY_MAX_HEALTH:
			return _failure(
				"切片存档 %s 状态的 enemy_health 必须在 1–%d 之间。"
				% [encounter_state, FIELD_ENEMY_MAX_HEALTH]
			)
	elif enemy_health != 0:
		return _failure(
			"切片存档 %s 状态的 enemy_health 必须为 0。"
			% encounter_state
		)
	return {
		"success": true,
		"message": "战斗状态有效。",
		"data": {
			"player_health": player_health,
			"field_encounter": {
				"state": encounter_state,
				"enemy_health": enemy_health,
			},
		},
	}


func _is_integral_number(value) -> bool:
	if not (value is int or value is float):
		return false
	return is_equal_approx(float(value), float(int(value)))


func _validate_schema_nine_payload(value) -> Dictionary:
	if not (value is Dictionary):
		return _failure("schema 9 存档根对象必须是对象。")
	var payload: Dictionary = value
	if not _has_exact_keys(payload, ROOT_KEYS):
		return _failure("schema 9 存档根对象字段集合无效。")
	if (
		not _is_integral_number(payload["save_schema_version"])
		or int(payload["save_schema_version"]) != SAVE_SCHEMA_VERSION
	):
		return _failure("schema 9 存档版本字段无效。")
	if (
		not (payload["game_version"] is String)
		or String(payload["game_version"]) != GAME_VERSION
	):
		return _failure("schema 9 存档游戏版本字段无效。")
	if not (payload["updated_at"] is String):
		return _failure("schema 9 存档 updated_at 必须是字符串。")
	if not (payload["core_repaired"] is bool):
		return _failure("schema 9 存档 core_repaired 必须是布尔值。")
	if not _is_integral_number(payload["core_energy"]):
		return _failure("schema 9 存档 core_energy 必须是整数。")
	for coordinate_key in ["player_x", "player_y"]:
		var coordinate = payload[coordinate_key]
		if (
			not (coordinate is float or coordinate is int)
			or not is_finite(float(coordinate))
		):
			return _failure(
				"schema 9 存档 %s 必须是有限数值。" % coordinate_key
			)
	var harvested = payload["harvested_clusters"]
	if not (harvested is Array):
		return _failure("schema 9 存档 harvested_clusters 必须是数组。")
	for cluster_name in harvested:
		if not (cluster_name is String):
			return _failure(
				"schema 9 存档 harvested_clusters 只能包含字符串。"
			)

	var pocket_result := _validate_current_inventory(
		payload["pocket"],
		SliceInventoryProfiles.category_pocket(),
		"pocket"
	)
	if not bool(pocket_result.get("success", false)):
		return pocket_result
	var core_result := _validate_current_inventory(
		payload["core_storage"],
		SliceInventoryProfiles.category_core_storage(),
		"core_storage"
	)
	if not bool(core_result.get("success", false)):
		return core_result
	var pocket_contents: Dictionary = pocket_result["data"]["contents"]
	var core_contents: Dictionary = core_result["data"]["contents"]
	if (
		int(pocket_contents.get(SliceItemCatalog.PULSE_RIFLE_ID, 0))
		+ int(core_contents.get(SliceItemCatalog.PULSE_RIFLE_ID, 0))
		> 1
	):
		return _failure("schema 9 前哨脉冲步枪总量不能超过 1。")
	var building_result := SliceBuildingSaveCodec.validate_schema_eight(
		payload["buildings"], payload["next_building_serial"]
	)
	if not bool(building_result.get("success", false)):
		return building_result
	var combat_result := _validate_combat_state(
		payload["player_health"],
		payload["field_encounter"],
		int(payload["core_energy"])
	)
	if not bool(combat_result.get("success", false)):
		return combat_result
	var journey_result := _validate_first_journey_flags(
		payload["first_journey_flags"]
	)
	if not bool(journey_result.get("success", false)):
		return journey_result
	var exploration_result := _validate_explored_map_bits(
		payload["explored_map_bits"]
	)
	if not bool(exploration_result.get("success", false)):
		return exploration_result

	var canonical := payload.duplicate(true)
	canonical["save_schema_version"] = SAVE_SCHEMA_VERSION
	canonical["pocket"] = pocket_result["data"]
	canonical["core_storage"] = core_result["data"]
	var building_data: Dictionary = building_result["data"]
	canonical["buildings"] = building_data["buildings"]
	canonical["next_building_serial"] = building_data[
		"next_building_serial"
	]
	var combat_data: Dictionary = combat_result["data"]
	canonical["player_health"] = combat_data["player_health"]
	canonical["field_encounter"] = combat_data["field_encounter"]
	canonical["first_journey_flags"] = journey_result["data"]
	canonical["explored_map_bits"] = exploration_result["data"]
	return {"success": true, "message": "schema 9 存档有效。", "data": canonical}


func _validate_first_journey_flags(value) -> Dictionary:
	if not (value is Dictionary):
		return _failure("schema 9 first_journey_flags 必须是对象。")
	var flags: Dictionary = value
	if not _has_exact_keys(
		flags, ["part_recipe_inspected", "terminal_opened"]
	):
		return _failure("schema 9 first_journey_flags 字段集合无效。")
	for flag_name in ["terminal_opened", "part_recipe_inspected"]:
		if not (flags[flag_name] is bool):
			return _failure(
				"schema 9 first_journey_flags.%s 必须是布尔值。"
				% flag_name
			)
	if bool(flags["part_recipe_inspected"]) and not bool(flags["terminal_opened"]):
		return _failure("schema 9 配方已查看时终端必须已经打开。")
	return {
		"success": true,
		"data": {
			"terminal_opened": bool(flags["terminal_opened"]),
			"part_recipe_inspected": bool(flags["part_recipe_inspected"]),
		},
	}


func _validate_explored_map_bits(value) -> Dictionary:
	if not (value is String):
		return _failure("schema 9 explored_map_bits 必须是 Base64 字符串。")
	var encoded := String(value)
	if encoded.length() != SliceExplorationState.BASE64_LENGTH:
		return _failure("schema 9 explored_map_bits 长度无效。")
	var decoded := Marshalls.base64_to_raw(encoded)
	if (
		decoded.size() != SliceExplorationState.BYTE_COUNT
		or Marshalls.raw_to_base64(decoded) != encoded
	):
		return _failure("schema 9 explored_map_bits 编码无效。")
	return {"success": true, "data": encoded}


func _migrated_first_journey_flags(
	save_data: Dictionary,
	pocket: Dictionary,
	core_storage: Dictionary,
	player_position: Vector2
) -> Dictionary:
	var progressed := (
		bool(save_data.get("core_repaired", false))
		or int(save_data.get("core_energy", 0)) > 0
		or not canonical_string_array(save_data.get("harvested_clusters", [])).is_empty()
		or _inventory_item_count(pocket, SliceWorld.ITEM_CRYSTAL) > 0
		or _inventory_item_count(pocket, SliceWorld.ITEM_PART) > 0
		or _inventory_item_count(core_storage, SliceWorld.ITEM_CRYSTAL) > 0
		or _inventory_item_count(core_storage, SliceWorld.ITEM_PART) > 0
		or player_position.distance_to(SliceExplorationState.START_SPAWN) > 96.0
	)
	return {
		"terminal_opened": progressed,
		"part_recipe_inspected": progressed,
	}


func _canonical_inventory_input(
	value,
	profile: SliceInventoryProfile,
	label: String
) -> Dictionary:
	if not (value is Dictionary):
		return _failure("切片存档 %s 必须是对象。" % label)
	var contents = value.get("contents", {})
	if not (contents is Dictionary):
		return _failure("切片存档 %s.contents 必须是对象。" % label)
	return _validate_current_inventory(
		{"contents": contents.duplicate(true)}, profile, label
	)


func _validate_current_inventory(
	value,
	profile: SliceInventoryProfile,
	label: String
) -> Dictionary:
	if not (value is Dictionary):
		return _failure("schema 9 %s 必须是对象。" % label)
	var inventory: Dictionary = value
	if (
		inventory.keys().size() != 1
		or not inventory.has("contents")
	):
		return _failure(
			"schema 9 %s 必须且只能包含 contents。" % label
		)
	var contents = inventory["contents"]
	if not (contents is Dictionary):
		return _failure("schema 9 %s.contents 必须是对象。" % label)
	var canonical_contents := {}
	for item_id in contents:
		if not (item_id is String) or String(item_id).is_empty():
			return _failure(
				"schema 9 %s 包含无效物品 ID。" % label
			)
		var amount = contents[item_id]
		if not _is_integral_number(amount) or int(amount) <= 0:
			return _failure(
				"schema 9 %s 的物品数量必须是正整数。" % label
			)
		canonical_contents[String(item_id)] = int(amount)
	if not profile.accepts(canonical_contents):
		return _failure("schema 9 %s 超出容器 profile。" % label)
	return {
		"success": true,
		"message": "schema 9 库存有效。",
		"data": {"contents": canonical_contents},
	}


func _validate_load_context(value: Dictionary) -> Dictionary:
	var keys := [
		"migration_required", "publish_required", "source_game_version",
		"source_path", "source_schema_version", "source_sha256",
	]
	if not _has_exact_keys(value, keys):
		return _failure("载入上下文字段集合无效。")
	var source_path_value = value["source_path"]
	var source_sha_value = value["source_sha256"]
	var source_game_value = value["source_game_version"]
	if (
		not (source_path_value is String)
		or not (source_sha_value is String)
		or String(source_sha_value).is_empty()
		or not (source_game_value is String)
	):
		return _failure("载入上下文来源字段无效。")
	var source_path := String(source_path_value)
	var candidates: Array[String] = [_save_file]
	candidates.append_array(_save_backup_files)
	if not candidates.has(source_path):
		return _failure("载入上下文不属于当前存档服务。")
	var version_value = value["source_schema_version"]
	if (
		not _is_integral_number(version_value)
		or int(version_value) < MIN_SUPPORTED_SCHEMA_VERSION
		or int(version_value) > SAVE_SCHEMA_VERSION
	):
		return _failure("载入上下文版本无效。")
	if (
		not (value["migration_required"] is bool)
		or not (value["publish_required"] is bool)
	):
		return _failure("载入上下文发布标记无效。")
	var migration_required := int(version_value) < SAVE_SCHEMA_VERSION
	var publish_required := migration_required or source_path != _save_file
	if (
		bool(value["migration_required"]) != migration_required
		or bool(value["publish_required"]) != publish_required
	):
		return _failure("载入上下文发布标记不一致。")
	return {"success": true, "message": "载入上下文有效。", "data": value.duplicate(true)}


func _load_contexts_match(left: Dictionary, right: Dictionary) -> bool:
	return left == right


func _has_exact_keys(value: Dictionary, expected: Array) -> bool:
	if value.keys().size() != expected.size():
		return false
	for key in expected:
		if not value.has(key):
			return false
	return true


static func canonical_string_array(value) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(String(item))
	return result


## Frozen schema 2–7 normalization. It intentionally retains the old numeric
## capacity projection until the versioned migration strips it.
func _legacy_inventory_dict(value) -> Dictionary:
	var capacity := 0
	var contents := {}
	if value is Dictionary:
		capacity = int(value.get("capacity", 0))
		var raw = value.get("contents", {})
		if raw is Dictionary:
			for key in raw:
				var n := int(raw[key])
				if n > 0:
					contents[String(key)] = n
	return {"capacity": capacity, "contents": contents}


func _without_legacy_inventory_capacity(value: Dictionary) -> Dictionary:
	var contents = value.get("contents", {})
	return {
		"contents": (
			contents.duplicate(true) if contents is Dictionary else {}
		),
	}


func _restore_legacy_item(
	inventory: Dictionary,
	item_id: String,
	amount: int
) -> Dictionary:
	var restored := inventory.duplicate(true)
	if amount <= 0:
		return restored
	var contents: Dictionary = restored.get("contents", {})
	contents[item_id] = int(contents.get(item_id, 0)) + amount
	restored["contents"] = contents
	return restored


func _local_time_text() -> String:
	return Time.get_datetime_string_from_system(false, true)


func _success(message: String) -> Dictionary:
	return {"success": true, "message": message}


func _failure(message: String) -> Dictionary:
	return {"success": false, "message": message}
