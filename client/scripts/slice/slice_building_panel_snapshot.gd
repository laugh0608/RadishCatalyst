class_name SliceBuildingPanelSnapshot
extends RefCounted

## Read-only presentation model for the placed-building operation panel.
## Device rules remain in their runtime classes and SliceWorld; this class only
## translates current state into stable, structured UI data.

static func build(
	world: Node,
	target: SliceBuildingInstance,
	selected_item_id: String = ""
) -> Dictionary:
	if world == null or target == null or target.definition == null:
		return {}
	var snapshot := _base_snapshot(world, target)
	if target is SliceCollector:
		_apply_collector(snapshot, world, target as SliceCollector)
	elif target is SliceStorage:
		_apply_storage(
			snapshot, world, target as SliceStorage, selected_item_id
		)
	elif target is SliceReactor:
		_apply_reactor(snapshot, world, target as SliceReactor)
	elif target is SliceConveyor:
		_apply_conveyor(snapshot, world, target as SliceConveyor)
	elif (
		target.definition.power_role
		== SliceBuildingDefinition.POWER_RELAY
	):
		_apply_relay(snapshot, world, target)
	else:
		_apply_floor(snapshot)
	return snapshot


static func _base_snapshot(
	world: Node,
	target: SliceBuildingInstance
) -> Dictionary:
	var definition := target.definition
	var adjust_reason: String = world.adjustment_block_reason(target)
	var demolish_reason: String = world.demolition_block_reason(target)
	return {
		"device_id": definition.building_id,
		"display_name": definition.display_name,
		"category": _category_name(definition),
		"icon": _device_icon(target),
		"primary": {
			"tone": "neutral",
			"title": "待命",
		},
		"power": _power_snapshot(target),
		"ports": world.building_logistics_status_snapshot(target),
		"content_title": "设备信息",
		"slot_1": {},
		"slot_2": {},
		"inventory_items": [],
		"selected_item_id": "",
		"process": {},
		"capacity": {},
		"details": "",
		"operations": [],
		"maintenance": {
			"adjust_enabled": adjust_reason.is_empty(),
			"adjust_reason": adjust_reason,
			"demolish_enabled": demolish_reason.is_empty(),
			"demolish_reason": demolish_reason,
		},
	}


static func _apply_collector(
	snapshot: Dictionary,
	world: Node,
	collector: SliceCollector
) -> void:
	var free_space: int = world.pocket.free_space_for(
		SliceWorld.ITEM_CRYSTAL
	)
	var primary := {
		"tone": "working",
		"title": "自动采集中",
	}
	if not collector.powered:
		primary = {
			"tone": "fault",
			"title": "设备断电",
		}
	elif collector.buffer >= SliceCollector.BUFFER_CAP:
		primary = {
			"tone": "warning",
			"title": "缓冲已满",
		}
	elif collector.buffer > 0:
		primary = {
			"tone": "ready",
			"title": "晶体可取",
		}
	snapshot["primary"] = primary
	snapshot["content_title"] = "产出缓冲"
	snapshot["slot_1"] = _item_slot(
		_item_name(SliceWorld.ITEM_CRYSTAL),
		collector.buffer,
		SliceCollector.BUFFER_CAP,
		_item_icon(SliceWorld.ITEM_CRYSTAL)
	)
	snapshot["process"] = {
		"title": "采集周期",
		"value": collector.production_progress,
		"maximum": SliceWorld.COLLECTOR_PRODUCE_INTERVAL,
		"text": "%.1f / %.1f 秒" % [
			collector.production_progress,
			SliceWorld.COLLECTOR_PRODUCE_INTERVAL,
		],
	}
	snapshot["capacity"] = {
		"value": collector.buffer,
		"maximum": SliceCollector.BUFFER_CAP,
		"text": "缓冲 %d / %d" % [
			collector.buffer,
			SliceCollector.BUFFER_CAP,
		],
	}
	snapshot["details"] = "通电后持续采集；缓冲装满时自动暂停。"
	snapshot["operations"] = [{
		"id": "collect",
		"label": "取出全部晶体",
		"hotkey": "3",
		"enabled": collector.buffer > 0 and free_space > 0,
		"reason": (
			"缓冲中没有晶体"
			if collector.buffer <= 0
			else "背包已满" if free_space <= 0 else ""
		),
	}]


