@tool
class_name AIInteractionSerializer
extends AISerializerBase

func serialize_interactions(interactions: Array) -> String:
	var lines = []
	for interaction in interactions:
		lines.append(_serialize_interaction(interaction, 0))
	return "\n".join(lines)

func _serialize_interaction(interaction, level: int) -> String:
	var indent = AIStringUtils.get_indent(level, indent_size)
	var lines = [
		"%sinteraction \"%s\"" % [indent, interaction.name],
		"%starget = %s" % [AIStringUtils.get_indent(level + 1, indent_size), interaction.target_id]
	]
	
	for state in interaction.states:
		lines.append(_serialize_state(state, level + 1))
		
	return "\n".join(lines)

func _serialize_state(state, level: int) -> String:
	var indent = AIStringUtils.get_indent(level, indent_size)
	var lines = ["%sstate \"%s\"" % [indent, state.name]]
	
	var sub_indent = AIStringUtils.get_indent(level + 1, indent_size)
	
	if not state.condition.is_empty():
		lines.append("%scondition = \"%s\"" % [sub_indent, state.condition])
		
	for prop_name in state.property_overrides:
		var val_str = AIStringUtils.format_value(state.property_overrides[prop_name])
		lines.append("%sproperty %s" % [sub_indent, prop_name])
		lines.append("%svalue = %s" % [AIStringUtils.get_indent(level + 2, indent_size), val_str])
		
	for action in state.animation_actions:
		lines.append("%sanimation %s" % [sub_indent, action])
		var action_data = state.animation_actions[action]
		if action_data is Dictionary:
			lines.append("%starget = \"%s\"" % [AIStringUtils.get_indent(level + 2, indent_size), action_data.get("name", "")])
			if action_data.has("from_end"):
				lines.append("%sfrom_end = %s" % [AIStringUtils.get_indent(level + 2, indent_size), "true" if action_data["from_end"] else "false"])
			if action_data.has("reset"):
				lines.append("%sreset = %s" % [AIStringUtils.get_indent(level + 2, indent_size), "true" if action_data["reset"] else "false"])
		else:
			lines.append("%starget = \"%s\"" % [AIStringUtils.get_indent(level + 2, indent_size), action_data])
		
	for action in state.tween_actions:
		lines.append("%stween %s" % [sub_indent, action])
		var action_data = state.tween_actions[action]
		if action_data is Dictionary:
			lines.append("%starget = \"%s\"" % [AIStringUtils.get_indent(level + 2, indent_size), action_data.get("name", "")])
		else:
			lines.append("%starget = \"%s\"" % [AIStringUtils.get_indent(level + 2, indent_size), action_data])
		
	return "\n".join(lines)
