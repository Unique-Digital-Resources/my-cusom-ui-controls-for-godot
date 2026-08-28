@tool
class_name AIPropertyUtils
extends RefCounted

## Handles reflection, Variant conversion, recursive Resource traversal, 
## and strict default-value filtering using AIDefaultsRegistry.

static func apply_property_to_target(target: Object, prop_name: String, value: Variant) -> void:
	if not target: return
	
	# FIX: Handle loading external resources (textures, audio, fonts, etc.)
	if value is Dictionary and value.has("__type__") and value["__type__"] == "load":
		var res_path = value.get("path", "")
		if res_path.begins_with("res://"):
			var res = load(res_path)
			if res:
				target.set(prop_name, res)
				if target is CanvasItem: target.queue_redraw()
			else:
				push_warning("AI Scene Format: Failed to load resource at path: " + res_path)
		return

	# 1. Handle Resource Properties (Values that are Dictionaries from our parser)
	if value is Dictionary and value.has("__type__") and value["__type__"] == "call":
		var res_type = value.get("name", "")
		if ClassDB.class_exists(res_type) and ClassDB.is_parent_class(res_type, "Resource"):
			var new_res = _create_resource(res_type, value.get("args", []))
			target.set(prop_name, new_res)
			if target is CanvasItem: target.queue_redraw()
			return

	# 2. Handle Theme Overrides specifically (Godot 4 requirement)
	if prop_name.begins_with("theme_override_styles/"):
		var override_name = prop_name.trim_prefix("theme_override_styles/").strip_edges()
		if target is Control:
			if value is Dictionary and value.has("__type__") and value["__type__"] == "call":
				var sb = _create_resource(value.get("name", ""), value.get("args", []))
				if sb is StyleBox:
					target.add_theme_stylebox_override(override_name, sb)
					target.queue_redraw()
		return

	# 3. Handle standard properties
	var valid = false
	for p in target.get_property_list():
		if p.name == prop_name:
			valid = true
			break
			
	if prop_name.begins_with("metadata/") or prop_name in ["offset_left", "offset_right", "offset_top", "offset_bottom", "layout_mode", "anchors_preset"]:
		valid = true
		
	if valid:
		target.set(prop_name, value)
		if target is CanvasItem: target.queue_redraw()

static func _create_resource(res_type: String, args: Array) -> Resource:
	if not ClassDB.class_exists(res_type): return null
	if not ClassDB.is_parent_class(res_type, "Resource"): return null
	return ClassDB.instantiate(res_type)

# --- Default Filtering Logic ---

static func is_property_default(target: Object, prop_name: String, value: Variant) -> bool:
	return AIDefaultsRegistry.is_default(target, prop_name, value)
