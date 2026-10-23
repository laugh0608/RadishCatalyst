extends RefCounted

const Codec := preload("res://scripts/factory/save/codec.gd")
const DEFAULT_ROOT := "user://saves/factory/worlds"
const MAX_BYTES := 4 * 1024 * 1024
const EnergyCopy := preload("res://scripts/factory/save/energy_copy.gd")
const Engineering := preload("res://data/factory/engineering_rules.gd")
var allow_engineering := false
var root: String
var world_id := ""
var world_name := ""
var sequence := 0
var token := ""
var expected_main_hash := ""
var session_identity: Array = []
var loaded := false
var last_warning := ""
## Optional deterministic IO fault hook used only by isolated checks.
var fault: Callable


func _init(save_root: String = DEFAULT_ROOT, engineering_context := false) -> void:
	root = ProjectSettings.globalize_path(save_root)
	allow_engineering = engineering_context and root != ProjectSettings.globalize_path(DEFAULT_ROOT)


func path(name: String = "") -> String:
	return root.path_join(world_id).path_join(name)


func _fail(stage: String) -> bool:
	return fault.is_valid() and bool(fault.call(stage))


func _error(message: String) -> Dictionary:
	return {"ok": false, "reason": message}


func _hash(file_path: String) -> String:
	return FileAccess.get_sha256(file_path) if FileAccess.file_exists(file_path) else ""


func _read(file_path: String, id: String) -> Dictionary:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return _error("无法读取 " + file_path.get_file())
	if file.get_length() > MAX_BYTES:
		return _error("存档超过允许大小。")
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(content) != OK:
		return _error("存档 JSON 损坏：" + json.get_error_message())
	var result := Codec.decode(json.data, id)
	if json.data is Dictionary:
		result.declared_identity = _identity(json.data)
		if Engineering.matches(json.data) and not allow_engineering:
			return Codec.failure("工程规模验证存档只能从隔离检查入口继续。", true)
	if json.data is Dictionary and Codec.integer(json.data.get("save_schema_version")):
		result.declared_schema = int(json.data.save_schema_version)
	if result.ok:
		result.source = file_path
		result.hash = content.sha256_text()
	return result


static func _identity(document: Dictionary) -> Array:
	return [int(document.get("save_schema_version", -1)) if Codec.integer(document.get("save_schema_version")) else -1, document.get("ruleset_id"), document.get("map_id"), document.get("supply_id")]


func list_worlds() -> Array[Dictionary]:
	var worlds: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(root):
		return worlds
	for id in DirAccess.get_directories_at(root):
		if not Codec.valid_id(id):
			continue
		var candidate := find_candidate(id)
		var entry := {"id": id, "name": id, "ok": candidate.ok, "status": ""}
		if candidate.ok:
			entry.name = candidate.document.name
			entry.schema = int(candidate.document.save_schema_version)
			entry.sequence = int(candidate.document.sequence)
			entry.hash = candidate.hash
			entry.title = candidate.document.name
			entry.name += " · 工程规模验证" if Engineering.matches(candidate.document) else " · 能源循环 E2" if entry.schema == 7 else " · 生产扩建 E1" if entry.schema == 6 else " · 物品准入工厂" if entry.schema == 5 else " · 分流与汇合工厂" if entry.schema == 4 else " · 范围供电工厂" if entry.schema == 3 else " · 勘探工厂（旧接线）" if entry.schema == 2 else " · 基础工厂"
			entry.status = "可继续" if candidate.source.ends_with("/autosave.json") else "可从备份恢复"
		else:
			entry.status = candidate.reason
		if DirAccess.dir_exists_absolute(root.path_join(id).path_join("session.lock")):
			entry.status += " · 写入锁"
		worlds.append(entry)
	worlds.sort_custom(func(a, b): return a.id < b.id)
	return worlds


