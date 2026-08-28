@tool
class_name AIStringUtils
extends RefCounted

## Shared string helpers for parsing and serialization.

static func parse_value(raw: String) -> Variant:
	raw = raw.strip_edges()
	
	if raw == "true": return true
	if raw == "false": return false
	
	if raw.to_lower() == "null" or raw.to_lower() == "nil": return null
	
	if raw.is_valid_int(): return raw.to_int()
	if raw.is_valid_float(): return raw.to_float()
	
	if raw.begins_with("Vector2(") and raw.ends_with(")"):
		var inner = raw.trim_prefix("Vector2(").trim_suffix(")")
		var parts = inner.split(",")
		if parts.size() == 2:
			return Vector2(float(parts[0].strip_edges()), float(parts[1].strip_edges()))
			
	if raw.begins_with("Vector3(") and raw.ends_with(")"):
		var inner = raw.trim_prefix("Vector3(").trim_suffix(")")
		var parts = inner.split(",")
		if parts.size() == 3:
			return Vector3(float(parts[0].strip_edges()), float(parts[1].strip_edges()), float(parts[2].strip_edges()))
			
	if raw.begins_with("Color(") and raw.ends_with(")"):
		var inner = raw.trim_prefix("Color(").trim_suffix(")")
		var parts = inner.split(",")
		if parts.size() >= 3:
			var r = float(parts[0].strip_edges())
			var g = float(parts[1].strip_edges())
			var b = float(parts[2].strip_edges())
			var a = 1.0 if parts.size() < 4 else float(parts[3].strip_edges())
			return Color(r, g, b, a)
			
	if raw.begins_with("NodePath(\"") and raw.ends_with("\")"):
		return NodePath(raw.trim_prefix("NodePath(\"").trim_suffix("\")"))
		
	if raw.begins_with("\"") and raw.ends_with("\"") and raw.length() >= 2:
		var str_val = raw.substr(1, raw.length() - 2)
		# FIX: Unescape newlines and tabs
		str_val = str_val.replace("\\n", "\n").replace("\\t", "\t")
		return str_val
		
	return raw

static func format_value(value: Variant) -> String:
	match typeof(value):
		TYPE_BOOL: return "true" if value else "false"
		TYPE_INT, TYPE_FLOAT: return str(value)
		TYPE_STRING:
			var escaped = value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\t", "\\t")
			return "\"%s\"" % escaped
		TYPE_NIL: return "null"
		TYPE_VECTOR2: return "Vector2(%s, %s)" % [value.x, value.y]
		TYPE_VECTOR3: return "Vector3(%s, %s, %s)" % [value.x, value.y, value.z]
		TYPE_COLOR: return "Color(%s, %s, %s, %s)" % [value.r, value.g, value.b, value.a]
		TYPE_NODE_PATH: return "NodePath(\"%s\")" % value
		TYPE_RECT2: return "Rect2(%s, %s, %s, %s)" % [value.position.x, value.position.y, value.size.x, value.size.y]
		TYPE_OBJECT, TYPE_CALLABLE, TYPE_SIGNAL: return "null"
		_: return "null"

static func get_indent(level: int, size: int = 4) -> String:
	return " ".repeat(level * size)
