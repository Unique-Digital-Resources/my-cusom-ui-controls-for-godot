@tool
class_name AICommandCreateNode
extends RefCounted

## Creates nodes in the Godot SceneTree.

static func execute(parent: Node, node_type: String, node_name: String) -> Node:
    if not ClassDB.class_exists(node_type):
        push_error("AI Scene Format: Cannot create unknown node type: " + node_type)
        return null
        
    var node = ClassDB.instantiate(node_type)
    node.name = node_name
    parent.add_child(node)
    node.owner = parent.owner if parent.owner else parent
    return node