func find_candidate(id: String) -> Dictionary:
	if not Codec.valid_id(id):
		return _error("世界 ID 无效。")
	var errors: Array[String] = []
	var newest_schema := 0
	var newest_identity: Array = []
	for name in ["autosave.json", "backups/autosave.bak.1.json", "backups/autosave.bak.2.json", "backups/autosave.bak.3.json"]:
		var result := _read(root.path_join(id).path_join(name), id)
		var identity: Array = result.get("declared_identity", [])
		var declared: int = result.get("declared_schema", 0)
		if declared > 0 and newest_identity.is_empty():
			newest_identity = identity
		if declared >= 5 and not newest_identity.is_empty() and identity != newest_identity:
			return Codec.failure("备份与主档的规则、地图或供给身份不同，原文件已保留。", true)
		newest_schema = maxi(newest_schema, declared)
		if result.ok and newest_schema >= 3 and result.document.save_schema_version < newest_schema:
			errors.append("跳过升级前的旧规则副本，避免回退规则。")
			continue
		if result.ok or result.get("unsupported", false):
			return result
		errors.append(result.reason)
	return _error("没有有效存档；原文件已保留。 " + " / ".join(errors))


func acquire(id: String) -> Dictionary:
	if not token.is_empty() or not Codec.valid_id(id):
		return _error("写入会话已打开或世界 ID 无效。")
	world_id = id
	if not DirAccess.dir_exists_absolute(path()):
		return _error("世界目录不存在。")
	if DirAccess.make_dir_absolute(path("session.lock")) != OK:
		return _error("此世界已有写入会话。关闭其他客户端；若异常退出，请使用“恢复遗留锁”。")
	token = Crypto.new().generate_random_bytes(16).hex_encode()
	var owner := {"pid": OS.get_process_id(), "token": token, "host": OS.get_unique_id()}
	var result := _write(path("session.lock/owner.json"), JSON.stringify(owner))
	if not result.ok:
		DirAccess.remove_absolute(path("session.lock"))
		token = ""
	return result


func _owns_lock() -> bool:
	if token.is_empty():
		return false
	var owner = _read_owner(path("session.lock/owner.json"))
	return owner is Dictionary and owner.get("token") == token and owner.get("pid") == OS.get_process_id()


func _read_owner(owner_path: String) -> Variant:
	var file := FileAccess.open(owner_path, FileAccess.READ)
	if file == null or file.get_length() > 4096:
		return null
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	return json.data if error == OK else null


func _owner_exited(pid: int) -> bool:
	if pid == OS.get_process_id():
		return false
	# Godot's is_process_running only accepts children spawned by this instance.
	# Capture stderr too: a failed/denied probe is unknown, never a dead owner.
	var output: Array = []
	if OS.get_name() in ["macOS", "Linux"]:
		var code := OS.execute("/bin/ps", ["-p", str(pid), "-o", "pid="], output, true)
		return code == 1 and "".join(output).strip_edges().is_empty()
	if OS.get_name() == "Windows":
		var command := "try { [System.Diagnostics.Process]::GetProcessById(%d).Id; exit 0 } catch [System.ArgumentException] { exit 3 } catch { exit 4 }" % pid
		return OS.execute("powershell.exe", ["-NoProfile", "-NonInteractive", "-Command", command], output, true) == 3
	return false


func release() -> Dictionary:
	if token.is_empty():
		return {"ok": true}
	if not _owns_lock():
		return _error("写入锁身份已变化，未清除其他会话的锁。")
	if DirAccess.remove_absolute(path("session.lock/owner.json")) != OK or DirAccess.remove_absolute(path("session.lock")) != OK:
		return _error("进度已保存，但写入锁释放失败。")
	token = ""
	loaded = false
	return {"ok": true}


func recover_stale_lock(id: String) -> Dictionary:
	if not Codec.valid_id(id):
		return _error("世界 ID 无效。")
	return _recover_lock(root.path_join(id).path_join("session.lock"))


func recover_creation_lock() -> Dictionary:
	return _recover_lock(root.path_join("creation.lock"))


func _recover_lock(lock_path: String) -> Dictionary:
	if DirAccess.make_dir_absolute(lock_path.path_join("recovery.guard")) != OK:
		return _error("锁恢复正在进行或锁目录不存在。")
	var owner = _read_owner(lock_path.path_join("owner.json"))
	var result := _error("无法确认锁所有者已退出；原锁已保留。")
	if owner is Dictionary and Codec.integer(owner.get("pid"), 1) and owner.get("host") == OS.get_unique_id():
		if _owner_exited(int(owner.pid)):
			if DirAccess.remove_absolute(lock_path.path_join("owner.json")) == OK:
				result = {"ok": true}
	DirAccess.remove_absolute(lock_path.path_join("recovery.guard"))
	if result.ok and DirAccess.remove_absolute(lock_path) != OK:
		return _error("遗留锁目录无法释放。")
	return result


