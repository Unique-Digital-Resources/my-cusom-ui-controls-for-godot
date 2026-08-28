@tool
class_name AIAnimationParser
extends RefCounted

## V2 Animation Parser.

class AIAnimKeyframe:
	var time: float
	var value: Variant
	var transition: int = Tween.TRANS_LINEAR
	var ease: int = Tween.EASE_IN_OUT

class AIAnimTrack:
	var path: String
	var type: int = Animation.TYPE_VALUE
	var interp: int = Animation.INTERPOLATION_LINEAR
	var keyframes: Array[AIAnimKeyframe] = []

class AIAnim:
	var name: String
	var length: float = 1.0
	var loop: bool = false
	var tracks: Array[AIAnimTrack] = []

func parse_animations(anim_ast: AIParserBase.ASTNode) -> Array[AIAnim]:
	var animations: Array[AIAnim] = []
	if not anim_ast: return animations
	for child in anim_ast.children:
		if child.type == "block" and child.key.begins_with("animation "):
			animations.append(_parse_animation(child))
	return animations

func _parse_animation(block: AIParserBase.ASTNode) -> AIAnim:
	var anim = AIAnim.new()
	var parts = block.key.split(" ", true, 1)
	if parts.size() > 1: anim.name = parts[1].strip_edges().trim_prefix("\"").trim_suffix("\"")
	for child in block.children:
		if child.type == "prop":
			if child.key == "length":
				anim.length = float(child.value)
			elif child.key == "loop":
				anim.loop = child.value
		elif child.type == "block" and child.key.begins_with("track "):
			anim.tracks.append(_parse_track(child))
	return anim

func _parse_track(block: AIParserBase.ASTNode) -> AIAnimTrack:
	var track = AIAnimTrack.new()
	var parts = block.key.split(" ", true, 1)
	if parts.size() > 1: track.path = parts[1].strip_edges().trim_prefix("\"").trim_suffix("\"")
	
	for child in block.children:
		if child.type == "prop":
			if child.key == "type":
				track.type = _parse_track_type(child.value)
			elif child.key == "interp":
				track.interp = _parse_interp(child.value)
			# FIX: Catch ANY other property as a keyframe to prevent missing keys
			else:
				track.keyframes.append(_parse_keyframe_prop(child))
		elif child.type == "block" and child.key.begins_with("keyframe "):
			track.keyframes.append(_parse_keyframe_block(child))
	return track

func _parse_keyframe_prop(ast: AIParserBase.ASTNode) -> AIAnimKeyframe:
	var key = AIAnimKeyframe.new()
	var parts = ast.key.split(" ", true, 1)
	if parts.size() > 1: key.time = float(parts[1].strip_edges())
	
	if ast.value is Dictionary and ast.value.has("value"):
		key.value = ast.value["value"]
		var ease_data = ast.value.get("ease")
		if ease_data and ease_data.has("curve"):
			key.transition = _parse_trans(ease_data["curve"])
			key.ease = _parse_ease(ease_data["dir"])
	else:
		key.value = ast.value
	return key

func _parse_keyframe_block(block: AIParserBase.ASTNode) -> AIAnimKeyframe:
	var key = AIAnimKeyframe.new()
	var parts = block.key.split(" ", true, 1)
	if parts.size() > 1: key.time = float(parts[1].strip_edges())
	for child in block.children:
		if child.type == "prop":
			if child.key == "value":
				key.value = child.value
			elif child.key == "ease":
				if child.value is Dictionary and child.value.has("__type__") and child.value["__type__"] == "ease":
					key.transition = _parse_trans(child.value.get("curve", "LINEAR"))
					key.ease = _parse_ease(child.value.get("dir", "IN"))
	return key

func _parse_track_type(s: String) -> int:
	match s:
		"VALUE": return Animation.TYPE_VALUE
		"POSITION_3D": return Animation.TYPE_POSITION_3D
		"ROTATION_3D": return Animation.TYPE_ROTATION_3D
		"SCALE_3D": return Animation.TYPE_SCALE_3D
		"METHOD": return Animation.TYPE_METHOD
		"BEZIER": return Animation.TYPE_BEZIER
		"AUDIO": return Animation.TYPE_AUDIO
	return Animation.TYPE_VALUE

func _parse_interp(s: String) -> int:
	match s:
		"NEAREST": return Animation.INTERPOLATION_NEAREST
		"LINEAR": return Animation.INTERPOLATION_LINEAR
		"CUBIC": return Animation.INTERPOLATION_CUBIC
	return Animation.INTERPOLATION_LINEAR

func _parse_trans(s: String) -> int:
	match s:
		"LINEAR": return Tween.TRANS_LINEAR
		"SINE": return Tween.TRANS_SINE
		"QUINT": return Tween.TRANS_QUINT
		"QUART": return Tween.TRANS_QUART
		"QUAD": return Tween.TRANS_QUAD
		"EXPO": return Tween.TRANS_EXPO
		"ELASTIC": return Tween.TRANS_ELASTIC
		"CUBIC": return Tween.TRANS_CUBIC
		"CIRC": return Tween.TRANS_CIRC
		"BOUNCE": return Tween.TRANS_BOUNCE
		"BACK": return Tween.TRANS_BACK
	return Tween.TRANS_LINEAR

func _parse_ease(s: String) -> int:
	match s:
		"IN": return Tween.EASE_IN
		"OUT": return Tween.EASE_OUT
		"IN_OUT": return Tween.EASE_IN_OUT
		"OUT_IN": return Tween.EASE_OUT_IN
	return Tween.EASE_IN_OUT
