class_name RenderImage
extends RenderObject

# Represents an image primitive

var resource_id: String = ""
var rect: Rect2 = Rect2(0, 0, 0, 0)

func _init():
    object_type = "image"

func _to_string() -> String:
    return "RenderImage(res=%s, %s)" % [resource_id, node_name]