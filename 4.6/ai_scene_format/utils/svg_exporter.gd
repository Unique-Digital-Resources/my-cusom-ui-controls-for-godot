@tool
class_name AISVGExporter
extends RefCounted

## Generic Scene Tree to SVG Tree Converter.
## Recursively traverses Control nodes and builds a perfectly nested SVG tree.

static func export_tree(root: Control, path: String) -> Error:
	if not root: return ERR_INVALID_PARAMETER
	
	var root_size = root.size
	var svg_content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
	svg_content += "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%d\" height=\"%d\" viewBox=\"0 0 %d %d\">\n" % [int(root_size.x), int(root_size.y), int(root_size.x), int(root_size.y)]
	
	# Defs for shadows
	svg_content += "  <defs>\n"
	svg_content += "    <filter id=\"godot_shadow\" x=\"-50%\" y=\"-50%\" width=\"200%\" height=\"200%\">\n"
	svg_content += "      <feDropShadow dx=\"2\" dy=\"2\" stdDeviation=\"3\" flood-opacity=\"0.3\"/>\n"
	svg_content += "    </filter>\n"
	svg_content += "  </defs>\n"
	
	# Recursively build the SVG tree
	svg_content += _process_node_recursive(root, 1)
	
	svg_content += "</svg>\n"
	
	# Save to file
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(svg_content)
		file.close()
		print("✅ SVG Tree Exported successfully to: ", path)
		return OK
	else:
		push_error("Failed to open file for SVG export: " + path)
		return ERR_CANT_OPEN

static func _process_node_recursive(node: Node, indent_level: int) -> String:
	if not node is Control: return ""
	
	var ctrl = node as Control
	if not ctrl.is_visible_in_tree(): return ""
	
	var pad = "  ".repeat(indent_level)
	var svg = ""
	
	# 1. Open Group (mirrors the Godot Node)
	# We use the node's local position relative to its parent
	svg += "%s<g transform=\"translate(%f, %f)\">\n" % [pad, ctrl.position.x, ctrl.position.y]
	
	var size = ctrl.size
	
	# 2. Draw StyleBoxes (Backgrounds & Borders)
	var stylebox_names = []
	if ctrl is Panel or ctrl is PanelContainer: stylebox_names.append("panel")
	if ctrl is Label or ctrl is Button: stylebox_names.append("normal")
	
	for sb_name in stylebox_names:
		var sb = ctrl.get_theme_stylebox(sb_name)
		if sb and sb is StyleBoxFlat:
			svg += _stylebox_to_svg(sb, size, indent_level + 1)
			break # Draw only the first valid background
	
	# 3. Draw Text
	if ctrl is Label or ctrl is RichTextLabel:
		svg += _text_to_svg(ctrl, size, indent_level + 1)
		
	# 4. Process Children recursively
	for child in ctrl.get_children():
		svg += _process_node_recursive(child, indent_level + 1)
		
	# 5. Close Group
	svg += "%s</g>\n" % pad
	
	return svg

