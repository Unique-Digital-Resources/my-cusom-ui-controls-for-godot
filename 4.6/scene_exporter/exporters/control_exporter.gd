class_name ControlExporter
extends BaseExporter

# Generic exporter for Control nodes.
# In Phase 6, it simply creates the group and processes children.
# Later phases will add StyleBox, text, and image rendering.

func export_node(info: NodeInfo, context: ExportContext) -> RenderGroup:
    # Skip layout-only nodes (like Containers) from creating visual artifacts, 
    # but we still process their children.
    if info.is_layout_only:
        return super.export_node(info, context)
        
    var group = super.export_node(info, context)
    
    # Phase 8 will add StyleBox parsing here:
    # var stylebox_id = info.resolved_theme.styleboxes.get("panel", "")
    # if stylebox_id != "":
    #     var shape = RenderShape.new()
    #     shape.shape_type = "rounded_rect"
    #     shape.rect = Rect2(Vector2.ZERO, info.size)
    #     group.add_child(shape)
    
    return group