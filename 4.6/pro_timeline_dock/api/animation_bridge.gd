class_name AnimationBridge
extends RefCounted

var player: AnimationPlayer = null
var animation: Animation = null
var locked_tracks: Dictionary = {} 
var current_time: float = 0.0
var refresh_callable: Callable
var dock: Control
var is_updating: bool = false

var segment_modes: Dictionary = {}

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

func get_segment_mode(t_idx: int, k_idx: int) -> Dictionary:
	var key = "%d:%d" % [t_idx, k_idx]
	if segment_modes.has(key):
		return segment_modes[key]
	return {"mode": 0, "in_steps": 1, "out_steps": 1, "start_with": 0}

func set_segment_mode(t_idx: int, k_idx: int, mode: int, in_steps: int = 1, out_steps: int = 1, start_with: int = 0) -> void:
	var key = "%d:%d" % [t_idx, k_idx]
	segment_modes[key] = {"mode": mode, "in_steps": in_steps, "out_steps": out_steps, "start_with": start_with}
	if refresh_callable.is_valid(): refresh_callable.call()

# Helper to interpolate variants safely
func _lerp_variant(a: Variant, b: Variant, t: float) -> Variant:
	t = clamp(t, 0.0, 1.0)
	if a is Vector2: return a.lerp(b, t)
	if a is Vector3: return a.lerp(b, t)
	if a is Vector4: return a.lerp(b, t)
	if a is Quaternion: return a.slerp(b, t)
	if a is Color: return a.lerp(b, t)
	if a is float or a is int: return lerpf(a, b, t)
	return a # Fallback

func apply_custom_modes(time: float) -> void:
	if not animation or not player: return
	var root = player.get_node_or_null(player.root_node)
	if not root: return

	for t_idx in range(animation.get_track_count()):
		if animation.track_get_type(t_idx) != Animation.TYPE_VALUE: continue
		var key_count = animation.track_get_key_count(t_idx)
		if key_count < 2: continue
		
		var current_k_idx = -1
		for k_idx in range(key_count - 1):
			var t1 = animation.track_get_key_time(t_idx, k_idx)
			var t2 = animation.track_get_key_time(t_idx, k_idx + 1)
			if time >= t1 and time < t2:
				current_k_idx = k_idx
				break
		
		if current_k_idx == -1: continue
		
		var seg_data = get_segment_mode(t_idx, current_k_idx)
		var mode = seg_data.get("mode", 0)
		if mode == 0: continue # Continuous
		
		var t1 = animation.track_get_key_time(t_idx, current_k_idx)
		var t2 = animation.track_get_key_time(t_idx, current_k_idx + 1)
		var val1 = animation.track_get_key_value(t_idx, current_k_idx)
		var val2 = animation.track_get_key_value(t_idx, current_k_idx + 1)
		
		var target_val = val1
		
		if mode == 1: # Discrete
			target_val = val1
		elif mode == 2: # Intermittent
			var in_steps = seg_data.get("in_steps", 1)
			var out_steps = seg_data.get("out_steps", 1)
			var start_with = seg_data.get("start_with", 0)
			
			var fps = 60.0
			if Engine.get_frames_per_second() > 0:
				fps = float(Engine.get_frames_per_second())
			var frame_dur = 1.0 / fps
			
			var cycle_time = (in_steps + out_steps) * frame_dur
			if cycle_time <= 0: cycle_time = 0.016
			
			var elapsed = time - t1
			var cycle_idx = int(elapsed / cycle_time)
			var time_in_cycle = elapsed - (cycle_idx * cycle_time)
			
			var in_time = in_steps * frame_dur
			var out_time = out_steps * frame_dur
			
			var is_out_step = false
			var hold_time = t1
			
			if start_with == 0: # starts with in
				if time_in_cycle >= in_time:
					is_out_step = true
					hold_time = t1 + cycle_idx * cycle_time + in_time
			else: # starts with out
				if time_in_cycle < out_time:
					is_out_step = true
					hold_time = t1 + cycle_idx * cycle_time
					
			if is_out_step:
				var progress = (hold_time - t1) / (t2 - t1) if (t2 - t1) > 0 else 0.0
				target_val = _lerp_variant(val1, val2, progress)
			else:
				continue # Let Godot's native seek handle the in-step interpolation
				
		var path = animation.track_get_path(t_idx)
		if path.get_subname_count() > 0:
			var node = root.get_node_or_null(path)
			if node:
				var prop_name = path.get_subname(0)
				node.set(prop_name, target_val)

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
