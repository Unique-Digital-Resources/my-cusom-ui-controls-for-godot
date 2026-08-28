@tool
class_name SVGStyleMapper
extends RefCounted

## Translates Godot StyleBoxFlat into SVG graphic elements.

static func map_stylebox(sb: StyleBoxFlat, size: Vector2, indent_level: int) -> String:
    var pad = "  ".repeat(indent_level)
    var svg = ""
    
    var w = size.x
    var h = size.y
    var rx = sb.corner_radius_top_left
    
    var shadow_attr = ""
    if sb.shadow_size > 0:
        shadow_attr = " filter=\"url(#godot_shadow)\""
        
    # 1. Draw Background Fill
    var bg_c = sb.bg_color
    var bg_rgb = SVGUtils.color_to_rgb(bg_c)
    svg += "%s<rect x=\"0\" y=\"0\" width=\"%s\" height=\"%s\" rx=\"%d\" fill=\"%s\" fill-opacity=\"%s\"%s />\n" % [
        pad, SVGUtils.fmt(w), SVGUtils.fmt(h), rx, bg_rgb, SVGUtils.fmt(bg_c.a), shadow_attr
    ]
    
    # 2. Draw Independent Borders (Inside the rect, like Godot)
    var b_c = sb.border_color
    var b_rgb = SVGUtils.color_to_rgb(b_c)
    var b_a = b_c.a
    
    if sb.border_width_left > 0:
        svg += "%s<rect x=\"0\" y=\"0\" width=\"%s\" height=\"%s\" fill=\"%s\" fill-opacity=\"%s\" />\n" % [
            pad, SVGUtils.fmt(sb.border_width_left), SVGUtils.fmt(h), b_rgb, SVGUtils.fmt(b_a)
        ]
    if sb.border_width_right > 0:
        var bx = w - sb.border_width_right
        svg += "%s<rect x=\"%s\" y=\"0\" width=\"%s\" height=\"%s\" fill=\"%s\" fill-opacity=\"%s\" />\n" % [
            pad, SVGUtils.fmt(bx), SVGUtils.fmt(sb.border_width_right), SVGUtils.fmt(h), b_rgb, SVGUtils.fmt(b_a)
        ]
    if sb.border_width_top > 0:
        svg += "%s<rect x=\"0\" y=\"0\" width=\"%s\" height=\"%s\" fill=\"%s\" fill-opacity=\"%s\" />\n" % [
            pad, SVGUtils.fmt(w), SVGUtils.fmt(sb.border_width_top), b_rgb, SVGUtils.fmt(b_a)
        ]
    if sb.border_width_bottom > 0:
        var by = h - sb.border_width_bottom
        svg += "%s<rect x=\"0\" y=\"%s\" width=\"%s\" height=\"%s\" fill=\"%s\" fill-opacity=\"%s\" />\n" % [
            pad, SVGUtils.fmt(by), SVGUtils.fmt(w), SVGUtils.fmt(sb.border_width_bottom), b_rgb, SVGUtils.fmt(b_a)
        ]
        
    return svg