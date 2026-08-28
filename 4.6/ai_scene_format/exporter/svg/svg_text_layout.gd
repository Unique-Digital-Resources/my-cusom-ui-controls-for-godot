@tool
class_name SVGTextLayout
extends RefCounted

## Converts Godot Label/RichTextLabel into SVG text elements.
## Includes word-wrapping using Godot's font metrics to mimic autowrap.

static func map_text(ctrl: Control, size: Vector2, indent_level: int) -> String:
	var pad = "  ".repeat(indent_level)
	var svg = ""
	
	var text = ""
	var raw_text = ""
	var font_size = 16
	var color = Color.BLACK
	var h_align = 0
	var v_align = 0
	
	if ctrl is Label:
		text = (ctrl as Label).text
		raw_text = text
		font_size = ctrl.get_theme_font_size("font_size")
		color = ctrl.get_theme_color("font_color")
		h_align = (ctrl as Label).horizontal_alignment
		v_align = (ctrl as Label).vertical_alignment
	elif ctrl is RichTextLabel:
		raw_text = (ctrl as RichTextLabel).text
		text = (ctrl as RichTextLabel).get_parsed_text()
		font_size = ctrl.get_theme_font_size("normal_font_size")
		color = ctrl.get_theme_color("default_color")
		h_align = (ctrl as RichTextLabel).horizontal_alignment
		v_align = (ctrl as RichTextLabel).vertical_alignment
		if raw_text.find("[right]") != -1:
			h_align = 2 # Force right align if BBCode contains [right]
			
	# Get Godot's default font to measure text width for wrapping
	var font = ctrl.get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font
		
	var fill_str = SVGUtils.color_to_rgb(color)
	
	# 1. Word Wrap Logic (Mimics Godot's autowrap)
	var wrapped_lines = []
	for paragraph in text.split("\n"):
		var words = paragraph.split(" ")
		var current_line = ""
		
		for word in words:
			var test_line = current_line
			if test_line.length() > 0: test_line += " "
			test_line += word
			
			# Measure width. If it fits, keep it. If not, push the current line and start a new one.
			var line_width = font.get_string_size(test_line, font_size).x
			if line_width <= size.x or current_line.length() == 0:
				current_line = test_line
			else:
				wrapped_lines.append(current_line)
				current_line = word
				
		if current_line.length() > 0:
			wrapped_lines.append(current_line)
			
	# 2. Layout Logic
	var line_height = font_size * 1.15
	
	# Calculate Y offset based on Vertical Alignment
	var start_y = 0
	if v_align == 1: start_y = (size.y - (wrapped_lines.size() * line_height)) / 2.0
	elif v_align == 2: start_y = size.y - (wrapped_lines.size() * line_height)
	start_y += line_height * 0.8 # Baseline offset
	
	# Calculate X anchor based on Horizontal Alignment
	var anchor = "start"
	var x = 0
	if h_align == 1: 
		x = size.x / 2.0
		anchor = "middle"
	elif h_align == 2: 
		x = size.x
		anchor = "end"
		
	# 3. Generate SVG <text> tags
	for i in range(wrapped_lines.size()):
		var line = SVGUtils.escape_xml(wrapped_lines[i])
		var y = start_y + (i * line_height)
		
		var rtl_dir = ""
		if SVGUtils.is_arabic(raw_text):
			rtl_dir = " direction=\"rtl\""
			
		svg += "%s<text x=\"%s\" y=\"%s\" font-family=\"sans-serif\" font-size=\"%d\" fill=\"%s\" text-anchor=\"%s\"%s>%s</text>\n" % [
			pad, SVGUtils.fmt(x), SVGUtils.fmt(y), font_size, fill_str, anchor, rtl_dir, line
		]
		
	return svg
