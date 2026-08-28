@tool
class_name AIInteractionImporter
extends RefCounted

class AIInteractionState:
	var name: String = "default"
	var condition: String = ""
	var property_overrides: Dictionary = {} 
	var animation_actions: Dictionary = {} # Now stores Dictionaries
	var tween_actions: Dictionary = {}     # Now stores Dictionaries

	func to_dict() -> Dictionary:
		return {
			"name": name,
			"condition": condition,
			"property_overrides": property_overrides,
			"animation_actions": animation_actions,
			"tween_actions": tween_actions
		}

	static func from_dict(d: Dictionary) -> AIInteractionState:
		var s = AIInteractionState.new()
		s.name = d.get("name", "default")
		s.condition = d.get("condition", "")
		s.property_overrides = d.get("property_overrides", {})
		s.animation_actions = d.get("animation_actions", {})
		s.tween_actions = d.get("tween_actions", {})
		return s

class AIInteraction:
	var name: String = "default"
	var target_id: String = ""
	var states: Array[AIInteractionState] = []

	func to_dict() -> Dictionary:
		var states_data = []
		for s in states:
			states_data.append(s.to_dict())
		return {
			"name": name,
			"target_id": target_id,
			"states": states_data
		}

	static func from_dict(d: Dictionary) -> AIInteraction:
		var i = AIInteraction.new()
		i.name = d.get("name", "default")
		i.target_id = d.get("target_id", "")
		for s_data in d.get("states", []):
			i.states.append(AIInteractionState.from_dict(s_data))
		return i

const META_KEY = "_ai_interactions_"

static func import_interactions(node: Node) -> Array[AIInteraction]:
	if not node or not node.has_meta(META_KEY):
		return []
		
	var data = node.get_meta(META_KEY)
	if not data is Array: return []
	
	var models: Array[AIInteraction] = []
	for d in data:
		models.append(AIInteraction.from_dict(d))
		
	return models
