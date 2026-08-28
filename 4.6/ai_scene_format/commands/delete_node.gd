@tool
class_name AICommandDeleteNode
extends RefCounted

## Deletes nodes from the Godot SceneTree.

static func execute(node: Node) -> void:
    if not node: return
    node.get_parent().remove_child(node)
    node.queue_free()