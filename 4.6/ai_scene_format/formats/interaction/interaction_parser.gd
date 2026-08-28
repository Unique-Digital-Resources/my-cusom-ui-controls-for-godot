@tool
class_name AIInteractionParser
extends RefCounted

## V2 Interaction Parser.
## Consumes the V2 AST and returns an Array of Dictionaries matching the V1 metadata format.

func parse_interactions(interact_ast: AIParserBase.ASTNode) -> Array:
	var interactions = []
	if not interact_ast: return interactions
	
	# Group states by their target_path to match the V1 metadata structure
	var grouped: Dictionary = {}
	
	for child in interact_ast.children:
		if child.type == "call" and child.key in ["state", "trigger"]:
			var target_path = child.value[0] if child.value.size() > 0 else ""
			var event_name = child.value[1] if child.value.size() > 1 else "default"
			
			var condition = ""
			var actions = []
			
			for c in child.children:
				if c.type == "prop" and c.key == "condition":
					condition = c.value
				elif c.type == "block" and c.key == "action":
					for act in c.children:
						if act.type == "call":
							actions.append({"type": act.key, "data": act.value})
							
			var state_dict = {
				"name": event_name,
				"condition": condition,
				"actions": actions
			}
			
			if not grouped.has(target_path):
				grouped[target_path] = []
			grouped[target_path].append(state_dict)
			
	for target_path in grouped.keys():
		interactions.append({
			"target_id": target_path,
			"states": grouped[target_path]
		})
		
	return interactions
