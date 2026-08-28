class_name AIResourceModel
extends RefCounted

## Represents a Godot Resource recursively.
## Upgraded in Phase 9 to handle Custom Resources and script paths.

var type: String = "Resource"             # e.g., "Material", "Shader", "Theme"
var script_path: String = ""              # For custom resource scripts
var id: String = ""                       # Stable ID for cross-document references

var properties: Dictionary = {}           # String -> AIPropertyModel

func add_property(prop: AIPropertyModel) -> void:
    properties[prop.name] = prop

func get_property(prop_name: String) -> AIPropertyModel:
    return properties.get(prop_name)

func _to_string() -> String:
    return "Resource(%s, %s)" % [type, id]