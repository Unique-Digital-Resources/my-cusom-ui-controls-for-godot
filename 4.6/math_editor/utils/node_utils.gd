class_name MathNodeUtils
extends RefCounted

## Shared helper code for node tree operations.

## Recursively sets the owner of a node and all its children to the given root.
## Essential for saving dynamically generated nodes in the editor.
static func set_owner_recursive(node: Node, root: Node) -> void:
    if node == root: 
        return
    node.owner = root
    for child in node.get_children():
        set_owner_recursive(child, root)

## Safely frees and removes all children from a node.
static func clear_children(node: Node) -> void:
    for child in node.get_children():
        node.remove_child(child)
        child.queue_free()