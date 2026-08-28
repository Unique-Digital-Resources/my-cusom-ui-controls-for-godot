class_name AnimationResolver
extends RefCounted

# Extracts animation tracks from AnimationPlayers in the scene 
# and assigns them to the corresponding NodeInfo objects.

func resolve(root_node: Node, root_info: NodeInfo) -> void:
	var players = root_node.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
		
	var node_map: Dictionary = {}
	_build_node_map(root_info, node_map)
	
	for player in players:
		for anim_name in player.get_animation_list():
			if anim_name in ["RESET", "travel", "idle"]: continue
			var anim = player.get_animation(anim_name)
			if anim == null: continue
			
			for track_idx in range(anim.get_track_count()):
				var path = anim.track_get_path(track_idx)
				if path.get_subname_count() == 0: continue
				
				var node_path = NodePath(path.get_concatenated_names())
				var prop_path = String(path.get_concatenated_subnames())
				var target_node = player.get_node_or_null(node_path)
				
				if target_node and node_map.has(target_node):
					var info = node_map[target_node]
					var render_anim = _convert_track(anim, track_idx, prop_path, anim.length)
					if render_anim:
						info.animations.append(render_anim)

func _build_node_map(info: NodeInfo, map: Dictionary) -> void:
	map[info.node] = info
	for child in info.children_info:
		_build_node_map(child, map)

func _convert_track(anim: Animation, track_idx: int, prop_path: String, duration: float) -> RenderAnimation:
	var render_anim = RenderAnimation.new()
	render_anim.duration = duration
	
	# Fix: Explicitly map X and Y position tracks so HTML writer can use 'left' and 'top'
	match prop_path:
		"position": render_anim.target_property = "transform.translate"
		"position:x": render_anim.target_property = "transform.translate.x"
		"position:y": render_anim.target_property = "transform.translate.y"
		"rotation": render_anim.target_property = "transform.rotate"
		"scale": render_anim.target_property = "transform.scale"
		"modulate:a", "modulate": render_anim.target_property = "opacity"
		"modulate:r", "modulate:g", "modulate:b": render_anim.target_property = "fill"
		_: return null
		
	var interp = anim.track_get_interpolation_mode(track_idx)
	render_anim.interpolation = "linear" if interp == Animation.INTERPOLATION_LINEAR else "discrete" if interp == Animation.INTERPOLATION_NEAREST else "linear"
	
	for key_idx in range(anim.track_get_key_count(track_idx)):
		var time = anim.track_get_key_time(track_idx, key_idx)
		var value = anim.track_get_key_value(track_idx, key_idx)
		render_anim.keyframes.append({"time": time, "value": value})
		
	return render_anim
