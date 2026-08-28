@tool
class_name AITreeUtils
extends RefCounted

## SceneTree helpers for finding nodes and managing hierarchy.

static func get_node_path_string(node: Node) -> String:
	if not node: return ""
	return node.get_path()

static func find_node_by_path(root: Node, path: String) -> Node:
	if not root or path.is_empty(): return null
	if NodePath(path) == root.get_path(): return root
	return root.get_node_or_null(NodePath(path))
