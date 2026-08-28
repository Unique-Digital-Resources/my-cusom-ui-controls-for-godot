@tool
class_name AILayoutSerializer
extends AISerializerBase

## Generates Layout documents from an AISceneModel.

func serialize_subtree(model: AISceneModel, root_id: String) -> String:
	var root_node = model.get_node(root_id)
	if not root_node: return ""
	
	return _serialize_node_recursive(root_node, model, 0)

func _serialize_node_recursive(node: AINodeModel, model: AISceneModel, level: int) -> String:
	var indent = AIStringUtils.get_indent(level, indent_size)
	var header = "%s%s %s #%s" % [indent, node.type, node.name, node.id]
	var lines = [header]
	
	for key in node.properties:
		var prop = node.properties[key] as AIPropertyModel
		if not prop.is_default:
			lines.append(_serialize_property(prop, level + 1))
			
	for child_id in node.child_ids:
		var child = model.get_node(child_id)
		if child:
			lines.append(_serialize_node_recursive(child, model, level + 1))
			
	return "\n".join(lines)
