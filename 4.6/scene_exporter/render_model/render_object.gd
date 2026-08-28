class_name RenderObject
extends RefCounted

# Base class for all renderable objects in the render model

var object_type: String = "base"
var id: String = ""
var node_name: String = ""

var transform: RenderTransform = RenderTransform.new()
var style: RenderStyle = RenderStyle.new()
var clip: RenderClip = null
var visible: bool = true

var animations: Array[RenderAnimation] = [] # Phase 14

func _to_string() -> String:
    return "RenderObject(%s, %s)" % [object_type, node_name]