@tool
class_name AITweenSerializer
extends AISerializerBase

func serialize_tweens(tweens: Array) -> String:
	var lines = []
	for tween in tweens:
		lines.append(_serialize_tween(tween, 0))
	return "\n".join(lines)

func _serialize_tween(tween, level: int) -> String:
	var indent = AIStringUtils.get_indent(level, indent_size)
	var lines = [
		"%stween \"%s\"" % [indent, tween.name],
		"%sduration = %s" % [AIStringUtils.get_indent(level + 1, indent_size), tween.duration],
		"%stransition = %s" % [AIStringUtils.get_indent(level + 1, indent_size), _get_trans_string(tween.transition)],
		"%sease = %s" % [AIStringUtils.get_indent(level + 1, indent_size), _get_ease_string(tween.ease)],
		"%starget = %s" % [AIStringUtils.get_indent(level + 1, indent_size), tween.target_id],
		"%sproperty = %s" % [AIStringUtils.get_indent(level + 1, indent_size), tween.property],
		"%srelative = %s" % [AIStringUtils.get_indent(level + 1, indent_size), "true" if tween.relative else "false"],
		"%sloop = %s" % [AIStringUtils.get_indent(level + 1, indent_size), "true" if tween.loop else "false"]
	]
	
	if tween.start_value != null:
		lines.append("%sstart_value = %s" % [AIStringUtils.get_indent(level + 1, indent_size), AIStringUtils.format_value(tween.start_value)])
		
	lines.append("%sfinal_value = %s" % [AIStringUtils.get_indent(level + 1, indent_size), AIStringUtils.format_value(tween.final_value)])
	
	return "\n".join(lines)

func _get_trans_string(trans: int) -> String:
	match trans:
		Tween.TRANS_LINEAR: return "LINEAR"
		Tween.TRANS_SINE: return "SINE"
		Tween.TRANS_QUINT: return "QUINT"
		Tween.TRANS_QUART: return "QUART"
		Tween.TRANS_QUAD: return "QUAD"
		Tween.TRANS_EXPO: return "EXPO"
		Tween.TRANS_ELASTIC: return "ELASTIC"
		Tween.TRANS_CUBIC: return "CUBIC"
		Tween.TRANS_CIRC: return "CIRC"
		Tween.TRANS_BOUNCE: return "BOUNCE"
		Tween.TRANS_BACK: return "BACK"
		_: return "LINEAR"

func _get_ease_string(ease: int) -> String:
	match ease:
		Tween.EASE_IN: return "IN"
		Tween.EASE_OUT: return "OUT"
		Tween.EASE_IN_OUT: return "IN_OUT"
		Tween.EASE_OUT_IN: return "OUT_IN"
		_: return "IN_OUT"
