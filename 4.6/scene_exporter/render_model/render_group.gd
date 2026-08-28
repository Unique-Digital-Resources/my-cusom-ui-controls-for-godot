class_name RenderGroup
extends RenderObject

# Represents a hierarchical group of render objects (like a Godot Control)

var children: Array[RenderObject] = []

func _init():
    object_type = "group"

func add_child(child: RenderObject) -> void:
    children.append(child)

func _to_string() -> String:
    return "RenderGroup(%s, children=%d)" % [node_name, children.size()]