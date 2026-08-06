class_name SliceBuildingActionPanel
extends CanvasLayer

## Unified operation panel for every placed building. Mouse buttons and numeric
## aliases share the same action methods; all mutations remain in SliceWorld.

const TONE_COLORS := {
	"ready": Color(0.035, 0.42, 0.4, 1.0),
	"working": Color(0.106, 0.38, 0.55, 1.0),
	"warning": Color(0.702, 0.392, 0.102, 1.0),
	"fault": Color(0.722, 0.18, 0.149, 1.0),
	"neutral": Color(0.24, 0.28, 0.28, 1.0),
}

var _world: Node
var _target: SliceBuildingInstance
var _open := false
var _confirming_demolition := false
var _result := ""
var _refresh_elapsed := 0.0
var _snapshot: Dictionary = {}
var _operation_buttons: Array[Button] = []

@onready var _root: Control = $Root
@onready var _device_icon: TextureRect = (
	$Root/Window/Margin/Layout/Body/Identity/IdentityCard/Margin/Layout/DeviceIcon
)
@onready var _category: Label = (
	$Root/Window/Margin/Layout/Body/Identity/IdentityCard/Margin/Layout/Category
)
@onready var _title: Label = (
	$Root/Window/Margin/Layout/Body/Identity/IdentityCard/Margin/Layout/Title
)
@onready var _instance: Label = (
	$Root/Window/Margin/Layout/Header/Margin/Row/Identity/Instance
)
@onready var _status_value: Label = (
	$Root/Window/Margin/Layout/Header/Margin/Row/Status/Value
)
@onready var _primary_title: Label = (
	$Root/Window/Margin/Layout/Body/Identity/Primary/Margin/Text/Title
)
@onready var _status_row: VBoxContainer = (
	$Root/Window/Margin/Layout/Body/Identity/StatusRow
)
@onready var _power_card: PanelContainer = (
	$Root/Window/Margin/Layout/Body/Identity/StatusRow/PowerCard
)
@onready var _port_1: PanelContainer = (
	$Root/Window/Margin/Layout/Body/Identity/StatusRow/Ports/Port1
)
@onready var _port_2: PanelContainer = (
	$Root/Window/Margin/Layout/Body/Identity/StatusRow/Ports/Port2
)
@onready var _content_title: Label = (
	$Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/Title
)
@onready var _slot_1: PanelContainer = (
	$Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/FlowRow/Slot1
)
@onready var _slot_2: PanelContainer = (
	$Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/FlowRow/Slot2
)
@onready var _flow_row: HBoxContainer = (
	$Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/FlowRow
)
@onready var _flow_arrow: Label = (
	$Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/FlowRow/FlowArrow
)
@onready var _process_box: VBoxContainer = (
	$Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/FlowRow/Process
)
@onready var _process_title: Label = (
	$Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/FlowRow/Process/Title
)
@onready var _process_progress: ProgressBar = (
	$Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/FlowRow/Process/Progress
)
@onready var _process_text: Label = (
	$Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/FlowRow/Process/ProgressText
)
@onready var _capacity_box: HBoxContainer = (
	$Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/Capacity
)
@onready var _capacity_progress: ProgressBar = (
	$Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/Capacity/Progress
)
@onready var _capacity_text: Label = (
	$Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/Capacity/Text
)
@onready var _details: Label = (
	$Root/Window/Margin/Layout/Body/Material/Content/Margin/Layout/DetailsPanel/Margin/Details
)
@onready var _operations_empty: Label = (
	$Root/Window/Margin/Layout/Body/Side/Operations/Margin/Layout/Empty
)
@onready var _adjust_button: Button = (
	$Root/Window/Margin/Layout/Body/Side/Maintenance/Margin/Layout/Buttons/Adjust
)
@onready var _demolish_button: Button = (
	$Root/Window/Margin/Layout/Body/Side/Maintenance/Margin/Layout/Buttons/Demolish
)
@onready var _maintenance_reason: Label = (
	$Root/Window/Margin/Layout/Body/Side/Maintenance/Margin/Layout/BlockReason
)
@onready var _demolition_confirm: HBoxContainer = (
	$Root/Window/Margin/Layout/Body/Side/Maintenance/Margin/Layout/Confirm
)
@onready var _result_panel: PanelContainer = (
	$Root/Window/Margin/Layout/Body/Side/Result
)
@onready var _result_text: Label = (
	$Root/Window/Margin/Layout/Body/Side/Result/Margin/Text
)


