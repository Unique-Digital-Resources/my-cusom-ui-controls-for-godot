@tool
class_name SVGNodeVisitor
extends RefCounted

## Recursively traverses the Godot Scene Tree and builds a nested SVG group tree.

const StyleMapper = preload("res://addons/ai_scene_format/exporter/svg/svg_style_mapper.gd")
const TextLayout = preload("res://addons/ai_scene_format/exporter/svg/svg_text_layout.gd")

func traverse(node: Node, indent_level: int) -> String:
	if not node is Control:
		return ""
		
	var ctrl = node as Control
	if not ctrl.is_visible_in_tree():
		return ""
		
	var pad = "  ".repeat(indent_level)
	var svg = ""
	
	# 1. Open Group (mirrors the Godot Node's local position)
	svg += "%s<g transform=\"translate(%f, %f)\">\n" % [pad, ctrl.position.x, ctrl.position.y]
	
	var size = ctrl.size
	
	# 2. Draw StyleBoxes (Backgrounds & Borders)
	# Check all possible stylebox names to ensure we don't miss Label or Panel backgrounds
	var stylebox_names = ["panel", "normal", ""]
	for sb_name in stylebox_names:
		var sb = ctrl.get_theme_stylebox(sb_name)
		if sb and sb is StyleBoxFlat:
			svg += StyleMapper.map_stylebox(sb, size, indent_level + 1)
			break # Draw only the first valid background to avoid overlap
	
	# 3. Draw Text
	if ctrl is Label or ctrl is RichTextLabel:
		svg += TextLayout.map_text(ctrl, size, indent_level + 1)
		
	# 4. Process Children recursively
	for child in ctrl.get_children():
		svg += traverse(child, indent_level + 1)
		
	# 5. Close Group
	svg += "%s</g>\n" % pad
	
	return svg
