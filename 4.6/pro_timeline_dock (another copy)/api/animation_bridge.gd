class_name AnimationBridge
extends RefCounted

var player: AnimationPlayer = null
var animation: Animation = null
var locked_tracks: Dictionary = {} 
var current_time: float = 0.0
var refresh_callable: Callable
var dock: Control
var is_updating: bool = false

func set_player(p_player: AnimationPlayer) -> void:
	if animation and animation.changed.is_connected(_on_animation_changed):
		animation.changed.disconnect(_on_animation_changed)
		
	player = p_player
	animation = null
	if player:
		var target_name = player.current_animation
		if target_name == "" or target_name == "RESET":
			for lib_name in player.get_animation_library_list():
				var lib = player.get_animation_library(lib_name)
				for anim_name in lib.get_animation_list():
					if anim_name != "RESET":
						target_name = anim_name
						break
				if target_name != "" and target_name != "RESET": break
				
		if target_name != "":
			for lib_name in player.get_animation_library_list():
				var lib = player.get_animation_library(lib_name)
				if lib.has_animation(target_name):
					animation = lib.get_animation(target_name)
					break
					
		if animation:
			animation.changed.connect(_on_animation_changed)

func set_refresh_callable(c: Callable) -> void:
	refresh_callable = c

func _on_animation_changed() -> void:
	if is_updating: return
	if refresh_callable.is_valid():
		refresh_callable.call()

func get_length() -> float:
	if animation: return animation.length
	return 1.0

func get_timeline_data() -> Dictionary:
	var data = { "owners": [] }
	if not animation: return data
	
	var owners_dict = {}
	for track_idx in range(animation.get_track_count()):
		if animation.track_get_key_count(track_idx) == 0:
			continue
			
		var path_str = str(animation.track_get_path(track_idx))
		var owner_name = "Root"
		var prop_name = path_str
		if ":" in path_str:
			var parts = path_str.split(":")
			var node_part = parts[0]
			prop_name = parts[1]
			if node_part != "":
				var node_parts = node_part.split("/")
				owner_name = node_parts[node_parts.size() - 1]
			
		if not owners_dict.has(owner_name):
			owners_dict[owner_name] = { "id": owner_name, "name": owner_name, "tracks": [] }
		
		var track_data = {
			"id": "track_%d" % track_idx,
			"idx": track_idx,
			"name": prop_name,
			"visible": animation.track_is_enabled(track_idx),
			"locked": locked_tracks.get(track_idx, false),
			"keyframes": []
		}
		
		var key_count = animation.track_get_key_count(track_idx)
		for key_idx in range(key_count):
			var start_time = animation.track_get_key_time(track_idx, key_idx)
			var value = animation.track_get_key_value(track_idx, key_idx)
			
			track_data["keyframes"].append({
				"id": "kf_%d_%d" % [track_idx, key_idx],
				"track_idx": track_idx,
				"key_idx": key_idx,
				"time": start_time,
				"value": value
			})
		owners_dict[owner_name]["tracks"].append(track_data)
	
	for owner_key in owners_dict:
		data["owners"].append(owners_dict[owner_key])
	return data

func update_keyframe_time(track_idx: int, key_idx: int, new_time: float, refresh_ui: bool = true) -> void:
	if not animation: return
	if track_idx < 0 or track_idx >= animation.get_track_count(): return
	if key_idx < 0 or key_idx >= animation.track_get_key_count(track_idx): return
	
	# FIX: Use dock's start and end times as hard limits
	var min_time = 0.0
	var max_time = 9999.0
	if dock:
		min_time = dock.start_time
		max_time = dock.end_time
	new_time = clamp(new_time, min_time, max_time)
	
	is_updating = true
	animation.track_set_key_time(track_idx, key_idx, new_time)
	
	if player and is_instance_valid(player):
		player.seek(current_time, true)
	is_updating = false
		
	if refresh_ui:
		call_deferred("emit_anim_changed")

func update_keyframe_value(track_idx: int, key_idx: int, new_value: Variant) -> void:
	if not animation: return
	if track_idx < 0 or track_idx >= animation.get_track_count(): return
	if key_idx < 0 or key_idx >= animation.track_get_key_count(track_idx): return
	
	is_updating = true
	animation.track_set_key_value(track_idx, key_idx, new_value)
	
	if player and is_instance_valid(player):
		player.seek(current_time, true)
	is_updating = false
	
	call_deferred("emit_anim_changed")

func emit_anim_changed():
	if animation:
		animation.emit_changed()

func set_track_visible(track_idx: int, is_visible: bool) -> void:
	if animation: 
		animation.track_set_enabled(track_idx, is_visible)
		animation.emit_changed()

func set_track_locked(track_idx: int, is_locked: bool) -> void:
	locked_tracks[track_idx] = is_locked

func is_track_locked(track_idx: int) -> bool:
	return locked_tracks.get(track_idx, false)

func remove_track(track_idx: int) -> void:
	if animation: 
		animation.remove_track(track_idx)
		animation.emit_changed()

func remove_owner(node_name: String) -> void:
	if not animation: return
	var tracks_to_remove = []
	for track_idx in range(animation.get_track_count()):
		var path_str = str(animation.track_get_path(track_idx))
		if path_name_contains_node(path_str, node_name):
			tracks_to_remove.append(track_idx)
	tracks_to_remove.reverse()
	for idx in tracks_to_remove:
		animation.remove_track(idx)
	animation.emit_changed()

func path_name_contains_node(path: String, node_name: String) -> bool:
	if ":" in path:
		var parts = path.split(":")
		var node_part = parts[0]
		if node_part != "":
			var node_parts = node_part.split("/")
			return node_name in node_parts
	return false
