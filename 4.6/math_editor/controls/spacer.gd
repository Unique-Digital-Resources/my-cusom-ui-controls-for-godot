@tool
class_name SpacerControl
extends MathElement

## An invisible element that inserts horizontal whitespace.
## Used for manual spacing commands like \quad, \,, \;, etc.

var em_width: float = 0.0

func measure(context: RenderContext) -> void:
	super.measure(context)
	var font_size = context.get_font_size()
	measured_size = Vector2(font_size * em_width, 0.0)
	baseline = 0.0
	custom_minimum_size = measured_size
	size = measured_size

func arrange(context: RenderContext, pos: Vector2) -> void:
	super.arrange(context, pos)
