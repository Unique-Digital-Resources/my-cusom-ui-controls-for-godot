class_name NodeInfo
extends RefCounted

# Data class holding complete collected information for a single node

var node: Node
var node_type: String
var node_name: String

# Hierarchy
var parent_info: NodeInfo
var children_info: Array[NodeInfo] = []

# Resolved data
var properties: Dictionary = {}
var visibility: Dictionary = {}
var transform: Transform2D = Transform2D.IDENTITY
var global_position: Vector2 = Vector2.ZERO
var size: Vector2 = Vector2.ZERO

# Phase 3: Theme data
var resolved_theme: Dictionary = {}

# Phase 4: Layout data
var absolute_position: Vector2 = Vector2.ZERO
var absolute_transform: Transform2D = Transform2D.IDENTITY
var clip_rect: Rect2 = Rect2(0, 0, 0, 0)
var is_layout_only: bool = false

# Phase 14: Animation data
var animations: Array[RenderAnimation] = []

func _to_string() -> String:
    return "NodeInfo(%s [%s])" % [node_name, node_type]