class_name RenderTransform
extends RefCounted

# Represents a 2D transformation

var origin: Vector2 = Vector2.ZERO
var rotation: float = 0.0
var scale: Vector2 = Vector2.ONE
var skew: Vector2 = Vector2.ZERO

func from_transform2d(t: Transform2D) -> void:
    # Extract translation
    origin = t.origin
    
    # Extract rotation, scale, and skew from the basis
    var sx = Vector2(t.x.x, t.y.x).length()
    var sy = Vector2(t.x.y, t.y.y).length()
    
    rotation = t.get_rotation()
    scale = Vector2(sx, sy)
    # Note: Skew extraction is complex, keeping it zero for now as standard controls rarely use skewed transforms.
    skew = Vector2.ZERO

func _to_string() -> String:
    return "RenderTransform(pos=%s, rot=%.2f, scale=%s)" % [origin, rad_to_deg(rotation), scale]