@tool
class_name SymbolDrawer
extends RefCounted

## Static utility for drawing text glyphs.
## Future phases will expand this to handle custom vector glyphs or fallback fonts.

static func draw_symbol(canvas: CanvasItem, font: Font, text: String, pos: Vector2, size: int, color: Color) -> void:
    if not font:
        return
        
    # pos represents the top-left of the glyph box, but baseline is required for draw_string
    # However, in our arrange() logic, child_y is calculated such that pos.y is top-left.
    # Godot's draw_string expects the baseline Y coordinate.
    var baseline_pos = Vector2(pos.x, pos.y)
    canvas.draw_string(font, baseline_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)