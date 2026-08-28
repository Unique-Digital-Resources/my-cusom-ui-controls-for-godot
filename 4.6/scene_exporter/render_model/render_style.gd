class_name RenderStyle
extends RefCounted

# Represents visual styling (fill, stroke, font, opacity, shadow, modulate)

var fill_color: Color = Color(0, 0, 0, 0)
var stroke_color: Color = Color(0, 0, 0, 0)
var stroke_width: float = 0.0
var opacity: float = 1.0

# Text specific
var font_resource_id: String = ""
var font_size: int = 16
var text_color: Color = Color.BLACK

# Shadow specific
var shadow_color: Color = Color(0, 0, 0, 0)
var shadow_size: float = 0.0
var shadow_offset: Vector2 = Vector2.ZERO
var shadow_id: String = ""

# Modulate specific
var modulate_color: Color = Color.WHITE
var modulate_id: String = ""

func _to_string() -> String:
	return "RenderStyle(fill=%s, stroke=%s, width=%.1f)" % [fill_color.to_html(), stroke_color.to_html(), stroke_width]
