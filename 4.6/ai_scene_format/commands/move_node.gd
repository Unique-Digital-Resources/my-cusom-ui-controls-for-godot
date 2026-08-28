@tool
class_name AICommandMoveNode
extends RefCounted

## Moves/reparents nodes in the Godot SceneTree.

static func execute(node: Node, new_parent: Node, new_index: int = -1) -> void:
    if not node or not new_parent: return
    
    var current_parent = node.get_parent()
    if current_parent:
        current_parent.remove_child(node)
        
    if new_index == -1:
        new_parent.add_child(node)
    else:
        new_parent.add_child(node)
        new_parent.move_child(node, new_index)
        
    # Ensure ownership is maintained
    if new_parent.owner:
        node.owner = new_parent.owner