func prepare(id: String) -> Dictionary:
	var lock_result := acquire(id)
	if not lock_result.ok:
		return lock_result
	var candidate := find_candidate(id)
	if not candidate.ok:
		release()
		return candidate
	expected_main_hash = _hash(path("autosave.json"))
	world_name = candidate.document.name
	sequence = int(candidate.document.sequence)
	session_identity = _identity(candidate.document)
	return candidate


## Stage a validated legacy candidate in memory; publish only after scene reconstruction.
func upgrade_automatic(candidate: Dictionary) -> Dictionary:
	if not _owns_lock() or not candidate.get("ok", false) or candidate.document.save_schema_version != 2:
		return _error("只有已锁定并校验的旧勘探世界可以升级。")
	Codec.V3.enable_automatic(candidate.model)
	candidate.upgrade_automatic = true
	return candidate


## Stage routing upgrade without modifying the source document or its hash.
func upgrade_routing(candidate: Dictionary) -> Dictionary:
	if not _owns_lock() or not candidate.get("ok", false) or candidate.document.save_schema_version != 3:
		return _error("只有已锁定并校验的范围供电世界可以升级物流。")
	var result := Codec.V4.upgrade(candidate.document)
	if not result.ok:
		return result
	candidate.model = result.model
	candidate.upgrade_routing = true
	return candidate


func upgrade_admission(candidate: Dictionary) -> Dictionary:
	if not _owns_lock() or not candidate.get("ok", false) or candidate.document.save_schema_version != 4:
		return _error("只有已锁定并校验的分流汇合世界可以升级准入口。")
	var result := Codec.V5.upgrade(candidate.document)
	if not result.ok: return result
	candidate.model = result.model
	candidate.upgrade_admission = true
	return candidate


## Called only after the candidate's model and view have been fully reconstructed.
func accept(candidate: Dictionary) -> Dictionary:
	if not _owns_lock() or _hash(candidate.source) != candidate.hash or _hash(path("autosave.json")) != expected_main_hash:
		return _error("存档来源在重建期间变化，已停止恢复。")
	if _fail("reconstruction"):
		return _error("候选重建失败。")
	loaded = true
	if candidate.get("upgrade_automatic", false) or candidate.get("upgrade_routing", false) or candidate.get("upgrade_admission", false):
		var retained := _retain_upgrade_source(candidate)
		if not retained.ok:
			loaded = false
			return retained
		var upgraded := save(candidate.model, candidate)
		if not upgraded.ok:
			loaded = false
			return upgraded
		upgraded["upgraded_admission" if candidate.get("upgrade_admission", false) else "upgraded_routing" if candidate.get("upgrade_routing", false) else "upgraded_automatic"] = true
		return upgraded
	if candidate.source != path("autosave.json"):
		var result := save(candidate.model, candidate)
		if not result.ok:
			loaded = false
			return result
		result.recovered_from = candidate.source
		return result
	return {"ok": true}


func _retain_upgrade_source(candidate: Dictionary) -> Dictionary:
	var prefix := "pre-admission-v4" if candidate.get("upgrade_admission", false) else "pre-routing-v3" if candidate.get("upgrade_routing", false) else "pre-auto-power-v2"
	var name := "backups/%s-%d-%s.json" % [prefix, int(candidate.document.sequence), candidate.hash.left(12)]
	if FileAccess.file_exists(path(name)):
		return {"ok": true} if _hash(path(name)) == candidate.hash else _error("升级前副本内容不一致，未覆盖。")
	if _fail("upgrade_backup") or DirAccess.make_dir_recursive_absolute(path("backups")) != OK:
		return _error("无法保留升级前进度，原世界未升级。")
	var result := _write(path(name + ".tmp"), FileAccess.get_file_as_string(candidate.source))
	if not result.ok or _hash(path(name + ".tmp")) != candidate.hash:
		return _error("升级前副本校验失败，原世界未升级。")
	if DirAccess.rename_absolute(path(name + ".tmp"), path(name)) != OK:
		return _error("升级前副本发布失败，原世界未升级。")
	return {"ok": true}


