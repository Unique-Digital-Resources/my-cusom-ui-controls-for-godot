class_name VisibilityResolver
extends RefCounted

# Resolves visibility and clipping checks for nodes

func resolve(node: Node) -> Dictionary:
    var vis_data: Dictionary = {
        "is_visible_in_tree": false,
        "is_visible_self": false,
        "clip_contents": false,
        "clip_rect": Rect2(0, 0, 0, 0)
    }
    
    if node is CanvasItem:
        vis_data.is_visible_in_tree = node.is_visible_in_tree()
        vis_data.is_visible_self = node.visible
        
    if node is Control:
        vis_data.clip_contents = node.clip_contents
        vis_data.clip_rect = Rect2(node.position, node.size)
        
    return vis_data