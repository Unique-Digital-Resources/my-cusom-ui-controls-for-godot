@tool
class_name FencedControl
extends MathContainer

## Visual control for scalable delimiters (fences).

var open_char: String = "("
var close_char: String = ")"
var _context: RenderContext

func _init(p_open: String = "(", p_close: String = ")") -> void:
	open_char = p_open
	close_char = p_close

func measure(context: RenderContext) -> void:
	_context = context
	super.measure(context)
	
	var content = get_node_or_null("Content")
	var content_w = 0.0
	var content_h = 0.0
	var content_asc = 0.0
	
	if content:
		content_w = content.measured_size.x
		content_h = content.measured_size.y
		content_asc = content.baseline
		
	var font_size = context.get_font_size()
	var bracket_width = font_size * 0.3
	var padding = font_size * 0.1
	
	measured_size.x = padding + bracket_width + padding + content_w + padding + bracket_width + padding
	measured_size.y = content_h
	baseline = content_asc
	
	custom_minimum_size = measured_size
	size = measured_size

func arrange(context: RenderContext, pos: Vector2) -> void:
	super.arrange(context, pos)
	
	var content = get_node_or_null("Content")
	var font_size = context.get_font_size()
	var bracket_width = font_size * 0.3
	var padding = font_size * 0.1
	
	if content:
		var y_shift = baseline - content.baseline
		var content_x = padding + bracket_width + padding
		content.arrange(context, Vector2(content_x, y_shift))

func _draw() -> void:
	if not _context:
		return
		
	var content = get_node_or_null("Content")
	var content_h = content.measured_size.y if content else _context.get_font_size()
	var font_size = _context.get_font_size()
	var bracket_width = font_size * 0.3
	var padding = font_size * 0.1
	var line_thick = font_size * _context.line_thickness
	
	var left_x = padding + (bracket_width * 0.5)
	var right_x = measured_size.x - padding - (bracket_width * 0.5)
	
	BracketDrawer.draw_bracket(self, open_char, Vector2(left_x, 0), content_h, bracket_width, line_thick, _context.color, true)
	BracketDrawer.draw_bracket(self, close_char, Vector2(right_x, 0), content_h, bracket_width, line_thick, _context.color, false)