func create(title: String, supply: String = Codec.Rules.NORMAL_SUPPLY, automatic_power := false) -> Dictionary:
	if supply == Engineering.SUPPLY_ID and not allow_engineering:
		return Codec.failure("工程规模验证只能从隔离检查入口创建。", true)
	if automatic_power and supply not in [Codec.V2.Config.SUPPLY_ID, Codec.V2.Config.ROUTING_SUPPLY_ID, Codec.V2.Config.ADMISSION_SUPPLY_ID, Engineering.SUPPLY_ID, Codec.V6.Expansion.SUPPLY_ID, Codec.V7.Energy.SUPPLY_ID]:
		return _error("范围供电仅适用于勘探工厂。")
	if title.strip_edges().is_empty() or title.length() > 48 or "\n" in title:
		return _error("请输入 1–48 个字符的单行世界名称。")
	if DirAccess.make_dir_recursive_absolute(root) != OK:
		return _error("无法创建工厂存档目录。")
	return _creation_transaction(func(): return _create_locked(title.strip_edges(), supply, automatic_power))


func _creation_transaction(action: Callable) -> Dictionary:
	if DirAccess.make_dir_absolute(root.path_join("creation.lock")) != OK:
		return _error("其他客户端正在创建世界。若原程序异常退出，请取消选中世界后恢复遗留锁。")
	var owner_path := root.path_join("creation.lock/owner.json")
	var creation_token := Crypto.new().generate_random_bytes(16).hex_encode()
	var owner := {"pid": OS.get_process_id(), "token": creation_token, "host": OS.get_unique_id()}
	var ownership := _write(owner_path, JSON.stringify(owner))
	if not ownership.ok:
		DirAccess.remove_absolute(root.path_join("creation.lock"))
		return ownership
	var result: Dictionary = action.call()
	var current_owner = _read_owner(owner_path)
	if current_owner is Dictionary and current_owner.get("token") == creation_token:
		DirAccess.remove_absolute(owner_path)
		DirAccess.remove_absolute(root.path_join("creation.lock"))
	return result


func _create_locked(title: String, supply: String, automatic_power: bool) -> Dictionary:
	if list_worlds().size() >= 30:
		return _error("首包最多保留 30 个工厂世界。")
	if not Codec.Rules.SUPPLIES.has(supply) and supply not in [Codec.V2.Config.SUPPLY_ID, Codec.V2.Config.ROUTING_SUPPLY_ID, Codec.V2.Config.ADMISSION_SUPPLY_ID, Engineering.SUPPLY_ID, Codec.V6.Expansion.SUPPLY_ID, Codec.V7.Energy.SUPPLY_ID]:
		return _error("未知供给版本。")
	var id := Crypto.new().generate_random_bytes(16).hex_encode()
	if DirAccess.make_dir_absolute(root.path_join(id)) != OK:
		return _error("无法创建世界目录。")
	var result := acquire(id)
	if not result.ok:
		return result
	world_name = title
	sequence = 0
	session_identity = []
	expected_main_hash = ""
	loaded = true
	var model: RefCounted
	if supply == Codec.V7.Energy.SUPPLY_ID:
		model = Codec.V7.EnergyModel.new()
	elif supply == Codec.V6.Expansion.SUPPLY_ID:
		model = Codec.V6.ExpansionModel.new()
	elif supply == Engineering.SUPPLY_ID:
		model = Codec.V5.EngineeringModel.new()
	elif supply == Codec.V2.Config.ADMISSION_SUPPLY_ID:
		model = Codec.V5.AdmissionModel.new()
	elif supply == Codec.V2.Config.ROUTING_SUPPLY_ID:
		model = Codec.V4.RoutingModel.new()
	else:
		model = Codec.V2.NewModel.new(automatic_power) if supply == Codec.V2.Config.SUPPLY_ID else Codec.Model.new(supply)
	result = save(model)
	if not result.ok:
		release()
		return result
	result.model = model
	return result


func _write(file_path: String, content: String) -> Dictionary:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return _error("无法写入 " + file_path.get_file())
	file.store_string(content)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return _error("写入未完成：" + error_string(error))
	return {"ok": true}


