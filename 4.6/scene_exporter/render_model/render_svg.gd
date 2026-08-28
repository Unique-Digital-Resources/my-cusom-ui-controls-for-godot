class_name RenderSVG
extends RenderObject

# Represents a raw SVG string to be embedded directly into the output

var svg_data: String = ""

func _init():
	object_type = "svg"
