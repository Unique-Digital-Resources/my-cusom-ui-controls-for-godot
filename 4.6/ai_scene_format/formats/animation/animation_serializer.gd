@tool
class_name AIAnimationSerializer
extends AISerializerBase

## Generates Animation documents from an AIAnimationModel.

func serialize_animations(animations: Array) -> String:
	var lines = []
	for anim in animations:
		lines.append(_serialize_animation(anim, 0))
	return "\n".join(lines)

func _serialize_animation(anim, level: int) -> String:
	var indent = AIStringUtils.get_indent(level, indent_size)
	var loop_str = "true" if anim.loop else "false"
	var lines = [
		"%sanimation \"%s\"" % [indent, anim.name],
		"%slength = %s" % [AIStringUtils.get_indent(level + 1, indent_size), anim.length],
		"%sloop = %s" % [AIStringUtils.get_indent(level + 1, indent_size), loop_str]
	]
	
	for track in anim.tracks:
		lines.append(_serialize_track(track, level + 1))
		
	return "\n".join(lines)

func _serialize_track(track, level: int) -> String:
	var indent = AIStringUtils.get_indent(level, indent_size)
	var type_str = _get_track_type_string(track.type)
	var interp_str = _get_interp_string(track.interp)
	
	var lines = [
		"%strack \"%s\"" % [indent, track.path],
		"%stype = %s" % [AIStringUtils.get_indent(level + 1, indent_size), type_str],
		"%sinterp = %s" % [AIStringUtils.get_indent(level + 1, indent_size), interp_str]
	]
	
	for key in track.keyframes:
		lines.append(_serialize_keyframe(key, level + 1))
		
	return "\n".join(lines)

func _serialize_keyframe(key, level: int) -> String:
	var indent = AIStringUtils.get_indent(level, indent_size)
	var val_str = AIStringUtils.format_value(key.value)
	return "%skeyframe %.3f %s transition %.2f" % [indent, key.time, val_str, key.transition]

func _get_track_type_string(type: int) -> String:
	match type:
		Animation.TYPE_VALUE: return "VALUE"
		Animation.TYPE_POSITION_3D: return "POSITION_3D"
		Animation.TYPE_ROTATION_3D: return "ROTATION_3D"
		Animation.TYPE_SCALE_3D: return "SCALE_3D"
		Animation.TYPE_METHOD: return "METHOD"
		Animation.TYPE_BEZIER: return "BEZIER"
		_: return "UNKNOWN"

func _get_interp_string(interp: int) -> String:
	match interp:
		Animation.INTERPOLATION_NEAREST: return "NEAREST"
		Animation.INTERPOLATION_LINEAR: return "LINEAR"
		Animation.INTERPOLATION_CUBIC: return "CUBIC"
		_: return "LINEAR"
