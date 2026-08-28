@tool
extends VBoxContainer

var timeline_header: HBoxContainer
var timeline_body: HSplitContainer
var left_panel: VBoxContainer
var right_panel: Control

var bridge: AnimationBridge
var timeline_data: Dictionary
var anim_player: AnimationPlayer

var start_time: float = 0.0
var end_time: float = 1.0
var current_time: float = 0.0
var pixels_per_second: float = 200.0
var is_playing: bool = false
var is_looping: bool = true
var speed: float = 1.0
var is_interacting: bool = false
var play_direction: int = 1
var current_zoom_level: float = 1.0
var resize_hooked: bool = false

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var bridge_script = load("res://addons/pro_timeline_dock/api/animation_bridge.gd")
	bridge = bridge_script.new()
	bridge.dock = self
	bridge.set_refresh_callable(refresh_timeline)
	
	var header_script = load("res://addons/pro_timeline_dock/ui/timeline_header.gd")
	timeline_header = header_script.new()
	add_child(timeline_header)
	
	if timeline_header.has_signal("play_pressed"): timeline_header.play_pressed.connect(_on_play_pressed)
	if timeline_header.has_signal("play_backwards_pressed"): timeline_header.play_backwards_pressed.connect(_on_play_backwards_pressed)
	if timeline_header.has_signal("stop_pressed"): timeline_header.stop_pressed.connect(_on_stop_pressed)
	if timeline_header.has_signal("frame_step_requested"): timeline_header.frame_step_requested.connect(_on_step)
	if timeline_header.has_signal("step_key_requested"): timeline_header.step_key_requested.connect(_on_step_key)
	if timeline_header.has_signal("loop_toggled"): timeline_header.loop_toggled.connect(func(is_on): is_looping = is_on)
	if timeline_header.has_signal("speed_changed"): timeline_header.speed_changed.connect(func(v): speed = v)
	if timeline_header.has_signal("range_changed"): timeline_header.range_changed.connect(_on_range_changed)
	if timeline_header.has_signal("zoom_changed"): timeline_header.zoom_changed.connect(_on_zoom_changed)
	
	timeline_header.set_loop_state(is_looping)
	
	add_child(HSeparator.new())
	
	var body_script = load("res://addons/pro_timeline_dock/ui/timeline_body.gd")
	timeline_body = body_script.new()
	timeline_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	timeline_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(timeline_body)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_A:
		if event.ctrl_pressed:
			if right_panel:
				right_panel.select_all_keyframes(bridge)
				accept_event()

func _process(delta: float) -> void:
	if is_playing and anim_player:
		current_time += (delta * speed * play_direction)
		if current_time > end_time:
			if is_looping: current_time = start_time
			else:
				current_time = end_time
				_on_stop_pressed()
		elif current_time < start_time:
			if is_looping: current_time = end_time
			else:
				current_time = start_time
				_on_stop_pressed()
				
		anim_player.seek(current_time, true)
		# FIX: Evaluate custom modes after Godot's default seek to override values
		bridge.apply_custom_modes(current_time)
		
		timeline_header.set_current_time(current_time)
		if right_panel: right_panel.update_playhead(current_time)
	
	bridge.current_time = current_time

func set_animation_player(player: AnimationPlayer) -> void:
	anim_player = player
	bridge.set_player(player)
	anim_player.active = true
	
	if anim_player.current_animation == "" or anim_player.current_animation == "RESET":
		var found = false
		for lib_name in anim_player.get_animation_library_list():
			var lib = anim_player.get_animation_library(lib_name)
			for anim_name in lib.get_animation_list():
				if anim_name != "RESET":
					anim_player.current_animation = anim_name
					found = true
					break
			if found: break
			
	end_time = bridge.get_length() + 0.2
	current_time = start_time
	timeline_header.set_range(start_time, end_time)
	refresh_timeline()

func refresh_timeline() -> void:
	if is_interacting: return
	
	if timeline_body:
		left_panel = timeline_body.get_node_or_null("LeftPanel")
		right_panel = timeline_body.get_node_or_null("RightPanel")
		
	if right_panel and not resize_hooked:
		right_panel.resized.connect(func(): refresh_timeline())
		resize_hooked = true
		
	timeline_data = bridge.get_timeline_data()
	
	_recalculate_pixels_per_second()
	
	if left_panel:
		left_panel.setup_editing(bridge, refresh_timeline)
		left_panel.populate(timeline_data.get("owners", []))
		
	if right_panel:
		right_panel.update_view(start_time, end_time, pixels_per_second, timeline_data.get("owners", []), bridge, refresh_timeline)
		right_panel.setup_interactions(anim_player, bridge, refresh_timeline)
		right_panel.timeline_ruler.dock = self
		right_panel.update_playhead(current_time)

func _recalculate_pixels_per_second() -> void:
	if right_panel:
		var scroll_container = right_panel.get_node_or_null("ScrollContainer")
		if scroll_container:
			var visible_width = scroll_container.size.x
			if visible_width > 0.0:
				var time_range = end_time - start_time
				if time_range <= 0: time_range = 1.0
				var fit_pps = visible_width / time_range
				pixels_per_second = fit_pps * current_zoom_level

func deselect_all_keyframes() -> void:
	if right_panel:
		right_panel.deselect_all_keyframes()

# --- Signal Handlers ---
func _on_play_pressed(play: bool) -> void:
	is_playing = play
	if play: play_direction = 1

func _on_play_backwards_pressed(play: bool) -> void:
	is_playing = play
	if play: play_direction = -1

func _on_stop_pressed() -> void:
	is_playing = false
	current_time = start_time
	timeline_header.set_playing_state(false)
	if anim_player:
		anim_player.stop()
		anim_player.seek(start_time, true)
	if right_panel: right_panel.update_playhead(current_time)

func _on_step(amount: float) -> void:
	if is_playing: return
	current_time = clamp(current_time + amount, start_time, end_time)
	if anim_player: anim_player.seek(current_time, true)
	bridge.apply_custom_modes(current_time)
	timeline_header.set_current_time(current_time)
	if right_panel: right_panel.update_playhead(current_time)

func _on_step_key(direction: int) -> void:
	if is_playing or not bridge.animation: return
	var closest_time = -1.0
	if direction > 0:
		var min_diff = INF
		for t_idx in range(bridge.animation.get_track_count()):
			for k_idx in range(bridge.animation.track_get_key_count(t_idx)):
				var kt = bridge.animation.track_get_key_time(t_idx, k_idx)
				if kt > current_time and kt - current_time < min_diff:
					min_diff = kt - current_time
					closest_time = kt
	else:
		var max_diff = -INF
		for t_idx in range(bridge.animation.get_track_count()):
			for k_idx in range(bridge.animation.track_get_key_count(t_idx)):
				var kt = bridge.animation.track_get_key_time(t_idx, k_idx)
				if kt < current_time and kt - current_time > max_diff:
					max_diff = kt - current_time
					closest_time = kt
					
	if closest_time >= 0.0:
		current_time = closest_time
		if anim_player: anim_player.seek(current_time, true)
		bridge.apply_custom_modes(current_time)
		timeline_header.set_current_time(current_time)
		if right_panel: right_panel.update_playhead(current_time)

func _on_range_changed(s: float, e: float) -> void:
	start_time = s
	end_time = e
	current_time = clamp(current_time, s, e)
	refresh_timeline()

func _on_zoom_changed(value: float) -> void:
	current_zoom_level = value
	refresh_timeline()
