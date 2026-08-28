@tool
extends Control
class_name DocumentEditor

var document: Document = Document.new()
var layout_engine: LayoutEngine = LayoutEngine.new()

var caret_paragraph: int = 0
var caret_offset: int = 0

var layout_cache: Dictionary = {}
var _object_pool: Dictionary = {} 

var caret_blink_timer: float = 0.0
var draw_caret: bool = true

# Metrics
var caret_row: int = 1
var caret_col: int = 1
var current_line_width: float = 0.0
var current_line_height: float = 0.0

const MARGIN: float = 20.0

func _ready() -> void:
	focus_mode = Control.FOCUS_CLICK
	_trigger_relayout()

func _exit_tree() -> void:
	for arr in _object_pool.values():
		for obj in arr:
			if is_instance_valid(obj):
				obj.queue_free()

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

func _get_or_create_object(provider: String, args: String) -> Control:
	if not _object_pool.has(provider):
		_object_pool[provider] = []
	for obj in _object_pool[provider]:
		if not obj.visible:
			_apply_args(obj, args, provider)
			return obj
			
	var obj = _instantiate_object(provider)
	if obj:
		add_child(obj)
		_apply_args(obj, args, provider)
		_object_pool[provider].append(obj)
	return obj

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var handled := true
		var key = event.keycode
		
		if key == KEY_BACKSPACE:
			if caret_offset > 0:
				document.delete_text(caret_paragraph, caret_offset, 1)
				caret_offset -= 1
			elif caret_paragraph > 0:
				caret_paragraph -= 1
				caret_offset = document.paragraphs[caret_paragraph].raw_text.length()
				document.merge_with_previous(caret_paragraph + 1)
		elif key == KEY_ENTER:
			document.split_paragraph(caret_paragraph, caret_offset)
			caret_paragraph += 1
			caret_offset = 0
		elif key == KEY_LEFT:
			caret_offset -= 1
			if caret_offset < 0 and caret_paragraph > 0:
				caret_paragraph -= 1
				caret_offset = document.paragraphs[caret_paragraph].raw_text.length()
		elif key == KEY_RIGHT:
			caret_offset += 1
			if caret_offset > document.paragraphs[caret_paragraph].raw_text.length() and caret_paragraph < document.paragraphs.size() - 1:
				caret_paragraph += 1
				caret_offset = 0
		else:
			handled = false
			
		if handled:
			get_viewport().set_input_as_handled()
			_reset_caret_blink()
			_trigger_relayout()
			return
			
	if event is InputEventKey and event.pressed and event.unicode != 0:
		var char = String.chr(event.unicode)
		document.insert_text(caret_paragraph, caret_offset, char)
		caret_offset += 1
		get_viewport().set_input_as_handled()
		_reset_caret_blink()
		_trigger_relayout()

func _trigger_relayout() -> void:
	if not is_instance_valid(document) or not is_instance_valid(layout_engine): return
	var available_width = size.x - (MARGIN * 2)
	var default_font = get_theme_default_font()
	layout_cache = layout_engine.layout_document(document, available_width, default_font, caret_paragraph, caret_offset)
	
	caret_row = caret_paragraph + 1
	caret_col = caret_offset + 1
	if document.paragraphs.size() > 0 and layout_cache.has("paragraphs_data"):
		var p_data = layout_cache["paragraphs_data"][caret_paragraph]
		current_line_height = p_data.height
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_trigger_relayout()

func _process(delta: float) -> void:
	if has_focus():
		caret_blink_timer += delta
		if caret_blink_timer > 0.5:
			draw_caret = !draw_caret
			caret_blink_timer = 0.0
			queue_redraw()

func _reset_caret_blink() -> void:
	caret_blink_timer = 0.0
	draw_caret = true
	queue_redraw()