static func _apply_storage(
	snapshot: Dictionary,
	world: Node,
	storage: SliceStorage,
	requested_item_id: String
) -> void:
	var inventory_items := _storage_inventory_items(world, storage)
	var selected_item_id := requested_item_id
	var selectable_ids: Array[String] = []
	for item in inventory_items:
		selectable_ids.append(String((item as Dictionary)["item_id"]))
	if not selectable_ids.has(selected_item_id):
		selected_item_id = (
			selectable_ids[0] if not selectable_ids.is_empty() else ""
		)
	var selected_name := (
		"未选择物品" if selected_item_id.is_empty()
		else _item_name_or_id(selected_item_id)
	)
	var pocket_count: int = world.pocket.count(selected_item_id)
	var storage_count := storage.inventory.count(selected_item_id)
	var storage_space := storage.inventory.free_space_for(selected_item_id)
	var pocket_space: int = world.pocket.free_space_for(selected_item_id)
	var known_ordinary := SliceItemCatalog.find(selected_item_id) != null
	var ports: Array = snapshot["ports"]
	var primary := {
		"tone": "ready",
		"title": storage.mode_display_name(),
	}
	if not storage.powered:
		primary = {
			"tone": "fault",
			"title": "设备断电",
		}
	elif storage.mode == SliceStorage.MODE_TRANSFER and not world.core_repaired:
		primary = {
			"tone": "warning",
			"title": "等待核心修复",
		}
	elif (
		storage.mode == SliceStorage.MODE_SUPPLY
		and (
			storage.output_item_id.is_empty()
			or storage.inventory.count(storage.output_item_id) <= 0
		)
	):
		primary = {
			"tone": "warning",
			"title": "供给筛选待补货",
		}
	elif not ports.is_empty():
		var port: Dictionary = ports[0]
		if String(port["state"]) == "wrong_direction":
			primary = {
				"tone": "fault",
				"title": "%s 方向错误" % String(port["label"]),
			}
		elif String(port["state"]) == "unconnected":
			primary = {
				"tone": "warning",
				"title": "%s 未连接" % String(port["label"]),
			}
	snapshot["primary"] = primary
	snapshot["content_title"] = "箱内物料 · 选择一类操作"
	snapshot["inventory_items"] = inventory_items
	snapshot["selected_item_id"] = selected_item_id
	var storage_profile := storage.inventory.profile()
	snapshot["capacity"] = {
		"value": storage.type_count(),
		"maximum": storage_profile.type_limit,
		"text": "物品类别 %d / %d" % [
			storage.type_count(),
			storage_profile.type_limit,
		],
	}
	var output_name := (
		"未选择"
		if storage.output_item_id.is_empty()
		else _item_name_or_id(storage.output_item_id)
	)
	snapshot["details"] = (
		"存储模式：右侧 OUT，通电后供给 %s；物流断链时手动存取仍可用。"
		% output_name
		if storage.mode == SliceStorage.MODE_SUPPLY
		else (
			"传输模式：左侧 IN 始终可接货；无线回传 %.1f / %.1f 秒，每次最多 %d 件，手动存取仍可用。"
			% [
				storage.transfer_progress,
				SliceStorage.TRANSFER_INTERVAL,
				SliceStorage.TRANSFER_BATCH_SIZE,
			]
		)
	)
	snapshot["operations"] = [
		_transfer_operation(
			"storage_deposit",
			"存入全部%s" % selected_name,
			"3",
			pocket_count if known_ordinary else 0,
			storage_space,
			(
				"请选择可存入的普通物品"
				if not known_ordinary
				else "背包中没有%s" % selected_name
			),
			"该类已达 %d 或储物箱已达 %d 类" % [
				storage_profile.item_capacity(selected_item_id),
				storage_profile.type_limit,
			]
		),
		_transfer_operation(
			"storage_withdraw",
			"取出全部%s" % selected_name,
			"4",
			storage_count,
			pocket_space,
			"箱内没有%s" % selected_name,
			"背包中该类已达 %d" % world.pocket.profile().item_capacity(
				selected_item_id
			)
		),
		{
			"id": "storage_toggle_mode",
			"label": "切换为%s" % (
				"传输模式"
				if storage.mode == SliceStorage.MODE_SUPPLY
				else "存储模式"
			),
			"hotkey": "5",
			"enabled": true,
			"reason": "",
		},
		{
			"id": "storage_cycle_output",
			"label": "切换供给筛选（当前：%s）" % output_name,
			"hotkey": "6",
			"enabled": not storage.present_transportable_ids().is_empty(),
			"reason": (
				"箱内没有可物流运输的物品"
				if storage.present_transportable_ids().is_empty()
				else ""
			),
		},
	]


