class_name LayoutEngine extends RefCounted

var _bold_font: FontVariation = null

func _get_bold_font(base_font: Font) -> FontVariation:
	if _bold_font == null:
		_bold_font = FontVariation.new()
		_bold_font.set_base_font(base_font)
		_bold_font.variation_embolden = 0.8
	return _bold_font

func _instantiate_object(provider: String) -> Control:
	if provider.begins_with("res://"):
		return load(provider).new()
	elif ClassDB.class_exists(provider) and ClassDB.can_instantiate(provider):
		return ClassDB.instantiate(provider)
	return null

func _apply_args(obj: Control, args: String, provider: String) -> void:
	if obj.has_method("set_args"):
		obj.set_args(args)
		return
	if provider == "Button":
		obj.text = args
	elif provider == "ColorRect":
		obj.color = Color.html(args) if Color.html_is_valid(args) else Color.WHITE

# Accurately measures the exact size the control will take up according to Godot's theme
func _get_object_size(provider: String, args: String, default_font: Font, font_size: int) -> Vector2:
	var obj = _instantiate_object(provider)
	if not obj:
		return Vector2(32, 32)
		
	if provider == "Button":
		obj.add_theme_font_override("font", default_font)
		obj.add_theme_font_size_override("font_size", font_size)
		
	_apply_args(obj, args, provider)
	
	var min_size = obj.get_combined_minimum_size()
	obj.free()
	
	return min_size if min_size.x > 0 else Vector2(32, 32)

func layout_document(doc: Document, width: float, default_font: Font, caret_paragraph: int, caret_offset: int) -> Dictionary:
	var paragraphs_data := []
	var total_height: float = 0.0
	var bold_font = _get_bold_font(default_font)
	
	for i in range(doc.paragraphs.size()):
		var para = doc.paragraphs[i]
		var c_offset = caret_offset if i == caret_paragraph else -1
		var render_tokens = para.get_render_tokens(c_offset)
		
		var font_size = 16
		if para.block_type == "heading":
			font_size = 24 if para.heading_level == 1 else 20
			
		var processed_tokens := []
		var para_height: float = 0.0
		var text_height: float = default_font.get_height(font_size)
		
		for tok in render_tokens:
			if tok.has("is_object") and tok.is_object:
				var obj_size = _get_object_size(tok.provider, tok.args, default_font, font_size)
				processed_tokens.append({
					"is_object": true, "provider": tok.provider, "args": tok.args,
					"size": obj_size, "raw_start": tok.raw_start, "raw_length": tok.raw_length
				})
				para_height = max(para_height, obj_size.y)
			else:
				var is_bold = tok.bold or para.block_type == "heading"
				var font_to_use = bold_font if is_bold else default_font
				para_height = max(para_height, font_to_use.get_height(font_size))
				processed_tokens.append(tok)
				
		paragraphs_data.append({
			"tokens": processed_tokens, "height": para_height, "font_size": font_size, "text_height": text_height
		})
		total_height += para_height + 8.0
		
	return {
		"paragraphs_data": paragraphs_data,
		"total_height": total_height,
		"bold_font": bold_font
	}
