@tool
class_name AISerializerBase
extends RefCounted

## Common serializer infrastructure.
## Converts internal Phase 2 models back into the textual format.

var indent_size: int = 4

func serialize_node(node: AINodeModel, level: int = 0) -> String:
	var indent = AIStringUtils.get_indent(level, indent_size)
	var header = "%s %s" % [node.type, node.name]
	var lines = [indent + header]
	
	for key in node.properties:
		var prop = node.properties[key] as AIPropertyModel
		if not prop.is_default:
			lines.append(_serialize_property(prop, level + 1))
			
	return "\n".join(lines)

func _serialize_property(prop: AIPropertyModel, level: int) -> String:
	var indent = AIStringUtils.get_indent(level, indent_size)
	
	if prop.is_resource and prop.resource:
		# FIX: Include resource type and ID in the header
		var header = "%s %s #%s" % [prop.name, prop.resource.type, prop.resource.id]
		var res_lines = [indent + header]
		for res_key in prop.resource.properties:
			var res_prop = prop.resource.properties[res_key] as AIPropertyModel
			if not res_prop.is_default:
				res_lines.append(_serialize_property(res_prop, level + 1))
		return "\n".join(res_lines)
		
	elif prop.is_reference and prop.reference:
		return "%s%s = %s" % [indent, prop.name, prop.reference._to_string()]
		
	else:
		return "%s%s = %s" % [indent, prop.name, AIStringUtils.format_value(prop.value)]

func _is_default_value(prop_name: String, value: Variant) -> bool:
	return false
