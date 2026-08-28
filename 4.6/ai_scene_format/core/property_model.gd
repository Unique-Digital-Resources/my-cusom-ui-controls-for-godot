class_name AIPropertyModel
extends RefCounted

## Represents a single editable property.
## Upgraded in Phase 9 to support recursive Arrays, Dictionaries, and nested resources.

var name: String
var value: Variant = null

# Type flags
var is_reference: bool = false
var reference: AIReference = null

var is_resource: bool = false
var resource: AIResourceModel = null

var is_array: bool = false
var is_dict: bool = false

# Used for Arrays and Dictionaries to hold their elements recursively
var sub_properties: Array[AIPropertyModel] = []

# PRD 12: Default Filtering
var is_default: bool = false

func _init(prop_name: String = "", prop_value: Variant = null) -> void:
    name = prop_name
    value = prop_value

func add_sub_property(prop: AIPropertyModel) -> void:
    sub_properties.append(prop)