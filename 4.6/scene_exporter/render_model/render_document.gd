class_name RenderDocument
extends RenderGroup

# Root document containing metadata and the base group

var width: float = 0.0
var height: float = 0.0
var background_color: Color = Color(0, 0, 0, 0)

func _init():
    object_type = "document"

func _to_string() -> String:
    return "RenderDocument(%dx%d, children=%d)" % [width, height, children.size()]