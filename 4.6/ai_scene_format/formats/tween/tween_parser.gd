@tool
class_name AITweenParser
extends RefCounted

## V2 Tween Parser.
## Consumes the V2 AST and returns an Array of Dictionaries matching the V1 metadata format.

func parse_tweens(tween_ast: AIParserBase.ASTNode) -> Array:
	var tweens = []
	if not tween_ast: return tweens
	
	for child in tween_ast.children:
		if child.type == "block" and child.key.begins_with("tween "):
			var tween = {}
			var parts = child.key.split(" ", true, 1)
			if parts.size() > 1:
				tween["name"] = parts[1].strip_edges().trim_prefix("\"").trim_suffix("\"")
			else:
				tween["name"] = "default"
				
			for c in child.children:
				if c.type == "prop":
					match c.key:
						"duration": tween["duration"] = float(c.value)
						"transition": tween["transition"] = _parse_trans(c.value)
						"ease": tween["ease"] = _parse_ease(c.value)
						"target": tween["target_id"] = c.value
						"property": tween["property"] = c.value
						# FIX: Assign directly, bool() constructor is invalid in GDScript
						"relative": tween["relative"] = c.value
						"loop": tween["loop"] = c.value
						"start_value": tween["start_value"] = c.value
						"final_value": tween["final_value"] = c.value
			tweens.append(tween)
			
	return tweens

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
