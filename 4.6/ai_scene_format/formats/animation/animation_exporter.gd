@tool
class_name AIAnimationExporter
extends RefCounted

## V2 Animation Builder.

# FIX: Added root_node parameter to resolve absolute paths correctly
static func apply_animations(player: AnimationPlayer, animations: Array, root_node: Node) -> void:
	if not player: return
	
	var lib: AnimationLibrary = null
	if player.has_animation_library(""): lib = player.get_animation_library("")
	else:
		lib = AnimationLibrary.new()
		player.add_animation_library("", lib)
		
	for anim_name in lib.get_animation_list().duplicate(): lib.remove_animation(anim_name)
		
	for anim in animations:
		var godot_anim = Animation.new()
		godot_anim.length = anim.length
		godot_anim.loop_mode = Animation.LOOP_LINEAR if anim.loop else Animation.LOOP_NONE
		
		var player_root_node = player.get_node_or_null(player.root_node)
		if not player_root_node:
			player_root_node = player.get_parent()
		
		for track in anim.tracks:
			var track_idx = godot_anim.add_track(track.type)
			
			var raw_path = track.path
			var node_part = raw_path
			var prop_part = ""
			if raw_path.contains(":"):
				var last_colon = raw_path.rfind(":")
				node_part = raw_path.substr(0, last_colon)
				prop_part = raw_path.substr(last_colon)
				
			# FIX: Resolve paths from the absolute root_node, not the player's parent
			var resolved_node = AIPathResolver.resolve_path(root_node, node_part)
			var final_path = node_part
			
			if resolved_node:
				final_path = str(player_root_node.get_path_to(resolved_node))
				if not prop_part.is_empty():
					final_path += prop_part
			else:
				push_warning("AI Scene Format V2: Could not find node '" + node_part + "' for animation track. Is it missing from the tree?")
				
			godot_anim.track_set_path(track_idx, NodePath(final_path))
			godot_anim.track_set_interpolation_type(track_idx, track.interp)
			
			for key in track.keyframes:
				if track.type == Animation.TYPE_AUDIO:
					var audio_path = key.value
					if audio_path is Dictionary and audio_path.has("path"):
						audio_path = audio_path["path"]
						
					if audio_path is String and audio_path.begins_with("res://"):
						var stream = load(audio_path)
						if stream is AudioStream:
							godot_anim.audio_track_insert_key(track_idx, key.time, stream, 0.0, 0.0)
						else:
							push_warning("AI Scene Format: Invalid audio stream at path: " + audio_path)
				else:
					if key.value == null: continue
					if typeof(key.value) == TYPE_DICTIONARY: continue
						
					var key_idx = godot_anim.track_insert_key(track_idx, key.time, key.value)
					godot_anim.track_set_key_transition(track_idx, key_idx, 1.0)
				
		lib.add_animation(anim.name, godot_anim)
		
	player.notify_property_list_changed()
