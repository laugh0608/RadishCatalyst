class_name SliceBuildingPanelSnapshot
extends RefCounted

## Read-only presentation model for the placed-building operation panel.
## Device rules remain in their runtime classes and SliceWorld; this class only
## translates current state into stable, structured UI data.

const CRYSTAL_ICON := preload("res://assets/sprites/slice/cargo_crystal.png")
const CATALYST_ICON := preload("res://assets/sprites/slice/cargo_catalyst.png")


static func build(
	world: Node,
	target: SliceBuildingInstance
) -> Dictionary:
	if world == null or target == null or target.definition == null:
		return {}
	var snapshot := _base_snapshot(world, target)
	if target is SliceCollector:
		_apply_collector(snapshot, world, target as SliceCollector)
	elif target is SliceStorage:
		_apply_storage(snapshot, world, target as SliceStorage)
	elif target is SliceReactor:
		_apply_reactor(snapshot, world, target as SliceReactor)
	elif target is SliceConveyor:
		_apply_conveyor(snapshot, target as SliceConveyor)
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
	var free_space: int = world.pocket.free_space()
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
		"晶体",
		collector.buffer,
		SliceCollector.BUFFER_CAP,
		CRYSTAL_ICON
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
	storage: SliceStorage
) -> void:
	var crystal_count := storage.inventory.count(SliceWorld.ITEM_CRYSTAL)
	var catalyst_count := storage.inventory.count(SliceWorld.ITEM_CATALYST)
	var storage_space := storage.inventory.free_space()
	var pocket_space: int = world.pocket.free_space()
	var ports: Array = snapshot["ports"]
	var primary := {
		"tone": "ready",
		"title": "仓储可用",
	}
	if not ports.is_empty():
		var port: Dictionary = ports[0]
		if String(port["state"]) == "wrong_direction":
			primary = {
				"tone": "fault",
				"title": "物流方向错误",
			}
		elif String(port["state"]) == "unconnected":
			primary = {
				"tone": "warning",
				"title": "物流口未连接",
			}
	snapshot["primary"] = primary
	snapshot["content_title"] = "箱内物料"
	snapshot["slot_1"] = _item_slot(
		"晶体", crystal_count, SliceStorage.CAPACITY, CRYSTAL_ICON
	)
	snapshot["slot_2"] = _item_slot(
		"催化剂", catalyst_count, SliceStorage.CAPACITY, CATALYST_ICON
	)
	snapshot["capacity"] = {
		"value": storage.inventory.total(),
		"maximum": SliceStorage.CAPACITY,
		"text": "总容量 %d / %d" % [
			storage.inventory.total(),
			SliceStorage.CAPACITY,
		],
	}
	snapshot["details"] = "单一 IO 口会根据传送带箭头自动成为 IN 或 OUT。"
	snapshot["operations"] = [
		_transfer_operation(
			"deposit_crystal",
			"存入全部晶体",
			"3",
			world.pocket.count(SliceWorld.ITEM_CRYSTAL),
			storage_space,
			"背包中没有晶体",
			"储物箱已满"
		),
		_transfer_operation(
			"withdraw_crystal",
			"取出全部晶体",
			"4",
			crystal_count,
			pocket_space,
			"箱内没有晶体",
			"背包已满"
		),
		_transfer_operation(
			"deposit_catalyst",
			"存入全部催化剂",
			"5",
			world.pocket.count(SliceWorld.ITEM_CATALYST),
			storage_space,
			"背包中没有催化剂",
			"储物箱已满"
		),
		_transfer_operation(
			"withdraw_catalyst",
			"取出全部催化剂",
			"6",
			catalyst_count,
			pocket_space,
			"箱内没有催化剂",
			"背包已满"
		),
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
	var recoverable := input_count + output_count
	if reactor.processing:
		recoverable += SliceReactor.INPUT_CAPACITY
	snapshot["primary"] = primary
	snapshot["content_title"] = "固定配方反应"
	snapshot["slot_1"] = _item_slot(
		"晶体",
		input_count,
		SliceReactor.INPUT_CAPACITY,
		CRYSTAL_ICON
	)
	snapshot["slot_2"] = _item_slot(
		"催化剂",
		output_count,
		SliceReactor.OUTPUT_CAPACITY,
		CATALYST_ICON
	)
	snapshot["process"] = {
		"title": "2 晶体  →  1 催化剂",
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
		"enabled": (
			recoverable > 0
			and world.pocket.free_space() >= recoverable
		),
		"reason": (
			"反应器内没有可回收物料"
			if recoverable <= 0
			else (
				"背包需要 %d 个空位" % recoverable
				if world.pocket.free_space() < recoverable
				else ""
			)
		),
	}]


static func _apply_conveyor(
	snapshot: Dictionary,
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
	return sprite.texture if sprite != null else null


static func _item_name(item_id: String) -> String:
	match item_id:
		SliceWorld.ITEM_CRYSTAL:
			return "晶体"
		SliceWorld.ITEM_CATALYST:
			return "催化剂"
		_:
			return "空载"


static func _item_icon(item_id: String) -> Texture2D:
	match item_id:
		SliceWorld.ITEM_CRYSTAL:
			return CRYSTAL_ICON
		SliceWorld.ITEM_CATALYST:
			return CATALYST_ICON
		_:
			return null
