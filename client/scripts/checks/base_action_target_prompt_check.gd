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
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()

	var supply_marker := _create_interactable(
		"map_object_instance.steady_supply_drop_marker",
		"map_object.steady_supply_drop_marker",
		"inspect"
	)
	host._expect_text_contains(
		formatter.format_frontline_action_target_prompt(supply_marker, character_state, world_state),
		"按 E 读取补给回执",
		"steady supply target prompt exposes read action"
	)
	host._expect_text_contains(
		formatter.format_frontline_action_target_prompt(supply_marker, character_state, world_state),
		"回基地使用基础反应器解析稳场补给反馈",
		"steady supply target prompt points to base analysis"
	)

	var survey_west := _create_interactable(
		"map_object_instance.phase_survey_node_west",
		"map_object.phase_survey_node_west",
		"inspect"
	)
	host._expect_text_contains(
		formatter.format_frontline_action_target_prompt(survey_west, character_state, world_state),
		"当前进度 0/2",
		"phase survey target prompt shows two-node progress"
	)
	host._expect_text_contains(
		formatter.format_frontline_action_target_prompt(survey_west, character_state, world_state),
		"按 E 写入测绘读数",
		"phase survey target prompt exposes write action"
	)

	world_state.quest_state.set_objective_progress(
		"quest.inspect_phase_survey_nodes",
		"inspect",
		"map_object.phase_survey_node_west",
		1.0
	)
	var survey_east := _create_interactable(
		"map_object_instance.phase_survey_node_east",
		"map_object.phase_survey_node_east",
		"inspect"
	)
	host._expect_text_contains(
		formatter.format_frontline_action_target_prompt(survey_east, character_state, world_state),
		"当前进度 1/2",
		"phase survey target prompt keeps partial progress"
	)

	var pressure_node := _create_interactable(
		"map_object_instance.pressure_clearance_node",
		"map_object.pressure_clearance_node",
		"clear"
	)
	host._expect_text_contains(
		formatter.format_frontline_action_target_prompt(pressure_node, character_state, world_state),
		"按 E 清理压力扰点",
		"pressure clearance target prompt exposes clear action"
	)
	host._expect_text_contains(
		formatter.format_frontline_action_target_prompt(pressure_node, character_state, world_state),
		"回基地使用基础反应器解析压力清障反馈",
		"pressure clearance target prompt points to base analysis"
	)
	host._expect_text_missing(
		formatter.format_clear_prompt(pressure_node, character_state, world_state),
		"阻挡建造",
		"pressure clearance prompt should not fall back to build blocker wording"
	)

	var gather_system := GatherSystem.new(host.data_registry)
	host._expect_text_contains(
		String(gather_system.interact_with_object(
			supply_marker.instance_id,
			supply_marker.definition_id,
			supply_marker.interaction_type,
			character_state,
			world_state
		).get("message", "")),
		"回基地用基础反应器解析补给收益",
		"steady supply interaction result points to base analysis"
	)
	host._expect_text_contains(
		String(gather_system.interact_with_object(
			pressure_node.instance_id,
			pressure_node.definition_id,
			pressure_node.interaction_type,
			character_state,
			world_state
		).get("message", "")),
		"回基地用基础反应器解析防护收益",
		"pressure clearance interaction result points to base analysis"
	)

	supply_marker.free()
	survey_west.free()
	survey_east.free()
	pressure_node.free()


func _create_interactable(instance_id: String, definition_id: String, interaction_type: String) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.instance_id = instance_id
	interactable.definition_id = definition_id
	interactable.interaction_type = interaction_type
	return interactable
