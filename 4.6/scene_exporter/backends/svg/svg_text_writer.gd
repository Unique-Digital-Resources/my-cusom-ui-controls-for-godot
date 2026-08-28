class_name SVGTextWriter
extends RefCounted

# Serializes RenderText objects into SVG <text> tags

func write(text_obj: RenderText, style: RenderStyle, transform_attrs: String) -> String:
	var attrs: PackedStringArray = PackedStringArray()
	
	if transform_attrs != "":
		attrs.append(transform_attrs)
		
	attrs.append("x=\"%.2f\"" % text_obj.position.x)
	attrs.append("y=\"%.2f\"" % text_obj.position.y)
	
	# Preserve spaces exactly as they are
	attrs.append("xml:space=\"preserve\"")
	
	if style.font_size > 0:
		attrs.append("font-size=\"%d\"" % style.font_size)
		
	# Default Font: Open Sans SemiBold (Godot 4 default)
	attrs.append("font-family=\"Open Sans, sans-serif\"")
	attrs.append("font-weight=\"600\"")
		
	var fill_color = style.text_color if style.text_color.a > 0 else Color.BLACK
	attrs.append("fill=\"#%s\"" % fill_color.to_html(false))
	if fill_color.a < 1.0:
		attrs.append("fill-opacity=\"%.3f\"" % fill_color.a)
		
	var is_rtl = _is_rtl(text_obj.text)
	var anchor = "start"
	match text_obj.alignment:
		"center": anchor = "middle"
		"right": anchor = "end"
		_: anchor = "start"
		
	var bidi_attrs = ""
	if is_rtl:
		bidi_attrs = " direction=\"rtl\" unicode-bidi=\"embed\""
		attrs.append(bidi_attrs.strip_edges())
		
		if anchor == "start":
			anchor = "end"
		elif anchor == "end":
			anchor = "start"
			
	attrs.append("text-anchor=\"%s\"" % anchor)
		
	var content = _format_text_content(text_obj.text, text_obj.position.x, style.font_size, is_rtl)
	
	return "<text %s>%s</text>" % [" ".join(attrs), content]

func _format_text_content(text: String, x_pos: float, base_font_size: int, is_rtl: bool) -> String:
	# Split text by newline to create separate tspans for each line
	var lines = text.split("\n")
	
	# If it's a single line, just parse and return it without extra tspans
	if lines.size() == 1:
		return _parse_bbcode(lines[0])
		
	var tspans: PackedStringArray = PackedStringArray()
	
	for i in range(lines.size()):
		var line = lines[i]
		var parsed_line = _parse_bbcode(line)
		
		if i == 0:
			# First line inherits position from <text>, no need for x or dy
			tspans.append(parsed_line)
		else:
			# Subsequent lines need x to reset horizontal position, and dy to move down.
			# Fix: Increased dy to 1.7em to better match Godot's default vertical spacing,
			# especially when lines contain mixed font sizes via BBCode.
			var tspan_attrs = "x=\"%.2f\" dy=\"1.7em\" font-size=\"%d\"" % [x_pos, base_font_size]
			tspans.append("<tspan %s>%s</tspan>" % [tspan_attrs, parsed_line])
			
	return "".join(tspans)

func _parse_bbcode(text: String) -> String:
	# Escape XML characters first
	text = text.replace("&", "&amp;")
	
	# Strip alignment tags as they are handled by text-anchor
	text = text.replace("[right]", "").replace("[/right]", "")
	text = text.replace("[center]", "").replace("[/center]", "")
	text = text.replace("[left]", "").replace("[/left]", "")
	
	# Map Godot BBCode to SVG tspan elements
	text = text.replace("[b]", "<tspan font-weight=\"bold\">").replace("[/b]", "</tspan>")
	text = text.replace("[i]", "<tspan font-style=\"italic\">").replace("[/i]", "</tspan>")
	text = text.replace("[u]", "<tspan text-decoration=\"underline\">").replace("[/u]", "</tspan>")
	text = text.replace("[s]", "<tspan text-decoration=\"line-through\">").replace("[/s]", "</tspan>")
	
	# Regex for color tags [color=red] or [color=#ff0000]
	var regex_color = RegEx.new()
	regex_color.compile("\\[color=(.*?)\\]")
	text = regex_color.sub(text, "<tspan fill=\"$1\">", true)
	text = text.replace("[/color]", "</tspan>")
	
	# Regex for font size tags [font_size=24]
	var regex_size = RegEx.new()
	regex_size.compile("\\[font_size=(.*?)\\]")
	text = regex_size.sub(text, "<tspan font-size=\"$1\">", true)
	text = text.replace("[/font_size]", "</tspan>")
	
	return text

func _is_rtl(text: String) -> bool:
	for c in text:
		var code = c.unicode_at(0)
		# Basic Arabic Unicode block
		if code >= 0x0600 and code <= 0x06FF:
			return true
	return false
