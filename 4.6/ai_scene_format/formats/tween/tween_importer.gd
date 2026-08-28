@tool
class_name AITweenImporter
extends RefCounted

class AITween:
	var name: String = "default"
	var duration: float = 1.0
	var transition: int = Tween.TRANS_LINEAR
	var ease: int = Tween.EASE_IN_OUT
	var target_id: String = ""
	var property: String = ""
	var start_value: Variant = null # NEW
	var final_value: Variant = null
	var relative: bool = false
	var loop: bool = false

	func to_dict() -> Dictionary:
		return {
			"name": name,
			"duration": duration,
			"transition": transition,
			"ease": ease,
			"target_id": target_id,
			"property": property,
			"start_value": start_value,
			"final_value": final_value,
			"relative": relative,
			"loop": loop
		}

	static func from_dict(d: Dictionary) -> AITween:
		var t = AITween.new()
		t.name = d.get("name", "default")
		t.duration = d.get("duration", 1.0)
		t.transition = d.get("transition", Tween.TRANS_LINEAR)
		t.ease = d.get("ease", Tween.EASE_IN_OUT)
		t.target_id = d.get("target_id", "")
		t.property = d.get("property", "")
		t.start_value = d.get("start_value", null)
		t.final_value = d.get("final_value", null)
		t.relative = d.get("relative", false)
		t.loop = d.get("loop", false)
		return t

const META_KEY = "_ai_tweens_"

static func import_tweens(node: Node) -> Array[AITween]:
	if not node or not node.has_meta(META_KEY):
		return []
		
	var tweens_data = node.get_meta(META_KEY)
	if not tweens_data is Array: return []
	
	var models: Array[AITween] = []
	for d in tweens_data:
		models.append(AITween.from_dict(d))
		
	return models
