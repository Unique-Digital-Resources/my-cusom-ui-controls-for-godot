@tool
extends EditorPlugin

var timeline_dock: Control
var editor_selection: EditorSelection

func _enter_tree() -> void:
    var dock_script = load("res://addons/pro_timeline_dock/ui/timeline_dock.gd")
    timeline_dock = dock_script.new()
    add_control_to_bottom_panel(timeline_dock, "Pro Timeline")
    
    # Connect to editor selection to detect AnimationPlayers
    editor_selection = get_editor_interface().get_selection()
    editor_selection.selection_changed.connect(_on_selection_changed)

func _exit_tree() -> void:
    if timeline_dock:
        remove_control_from_bottom_panel(timeline_dock)
        timeline_dock.queue_free()
    if editor_selection:
        editor_selection.selection_changed.disconnect(_on_selection_changed)

func _on_selection_changed() -> void:
    var selected = editor_selection.get_selected_nodes()
    if selected.size() == 1 and selected[0] is AnimationPlayer:
        var player = selected[0] as AnimationPlayer
        if timeline_dock.has_method("set_animation_player"):
            timeline_dock.set_animation_player(player)