static func _apply_reactor(
	snapshot: Dictionary,
	world: Node,
	reactor: SliceReactor
) -> void:
	var input_count := reactor.input_inventory.count(
		SliceReactor.INPUT_ITEM_ID
	)
	var output_count := reactor.output_inventory.count(
		SliceReactor.OUTPUT_ITEM_ID
	)
	var status: String = world.reactor_status_text(reactor)
	var primary := _reactor_primary(status)
	var recoverable_crystal := input_count
	if reactor.processing:
		recoverable_crystal += SliceReactor.INPUT_CAPACITY
	var recoverable := recoverable_crystal + output_count
	var recovery_batch := {}
	if recoverable_crystal > 0:
		recovery_batch[SliceWorld.ITEM_CRYSTAL] = recoverable_crystal
	if output_count > 0:
		recovery_batch[SliceWorld.ITEM_CATALYST] = output_count
	var can_recover: bool = (
		recoverable > 0
		and world.pocket.can_add_batch(recovery_batch)
	)
	snapshot["primary"] = primary
	snapshot["content_title"] = "反应流程"
	snapshot["slot_1"] = _item_slot(
		"IN · 2 %s" % _item_name(SliceWorld.ITEM_CRYSTAL),
		input_count,
		SliceReactor.INPUT_CAPACITY,
		_item_icon(SliceWorld.ITEM_CRYSTAL)
	)
	snapshot["slot_2"] = _item_slot(
		"OUT · 1 %s" % _item_name(SliceWorld.ITEM_CATALYST),
		output_count,
		SliceReactor.OUTPUT_CAPACITY,
		_item_icon(SliceWorld.ITEM_CATALYST)
	)
	snapshot["process"] = {
		"title": "加工 · 10 秒",
		"value": reactor.production_progress,
		"maximum": SliceReactor.PROCESS_DURATION,
		"text": "%.1f / %.1f 秒" % [
			reactor.production_progress,
			SliceReactor.PROCESS_DURATION,
		],
	}
	snapshot["details"] = (
		"IN 只接收晶体，OUT 只输出催化剂；断电会保留加工进度。"
	)
	snapshot["operations"] = [{
		"id": "recover_reactor",
		"label": "原子回收机内物料",
		"hotkey": "3",
		"enabled": can_recover,
		"reason": (
			"反应器内没有可回收物料"
			if recoverable <= 0
			else (
				"背包需要 %d 个空位" % recoverable
				if not can_recover
				else ""
			)
		),
	}]


static func _apply_conveyor(
	snapshot: Dictionary,
	world: Node,
	conveyor: SliceConveyor
) -> void:
	var direction_names := {
		Vector2i.UP: "上",
		Vector2i.RIGHT: "右",
		Vector2i.DOWN: "下",
		Vector2i.LEFT: "左",
	}
	var cargo_name := _item_name(conveyor.cargo_item_id)
	snapshot["primary"] = {
		"tone": "working" if conveyor.has_cargo() else "ready",
		"title": "正在输送" if conveyor.has_cargo() else "传送带空闲",
	}
	snapshot["content_title"] = "输送状态"
	snapshot["slot_1"] = (
		_item_slot(
			cargo_name,
			1,
			1,
			_item_icon(conveyor.cargo_item_id)
		)
		if conveyor.has_cargo()
		else _item_slot("空载", 0, 1, null)
	)
	snapshot["process"] = {
		"title": "朝 %s 输送" % direction_names[conveyor.output_direction()],
		"value": conveyor.cargo_progress,
		"maximum": 1.0,
		"text": (
			"%d%%" % roundi(conveyor.cargo_progress * 100.0)
			if conveyor.has_cargo()
			else "等待货物"
		),
	}
	snapshot["details"] = "按 R 调整时会切换固定像素方向帧。"
	if conveyor.has_cargo():
		var cargo_space: int = world.pocket.free_space_for(
			conveyor.cargo_item_id
		)
		snapshot["operations"] = [{
			"id": "recover_conveyor_cargo",
			"label": "回收带上货物",
			"hotkey": "3",
			"enabled": cargo_space > 0,
			"reason": "背包中该物品已达上限" if cargo_space <= 0 else "",
		}]


static func _apply_relay(
	snapshot: Dictionary,
	world: Node,
	target: SliceBuildingInstance
) -> void:
	var impact: int = world.relay_disconnect_impact_count(target)
	snapshot["primary"] = {
		"tone": "ready" if target.powered else "fault",
		"title": "供电中" if target.powered else "未接入核心电网",
	}
	snapshot["content_title"] = "供电影响"
	snapshot["details"] = (
		"调整或拆除预计会使 %d 台设备断电。" % impact
		if impact > 0
		else "当前没有设备依赖此中继供电。"
	)


