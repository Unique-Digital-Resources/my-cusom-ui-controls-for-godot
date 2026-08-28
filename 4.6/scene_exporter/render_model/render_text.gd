class_name RenderText
extends RenderObject

# Represents a text primitive

var text: String = ""
var position: Vector2 = Vector2.ZERO
var alignment: String = "left" # "left", "center", "right"

func _init():
    object_type = "text"

func _to_string() -> String:
    return "RenderText('%s', %s)" % [text.substr(0, 10), node_name]