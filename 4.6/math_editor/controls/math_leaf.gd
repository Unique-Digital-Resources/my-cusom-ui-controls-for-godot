@tool
class_name MathLeaf
extends MathElement

## Base class for elements with no MathElement children 
## (e.g., Symbol, Number, Operator).

# Leaf nodes store their text representation for drawing and measuring
var text: String = ""

func measure(context: RenderContext) -> void:
    super.measure(context)
    if text.is_empty():
        measured_size = Vector2.ZERO
        baseline = 0.0
        return
        
    var font = context.style.font
    var size = context.get_font_size()
    
    measured_size = FontMetrics.get_text_size(text, font, size)
    baseline = FontMetrics.get_ascent(font, size)
    
    # Update the Godot Control size so mouse interactions and clipping work
    custom_minimum_size = measured_size
    size = measured_size

func arrange(context: RenderContext, pos: Vector2) -> void:
    super.arrange(context, pos)
    # Leaf nodes don't need to arrange children, just update their position
    position = pos