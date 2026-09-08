extends Control

signal back_requested
signal world_ready(store: RefCounted, model: RefCounted, candidate: Dictionary)
const Store := preload("res://scripts/factory/save/store.gd")
var save_root := Store.DEFAULT_ROOT
var catalog: RefCounted
var worlds: Array[Dictionary] = []
var list := ItemList.new()
var title_input := LineEdit.new()
var notice := Label.new()
var create_button := Button.new()
var continue_button := Button.new()
var recover_button := Button.new()
var selected := -1


func _ready() -> void:
	catalog = Store.new(save_root)
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
	title_input.placeholder_text = "新工厂名称（最多 48 字）"
	title_input.max_length = 48
	layout.add_child(title_input)
	var row := HBoxContainer.new()
	layout.add_child(row)
	for spec in [[create_button, "创建并进入", _create], [continue_button, "继续选中世界", _continue],
		[recover_button, "恢复遗留锁", _recover], [Button.new(), "刷新", refresh],
		[Button.new(), "返回启动菜单", func(): back_requested.emit()]]:
		var button: Button = spec[0]
		button.text = spec[1]
		button.custom_minimum_size = Vector2(180, 48)
		button.pressed.connect(spec[2])
		row.add_child(button)
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
	recover_button.disabled = selected < 0 and not DirAccess.dir_exists_absolute(catalog.root.path_join("creation.lock"))
	notice.text = "创建空工厂，从第一条产线开始。旧二维世界保留在原入口。" if selected < 0 else worlds[selected].status


func _create() -> void:
	var store := Store.new(save_root)
	var result := store.create(title_input.text)
	if not result.ok:
		notice.text = result.reason
		return
	world_ready.emit(store, result.model, {})


func _continue() -> void:
	if selected < 0:
		return
	var store := Store.new(save_root)
	var result := store.prepare(worlds[selected].id)
	if not result.ok:
		notice.text = result.reason
		return
	world_ready.emit(store, result.model, result)


func _recover() -> void:
	var result: Dictionary = catalog.recover_creation_lock() if selected < 0 else catalog.recover_stale_lock(worlds[selected].id)
	refresh()
	notice.text = "已确认原进程退出，遗留锁已释放。请重新选择并继续世界。" if result.ok else result.reason
