class_name RenderAnimation
extends RefCounted

# Represents a serialized animation track for a specific render object

var target_property: String = "" # "opacity", "fill", "transform.translate", "transform.rotate", "transform.scale"
var keyframes: Array[Dictionary] = [] # {"time": float, "value": Variant}
var duration: float = 1.0
var loop: bool = true
var interpolation: String = "linear" # "linear", "discrete"

func _to_string() -> String:
    return "RenderAnimation(prop=%s, keys=%d)" % [target_property, keyframes.size()]