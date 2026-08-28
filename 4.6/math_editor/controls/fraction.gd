@tool
class_name FractionControl
extends MathContainer

## Visual control for rendering fractions.

var _context: RenderContext

func measure(context: RenderContext) -> void:
	_context = context
	super.measure(context)
	
	var num = get_node_or_null("Numerator")
	var den = get_node_or_null("Denominator")
	
	var num_w = 0.0
	var num_h = 0.0
	var den_w = 0.0
	var den_h = 0.0
	
	if num:
		num_w = num.measured_size.x
		num_h = num.measured_size.y
	if den:
		den_w = den.measured_size.x
		den_h = den.measured_size.y
		
	var font_size = context.get_font_size()
	var line_thick = font_size * _context.line_thickness
	var gap = font_size * 0.2 
	
	measured_size.x = max(num_w, den_w)
	measured_size.y = num_h + den_h + line_thick + (gap * 2.0)
	baseline = num_h + gap + (line_thick / 2.0)
	
	custom_minimum_size = measured_size
	size = measured_size

func arrange(context: RenderContext, pos: Vector2) -> void:
	super.arrange(context, pos)
	
	var num = get_node_or_null("Numerator")
	var den = get_node_or_null("Denominator")
	
	var num_h = num.measured_size.y if num else 0.0
	var font_size = context.get_font_size()
	var line_thick = font_size * _context.line_thickness
	var gap = font_size * 0.2
	
	if num:
		var num_x = (measured_size.x - num.measured_size.x) / 2.0
		num.arrange(context, Vector2(num_x, 0.0))
		
	if den:
		var den_x = (measured_size.x - den.measured_size.x) / 2.0
		var den_y = num_h + (gap * 2.0) + line_thick
		den.arrange(context, Vector2(den_x, den_y))

func _draw() -> void:
	if not _context:
		return
		
	var font_size = _context.get_font_size()
	var line_thick = font_size * _context.line_thickness
	var gap = font_size * 0.2
	
	var num = get_node_or_null("Numerator")
	var num_h = num.measured_size.y if num else 0.0
	
	var line_y = num_h + gap + (line_thick / 2.0)
	OperatorDrawer.draw_fraction_line(self, Vector2(0, line_y - (line_thick / 2.0)), measured_size.x, line_thick, _context.color)