func _ready() -> void:
	var operations_path := (
		$Root/Window/Margin/Layout/Body/Side/Operations/Margin/Layout
	)
	_operation_buttons = [
		operations_path.get_node("Action1") as Button,
		operations_path.get_node("Action2") as Button,
		operations_path.get_node("Action3") as Button,
		operations_path.get_node("Action4") as Button,
	]
	for index in range(_operation_buttons.size()):
		_operation_buttons[index].pressed.connect(
			_on_operation_pressed.bind(index)
		)
	(
		$Root/Window/Margin/Layout/Header/Margin/Row/Close
		as Button
	).pressed.connect(close)
	_adjust_button.pressed.connect(_request_adjustment)
	_demolish_button.pressed.connect(_request_demolition)
	(
		$Root/Window/Margin/Layout/Body/Side/Maintenance/Margin/Layout/Confirm/ConfirmDemolish
		as Button
	).pressed.connect(_confirm_demolition)
	(
		$Root/Window/Margin/Layout/Body/Side/Maintenance/Margin/Layout/Confirm/CancelDemolish
		as Button
	).pressed.connect(_cancel_demolition)


func setup(world: Node) -> void:
	_world = world
	_world.building_storage_changed.connect(_on_building_storage_changed)
	_world.inventory_changed.connect(_on_inventory_changed)
	_root.visible = false


func open(instance: SliceBuildingInstance) -> void:
	if instance == null or instance.definition == null:
		return
	_target = instance
	_open = true
	_confirming_demolition = false
	_result = ""
	_refresh_elapsed = 0.0
	_root.visible = true
	_refresh()


func close() -> void:
	_target = null
	_open = false
	_confirming_demolition = false
	_result = ""
	_snapshot = {}
	_root.visible = false


func is_open() -> bool:
	return _open


func target_instance() -> SliceBuildingInstance:
	return _target


func current_snapshot() -> Dictionary:
	return _snapshot.duplicate(true)


func primary_status_text() -> String:
	return _primary_title.text


func action_button(action_id: String) -> Button:
	for button in _operation_buttons:
		if String(button.get_meta("action_id", "")) == action_id:
			return button
	return null


func port_state(index: int) -> String:
	var cards: Array[PanelContainer] = [_port_1, _port_2]
	if index < 0 or index >= cards.size():
		return ""
	return String(cards[index].get_meta("port_state", ""))


func _process(delta: float) -> void:
	if not _open:
		return
	if not is_instance_valid(_target):
		close()
		return
	if not (
		_target is SliceCollector
		or _target is SliceReactor
		or _target is SliceConveyor
	):
		return
	_refresh_elapsed += delta
	if _refresh_elapsed >= 0.15:
		_refresh_elapsed = 0.0
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not _open or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var handled := true
	match key_event.keycode:
		KEY_ESCAPE:
			close()
		KEY_1:
			_request_adjustment()
		KEY_2:
			if _confirming_demolition:
				_confirm_demolition()
			else:
				_request_demolition()
		KEY_3:
			_perform_hotkey_operation("3")
		KEY_4:
			_perform_hotkey_operation("4")
		KEY_5:
			_perform_hotkey_operation("5")
		KEY_6:
			_perform_hotkey_operation("6")
		_:
			handled = false
	if handled:
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	if (
		_target == null
		or not is_instance_valid(_target)
		or _target.definition == null
	):
		close()
		return
	_snapshot = SliceBuildingPanelSnapshot.build(_world, _target)
	if _snapshot.is_empty():
		close()
		return
	_update_header()
	_update_primary()
	_update_status_cards()
	_update_content()
	_update_operations()
	_update_maintenance()


func _update_header() -> void:
	_device_icon.texture = _snapshot.get("icon") as Texture2D
	_category.text = String(_snapshot["category"]).to_upper()
	_title.text = String(_snapshot["display_name"])
	_instance.text = "%s / INSTANCE · %s" % [
		String(_snapshot["display_name"]), _target.instance_id
	]
	var primary: Dictionary = _snapshot["primary"]
	_status_value.text = String(primary["title"])
	_status_value.add_theme_color_override(
		"font_color", _tone_color(String(primary["tone"]))
	)


func _update_primary() -> void:
	var primary: Dictionary = _snapshot["primary"]
	_primary_title.text = String(primary["title"])
	_primary_title.add_theme_color_override(
		"font_color", _tone_color(String(primary["tone"]))
	)


