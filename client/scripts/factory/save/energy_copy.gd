extends RefCounted

## Keep all unpublished output outside valid world IDs. Rename only a verified V7.
static func create(target: RefCounted, id: String, expected_sequence: int, expected_hash: String, title: String) -> Dictionary:
	if target.list_worlds().size() >= 30: return target._error("最多保留 30 个工厂世界。")
	var source: RefCounted = target.get_script().new(target.root)
	var candidate: Dictionary = source.prepare(id)
	if not candidate.ok: return candidate
	var result := _copy_locked(target, source, candidate, expected_sequence, expected_hash, title)
	var released: Dictionary = source.release()
	if not released.ok:
		if result.ok:
			result.warning = "能源副本已创建，但来源写入锁释放失败：" + released.reason
			target.last_warning = result.warning
		else:
			result.reason += "；" + released.reason
	return result


static func _copy_locked(target: RefCounted, source: RefCounted, candidate: Dictionary, expected_sequence: int, expected_hash: String, title: String) -> Dictionary:
	if candidate.document.save_schema_version != 6 or candidate.source != source.path("autosave.json"):
		return target._error("只能复制有效 E1 主档；旧版本、工程身份或需备份恢复的世界不能直接复制。")
	if candidate.document.sequence != expected_sequence or candidate.hash != expected_hash:
		return target._error("选中的 E1 快照已经变化，请刷新列表后重新确认。")
	var id: String = Crypto.new().generate_random_bytes(16).hex_encode()
	var decoded: Dictionary = target.Codec.V7.copy_from_e1(candidate.document, id, title, candidate.hash)
	if not decoded.ok: return decoded
	var staging_root: String = target.root.path_join(".energy-copy-" + id)
	if DirAccess.make_dir_recursive_absolute(staging_root.path_join(id)) != OK:
		return target._error("无法准备能源复制目录，来源保持不变。")
	var staging: RefCounted = target.get_script().new(staging_root)
	staging.fault = target.fault
	var acquired: Dictionary = staging.acquire(id)
	if not acquired.ok: return acquired
	staging.world_name = title
	staging.loaded = true
	var written: Dictionary = staging.save(decoded.model)
	if not written.ok:
		staging.release()
		return target._error(written.reason + "；未发布能源世界，诊断保留在 " + staging_root)
	if not source._owns_lock() or source._hash(candidate.source) != candidate.hash or target._fail("copy_source_changed"):
		staging.release()
		return target._error("复制期间来源或锁发生变化，未发布能源世界。")
	if target._fail("copy_publish") or DirAccess.rename_absolute(staging.path(), target.root.path_join(id)) != OK:
		staging.release()
		return target._error("能源副本发布失败，来源不变，完整诊断已保留。")
	# The live lock moves with the verified directory; there is no unlocked window.
	for key in ["world_id", "world_name", "sequence", "token", "expected_main_hash", "session_identity", "loaded", "last_warning"]:
		target.set(key, staging.get(key))
	staging.token = ""
	DirAccess.remove_absolute(staging_root)
	return {"ok": true, "model": decoded.model, "sequence": target.sequence, "warning": written.get("warning", "")}
