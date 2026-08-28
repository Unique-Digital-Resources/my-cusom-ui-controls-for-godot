class_name AINodeModel
extends RefCounted

## Represents a single node in the internal editable scene representation.

var id: String                           # Stable unique ID
var type: String = "Node"                # e.g., "Button", "Node2D"
var name: String = "Node"                # Display name
var parent_id: String = ""               # Parent's stable ID (empty if root)

var child_ids: Array[String] = []        # Ordered list of children IDs

# Dictionary of String -> AIPropertyModel
var properties: Dictionary = {}

func add_child(child_id: String) -> void:
    if not child_id in child_ids:
        child_ids.append(child_id)

func remove_child(child_id: String) -> void:
    child_ids.erase(child_id)

func add_property(prop: AIPropertyModel) -> void:
    properties[prop.name] = prop

func get_property(prop_name: String) -> AIPropertyModel:
    return properties.get(prop_name)

func _to_string() -> String:
    return "Node(%s, %s)" % [type, name]