class_name AIReference
extends RefCounted

## Represents a reference to a Node, Resource, or File.
## Used inside the PropertyModel to maintain stable links.

enum Type {
    NODE,
    RESOURCE,
    FILE
}

var type: int = Type.NODE
var target_id: String = ""  # Used for Node and Resource references
var file_path: String = ""  # Used for File references

func _to_string() -> String:
    match type:
        Type.NODE: return "NodeRef(%s)" % target_id
        Type.RESOURCE: return "ResourceRef(%s)" % target_id
        Type.FILE: return "FileRef(%s)" % file_path
    return "UnknownRef"