func _update_status_cards() -> void:
	var power: Dictionary = _snapshot["power"]
	_power_card.visible = not power.is_empty()
	if not power.is_empty():
		_set_status_card(
			_power_card,
			String(power["title"]),
			String(power["value"]),
			String(power["detail"]),
			String(power["tone"])
		)
	var ports: Array = _snapshot["ports"]
	var port_cards: Array[PanelContainer] = [_port_1, _port_2]
	for index in range(port_cards.size()):
		var card := port_cards[index]
		card.visible = index < ports.size()
		card.set_meta("port_state", "")
		if index >= ports.size():
			continue
		var port: Dictionary = ports[index]
		card.set_meta("port_state", String(port["state"]))
		_set_status_card(
			card,
			String(port["label"]),
			String(port["title"]),
			String(port["detail"]),
			String(port["tone"])
		)
	_status_row.visible = (
		_power_card.visible
		or _port_1.visible
		or _port_2.visible
	)


func _set_status_card(
	card: PanelContainer,
	title: String,
	value: String,
	detail: String,
	tone: String
) -> void:
	var text_box := card.get_node("Margin/Text")
	(text_box.get_node("Title") as Label).text = title
	var value_label := text_box.get_node("Value") as Label
	value_label.text = value
	value_label.add_theme_color_override(
		"font_color", _tone_color(tone)
	)
	(text_box.get_node("Detail") as Label).text = detail


func _update_content() -> void:
	_content_title.text = String(_snapshot["content_title"])
	_set_item_slot(_slot_1, _snapshot["slot_1"])
	_set_item_slot(_slot_2, _snapshot["slot_2"])
	_slot_1.visible = not (_snapshot["slot_1"] as Dictionary).is_empty()
	_slot_2.visible = not (_snapshot["slot_2"] as Dictionary).is_empty()
	var process: Dictionary = _snapshot["process"]
	_process_box.visible = not process.is_empty()
	_flow_arrow.visible = _slot_2.visible and _process_box.visible
	if not process.is_empty():
		_process_title.text = String(process["title"])
		_process_progress.max_value = maxf(
			0.001, float(process["maximum"])
		)
		_process_progress.value = float(process["value"])
		_process_text.text = String(process["text"])
	var capacity: Dictionary = _snapshot["capacity"]
	_capacity_box.visible = not capacity.is_empty()
	if not capacity.is_empty():
		_capacity_progress.max_value = maxf(
			0.001, float(capacity["maximum"])
		)
		_capacity_progress.value = float(capacity["value"])
		_capacity_text.text = String(capacity["text"])
	_flow_row.visible = (
		_slot_1.visible
		or _slot_2.visible
		or _process_box.visible
	)
	_details.text = String(_snapshot["details"])


func _set_item_slot(
	card: PanelContainer,
	data: Dictionary
) -> void:
	if data.is_empty():
		return
	var layout := card.get_node("Margin/Layout")
	(layout.get_node("Icon") as TextureRect).texture = (
		data.get("icon") as Texture2D
	)
	(layout.get_node("Label") as Label).text = String(data["label"])
	(layout.get_node("Count") as Label).text = "%d / %d" % [
		int(data["count"]),
		int(data["capacity"]),
	]


func _update_operations() -> void:
	var operations: Array = _snapshot["operations"]
	_operations_empty.visible = operations.is_empty()
	for index in range(_operation_buttons.size()):
		var button := _operation_buttons[index]
		button.visible = index < operations.size()
		button.set_meta("action_id", "")
		if index >= operations.size():
			continue
		var operation: Dictionary = operations[index]
		var enabled := bool(operation["enabled"])
		var reason := String(operation["reason"])
		button.set_meta("action_id", String(operation["id"]))
		button.disabled = not enabled
		button.text = "[%s] %s" % [
			String(operation["hotkey"]),
			String(operation["label"]),
		]
		if not enabled and not reason.is_empty():
			button.text += "\n%s" % reason
		button.tooltip_text = reason


