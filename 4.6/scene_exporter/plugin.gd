@tool
extends EditorPlugin

var dock

func _enter_tree():
    dock = preload("res://addons/scene_exporter/ui/export_dock.tscn").instantiate()
    add_control_to_dock(DOCK_SLOT_RIGHT_UR, dock)
    ExportUtils.log_message("Scene to SVG Exporter plugin loaded.")

func _exit_tree():
    if dock:
        remove_control_from_docks(dock)
        dock.free()

# Fix: Godot calls this automatically whenever the active scene changes
func _scene_changed(scene_root: Node):
    if dock and dock.has_method("_refresh_scene_info"):
        dock._refresh_scene_info()

# Fix: Godot calls this automatically when a scene is closed
func _scene_closed(filepath: String):
    if dock and dock.has_method("_refresh_scene_info"):
        dock._refresh_scene_info()