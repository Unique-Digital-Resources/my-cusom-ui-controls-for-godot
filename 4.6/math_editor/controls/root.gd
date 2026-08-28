@tool
class_name RootControl
extends MathContainer

## Visual control for rendering square roots and nth roots.

var _context: RenderContext

func measure(context: RenderContext) -> void:
	_context = context
	super.measure(context)
	
	var rad = get_node_or_null("Radicand")
	var idx = get_node_or_null("Index")
	
	var rad_w = 0.0
	var rad_h = 0.0
	var rad_asc = 0.0
	var idx_w = 0.0
	var idx_h = 0.0
	
	if rad:
		rad_w = rad.measured_size.x
		rad_h = rad.measured_size.y
		rad_asc = rad.baseline
		
	var sub_ctx = context.get_scaled_context(_context.script_scale)
	if idx:
		idx.measure(sub_ctx)
		idx_w = idx.measured_size.x
		idx_h = idx.measured_size.y
		
	var font_size = context.get_font_size()
	var padding = font_size * 0.1
	var hook_width = font_size * 0.6
	
	measured_size.x = idx_w + hook_width + rad_w + (padding * 2.0)
	
	var top_y = min(0.0, -padding)
	var bottom_y = max(rad_h + padding, idx_h * 0.5)
	
	measured_size.y = bottom_y - top_y
	baseline = rad_asc + padding - top_y
	
	custom_minimum_size = measured_size
	size = measured_size

func arrange(context: RenderContext, pos: Vector2) -> void:
	super.arrange(context, pos)
	
	var rad = get_node_or_null("Radicand")
	var idx = get_node_or_null("Index")
	
	var font_size = context.get_font_size()
	var padding = font_size * 0.1
	var hook_width = font_size * 0.6
	
	var rad_baseline = rad.baseline if rad else 0.0
	var y_shift = baseline - (rad_baseline + padding)
	
	var current_x = 0.0
	var sub_ctx = context.get_scaled_context(_context.script_scale)
	
	if idx:
		var idx_y = y_shift - (idx.measured_size.y * 0.5)
		idx.arrange(sub_ctx, Vector2(current_x, idx_y))
		current_x += idx.measured_size.x
		
	if rad:
		var rad_x = current_x + hook_width + padding
		var rad_y = y_shift
		rad.arrange(context, Vector2(rad_x, rad_y))

func _draw() -> void:
	if not _context:
		return
		
	var rad = get_node_or_null("Radicand")
	var idx = get_node_or_null("Index")
	
	var font_size = _context.get_font_size()
	var padding = font_size * 0.1
	var hook_width = font_size * 0.6
	var line_thick = font_size * _context.line_thickness
	
	var idx_w = idx.measured_size.x if idx else 0.0
	var rad_w = rad.measured_size.x if rad else 0.0
	
	var hook_x = idx_w
	var rad_x = hook_x + hook_width
	
	var bar_end_x = rad_x + rad_w + padding
	
	var rad_h = rad.measured_size.y if rad else font_size
	var rad_baseline = rad.baseline if rad else 0.0
	var y_shift = baseline - (rad_baseline + padding)
	
	var top_y = -padding + y_shift
	var bottom_y = rad_h + padding + y_shift
	
	# FIX: Pass hook_x and bar_end_x to the updated drawer
	OperatorDrawer.draw_root_sign(
		self, 
		hook_x, 
		bar_end_x, 
		top_y, 
		bottom_y, 
		hook_width, 
		line_thick, 
		_context.color
	)
