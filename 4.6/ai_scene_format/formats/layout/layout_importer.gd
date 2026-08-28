@tool
class_name AILayoutImporter
extends RefCounted

## Converts a Godot scene subtree into an internal AISceneModel (Legacy V1).

static func import_subtree(root_node: Node) -> AISceneModel:
	var model = AISceneModel.new()
	if not root_node: return model
	_import_recursive(root_node, model, "")
	return model

static func _import_recursive(node: Node, model: AISceneModel, parent_id: String) -> void:
	var node_id = str(node.get_instance_id())
	var node_model = model.create_node(node.get_class(), node.name, parent_id, node_id)
	
	for p in node.get_property_list():
		var p_name = p.name
		if p.usage & PROPERTY_USAGE_STORAGE == 0: continue
		if p_name in ["script", "owner", "name", "scene_file_path"]: continue
		var val = node.get(p_name)
		# FIX: Just store the raw value, V1 default filtering is deprecated
		var prop_model = AIPropertyModel.new(p_name, val)
		node_model.add_property(prop_model)
		
	for child in node.get_children():
		_import_recursive(child, model, node_model.id)
