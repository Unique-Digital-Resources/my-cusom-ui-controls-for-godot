class_name ClipSolver
extends RefCounted

# Calculates the clipping region for a node.
# If a node has 'clip_contents' enabled, its children are clipped to its rect.
# Otherwise, it inherits the parent's clip rect.

func resolve(info: NodeInfo, parent_clip: Rect2) -> Rect2:
    if not info.node is Control:
        return parent_clip

    var node_rect = Rect2(info.absolute_position, info.size)
    
    if info.properties.get("clip_contents", false):
        if parent_clip.has_area():
            # Intersect with parent clip if parent was also clipping
            return parent_clip.intersection(node_rect)
        else:
            return node_rect
    
    # Not clipping, pass parent's clip down
    return parent_clip