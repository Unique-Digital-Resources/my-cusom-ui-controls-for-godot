@tool
class_name ScriptControl
extends MathContainer

## Visual control for superscripts and subscripts.

func measure(context: RenderContext) -> void:
	super.measure(context)
	
	var base = get_node_or_null("Base")
	var sup = get_node_or_null("Super")
	var sub = get_node_or_null("Sub")
	
	var base_w = 0.0
	var base_h = 0.0
	var base_asc = 0.0
	var base_desc = 0.0
	var sup_w = 0.0
	var sup_h = 0.0
	var sup_asc = 0.0
	var sub_w = 0.0
	var sub_h = 0.0
	var sub_asc = 0.0
	
	if base:
		base_w = base.measured_size.x
		base_h = base.measured_size.y
		base_asc = base.baseline
		base_desc = base_h - base_asc
		
	var sub_ctx = context.get_scaled_context(context.script_scale)
	if sup:
		sup.measure(sub_ctx)
		sup_w = sup.measured_size.x
		sup_h = sup.measured_size.y
		sup_asc = sup.baseline
	if sub:
		sub.measure(sub_ctx)
		sub_w = sub.measured_size.x
		sub_h = sub.measured_size.y
		sub_asc = sub.baseline
		
	measured_size.x = base_w + max(sup_w, sub_w)
	
	# FIX: Uses exact limit_gap value without halving it
	var gap = context.get_font_size() * context.limit_gap
	
	var top_y = 0.0
	if sup:
		var sup_baseline_y = base_asc - (base_asc * 0.5)
		top_y = min(0.0, sup_baseline_y - sup_asc - gap)
		
	var bottom_y = base_h
	if sub:
		var sub_baseline_y = base_asc + (base_desc * 0.5)
		bottom_y = max(bottom_y, sub_baseline_y + (sub_h - sub_asc) + gap)
		
	measured_size.y = bottom_y - top_y
	baseline = base_asc - top_y
	
	custom_minimum_size = measured_size
	size = measured_size

func arrange(context: RenderContext, pos: Vector2) -> void:
	super.arrange(context, pos)
	
	var base = get_node_or_null("Base")
	var sup = get_node_or_null("Super")
	var sub = get_node_or_null("Sub")
	
	var base_asc = base.baseline if base else 0.0
	var base_desc = (base.measured_size.y - base_asc) if base else 0.0
	var y_shift = baseline - base_asc 
	var sub_ctx = context.get_scaled_context(context.script_scale)
	var x_offset = base.measured_size.x if base else 0.0
	var gap = context.get_font_size() * context.limit_gap
	
	if base:
		base.arrange(context, Vector2(0, y_shift))
	if sup:
		var sup_baseline_y = base_asc - (base_asc * 0.5)
		var sup_y = sup_baseline_y - sup.baseline + y_shift - gap
		sup.arrange(sub_ctx, Vector2(x_offset, sup_y))
	if sub:
		var sub_baseline_y = base_asc + (base_desc * 0.5)
		var sub_y = sub_baseline_y - sub.baseline + y_shift + gap
		sub.arrange(sub_ctx, Vector2(x_offset, sub_y))
