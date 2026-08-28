@tool
class_name AIFileUtils
extends RefCounted

## Handles file operations for saving and loading AI Scene Format documents.
## Ensures directories exist and handles UTF-8 text encoding.

# Writes text to a file, creating directories if necessary.
static func save_text(path: String, text: String) -> Error:
    # Ensure the target directory exists
    var dir_path = path.get_base_dir()
    if not DirAccess.dir_exists_absolute(dir_path):
        var mk_err = DirAccess.make_dir_recursive_absolute(dir_path)
        if mk_err != OK:
            push_error("AI Scene Format: Failed to create directory '%s'. Error: %d" % [dir_path, mk_err])
            return mk_err

    var file = FileAccess.open(path, FileAccess.WRITE)
    if not file:
        push_error("AI Scene Format: Failed to open file for writing: '%s'. Error: %d" % [path, FileAccess.get_open_error()])
        return FileAccess.get_open_error()

    file.store_string(text)
    file.close()
    return OK

# Reads text from a file.
static func load_text(path: String) -> String:
    if not FileAccess.file_exists(path):
        push_error("AI Scene Format: File does not exist: '%s'." % path)
        return ""

    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        push_error("AI Scene Format: Failed to open file for reading: '%s'. Error: %d" % [path, FileAccess.get_open_error()])
        return ""

    var text = file.get_as_text()
    file.close()
    return text

# Checks if a file exists.
static func file_exists(path: String) -> bool:
    return FileAccess.file_exists(path)

# Generates a standardized document file path based on scene and node.
# Example: res://ai_docs/MainScene_Button_Layout.ailayout
static func generate_doc_path(base_dir: String, scene_name: String, node_name: String, extension: String) -> String:
    if not extension.begins_with("."):
        extension = "." + extension
        
    # Sanitize names to be filesystem-safe
    var safe_scene = scene_name.to_pascal_case()
    var safe_node = node_name.to_pascal_case()
    
    var file_name = "%s_%s%s" % [safe_scene, safe_node, extension]
    
    # Ensure base directory doesn't double up slashes
    if base_dir.is_empty():
        base_dir = "res://"
    elif not base_dir.ends_with("/"):
        base_dir += "/"
        
    return base_dir + file_name