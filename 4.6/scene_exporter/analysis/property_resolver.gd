class_name PropertyResolver
extends RefCounted

# Reads exported properties from Godot nodes

const TARGET_PROPERTIES: Array[String] = [
	"position", "size", "anchors_preset", 
	"offset_left", "offset_top", "offset_right", "offset_bottom",
	"rotation", "scale", "pivot_offset", 
	"modulate", "visible", "z_index", "z_as_relative",
	"clip_contents", "mouse_filter", 
	"grow_horizontal", "grow_vertical", 
	"custom_minimum_size", "layout_mode",
	"size_flags_horizontal", "size_flags_vertical",
	"theme_override_colors", "theme_override_constants", 
	"theme_override_fonts", "theme_override_font_sizes", "theme_override_styles",
	"text", "horizontal_alignment", "vertical_alignment",
	"placeholder_text", "bbcode_enabled",
	"columns", "color", "autowrap_mode",
	"texture", "texture_normal", "stretch_mode",
	# SvgVectorControl properties
	"svg_path", "override_fill", "fill_color", "override_stroke", "stroke_color", "stroke_width", "base_scale"
]

func resolve(node: Node) -> Dictionary:
	var props: Dictionary = {}
	
	if not node is Control:
		if "position" in node:
			props["position"] = node.get("position")
		return props
		
	for prop_name in TARGET_PROPERTIES:
		if prop_name in node:
			props[prop_name] = node.get(prop_name)
			
	# Fallback to catch any exported properties we missed
	for p in node.get_property_list():
		if p.usage & PROPERTY_USAGE_EDITOR != 0 and p.usage & PROPERTY_USAGE_STORAGE != 0:
			if not props.has(p.name):
				props[p.name] = node.get(p.name)
				
	return props