func _update_maintenance() -> void:
	var maintenance: Dictionary = _snapshot["maintenance"]
	_adjust_button.disabled = not bool(
		maintenance["adjust_enabled"]
	)
	_adjust_button.tooltip_text = String(
		maintenance["adjust_reason"]
	)
	_demolish_button.disabled = not bool(
		maintenance["demolish_enabled"]
	)
	_demolish_button.tooltip_text = String(
		maintenance["demolish_reason"]
	)
	var maintenance_reasons: Array[String] = []
	if not String(maintenance["adjust_reason"]).is_empty():
		maintenance_reasons.append(
			"调整：%s" % String(maintenance["adjust_reason"])
		)
	if not String(maintenance["demolish_reason"]).is_empty():
		maintenance_reasons.append(
			"拆除：%s" % String(maintenance["demolish_reason"])
		)
	_maintenance_reason.visible = not maintenance_reasons.is_empty()
	_maintenance_reason.text = "\n".join(maintenance_reasons)
	_demolition_confirm.visible = _confirming_demolition
	_result_panel.visible = true
	_result_text.text = (
		_result if not _result.is_empty() else "设备状态已刷新"
	)


func _on_operation_pressed(index: int) -> void:
	if index < 0 or index >= _operation_buttons.size():
		return
	var action_id := String(
		_operation_buttons[index].get_meta("action_id", "")
	)
	if not action_id.is_empty():
		_perform_operation(action_id)


func _perform_hotkey_operation(hotkey: String) -> void:
	var operations: Array = _snapshot.get("operations", [])
	for operation_variant in operations:
		var operation: Dictionary = operation_variant
		if String(operation["hotkey"]) != hotkey:
			continue
		if not bool(operation["enabled"]):
			_result = String(operation["reason"])
			_refresh()
			return
		_perform_operation(String(operation["id"]))
		return


func _perform_operation(action_id: String) -> void:
	_confirming_demolition = false
	match action_id:
		"collect":
			var collector := _target as SliceCollector
			var buffer_before := collector.buffer
			_world.collect_from_collector(collector)
			var moved := buffer_before - collector.buffer
			_result = (
				"已取出晶体 %d" % moved
				if moved > 0
				else "没有可取出的晶体或背包已满"
			)
		"deposit_crystal":
			_result = _storage_transfer_result(
				_world.transfer_pocket_to_storage(
					_target as SliceStorage,
					SliceWorld.ITEM_CRYSTAL
				),
				"已存入晶体 %d",
				"没有可存入的晶体或储物箱已满"
			)
		"withdraw_crystal":
			_result = _storage_transfer_result(
				_world.transfer_storage_to_pocket(
					_target as SliceStorage,
					SliceWorld.ITEM_CRYSTAL
				),
				"已取出晶体 %d",
				"没有可取出的晶体或背包已满"
			)
		"deposit_catalyst":
			_result = _storage_transfer_result(
				_world.transfer_pocket_to_storage(
					_target as SliceStorage,
					SliceWorld.ITEM_CATALYST
				),
				"已存入催化剂 %d",
				"没有可存入的催化剂或储物箱已满"
			)
		"withdraw_catalyst":
			_result = _storage_transfer_result(
				_world.transfer_storage_to_pocket(
					_target as SliceStorage,
					SliceWorld.ITEM_CATALYST
				),
				"已取出催化剂 %d",
				"没有可取出的催化剂或背包已满"
			)
		"recover_reactor":
			var result: Dictionary = _world.recover_reactor_contents(
				_target as SliceReactor
			)
			_result = String(result.get("message", "回收失败"))
	_refresh()


func _storage_transfer_result(
	moved: int,
	success_pattern: String,
	failure: String
) -> String:
	return success_pattern % moved if moved > 0 else failure


func _request_adjustment() -> void:
	_confirming_demolition = false
	var reason: String = _world.adjustment_block_reason(_target)
	if not reason.is_empty():
		_result = reason
		_refresh()
	elif _world.begin_building_adjustment(_target):
		close()


func _request_demolition() -> void:
	var reason: String = _world.demolition_block_reason(_target)
	if not reason.is_empty():
		_confirming_demolition = false
		_result = reason
	else:
		_confirming_demolition = true
		_result = "拆除后返还 1 个设备套件；物料不会丢失。"
	_refresh()


func _confirm_demolition() -> void:
	if not _confirming_demolition:
		_request_demolition()
		return
	if _world.demolish_building(_target):
		close()
	else:
		_result = "拆除失败，设备状态可能已经变化"
		_confirming_demolition = false
		_refresh()


func _cancel_demolition() -> void:
	_confirming_demolition = false
	_result = ""
	_refresh()


func _tone_color(tone: String) -> Color:
	return TONE_COLORS.get(tone, TONE_COLORS["neutral"]) as Color


func _on_building_storage_changed(instance_id: String) -> void:
	if (
		_open
		and _target != null
		and _target.instance_id == instance_id
	):
		_refresh()


func _on_inventory_changed() -> void:
	if _open:
		_refresh()
