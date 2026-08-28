@tool
class_name AICommandRenameNode
extends RefCounted

## Renames nodes in the Godot SceneTree.

static func execute(node: Node, new_name: String) -> void:
    if not node: return
    node.name = new_name