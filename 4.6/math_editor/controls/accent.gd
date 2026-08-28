@tool
class_name AccentControl
extends MathContainer

## Draws lines, arrows, or hats over/under math elements.
## Expects one child (added by the Generator):
##   • "Content" - the inner expression

var accent_type: String = ""
var _context: RenderContext

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
	var gap = font_size * 0.1
	var accent_h = font_size * 0.2
	
	# If it's an over accent, we add height to the top. If under, to the bottom.
	var top_pad = 0.0
	var bot_pad = 0.0
	
	if accent_type in ["\\overline", "\\vec", "\\hat"]:
		top_pad = gap + accent_h
	elif accent_type == "\\underline":
		bot_pad = gap + accent_h
		
	measured_size.x = content_w
	measured_size.y = content_h + top_pad + bot_pad
	
	# Shift baseline down to accommodate top padding
	baseline = content_asc + top_pad
	
	custom_minimum_size = measured_size
	size = measured_size

func arrange(context: RenderContext, pos: Vector2) -> void:
	super.arrange(context, pos)
	
	var content = get_node_or_null("Content")
	var font_size = context.get_font_size()
	var gap = font_size * 0.1
	var top_pad = 0.0
	
	if accent_type in ["\\overline", "\\vec", "\\hat"]:
		top_pad = gap + (font_size * 0.2)
		
	if content:
		# Shift child down by top_pad
		content.arrange(context, Vector2(0, top_pad))

func _draw() -> void:
	if not _context:
		return
		
	var content = get_node_or_null("Content")
	var content_w = content.measured_size.x if content else _context.get_font_size()
	var font_size = _context.get_font_size()
	var gap = font_size * 0.1
	var line_thick = font_size * _context.line_thickness
	var color = _context.color
	
	if accent_type == "\\overline":
		var y = gap
		OperatorDrawer.draw_fraction_line(self, Vector2(0, y), content_w, line_thick, color)
		
	elif accent_type == "\\underline":
		var y = measured_size.y - gap - line_thick
		OperatorDrawer.draw_fraction_line(self, Vector2(0, y), content_w, line_thick, color)
		
	elif accent_type == "\\vec":
		var y = gap + (font_size * 0.1)
		OperatorDrawer.draw_vec_arrow(self, Vector2(0, y), content_w, line_thick, color)
		
	elif accent_type == "\\hat":
		var y = gap
		var hat_w = min(content_w, font_size * 0.8)
		var x = (content_w - hat_w) / 2.0
		OperatorDrawer.draw_hat(self, Vector2(x, y), hat_w, line_thick, color)
