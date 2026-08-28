@tool
class_name AIPathResolver
extends RefCounted

## V2 Path Resolver.
## Maps logical string paths (e.g., "Root/MainMenu/PlayBtn") to Godot Node instances.
## This allows developers to rename or move nodes in the Godot editor without breaking
## the animations and interactions defined in the .aiui file.

static func resolve_path(root: Node, path: String) -> Node:
	if not root or path.is_empty(): return null
	
	# If it's the root, return it
	if path == root.get_meta("_ai_path", ""):
		return root
		
	# Search children recursively for the meta tag
	return _find_by_meta(root, path)

static func _find_by_meta(current: Node, path: String) -> Node:
	if current.get_meta("_ai_path", "") == path:
		return current
		
	for child in current.get_children():
		var found = _find_by_meta(child, path)
		if found:
			return found
			
	return null

# Assigns a logical path to a node and its children recursively
static func assign_paths(node: Node, current_path: String = "") -> void:
	var path = current_path
	if path.is_empty():
		path = node.name
	else:
		path = current_path + "/" + node.name
		
	node.set_meta("_ai_path", path)
	
	for child in node.get_children():
		assign_paths(child, path)
