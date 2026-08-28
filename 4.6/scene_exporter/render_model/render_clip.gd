class_name RenderClip
extends RefCounted

# Represents a clipping region applied to render objects

var clip_type: String = "rect" # "rect" or "path"
var rect: Rect2 = Rect2(0, 0, 0, 0)
var path: PackedVector2Array = []
var id: String = "" # Filled by SVGDefsWriter

func _to_string() -> String:
    if clip_type == "rect":
        return "RenderClip(rect=%s)" % rect
    return "RenderClip(path_size=%d)" % path.size()