@tool
class_name AIDiffEngine
extends RefCounted

## Computes minimal document/scene diffs.

class DiffCommand:
	var type: String # "create", "delete", "rename", "move", "property"
	var node_id: String
	var data: Dictionary
	func _init(t: String, id: String, d: Dictionary = {}):
		type = t; node_id = id; data = d

static func compute_diff(old_model: AISceneModel, new_model: AISceneModel) -> Array[DiffCommand]:
	var commands: Array[DiffCommand] = []
	
	var old_ids = old_model.nodes.keys()
	var new_ids = new_model.nodes.keys()
	
	# 1. Detect Deleted Nodes
	for id in old_ids:
		if not new_ids.has(id):
			commands.append(DiffCommand.new("delete", id))
			
	# 2. Detect Created Nodes
	for id in new_ids:
		if not old_ids.has(id):
				commands.append(DiffCommand.new("create", id))
			
	# 3. Detect Modified Nodes (Properties, Name, Parent)
	for id in new_ids:
		if old_ids.has(id):
			var old_node = old_model.get_node(id)
			var new_node = new_model.get_node(id)
			
			# Check Name
			if old_node.name != new_node.name:
				commands.append(DiffCommand.new("rename", id, { "new_name": new_node.name }))
				
			# Check Parent
			if old_node.parent_id != new_node.parent_id:
				commands.append(DiffCommand.new("move", id, { "new_parent_id": new_node.parent_id }))
				
			# Check Properties
			var old_props = old_node.properties
			var new_props = new_node.properties
			
			for prop_name in new_props:
				if not old_props.has(prop_name):
					commands.append(DiffCommand.new("property", id, { "prop": new_props[prop_name] }))
				else:
					var old_p = old_props[prop_name] as AIPropertyModel
					var new_p = new_props[prop_name] as AIPropertyModel
					
					# FIX: Force resources to update. Godot's diff ignores null vs null, 
					# so we must explicitly tell it to apply if it's a resource.
					if new_p.is_resource or old_p.value != new_p.value or old_p.is_default != new_p.is_default:
						commands.append(DiffCommand.new("property", id, { "prop": new_p }))
						
	return commands
