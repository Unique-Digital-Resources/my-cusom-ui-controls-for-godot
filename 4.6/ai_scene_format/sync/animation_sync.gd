@tool
class_name AIAnimationSync
extends RefCounted

## V2 Animation Sync.
## Orchestrates finding the correct AnimationPlayer and applying animations.

static func apply_to_player(root: Node, player_path: String, anims: Array) -> void:
	var player = AIPathResolver.resolve_path(root, player_path)
	if player is AnimationPlayer:
		AIAnimationExporter.apply_animations(player, anims)
		EditorInterface.mark_scene_as_unsaved()
	else:
		push_warning("AI Scene Format V2: AnimationPlayer not found at path: " + player_path)
