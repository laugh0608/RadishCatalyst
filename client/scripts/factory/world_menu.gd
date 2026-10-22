extends Control

signal back_requested
signal world_ready(store: RefCounted, model: RefCounted, candidate: Dictionary)
const Store := preload("res://scripts/factory/save/store.gd")
var save_root := Store.DEFAULT_ROOT
var engineering_context := false
var catalog: RefCounted
var worlds: Array[Dictionary] = []
var list := ItemList.new()
var title_input := LineEdit.new()
var notice := Label.new()
var create_button := Button.new()
var continue_button := Button.new()
var upgrade_button := Button.new()
var pending_schema := 0
var recover_button := Button.new()
var selected := -1
var world_type := OptionButton.new()
var upgrade_dialog := ConfirmationDialog.new()
var pending_upgrade := ""


func _ready() -> void:
	catalog = Store.new(save_root, engineering_context)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color("182d2c")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 80)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	var title := Label.new()
	title.text = "工厂世界 · 建设与继续"
	title.add_theme_font_size_override("font_size", 32)
	layout.add_child(title)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.item_selected.connect(func(index): selected = index; _selection())
	list.item_activated.connect(func(_index): _continue())
	layout.add_child(list)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(notice)
	world_type.add_item("基础工厂 · 原预供电规则")
	world_type.add_item("勘探工厂 · 分流汇合、范围供电与矿道开拓")
	layout.add_child(world_type)
	title_input.placeholder_text = "新工厂名称（最多 48 字）"
	title_input.max_length = 48
	layout.add_child(title_input)
	var row := HFlowContainer.new()
	layout.add_child(row)
	for spec in [[create_button, "创建并进入", _create], [continue_button, "继续选中世界", _continue],
		[upgrade_button, "升级选中世界", _ask_upgrade], [recover_button, "恢复遗留锁", _recover], [Button.new(), "刷新", refresh],
		[Button.new(), "返回启动菜单", func(): back_requested.emit()]]:
		var button: Button = spec[0]
		button.text = spec[1]
		button.custom_minimum_size = Vector2(180, 48)
		button.pressed.connect(spec[2])
		row.add_child(button)
	upgrade_dialog.title = "升级范围自动供电"
	upgrade_dialog.dialog_text = "这个世界使用旧手动接线规则。升级后，范围内的节点与设备会自动接电。\n设备、库存、在制和探索进度保留，升级前存档会另行备份。\n升级后的进度需要使用本版本继续。"
	upgrade_dialog.ok_button_text = "升级并继续"
	upgrade_dialog.cancel_button_text = "取消"
	upgrade_dialog.confirmed.connect(func(): _open_world(pending_upgrade, pending_schema))
	add_child(upgrade_dialog)
	refresh()


func refresh() -> void:
	worlds = catalog.list_worlds()
	list.clear()
	selected = -1
	for entry in worlds:
		list.add_item(entry.name + "   ·   " + entry.status)
	create_button.disabled = worlds.size() >= 30
	_selection()


func _selection() -> void:
	continue_button.disabled = selected < 0 or not worlds[selected].ok
	continue_button.text = "继续选中世界"
	upgrade_button.disabled = selected < 0 or not worlds[selected].ok or worlds[selected].get("schema", 0) not in [2, 3, 4]
	upgrade_button.text = _upgrade_title(int(worlds[selected].get("schema", 0))) if selected >= 0 else "升级选中世界"
	recover_button.disabled = selected < 0 and not DirAccess.dir_exists_absolute(catalog.root.path_join("creation.lock"))
	notice.text = "创建空工厂，从第一条产线开始。旧二维世界保留在原入口。" if selected < 0 else worlds[selected].status


func _create() -> void:
	var store := Store.new(save_root, engineering_context)
	var result := store.create(title_input.text, Store.Codec.V2.Config.ADMISSION_SUPPLY_ID if world_type.selected == 1 else Store.Codec.Rules.NORMAL_SUPPLY, world_type.selected == 1)
	if not result.ok:
		notice.text = result.reason
		return
	world_ready.emit(store, result.model, {})


func _continue() -> void:
	if selected < 0:
		return
	_open_world(worlds[selected].id)


func _ask_upgrade() -> void:
	if selected < 0 or worlds[selected].get("schema", 0) not in [2, 3, 4]:
		return
	pending_upgrade = worlds[selected].id
	pending_schema = int(worlds[selected].schema)
	upgrade_dialog.title = _upgrade_title(pending_schema)
	match pending_schema:
		4: upgrade_dialog.dialog_text = "增加 8 个物品准入口，可筛选物品、设置本轮总配额。原物流轮转与吞吐保持。\n设备、物料、在制、探索与统计保留；原 V4 存档会独立备份。\n也可取消后继续 V4。升级后的进度需要使用支持准入口的版本。"
		3: upgrade_dialog.dialog_text = "增加 8 个分流器、8 个汇合器。物流采用统一公平轮转，机器补带可能多等 50ms。\n设备、物料、在制及探索进度保留；升级前存档会独立备份。\n此次只升级分流与汇合，之后可另行选择准入口；也可取消后按原规则继续。"
		2: upgrade_dialog.dialog_text = "范围内节点和设备改为自动接电。设备、物料、在制与探索进度保留，原档会独立备份。\n此次只升级供电，之后可另行选择分流与汇合。也可取消后按原规则继续。"
	upgrade_dialog.popup_centered(Vector2i(650, 270))


func _upgrade_title(schema: int) -> String:
	return {2: "升级范围自动供电", 3: "升级分流与汇合", 4: "升级物品准入口"}.get(schema, "升级选中世界")


func _open_world(id: String, upgrade_schema := 0) -> void:
	var store := Store.new(save_root, engineering_context)
	var result := store.prepare(id)
	if result.ok and upgrade_schema != 0:
		match upgrade_schema:
			4: result = store.upgrade_admission(result)
			3: result = store.upgrade_routing(result)
			2: result = store.upgrade_automatic(result)
	if not result.ok:
		notice.text = result.reason
		store.release()
		return
	world_ready.emit(store, result.model, result)


func _recover() -> void:
	var result: Dictionary = catalog.recover_creation_lock() if selected < 0 else catalog.recover_stale_lock(worlds[selected].id)
	refresh()
	notice.text = "已确认原进程退出，遗留锁已释放。请重新选择并继续世界。" if result.ok else result.reason
