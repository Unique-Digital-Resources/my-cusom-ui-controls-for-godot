@tool
class_name AISelectionSync
extends RefCounted

## Reacts to editor selection changes to trigger document generation.

signal selection_changed(node: Node)

var editor_selection: EditorSelection

func setup() -> void:
    if not Engine.is_editor_hint(): return
    editor_selection = EditorInterface.get_selection()
    if editor_selection:
        if not editor_selection.selection_changed.is_connected(_on_selection_changed):
            editor_selection.selection_changed.connect(_on_selection_changed)
        _on_selection_changed()

func _on_selection_changed() -> void:
    if not editor_selection: return
    var selected_nodes = editor_selection.get_selected_nodes()
    if selected_nodes.is_empty():
        selection_changed.emit(null)
    else:
        selection_changed.emit(selected_nodes[0])