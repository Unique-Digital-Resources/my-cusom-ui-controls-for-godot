@tool
extends EditorPlugin

const DocumentEditorScene = preload("res://addons/markdown_document_engine/editor/document_editor.tscn")

var editor_control: Control

func _enter_tree() -> void:
	# For Phase 1, we just add it as a main screen panel so we can test it easily
	editor_control = DocumentEditorScene.instantiate()
	get_editor_interface().get_editor_main_screen().add_child(editor_control)
	_make_visible(false)

func _exit_tree() -> void:
	if editor_control:
		_make_visible(false)
		editor_control.queue_free()

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if editor_control:
		editor_control.visible = visible

func _get_plugin_name() -> String:
	return "DocEngine"
