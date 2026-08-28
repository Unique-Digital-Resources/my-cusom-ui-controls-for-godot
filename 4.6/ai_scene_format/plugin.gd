@tool
extends EditorPlugin

const DockScene = preload("res://addons/ai_scene_format/dock/editor_dock.tscn")
var dock: Control

func _enter_tree() -> void:
    # Add the main dock to the editor
    dock = DockScene.instantiate()
    add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
    
    # Notify the dock that it has been added to the editor
    if dock.has_method("_on_editor_ready"):
        dock._on_editor_ready()

func _exit_tree() -> void:
    # Clean up the dock
    if dock:
        remove_control_from_docks(dock)
        dock.queue_free()
        dock = null