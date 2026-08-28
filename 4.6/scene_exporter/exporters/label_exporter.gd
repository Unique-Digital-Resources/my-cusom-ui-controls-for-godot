class_name LabelExporter
extends ControlExporter

# Exporter for Label and RichTextLabel.

func export_node(info: NodeInfo, context: ExportContext) -> RenderGroup:
	var group = super.export_node(info, context)
	
	# 1. Draw Background (StyleBox) if it exists (e.g., for Badges)
	var sb_id = info.resolved_theme.get("styleboxes", {}).get("normal", "")
	if sb_id != "" and sb_id != "null":
		var sb = context.resource_resolver.get_resource(sb_id)
		if sb is StyleBoxFlat:
			var shape = RenderShape.new()
			shape.node_name = info.node_name + "_bg"
			shape.shape_type = "rounded_rect" if sb.corner_radius_top_left > 0 else "rect"
			shape.rect = Rect2(Vector2.ZERO, info.size)
			shape.style.fill_color = sb.bg_color
			shape.corner_radius = sb.corner_radius_top_left
			group.children.insert(0, shape)
			
	# 2. Draw Text
	var text_obj = RenderText.new()
	text_obj.node_name = info.node_name + "_text"
	
	if info.node is RichTextLabel:
		var raw_text = info.node.text
		if raw_text.find("[right]") != -1:
			text_obj.alignment = "right"
		elif raw_text.find("[center]") != -1:
			text_obj.alignment = "center"
		else:
			text_obj.alignment = "left"
			
		text_obj.text = raw_text
			
		text_obj.style.text_color = info.resolved_theme.get("colors", {}).get("default_color", Color.BLACK)
		text_obj.style.font_size = info.resolved_theme.get("font_sizes", {}).get("normal_font_size", 16)
		text_obj.style.font_resource_id = info.resolved_theme.get("fonts", {}).get("normal_font", "")
	else:
		text_obj.text = info.properties.get("text", "")
		text_obj.style.text_color = info.resolved_theme.get("colors", {}).get("font_color", Color.BLACK)
		text_obj.style.font_size = info.resolved_theme.get("font_sizes", {}).get("font_size", 16)
		text_obj.style.font_resource_id = info.resolved_theme.get("fonts", {}).get("font", "")
		
		var h_align = info.properties.get("horizontal_alignment", 0)
		match h_align:
			1: text_obj.alignment = "center"
			2: text_obj.alignment = "right"
			_: text_obj.alignment = "left"
		
	var pos = Vector2.ZERO
	match text_obj.alignment:
		"center": pos.x = info.size.x / 2.0
		"right": pos.x = info.size.x
		_: pos.x = 0
		
	# Fix: RichTextLabel is top-aligned by default in Godot.
	if info.node is RichTextLabel:
		pos.y = text_obj.style.font_size * 1.2
	else:
		var v_align = info.properties.get("vertical_alignment", 1) if info.properties.has("vertical_alignment") else 1
		match v_align:
			0: pos.y = text_obj.style.font_size * 1.2
			1: pos.y = (info.size.y / 2.0) + (text_obj.style.font_size / 3.0)
			2: pos.y = info.size.y - (text_obj.style.font_size * 0.2)
			_: pos.y = text_obj.style.font_size * 1.2
		
	text_obj.position = pos
	
	# Fix: Apply text wrapping if enabled
	var autowrap = info.properties.get("autowrap_mode", 0)
	if info.node is Label and autowrap != 0: # 0 is AUTOWRAP_OFF
		text_obj.text = _wrap_text(text_obj.text, info.size.x, info.node)
	elif info.node is RichTextLabel and not info.properties.get("fit_content", false):
		# RichTextLabel wraps automatically if constrained and not fit_content
		text_obj.text = _wrap_text(text_obj.text, info.size.x, info.node)
	
	group.add_child(text_obj)
	return group

func _wrap_text(text: String, width: float, node: Control) -> String:
	if width <= 0:
		return text
		
	var font: Font = null
	var font_size: int = 16
	
	if node is Label:
		font = node.get_theme_font("font")
		font_size = node.get_theme_font_size("font_size")
	elif node is RichTextLabel:
		font = node.get_theme_font("normal_font")
		font_size = node.get_theme_font_size("normal_font_size")
		
	if font == null:
		return text
		
	# Split by existing newlines first to preserve manual line breaks
	var paragraphs = text.split("\n")
	var wrapped_paragraphs: PackedStringArray = PackedStringArray()
	
	for para in paragraphs:
		var words = para.split(" ")
		var current_line = ""
		var lines: PackedStringArray = PackedStringArray()
		
		for word in words:
			var test_line = word if current_line == "" else current_line + " " + word
			# Measure the text size using Godot's font metrics
			var size = font.get_string_size(test_line, font_size)
			if size.x > width and current_line != "":
				lines.append(current_line)
				current_line = word
			else:
				current_line = test_line
		if current_line != "":
			lines.append(current_line)
			
		wrapped_paragraphs.append("\n".join(lines))
		
	return "\n".join(wrapped_paragraphs)
