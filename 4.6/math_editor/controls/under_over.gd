@tool
class_name UnderOverControl
extends MathContainer

## Visual control for operators with limits (e.g., ∑, ∏, ∫, lim).

func measure(context: RenderContext) -> void:
	super.measure(context)
	
	var base = get_node_or_null("Base")
	var sup = get_node_or_null("Super")
	var sub = get_node_or_null("Sub")
	
	var base_w = 0.0
	var base_h = 0.0
	var base_asc = 0.0
	var sup_w = 0.0
	var sup_h = 0.0
	var sub_w = 0.0
	var sub_h = 0.0
	
	if base:
		base_w = base.measured_size.x
		base_h = base.measured_size.y
		base_asc = base.baseline
		
	var sub_ctx = context.get_scaled_context(context.script_scale)
	if sup:
		sup.measure(sub_ctx)
		sup_w = sup.measured_size.x
		sup_h = sup.measured_size.y
	if sub:
		sub.measure(sub_ctx)
		sub_w = sub.measured_size.x
		sub_h = sub.measured_size.y
		
	var font_size = context.get_font_size()
	# FIX: Uses the limit_gap property from the Math node
	var gap = font_size * context.limit_gap
	
	measured_size.x = max(base_w, max(sup_w, sub_w))
	
	var total_h = 0.0
	if sup:
		total_h += sup_h + gap
	total_h += base_h
	if sub:
		total_h += gap + sub_h
		
	measured_size.y = total_h
	
	baseline = 0.0
	if sup:
		baseline += sup_h + gap
	baseline += base_asc
	
	custom_minimum_size = measured_size
	size = measured_size

func arrange(context: RenderContext, pos: Vector2) -> void:
	super.arrange(context, pos)
	
	var base = get_node_or_null("Base")
	var sup = get_node_or_null("Super")
	var sub = get_node_or_null("Sub")
	
	var sub_ctx = context.get_scaled_context(context.script_scale)
	var font_size = context.get_font_size()
	var gap = font_size * context.limit_gap
	
	var current_y = 0.0
	
	if sup:
		var sup_x = (measured_size.x - sup.measured_size.x) / 2.0
		sup.arrange(sub_ctx, Vector2(sup_x, current_y))
		current_y += sup.measured_size.y + gap
		
	if base:
		var base_x = (measured_size.x - base.measured_size.x) / 2.0
		base.arrange(context, Vector2(base_x, current_y))
		current_y += base.measured_size.y + gap
		
	if sub:
		var sub_x = (measured_size.x - sub.measured_size.x) / 2.0
		sub.arrange(sub_ctx, Vector2(sub_x, current_y))
