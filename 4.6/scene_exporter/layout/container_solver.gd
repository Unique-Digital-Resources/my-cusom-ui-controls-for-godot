class_name ContainerSolver
extends RefCounted

# Handles Container nodes (VBox, HBox, Grid, Flow, etc.).
# Godot's engine automatically resolves the final global_position and size of children.
# This solver flags them so the render model skips drawing them (unless it's a PanelContainer)
# and extracts container-specific layout properties for potential debug/export.

const CONTAINER_TYPES: Array[String] = [
    "Container", "VBoxContainer", "HBoxContainer", "GridContainer", "FlowContainer", 
    "MarginContainer", "PanelContainer", "ScrollContainer", "SplitContainer", 
    "TabContainer"
]

func resolve(info: NodeInfo) -> void:
    if CONTAINER_TYPES.has(info.node_type):
        info.is_layout_only = true
        
        # Extract container-specific layout properties for potential debug/export
        if "separation" in info.node:
            info.properties["container_separation"] = info.node.get("separation")
        if "alignment" in info.node:
            info.properties["container_alignment"] = info.node.get("alignment")
            
        # Grab specific layout constants from theme if available (e.g., MarginContainer)
        if info.node_type == "MarginContainer":
            info.properties["margin_left"] = info.node.get_theme_constant("margin_left")
            info.properties["margin_top"] = info.node.get_theme_constant("margin_top")
            info.properties["margin_right"] = info.node.get_theme_constant("margin_right")
            info.properties["margin_bottom"] = info.node.get_theme_constant("margin_bottom")