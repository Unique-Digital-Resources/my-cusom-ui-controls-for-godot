class_name LayoutSolver
extends RefCounted

# Computes the final layout for the entire NodeInfo tree.
# Determines absolute x, y, width, height, clip, and transform.

var anchor_solver: AnchorSolver
var container_solver: ContainerSolver
var transform_solver: TransformSolver
var clip_solver: ClipSolver

func _init():
    anchor_solver = AnchorSolver.new()
    container_solver = ContainerSolver.new()
    transform_solver = TransformSolver.new()
    clip_solver = ClipSolver.new()

func solve(root_info: NodeInfo) -> void:
    ExportUtils.log_message("Calculating layout geometry...")
    _solve_node(root_info, Rect2(0, 0, 0, 0))

func _solve_node(info: NodeInfo, parent_clip: Rect2) -> void:
    if info.node is Control:
        # 1. Resolve absolute geometry
        info.absolute_position = anchor_solver.resolve(info)
        
        # 2. Resolve container flags
        container_solver.resolve(info)
        
        # 3. Resolve transform
        info.absolute_transform = transform_solver.resolve(info)
        
        # 4. Resolve clipping (must happen after absolute position is known)
        info.clip_rect = clip_solver.resolve(info, parent_clip)
    else:
        # Non-controls (future Node2D support) just inherit clip
        info.clip_rect = parent_clip
        
    # Process children recursively
    for child in info.children_info:
        _solve_node(child, info.clip_rect)