@tool
class_name SymbolControl
extends MathLeaf

## Visual control for rendering a single symbol, number, or operator glyph.

var _context: RenderContext
var latex_cmd: String = ""
var is_operator: bool = false
var is_large_operator: bool = false

func _init(p_text: String = "", p_latex: String = "", p_is_op: bool = false, p_is_large: bool = false) -> void:
	text = p_text
	latex_cmd = p_latex
	is_operator = p_is_op
	is_large_operator = p_is_large

func measure(context: RenderContext) -> void:
	_context = context
	if text.is_empty():
		measured_size = Vector2.ZERO
		baseline = 0.0
		return
		
	var font = _get_active_font(context)
	var size = _context.get_font_size()
	var display_text = _get_display_text(context)
	
	if is_large_operator:
		size = int(size * 1.3)
		
	measured_size = FontMetrics.get_text_size(display_text, font, size)
	baseline = FontMetrics.get_ascent(font, size)
	
	custom_minimum_size = measured_size
	size = measured_size

func _draw() -> void:
	if text.is_empty():
		return
		
	var font = _get_active_font(_context)
	var size = _context.get_font_size()
	if is_large_operator:
		size = int(size * 1.3)
	var color = _context.color
	var display_text = _get_display_text(_context)
	
	SymbolDrawer.draw_symbol(self, font, display_text, Vector2(0, baseline), size, color)

func _get_active_font(context: RenderContext) -> Font:
	if context.font_forced:
		return context.font
		
	var is_ascii_letter = (text.length() == 1) and ((text >= "a" and text <= "z") or (text >= "A" and text <= "Z"))
	if is_ascii_letter and not is_operator and not is_large_operator:
		return context.font_italic if context.font_italic else context.font
		
	return context.font

# NEW: Transforms text to Unicode if a style_override is active
func _get_display_text(context: RenderContext) -> String:
	if context.style_override == "blackboard":
		return SpecialFonts.get_blackboard(text)
	elif context.style_override == "caligraphic":
		return SpecialFonts.get_caligraphic(text)
	return text
