@tool
class_name MathContainer
extends MathElement

## Base class for elements that contain other MathElements 
## (e.g., Sequence, Fraction, Root, Matrix).

func measure(context: RenderContext) -> void:
    super.measure(context)
    # Containers typically measure their children first, 
    # then compute their own bounding box based on children.
    for child in get_children():
        if child is MathElement:
            child.measure(context)

func arrange(context: RenderContext, pos: Vector2) -> void:
    super.arrange(context, pos)
    # Children arrangement is specific to the container type 
    # (horizontal for Sequence, vertical for Fraction, etc.)