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
		"清障扰动守卫也需要先击退",
		"pressure clearance target prompt mentions guard combat"
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
	_expect_inspect_persists_sampled(
		gather_system,
		"map_object_instance.stability_echo_probe",
		"map_object.stability_echo_probe",
		"stability echo probe"
	)
	_expect_inspect_persists_sampled(
		gather_system,
		"map_object_instance.supply_return_marker",
		"map_object.supply_return_marker",
		"supply return marker"
	)
	_expect_inspect_persists_sampled(
		gather_system,
		"map_object_instance.route_signal_marker",
		"map_object.route_signal_marker",
		"route signal marker"
	)
	_expect_inspect_persists_sampled(
		gather_system,
		"map_object_instance.steady_supply_drop_marker",
		"map_object.steady_supply_drop_marker",
		"steady supply drop marker"
	)
	_expect_inspect_persists_sampled(
		gather_system,
		"map_object_instance.phase_survey_node_west",
		"map_object.phase_survey_node_west",
		"phase survey west node"
	)
	_expect_inspect_persists_sampled(
		gather_system,
		"map_object_instance.phase_survey_node_east",
		"map_object.phase_survey_node_east",
		"phase survey east node"
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


func _expect_inspect_persists_sampled(
	gather_system: GatherSystem,
	instance_id: String,
	definition_id: String,
	label: String
) -> void:
	var world_state := WorldState.create_default()
	var result := gather_system.interact_with_object(
		instance_id,
		definition_id,
		"inspect",
		CharacterState.create_default(),
		world_state
	)
	host._expect_equal(bool(result.get("success", false)), true, "%s inspect succeeds" % label)
	host._expect_equal(
		bool(world_state.get_map_object(instance_id).get("is_sampled", false)),
		true,
		"%s inspect persists sampled state for refreshed map visual" % label
	)
