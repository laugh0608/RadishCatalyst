class_name SliceBuildingActionPanel
extends CanvasLayer

## Short operation panel for a placed building. Demolition requires pressing 2
## twice; rule failures remain visible and never remove or drop player property.

var _world: Node
var _target: SliceBuildingInstance
var _open := false
var _confirming_demolition := false
var _result := ""
var _refresh_elapsed := 0.0

@onready var _root: Control = $Root
@onready var _list: Label = $Root/Box/List


func setup(world: Node) -> void:
	_world = world
	_world.building_storage_changed.connect(_on_building_storage_changed)
	_root.visible = false


func open(instance: SliceBuildingInstance) -> void:
	if instance == null or instance.definition == null:
		return
	_target = instance
	_open = true
	_confirming_demolition = false
	_result = ""
	_root.visible = true
	_refresh()


func close() -> void:
	_target = null
	_open = false
	_confirming_demolition = false
	_result = ""
	_root.visible = false


func is_open() -> bool:
	return _open


func _process(delta: float) -> void:
	if not _open or not (_target is SliceReactor):
		return
	_refresh_elapsed += delta
	if _refresh_elapsed >= 0.1:
		_refresh_elapsed = 0.0
		_refresh()


func target_instance() -> SliceBuildingInstance:
	return _target


func _unhandled_input(event: InputEvent) -> void:
	if not _open or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_ESCAPE:
			close()
		KEY_1:
			_confirming_demolition = false
			var reason: String = _world.adjustment_block_reason(_target)
			if not reason.is_empty():
				_result = reason
				_refresh()
			elif _world.begin_building_adjustment(_target):
				close()
		KEY_2:
			var reason: String = _world.demolition_block_reason(_target)
			if not reason.is_empty():
				_confirming_demolition = false
				_result = reason
				_refresh()
			elif not _confirming_demolition:
				_confirming_demolition = true
				_result = "再次按 2 确认拆除并返还套件"
				_refresh()
			elif _world.demolish_building(_target):
				close()
		KEY_3:
			if _target is SliceStorage:
				_confirming_demolition = false
				var moved: int = _world.transfer_pocket_to_storage(
					_target as SliceStorage,
					SliceWorld.ITEM_CRYSTAL
				)
				_result = (
					"已存入晶体 %d" % moved
					if moved > 0
					else "没有可存入的晶体或储物箱已满"
				)
				_refresh()
			elif _target is SliceReactor:
				_confirming_demolition = false
				var result: Dictionary = _world.recover_reactor_contents(
					_target as SliceReactor
				)
				_result = String(result.get("message", "回收失败"))
				_refresh()
		KEY_4:
			if _target is SliceStorage:
				_confirming_demolition = false
				var moved: int = _world.transfer_storage_to_pocket(
					_target as SliceStorage,
					SliceWorld.ITEM_CRYSTAL
				)
				_result = (
					"已取出晶体 %d" % moved
					if moved > 0
					else "没有可取出的晶体或背包已满"
				)
				_refresh()
		KEY_5:
			if _target is SliceStorage:
				_confirming_demolition = false
				var moved: int = _world.transfer_pocket_to_storage(
					_target as SliceStorage,
					SliceWorld.ITEM_CATALYST
				)
				_result = (
					"已存入催化剂 %d" % moved
					if moved > 0
					else "没有可存入的催化剂或储物箱已满"
				)
				_refresh()
		KEY_6:
			if _target is SliceStorage:
				_confirming_demolition = false
				var moved: int = _world.transfer_storage_to_pocket(
					_target as SliceStorage,
					SliceWorld.ITEM_CATALYST
				)
				_result = (
					"已取出催化剂 %d" % moved
					if moved > 0
					else "没有可取出的催化剂或背包已满"
				)
				_refresh()
		_:
			return
	get_viewport().set_input_as_handled()


func _refresh() -> void:
	if _target == null or _target.definition == null:
		close()
		return
	var lines: Array[String] = [
		"【%s】  Esc 返回" % _target.definition.display_name,
		"[1] 调整位置",
		"[2] 拆除并返还 1 个套件",
	]
	if (
		_target.definition.power_role
		== SliceBuildingDefinition.POWER_RELAY
	):
		lines.append(
			"断开预计影响：%d 台设备" % (
				_world.relay_disconnect_impact_count(_target)
			)
		)
	if _target is SliceStorage:
		var storage := _target as SliceStorage
		lines.append(
			"晶体：%d｜催化剂：%d｜总容量：%d/%d" % [
				storage.inventory.count(SliceWorld.ITEM_CRYSTAL),
				storage.inventory.count(SliceWorld.ITEM_CATALYST),
				storage.inventory.total(),
				SliceStorage.CAPACITY,
			]
		)
		lines.append("[3] 存入背包全部晶体")
		lines.append("[4] 取出箱内全部晶体")
		lines.append("[5] 存入背包全部催化剂")
		lines.append("[6] 取出箱内全部催化剂")
	elif _target is SliceReactor:
		var reactor := _target as SliceReactor
		lines.append("状态：%s" % _world.reactor_status_text(reactor))
		lines.append(
			"输入晶体：%d/%d｜输出催化剂：%d/%d" % [
				reactor.input_inventory.count(SliceReactor.INPUT_ITEM_ID),
				SliceReactor.INPUT_CAPACITY,
				reactor.output_inventory.count(SliceReactor.OUTPUT_ITEM_ID),
				SliceReactor.OUTPUT_CAPACITY,
			]
		)
		lines.append(
			"加工进度：%.1f/%.1f 秒" % [
				reactor.production_progress,
				SliceReactor.PROCESS_DURATION,
			]
		)
		lines.append("[3] 原子回收全部机内物料")
	elif _target is SliceConveyor:
		var conveyor := _target as SliceConveyor
		lines.append(
			"带上货物：%s" % (
				"晶体"
				if conveyor.cargo_item_id == SliceWorld.ITEM_CRYSTAL
				else (
					"催化剂"
					if conveyor.cargo_item_id == SliceWorld.ITEM_CATALYST
					else "空"
				)
			)
		)
	if not _result.is_empty():
		lines.append("")
		lines.append(_result)
	_list.text = "\n".join(lines)


func _on_building_storage_changed(instance_id: String) -> void:
	if (
		_open
		and _target != null
		and _target.instance_id == instance_id
	):
		_refresh()
