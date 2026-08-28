@tool
extends EditorPlugin

## Math Editor Plugin — entry point.
## Registers the Math Control node type and the custom Inspector plugin.

const MathNodeScript     = preload("res://addons/math_editor/nodes/math.gd")
const MathInspectorScript = preload("res://addons/math_editor/inspector/math_inspector.gd")

var _inspector_plugin: EditorInspectorPlugin


func _enter_tree() -> void:
    # Register "Math" so it appears in the Add Node dialog under Control.
    add_custom_type("Math", "Control", MathNodeScript, null)

    # Register the custom Inspector (formula input + Apply button).
    _inspector_plugin = MathInspectorScript.new()
    add_inspector_plugin(_inspector_plugin)


func _exit_tree() -> void:
    remove_custom_type("Math")

    if _inspector_plugin:
        remove_inspector_plugin(_inspector_plugin)
        _inspector_plugin = null