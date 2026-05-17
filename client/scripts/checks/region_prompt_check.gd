extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	var formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
	var gate_world := WorldState.create_default()
	var gate_character := CharacterState.create_default()
	host._expect_text_contains(
		formatter.format_pollution_gate_hint(gate_world, gate_character),
		"处理点扩建",
		"pollution gate requires treatment point"
	)
	host._expect_text_contains(
		formatter.format_pollution_gate_hint(gate_world, gate_character),
		"启用基础过滤模块",
		"pollution gate requires module"
	)
	gate_character.protection = 30.0
	host._expect_text_contains(
		formatter.format_pollution_entry_warning(gate_character),
		"污染边界警告",
		"pollution entry warning title"
	)
	host._expect_text_contains(
		formatter.format_region_gate_blocked_log("污染边界尚未稳定。", "需要：先完成处理点扩建。"),
		"通行受阻：污染边界",
		"region gate blocked log title"
	)
	host._expect_text_contains(
		formatter.format_region_gate_blocked_log("污染边界尚未稳定。", "需要：先完成处理点扩建。"),
		"下一步：需要：先完成处理点扩建。",
		"region gate blocked next step"
	)
	var field_reading_interactable := PrototypeInteractable.new()
	field_reading_interactable.instance_id = "map_object_instance.phase_well_chamber_shunt_west"
	field_reading_interactable.definition_id = "map_object.phase_well_chamber_shunt_node"
	field_reading_interactable.interaction_type = "inspect"
	var field_reading_world := WorldState.create_default()
	field_reading_world.quest_state.active_quest_ids = ["quest.collect_heart_spine"]
	field_reading_world.quest_state.set_objective_progress(
		"quest.collect_heart_spine",
		"inspect",
		"map_object.phase_well_chamber_shunt_node",
		1
	)
	var field_reading_prompt := formatter.format_field_reading_prompt(field_reading_interactable, field_reading_world)
	host._expect_text_contains(field_reading_prompt, "当前进度 1/2", "field reading prompt shows partial progress")
	host._expect_text_contains(field_reading_prompt, "心棘残片", "field reading prompt explains unlocked collection line")
	var field_reading_system := GatherSystem.new(host.data_registry)
	var field_reading_result := field_reading_system.interact_with_object(
		field_reading_interactable.instance_id,
		field_reading_interactable.definition_id,
		field_reading_interactable.interaction_type,
		CharacterState.create_default(),
		field_reading_world
	)
	host._expect_text_contains(
		String(field_reading_result.get("message", "")),
		"两处分流读数已写入",
		"field reading result explains completion effect"
	)
	field_reading_interactable.free()
	var ash_blocker := PrototypeInteractable.new()
	ash_blocker.instance_id = "map_object_instance.well_ash_crust_north"
	ash_blocker.definition_id = "map_object.well_ash_crust_blocker"
	ash_blocker.interaction_type = "clear"
	var ash_prompt := formatter.format_clear_prompt(ash_blocker, CharacterState.create_default(), WorldState.create_default())
	host._expect_text_contains(ash_prompt, "井壁余烬", "well ash crust prompt points to ash collection")
	host._expect_text_contains(ash_prompt, "清理余烬壳", "well ash crust prompt uses special clear action")
	ash_blocker.free()
	var ruin_world := WorldState.create_default()
	host._expect_text_contains(formatter.format_ruin_gate_prompt(ruin_world), "先压制污染残核", "ruin gate blocked prompt")
	ruin_world.quest_state.completed_quest_ids.append("quest.enter_pollution_edge")
	ruin_world.quest_state.completed_quest_ids.append("quest.defeat_elite_node")
	host._expect_text_contains(formatter.format_ruin_gate_prompt(ruin_world), "按 E 确认", "ruin gate ready prompt")
	ruin_world.quest_state.completed_quest_ids.append("quest.unlock_ruin_signal")
	host._expect_text_contains(formatter.format_ruin_gate_prompt(ruin_world), "遗迹外圈已开放", "ruin gate completed prompt")
	var echo_world := WorldState.create_default()
	host._expect_text_contains(formatter.format_signal_echo_cache_prompt(echo_world), "先检查外圈中继台", "signal echo cache blocked prompt")
	echo_world.quest_state.completed_quest_ids.append("quest.secure_outer_ring_signal")
	host._expect_text_contains(formatter.format_signal_echo_cache_prompt(echo_world), "按 E 回收", "signal echo cache ready prompt")
	echo_world.quest_state.completed_quest_ids.append("quest.salvage_signal_echo")
	host._expect_text_contains(formatter.format_signal_echo_cache_prompt(echo_world), "已回收", "signal echo cache completed prompt")
	var deep_door_world := WorldState.create_default()
	var deep_door_character := CharacterState.create_default()
	host._expect_text_contains(formatter.format_deep_ruin_door_prompt(deep_door_world, deep_door_character), "先回基地解析深段回波", "deep ruin door blocked prompt")
	deep_door_world.quest_state.completed_quest_ids.append("quest.analyze_deep_signal")
	host._expect_text_contains(formatter.format_deep_ruin_door_prompt(deep_door_world, deep_door_character), "缺少更深遗迹坐标", "deep ruin door missing coordinates prompt")
	deep_door_character.inventory.add_item("item.deep_ruin_coordinates", 1)
	host._expect_text_contains(formatter.format_deep_ruin_door_prompt(deep_door_world, deep_door_character), "按 E 写入", "deep ruin door ready prompt")
	deep_door_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_entrance")
	host._expect_text_contains(formatter.format_deep_ruin_door_prompt(deep_door_world, deep_door_character), "已写入", "deep ruin door completed prompt")
	var deep_latch_world := WorldState.create_default()
	var deep_latch_character := CharacterState.create_default()
	host._expect_text_contains(formatter.format_deep_ruin_latch_prompt(deep_latch_world, deep_latch_character), "先回基地精炼相位纤丝", "deep ruin latch blocked prompt")
	deep_latch_world.quest_state.completed_quest_ids.append("quest.assemble_deep_override")
	host._expect_text_contains(formatter.format_deep_ruin_latch_prompt(deep_latch_world, deep_latch_character), "缺少深段覆写栓", "deep ruin latch missing key prompt")
	deep_latch_character.inventory.add_item("item.deep_override_key", 1)
	host._expect_text_contains(formatter.format_deep_ruin_latch_prompt(deep_latch_world, deep_latch_character), "按 E 覆写", "deep ruin latch ready prompt")
	deep_latch_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_cache")
	host._expect_text_contains(formatter.format_deep_ruin_latch_prompt(deep_latch_world, deep_latch_character), "已覆写", "deep ruin latch completed prompt")
	var deep_array_world := WorldState.create_default()
	var deep_array_character := CharacterState.create_default()
	host._expect_text_contains(formatter.format_deep_signal_array_prompt(deep_array_world, deep_array_character), "先回基地解析深段样块", "deep signal array blocked prompt")
	deep_array_world.quest_state.completed_quest_ids.append("quest.analyze_deep_core")
	host._expect_text_contains(formatter.format_deep_signal_array_prompt(deep_array_world, deep_array_character), "缺少深段路由印片", "deep signal array missing imprint prompt")
	deep_array_character.inventory.add_item("item.deep_route_imprint", 1)
	host._expect_text_contains(formatter.format_deep_signal_array_prompt(deep_array_world, deep_array_character), "按 E 写入", "deep signal array ready prompt")
	deep_array_world.quest_state.completed_quest_ids.append("quest.activate_deep_array")
	host._expect_text_contains(formatter.format_deep_signal_array_prompt(deep_array_world, deep_array_character), "已点亮", "deep signal array completed prompt")
	var outpost_prompt_world := WorldState.create_default()
	var outpost_prompt_character := CharacterState.create_default()
	host._expect_text_contains(formatter.format_outpost_core_prompt(outpost_prompt_world, outpost_prompt_character), "按 E 恢复", "outpost core restore prompt")
	outpost_prompt_world.quest_state.completed_quest_ids.append("quest.restore_outpost")
	host._expect_text_contains(formatter.format_outpost_core_prompt(outpost_prompt_world, outpost_prompt_character), "整备在线", "outpost core ready prompt at full vitals")
	outpost_prompt_character.health = 74.0
	outpost_prompt_character.protection = 56.0
	host._expect_text_contains(formatter.format_outpost_core_prompt(outpost_prompt_world, outpost_prompt_character), "按 E 整备", "outpost core refill prompt")
	var relay_anchor_world := WorldState.create_default()
	var relay_anchor_character := CharacterState.create_default()
	host._expect_text_contains(formatter.format_phase_return_anchor_prompt(relay_anchor_world, relay_anchor_character), "先回基地整理深段读数矩阵", "phase relay anchor blocked prompt")
	relay_anchor_world.quest_state.completed_quest_ids.append("quest.assemble_deep_signal_matrix")
	host._expect_text_contains(formatter.format_phase_return_anchor_prompt(relay_anchor_world, relay_anchor_character), "缺少深段读数矩阵", "phase relay anchor missing matrix prompt")
	relay_anchor_character.inventory.add_item("item.deep_signal_matrix", 1)
	host._expect_text_contains(formatter.format_phase_return_anchor_prompt(relay_anchor_world, relay_anchor_character), "按 E 部署", "phase relay anchor ready prompt")
	relay_anchor_world.quest_state.completed_quest_ids.append("quest.deploy_phase_relay_anchor")
	host._expect_text_contains(formatter.format_phase_return_anchor_prompt(relay_anchor_world, relay_anchor_character), "按 E 回传", "phase relay anchor completed prompt")
	relay_anchor_world.quest_state.active_quest_ids = ["quest.reenter_phase_frontline"]
	host._expect_text_contains(formatter.format_phase_return_anchor_prompt(relay_anchor_world, relay_anchor_character), "重返更东侧裂相脊", "phase relay anchor completed prompt points to reentry followup")
	var relay_pad_world := WorldState.create_default()
	host._expect_text_contains(formatter.format_phase_relay_pad_prompt(relay_pad_world), "先在深段部署前线回传锚点", "phase relay pad blocked prompt")
	relay_pad_world.quest_state.completed_quest_ids.append("quest.deploy_phase_relay_anchor")
	host._expect_text_contains(formatter.format_phase_relay_pad_prompt(relay_pad_world), "前线锚点当前离线", "phase relay pad offline prompt")
	relay_pad_world.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor")
	host._expect_text_contains(formatter.format_phase_relay_pad_prompt(relay_pad_world), "当前落点", "phase relay pad should make active anchor explicit")
	host._expect_text_contains(formatter.format_phase_relay_pad_prompt(relay_pad_world), "深段固定点", "phase relay pad ready prompt")
	relay_pad_world.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
	host._expect_text_contains(formatter.format_phase_relay_pad_prompt(relay_pad_world), "按 R 切换", "phase relay pad multi-anchor prompt")
	relay_pad_world.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_tether")
	host._expect_text_contains(formatter.format_phase_relay_pad_prompt(relay_pad_world), "井系桥前线", "phase relay pad tether anchor prompt")
	relay_pad_world.quest_state.active_quest_ids = ["quest.reenter_phase_frontline"]
	host._expect_text_contains(formatter.format_phase_relay_pad_prompt(relay_pad_world), "裂相碎屑", "phase relay pad reentry prompt points to deeper followup")
	var spire_world := WorldState.create_default()
	var spire_character := CharacterState.create_default()
	host._expect_text_contains(formatter.format_phase_fault_spire_prompt(spire_world, spire_character), "中继调谐镜整备", "phase fault spire blocked prompt")
	spire_world.quest_state.completed_quest_ids.append("quest.refine_phase_splinters")
	host._expect_text_contains(formatter.format_phase_fault_spire_prompt(spire_world, spire_character), "缺少中继调谐镜", "phase fault spire missing lens prompt")
	spire_character.inventory.add_item("item.relay_tuning_lens", 1)
	host._expect_text_contains(formatter.format_phase_fault_spire_prompt(spire_world, spire_character), "按 E 校准", "phase fault spire ready prompt")
	spire_world.quest_state.completed_quest_ids.append("quest.inspect_phase_fault_spire")
	host._expect_text_contains(formatter.format_phase_fault_spire_prompt(spire_world, spire_character), "已校准", "phase fault spire completed prompt")
	var phase_well_lock_world := WorldState.create_default()
	var phase_well_lock_character := CharacterState.create_default()
	host._expect_text_contains(formatter.format_phase_well_lock_prompt(phase_well_lock_world, phase_well_lock_character), "先回基地完成相位井钥整备", "phase well lock blocked prompt")
	phase_well_lock_world.quest_state.completed_quest_ids.append("quest.refine_fault_residue")
	host._expect_text_contains(formatter.format_phase_well_lock_prompt(phase_well_lock_world, phase_well_lock_character), "缺少相位井钥", "phase well lock missing key prompt")
	phase_well_lock_character.inventory.add_item("item.phase_well_key", 1)
	host._expect_text_contains(formatter.format_phase_well_lock_prompt(phase_well_lock_world, phase_well_lock_character), "按 E 锁定", "phase well lock ready prompt")
	phase_well_lock_world.quest_state.completed_quest_ids.append("quest.unlock_phase_well")
	host._expect_text_contains(formatter.format_phase_well_lock_prompt(phase_well_lock_world, phase_well_lock_character), "回基地解析定位器", "phase well lock completed prompt points to locator analysis")
	var inner_phase_well_world := WorldState.create_default()
	var inner_phase_well_character := CharacterState.create_default()
	host._expect_text_contains(formatter.format_inner_phase_well_prompt(inner_phase_well_world, inner_phase_well_character), "先回基地完成相位井探针整备", "inner phase well blocked prompt")
	inner_phase_well_world.quest_state.completed_quest_ids.append("quest.refine_well_flux")
	host._expect_text_contains(formatter.format_inner_phase_well_prompt(inner_phase_well_world, inner_phase_well_character), "缺少相位井探针", "inner phase well missing probe prompt")
	inner_phase_well_character.inventory.add_item("item.phase_well_probe", 1)
	host._expect_text_contains(formatter.format_inner_phase_well_prompt(inner_phase_well_world, inner_phase_well_character), "按 E 勘验", "inner phase well ready prompt")
	inner_phase_well_world.quest_state.completed_quest_ids.append("quest.inspect_inner_phase_well")
	host._expect_text_contains(formatter.format_inner_phase_well_prompt(inner_phase_well_world, inner_phase_well_character), "回基地解析", "inner phase well completed prompt")
	var phase_well_sink_world := WorldState.create_default()
	var phase_well_sink_character := CharacterState.create_default()
	host._expect_text_contains(formatter.format_phase_well_sink_prompt(phase_well_sink_world, phase_well_sink_character), "完成井底整备", "phase well sink blocked prompt")
	phase_well_sink_world.quest_state.completed_quest_ids.append("quest.refine_well_ash")
	host._expect_text_contains(formatter.format_phase_well_sink_prompt(phase_well_sink_world, phase_well_sink_character), "缺少井底穿钉", "phase well sink missing pike prompt")
	phase_well_sink_character.inventory.add_item("item.phase_well_pike", 1)
	host._expect_text_contains(formatter.format_phase_well_sink_prompt(phase_well_sink_world, phase_well_sink_character), "按 E 凿开", "phase well sink ready prompt")
	phase_well_sink_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_sink")
	host._expect_text_contains(formatter.format_phase_well_sink_prompt(phase_well_sink_world, phase_well_sink_character), "回基地解析并继续推进井心室断面", "phase well sink completed prompt")
	var phase_well_chamber_world := WorldState.create_default()
	var phase_well_chamber_character := CharacterState.create_default()
	host._expect_text_contains(formatter.format_phase_well_chamber_prompt(phase_well_chamber_world, phase_well_chamber_character), "完成井心整备", "phase well chamber blocked prompt")
	phase_well_chamber_world.quest_state.completed_quest_ids.append("quest.refine_heart_spine")
	host._expect_text_contains(formatter.format_phase_well_chamber_prompt(phase_well_chamber_world, phase_well_chamber_character), "缺少井心分流栓", "phase well chamber missing shunt prompt")
	phase_well_chamber_character.inventory.add_item("item.phase_well_shunt", 1)
	host._expect_text_contains(formatter.format_phase_well_chamber_prompt(phase_well_chamber_world, phase_well_chamber_character), "按 E 勘验", "phase well chamber ready prompt")
	phase_well_chamber_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_chamber")
	host._expect_text_contains(formatter.format_phase_well_chamber_prompt(phase_well_chamber_world, phase_well_chamber_character), "回基地解析并继续推进井纺室断面", "phase well chamber completed prompt")
	var phase_well_loom_world := WorldState.create_default()
	var phase_well_loom_character := CharacterState.create_default()
	host._expect_text_contains(formatter.format_phase_well_loom_prompt(phase_well_loom_world, phase_well_loom_character), "完成井纺整备", "phase well loom blocked prompt")
	phase_well_loom_world.quest_state.completed_quest_ids.append("quest.refine_weft_bundle")
	host._expect_text_contains(formatter.format_phase_well_loom_prompt(phase_well_loom_world, phase_well_loom_character), "缺少井纺梭栓", "phase well loom missing shuttle prompt")
	phase_well_loom_character.inventory.add_item("item.phase_well_shuttle", 1)
	host._expect_text_contains(formatter.format_phase_well_loom_prompt(phase_well_loom_world, phase_well_loom_character), "按 E 勘验", "phase well loom ready prompt")
	phase_well_loom_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_loom")
	host._expect_text_contains(formatter.format_phase_well_loom_prompt(phase_well_loom_world, phase_well_loom_character), "回基地解析并继续推进井纹架断面", "phase well loom completed prompt")
	var phase_well_frame_world := WorldState.create_default()
	var phase_well_frame_character := CharacterState.create_default()
	host._expect_text_contains(formatter.format_phase_well_frame_prompt(phase_well_frame_world, phase_well_frame_character), "完成井纹架整备", "phase well frame blocked prompt")
	phase_well_frame_world.quest_state.completed_quest_ids.append("quest.refine_selvedge_strip")
	host._expect_text_contains(formatter.format_phase_well_frame_prompt(phase_well_frame_world, phase_well_frame_character), "缺少井纹架键栓", "phase well frame missing key prompt")
	phase_well_frame_character.inventory.add_item("item.phase_well_frame_key", 1)
	host._expect_text_contains(formatter.format_phase_well_frame_prompt(phase_well_frame_world, phase_well_frame_character), "按 E 勘验", "phase well frame ready prompt")
	phase_well_frame_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_frame")
	host._expect_text_contains(formatter.format_phase_well_frame_prompt(phase_well_frame_world, phase_well_frame_character), "相位井结核已带回基地", "phase well frame completed prompt")
	host._expect_text_contains(formatter.format_phase_well_frame_prompt(phase_well_frame_world, phase_well_frame_character), "继续推进井系桥断面", "phase well frame completed prompt keeps tether followup explicit")
	var phase_well_tether_world := WorldState.create_default()
	var phase_well_tether_character := CharacterState.create_default()
	host._expect_text_contains(formatter.format_phase_well_tether_prompt(phase_well_tether_world, phase_well_tether_character), "完成井系整备", "phase well tether blocked prompt")
	phase_well_tether_world.quest_state.completed_quest_ids.append("quest.refine_tether_fiber")
	host._expect_text_contains(formatter.format_phase_well_tether_prompt(phase_well_tether_world, phase_well_tether_character), "缺少井系定桩", "phase well tether missing spike prompt")
	phase_well_tether_character.inventory.add_item("item.phase_well_tether_spike", 1)
	host._expect_text_contains(formatter.format_phase_well_tether_prompt(phase_well_tether_world, phase_well_tether_character), "按 E 勘验", "phase well tether ready prompt")
	phase_well_tether_world.quest_state.completed_quest_ids.append("quest.inspect_phase_well_tether")
	host._expect_text_contains(formatter.format_phase_well_tether_prompt(phase_well_tether_world, phase_well_tether_character), "相位井锚核已带回基地", "phase well tether completed prompt")
	host._expect_text_contains(formatter.format_phase_well_tether_prompt(phase_well_tether_world, phase_well_tether_character), "完成锚场整备", "phase well tether completed prompt keeps anchor-field followup explicit")
	var anchor_field_world := WorldState.create_default()
	var anchor_field_character := CharacterState.create_default()
	host._expect_text_contains(formatter.format_phase_well_anchor_field_prompt(anchor_field_world, anchor_field_character), "完成锚场整备", "anchor field blocked prompt")
	anchor_field_world.quest_state.completed_quest_ids.append("quest.refine_anchor_core_dust")
	host._expect_text_contains(formatter.format_phase_well_anchor_field_prompt(anchor_field_world, anchor_field_character), "缺少井系校锚桩", "anchor field missing stake prompt")
	anchor_field_character.inventory.add_item("item.phase_well_anchor_stake", 1)
	host._expect_text_contains(formatter.format_phase_well_anchor_field_prompt(anchor_field_world, anchor_field_character), "按 E 部署", "anchor field deploy prompt")
	anchor_field_world.ensure_map_object("map_object_instance.phase_well_anchor_field", "map_object.phase_well_anchor_field", "region.phase_well_tether")["anchor_field_deployed"] = true
	host._expect_text_contains(formatter.format_phase_well_anchor_field_prompt(anchor_field_world, anchor_field_character), "回稳中", "anchor field active prompt")
	host._expect_text_contains(formatter.format_phase_well_anchor_field_prompt(anchor_field_world, anchor_field_character), "失败后可直接重试", "anchor field active prompt keeps retry guidance explicit")
	anchor_field_world.get_map_object("map_object_instance.phase_well_anchor_field")["anchor_field_pressure_cleared"] = true
	host._expect_text_contains(formatter.format_phase_well_anchor_field_prompt(anchor_field_world, anchor_field_character), "按 E 收束", "anchor field ready prompt")
	anchor_field_world.quest_state.completed_quest_ids.append("quest.stabilize_phase_well_anchor_field")
	host._expect_text_contains(formatter.format_phase_well_anchor_field_prompt(anchor_field_world, anchor_field_character), "局部稳定窗口", "anchor field completed prompt")
