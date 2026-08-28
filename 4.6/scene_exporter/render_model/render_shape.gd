class_name RenderShape
extends RenderObject

# Represents a shape primitive (Rectangle, Rounded Rectangle, Circle, Path)

var shape_type: String = "rect" # "rect", "rounded_rect", "circle", "path"
var rect: Rect2 = Rect2(0, 0, 0, 0)
var corner_radius: float = 0.0
var path: PackedVector2Array = []
var clip_id: String = "" # Applied to this shape (e.g., for borders)
var defines_clip_id: String = "" # Defines a clipPath for children/borders, but doesn't apply to this shape

func _init():
	object_type = "shape"

func _to_string() -> String:
	return "RenderShape(%s, %s)" % [shape_type, node_name]
