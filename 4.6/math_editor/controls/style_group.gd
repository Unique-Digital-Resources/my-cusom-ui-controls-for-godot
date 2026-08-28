@tool
class_name StyleGroupControl
extends MathContainer

## Modifies the RenderContext for its children based on LaTeX-like commands.
## Supports \color, \size, \bold, \mathit, \mathbb, \mathcal, and \colorbox

var style_type: String = ""
var style_value: String = ""

func measure(context: RenderContext) -> void:
	var mod_ctx = _get_modified_context(context)
	super.measure(mod_ctx)
	
	var content = get_node_or_null("Content")
	if content:
		measured_size = content.measured_size
		baseline = content.baseline
	else:
		measured_size = Vector2.ZERO
		baseline = 0.0
		
	custom_minimum_size = measured_size
	size = measured_size

func arrange(context: RenderContext, pos: Vector2) -> void:
	var mod_ctx = _get_modified_context(context)
	super.arrange(mod_ctx, pos)
	
	var content = get_node_or_null("Content")
	if content:
		content.arrange(mod_ctx, Vector2.ZERO)

func _get_modified_context(context: RenderContext) -> RenderContext:
	var mod_ctx = context.copy()
	
	if style_type == "color":
		mod_ctx.color = Color(style_value)
	elif style_type == "size":
		mod_ctx.base_size *= float(style_value)
	elif style_type == "bold":
		mod_ctx.font = context.font_bold if context.font_bold else context.font
		mod_ctx.font_forced = true
	elif style_type == "italic":
		mod_ctx.font = context.font_italic if context.font_italic else context.font
		mod_ctx.font_forced = true
	elif style_type == "bold_italic":
		mod_ctx.font = context.font_bold_italic if context.font_bold_italic else context.font
		mod_ctx.font_forced = true
	elif style_type == "blackboard":
		# Use dedicated font if provided, otherwise flag for Unicode mapping
		if context.font_blackboard:
			mod_ctx.font = context.font_blackboard
			mod_ctx.font_forced = true
		else:
			mod_ctx.style_override = "blackboard"
	elif style_type == "caligraphic":
		if context.font_caligraphic:
			mod_ctx.font = context.font_caligraphic
			mod_ctx.font_forced = true
		else:
			mod_ctx.style_override = "caligraphic"
		
	return mod_ctx

func _draw() -> void:
	if style_type == "bgcolor":
		var bg_color = Color(style_value)
		draw_rect(Rect2(Vector2.ZERO, measured_size), bg_color)
