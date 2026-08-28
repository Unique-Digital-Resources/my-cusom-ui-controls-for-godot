@tool
class_name AIInteractionExporter
extends RefCounted

## V2 Interaction Exporter.
## Applies an array of Interaction Dictionaries back onto a Godot Node's metadata.

static func apply_changes(root_node: Node, interactions: Array) -> void:
	if not root_node: return
	
	# FIX: Group interactions by their target node path
	var interactions_by_path = {}
	for interaction in interactions:
		var target_path = interaction.get("target_id", "")
		if not interactions_by_path.has(target_path):
			interactions_by_path[target_path] = []
		interactions_by_path[target_path].append(interaction)
		
	# FIX: Resolve paths and apply metadata using AIPathResolver
	for path in interactions_by_path.keys():
		var target_node = AIPathResolver.resolve_path(root_node, path)
		if target_node:
			target_node.set_meta(AIInteractionImporter.META_KEY, interactions_by_path[path])
			target_node.notify_property_list_changed()
		else:
			push_warning("AI Scene Format V2: Could not find interaction target node at path: " + path)
		
	EditorInterface.mark_scene_as_unsaved()