func save(model: RefCounted, recovery: Dictionary = {}) -> Dictionary:
	if model.supply_id == Engineering.SUPPLY_ID and not allow_engineering:
		return Codec.failure("当前会话不允许写入工程身份。", true)
	if not loaded or not _owns_lock():
		return _error("当前世界没有可写会话。")
	if _hash(path("autosave.json")) != expected_main_hash:
		return _error("主档被外部修改，停止覆盖；当前进度仍在内存。")
	var document := Codec.snapshot(model, world_id, world_name, sequence + 1)
	if not session_identity.is_empty() and (Engineering.matches(document) or session_identity[3] == Engineering.SUPPLY_ID or document.supply_id in [Codec.V6.Expansion.SUPPLY_ID, Codec.V7.Energy.SUPPLY_ID] or session_identity[3] in [Codec.V6.Expansion.SUPPLY_ID, Codec.V7.Energy.SUPPLY_ID]) and _identity(document) != session_identity:
		return Codec.failure("不能转换普通、工程与内容世界身份；E1 到 E2 须显式复制。", true)
	var valid := Codec.decode(document, world_id)
	if _fail("validation") or not valid.ok:
		return _error("保存校验失败：" + valid.get("reason", "校验故障"))
	if _fail("temporary_write"):
		return _error("临时写入失败。")
	var serialized := JSON.stringify(document, "", true, true)
	var result := _write(path("autosave.tmp.json"), serialized)
	if not result.ok:
		return result
	var readback := _read(path("autosave.tmp.json"), world_id)
	if _fail("readback") or not readback.ok or readback.hash != serialized.sha256_text():
		return _error("临时档读回不一致，未发布主档。")
	if not recovery.is_empty() and _hash(recovery.source) != recovery.hash:
		return _error("恢复来源已变化，未发布主档。")
	if recovery.is_empty() and FileAccess.file_exists(path("autosave.json")):
		result = _backup_main()
		if not result.ok:
			return result
	if not _owns_lock() or _hash(path("autosave.json")) != expected_main_hash:
		return _error("发布前主档或锁身份变化。")
	if _fail("publish") or DirAccess.rename_absolute(path("autosave.tmp.json"), path("autosave.json")) != OK:
		return _error("主档发布失败，原主档及恢复副本已保留。")
	sequence += 1
	session_identity = _identity(document)
	expected_main_hash = _hash(path("autosave.json"))
	var summary := {"world_id": world_id, "name": world_name, "sequence": sequence, "time": model.time}
	var warning := ""
	if _fail("metadata") or not _write(path("metadata.tmp.json"), JSON.stringify(summary)).ok or DirAccess.rename_absolute(path("metadata.tmp.json"), path("metadata.json")) != OK:
		warning = "进度已保存；列表摘要更新失败，下次从主档重建。"
	last_warning = warning
	return {"ok": true, "warning": warning, "sequence": sequence}


func _backup_main() -> Dictionary:
	var current := _read(path("autosave.json"), world_id)
	if not current.ok:
		return _error("当前主档校验失败，停止轮换备份。")
	if _fail("backup") or DirAccess.make_dir_recursive_absolute(path("backups")) != OK:
		return _error("无法准备恢复副本。")
	# Stage a verified copy before touching backup slots. Main remains intact on failure.
	var result := _write(path("backups/pending.json"), FileAccess.get_file_as_string(path("autosave.json")))
	if not result.ok or _hash(path("backups/pending.json")) != expected_main_hash:
		return _error("恢复副本写入或读回失败。")
	for index in [2, 1]:
		var source := path("backups/autosave.bak.%d.json" % index)
		if FileAccess.file_exists(source):
			if DirAccess.copy_absolute(source, path("backups/autosave.bak.%d.json" % (index + 1))) != OK:
				return _error("备份轮换失败，主档保持不变。")
	if DirAccess.rename_absolute(path("backups/pending.json"), path("backups/autosave.bak.1.json")) != OK:
		return _error("恢复副本发布失败。")
	return {"ok": true}


func copy_energy(id: String, expected_sequence: int, expected_hash: String, title: String) -> Dictionary:
	if not token.is_empty(): return _error("当前已有写入会话，不能创建能源副本。")
	if not Codec.valid_id(id) or expected_sequence < 1 or expected_hash.length() != 64:
		return _error("请选择有效 E1 快照后复制。")
	if title.strip_edges().is_empty() or title.length() > 48 or "\n" in title:
		return _error("请输入 1–48 个字符的单行世界名称。")
	return _creation_transaction(func(): return EnergyCopy.create(self, id, expected_sequence, expected_hash, title.strip_edges()))
