@tool
class_name AITweenExporter
extends RefCounted

## V2 Tween Exporter.
## Applies an array of Tween Dictionaries back onto a Godot Node's metadata.

static func apply_changes(root_node: Node, tweens: Array) -> void:
	if not root_node: return
	
	var tweens_by_path = {}
	for tween in tweens:
		var target_path = tween.get("target_id", "")
		if not tweens_by_path.has(target_path):
			tweens_by_path[target_path] = []
		tweens_by_path[target_path].append(tween)
		
	for path in tweens_by_path.keys():
		var target_node = AIPathResolver.resolve_path(root_node, path)
		if target_node:
			print("AI Scene Format: Setting tween metadata on ", target_node.name)
			target_node.set_meta(AITweenImporter.META_KEY, tweens_by_path[path])
			target_node.notify_property_list_changed()
		else:
			push_warning("AI Scene Format V2: Could not find tween target node at path: " + path)
			# DEBUG: Dump the tree to see what paths actually exist
			print("--- AI Scene Format DEBUG: Tree Dump ---")
			_dump_tree(root_node, 0)
			print("---------------------------------------")
		
	EditorInterface.mark_scene_as_unsaved()

static func _dump_tree(node: Node, indent: int) -> void:
	var spaces = " ".repeat(indent * 4)
	var path = node.get_meta("_ai_path", "NO_META")
	print("%s%s (Path: %s)" % [spaces, node.name, path])
	for child in node.get_children():
		_dump_tree(child, indent + 1)