func _draw() -> void:
	if not layout_cache.has("paragraphs_data"): return
		
	for arr in _object_pool.values():
		for obj in arr:
			obj.visible = false
			
	var paragraphs_data: Array = layout_cache["paragraphs_data"]
	var default_font = get_theme_default_font()
	var bold_font = layout_cache.get("bold_font", default_font)
	
	var y_offset := MARGIN
	
	for i in range(paragraphs_data.size()):
		var p_data = paragraphs_data[i]
		var tokens: Array = p_data.tokens
		var para_height: float = p_data.height
		var text_height: float = p_data.text_height
		var font_size: int = p_data.font_size
		var para = document.paragraphs[i]
		
		var x_offset := MARGIN
		var caret_x := x_offset
		var caret_drawn := false
		var line_width_calc: float = 0.0
		
		for tok in tokens:
			var token_width: float = 0.0
			var is_object = tok.has("is_object") and tok.is_object
			
			if is_object:
				var obj = _get_or_create_object(tok.provider, tok.args)
				if obj:
					obj.visible = true
					var obj_y = y_offset + (text_height - tok.size.y) / 2.0
					obj.position = Vector2(x_offset, obj_y)
					obj.size = tok.size
					
					# CRITICAL FIX: Force clipping so the control CANNOT draw over subsequent text
					obj.clip_contents = true
					
					token_width = tok.size.x
					line_width_calc += token_width
			else:
				var is_bold = tok.bold or para.block_type == "heading"
				var font_to_use = bold_font if is_bold else default_font
				token_width = font_to_use.get_string_size(tok.text, HORIZONTAL_ALIGNMENT_LEFT, size.x, font_size).x
				line_width_calc += token_width
				
				if tok.highlight and not tok.is_syntax:
					var rect = Rect2(x_offset, y_offset, token_width, font_to_use.get_height(font_size))
					draw_rect(rect, Color(1, 0.8, 0.2, 0.3))
			
			if i == caret_paragraph and has_focus() and not caret_drawn:
				if is_object:
					if caret_offset <= tok.raw_start:
						caret_drawn = true
					elif caret_offset >= tok.raw_start + tok.raw_length:
						caret_x += token_width
					else:
						caret_drawn = true
				else:
					if caret_offset <= tok.raw_start + tok.text.length():
						var text_to_measure = tok.text.substr(0, caret_offset - tok.raw_start)
						var font_to_use = bold_font if (tok.bold or para.block_type == "heading") else default_font
						caret_x += font_to_use.get_string_size(text_to_measure, HORIZONTAL_ALIGNMENT_LEFT, size.x, font_size).x
						caret_drawn = true
					else:
						caret_x += token_width
						
			if not is_object:
				var is_bold = tok.bold or para.block_type == "heading"
				var font_to_use = bold_font if is_bold else default_font
				var color = Color(0.5, 0.5, 0.5) if tok.is_syntax else Color.WHITE
				if tok.highlight and not tok.is_syntax:
					color = Color(1, 1, 0.6)
				font_to_use.draw_string(get_canvas_item(), Vector2(x_offset, y_offset + font_to_use.get_ascent(font_size)), tok.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
			
			x_offset += token_width
		
		if i == caret_paragraph:
			current_line_width = line_width_calc
			
		if i == caret_paragraph and has_focus() and not caret_drawn:
			caret_x = x_offset
			caret_drawn = true
			
		if i == caret_paragraph and has_focus() and draw_caret and caret_drawn:
			draw_line(
				Vector2(caret_x, y_offset + 2), 
				Vector2(caret_x, y_offset + para_height), 
				Color.WHITE, 
				2.0
			)
			
		y_offset += para_height + 8.0
		
	# Draw Status Bar Metrics
	var status_text = "Row: %d | Col: %d | Line W: %dpx | Line H: %dpx" % [caret_row, caret_col, int(current_line_width), int(current_line_height)]
	var status_y = size.y - 24.0
	draw_rect(Rect2(0, status_y, size.x, 24), Color(0.1, 0.1, 0.1, 0.8))
	default_font.draw_string(get_canvas_item(), Vector2(10, status_y + 16), status_text, HORIZONTAL_ALIGNMENT_LEFT, size.x, 14, Color(0.8, 0.8, 0.8))