static func _apply_floor(snapshot: Dictionary) -> void:
	snapshot["primary"] = {
		"tone": "ready",
		"title": "结构稳定",
	}
	snapshot["content_title"] = "地面支撑"
	snapshot["details"] = "调整或拆除前会检查上方设备，避免破坏现有基地。"


static func _reactor_primary(status: String) -> Dictionary:
	match status:
		"加工中":
			return {
				"tone": "working",
				"title": "反应进行中",
			}
		"待出料":
			return {
				"tone": "ready",
				"title": "催化剂待出料",
			}
		"出料堵塞":
			return {
				"tone": "fault",
				"title": "出料堵塞",
			}
		"缺晶体":
			return {
				"tone": "warning",
				"title": "输入不足",
			}
		"断电", "断电：加工暂停":
			return {
				"tone": "fault",
				"title": status,
			}
		"设备已失效":
			return {
				"tone": "fault",
				"title": status,
			}
		_:
			return {
				"tone": "ready",
				"title": "反应器就绪",
			}


static func _power_snapshot(target: SliceBuildingInstance) -> Dictionary:
	var role := target.definition.power_role
	if role == SliceBuildingDefinition.POWER_PASSIVE:
		return {}
	return {
		"tone": "ready" if target.powered else "fault",
		"title": "电力",
		"value": "在线" if target.powered else "断电",
		"detail": (
			"供电连接稳定"
			if target.powered
			else "未接入核心电网"
		),
	}


static func _transfer_operation(
	id: String,
	label: String,
	hotkey: String,
	source_count: int,
	target_space: int,
	empty_reason: String,
	full_reason: String
) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"hotkey": hotkey,
		"enabled": source_count > 0 and target_space > 0,
		"reason": (
			empty_reason
			if source_count <= 0
			else full_reason if target_space <= 0 else ""
		),
	}


static func _item_slot(
	label: String,
	count: int,
	capacity: int,
	icon: Texture2D
) -> Dictionary:
	return {
		"label": label,
		"count": count,
		"capacity": capacity,
		"icon": icon,
	}


static func _storage_inventory_items(
	world: Node,
	storage: SliceStorage
) -> Array[Dictionary]:
	var visible_ids := storage.inventory.contents_view()
	for item_id in world.pocket.item_ids():
		if SliceItemCatalog.is_known_ordinary(item_id):
			visible_ids[item_id] = 1
	var result: Array[Dictionary] = []
	for model_variant in SliceItemCatalog.read_model(visible_ids):
		var model: Dictionary = model_variant
		var item_id := String(model["item_id"])
		model["pocket_count"] = world.pocket.count(item_id)
		model["storage_count"] = storage.inventory.count(item_id)
		model["capacity"] = storage.inventory.profile().item_capacity(item_id)
		model["pocket_capacity"] = world.pocket.profile().item_capacity(item_id)
		model["icon"] = _item_icon(item_id)
		result.append(model)
	return result


static func _category_name(
	definition: SliceBuildingDefinition
) -> String:
	match definition.building_id:
		SliceBuildingCatalog.COLLECTOR_ID:
			return "采集设备"
		SliceBuildingCatalog.STORAGE_ID:
			return "仓储设备"
		SliceBuildingCatalog.REACTOR_ID:
			return "加工设备"
		SliceBuildingCatalog.POWER_RELAY_ID:
			return "电力设施"
		SliceBuildingCatalog.CONVEYOR_ID:
			return "物流设施"
		_:
			return "基地结构"


static func _device_icon(target: SliceBuildingInstance) -> Texture2D:
	var sprite := target.get_node_or_null("Sprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		return null
	var icon_region := target.definition.icon_region
	if not icon_region.has_area():
		return sprite.texture
	var atlas := AtlasTexture.new()
	atlas.atlas = sprite.texture
	atlas.region = icon_region
	return atlas


static func _item_name(item_id: String) -> String:
	var definition := SliceItemCatalog.find(item_id)
	return "空载" if definition == null else definition.short_name


static func _item_name_or_id(item_id: String) -> String:
	var definition := SliceItemCatalog.find(item_id)
	return item_id if definition == null else definition.short_name


static func _item_icon(item_id: String) -> Texture2D:
	var definition := SliceItemCatalog.find(item_id)
	if definition == null or definition.icon_path.is_empty():
		return null
	var texture := load(definition.icon_path) as Texture2D
	if definition.icon_region.has_area():
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = definition.icon_region
		return atlas
	return texture