static func _stylebox_to_svg(sb: StyleBoxFlat, size: Vector2, indent_level: int) -> String:
	var pad = "  ".repeat(indent_level)
	var svg = ""
	
	var w = size.x
	var h = size.y
	var rx = sb.corner_radius_top_left
	
	var shadow_attr = ""
	if sb.shadow_size > 0:
		shadow_attr = " filter=\"url(#godot_shadow)\""
		
	# 1. Draw Background Fill
	var bg_c = sb.bg_color
	var bg_rgb = "rgb(%d,%d,%d)" % [bg_c.r8, bg_c.g8, bg_c.b8]
	svg += "%s<rect x=\"0\" y=\"0\" width=\"%f\" height=\"%f\" rx=\"%d\" fill=\"%s\" fill-opacity=\"%f\"%s />\n" % [
		pad, w, h, rx, bg_rgb, bg_c.a, shadow_attr
	]
	
	# 2. Draw Independent Borders (Inside the rect, like Godot)
	var b_c = sb.border_color
	var b_rgb = "rgb(%d,%d,%d)" % [b_c.r8, b_c.g8, b_c.b8]
	var b_a = b_c.a
	
	if sb.border_width_left > 0:
		svg += "%s<rect x=\"0\" y=\"0\" width=\"%f\" height=\"%f\" fill=\"%s\" fill-opacity=\"%f\" />\n" % [
			pad, float(sb.border_width_left), h, b_rgb, b_a
		]
	if sb.border_width_right > 0:
		svg += "%s<rect x=\"%f\" y=\"0\" width=\"%f\" height=\"%f\" fill=\"%s\" fill-opacity=\"%f\" />\n" % [
			pad, w - sb.border_width_right, float(sb.border_width_right), h, b_rgb, b_a
		]
	if sb.border_width_top > 0:
		svg += "%s<rect x=\"0\" y=\"0\" width=\"%f\" height=\"%f\" fill=\"%s\" fill-opacity=\"%f\" />\n" % [
			pad, w, float(sb.border_width_top), b_rgb, b_a
		]
	if sb.border_width_bottom > 0:
		svg += "%s<rect x=\"0\" y=\"%f\" width=\"%f\" height=\"%f\" fill=\"%s\" fill-opacity=\"%f\" />\n" % [
			pad, h - sb.border_width_bottom, w, float(sb.border_width_bottom), b_rgb, b_a
		]
		
	return svg

static func _text_to_svg(ctrl: Control, size: Vector2, indent_level: int) -> String:
	var pad = "  ".repeat(indent_level)
	var svg = ""
	
	var text = ""
	var font_size = 16
	var color = Color.BLACK
	var h_align = 0
	var v_align = 0
	var is_rtl = false
	
	if ctrl is Label:
		text = (ctrl as Label).text
		font_size = ctrl.get_theme_font_size("font_size")
		color = ctrl.get_theme_color("font_color")
		h_align = (ctrl as Label).horizontal_alignment
		v_align = (ctrl as Label).vertical_alignment
	elif ctrl is RichTextLabel:
		text = (ctrl as RichTextLabel).get_parsed_text()
		font_size = ctrl.get_theme_font_size("normal_font_size")
		color = ctrl.get_theme_color("default_color")
		h_align = (ctrl as RichTextLabel).horizontal_alignment
		v_align = (ctrl as RichTextLabel).vertical_alignment
		if (ctrl as RichTextLabel).text.find("[right]") != -1:
			h_align = 2
			
	if text.length() > 0 and _is_arabic(text[0]):
		is_rtl = true
		
	var fill_str = "rgb(%d,%d,%d)" % [color.r8, color.g8, color.b8]
	var text_lines = text.split("\n")
	var line_height = font_size * 1.15
	
	# Calculate Y offset based on Vertical Alignment
	var start_y = 0
	if v_align == 1: start_y = (size.y - (text_lines.size() * line_height)) / 2.0
	elif v_align == 2: start_y = size.y - (text_lines.size() * line_height)
	start_y += line_height * 0.8 # Baseline
	
	# Calculate X anchor based on Horizontal Alignment
	var anchor = "start"
	var x = 0
	if h_align == 1: 
		x = size.x / 2.0
		anchor = "middle"
	elif h_align == 2: 
		x = size.x
		anchor = "end"
		
	for i in range(text_lines.size()):
		var line = text_lines[i].replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
		var y = start_y + (i * line_height)
		var rtl_dir = " direction=\"rtl\"" if is_rtl else ""
		
		svg += "%s<text x=\"%f\" y=\"%f\" font-family=\"sans-serif\" font-size=\"%d\" fill=\"%s\" text-anchor=\"%s\"%s>%s</text>\n" % [
			pad, x, y, font_size, fill_str, anchor, rtl_dir, line
		]
		
	return svg

static func _is_arabic(char: String) -> bool:
	var code = char.unicode_at(0)
	return code >= 0x0600 and code <= 0x06FF
