@tool
extends Control

var timeline_ruler: Control
var content_container: VBoxContainer
var playhead_container: Control
var playhead_line: ColorRect
var playhead_head: Control
var scroll_container: ScrollContainer
var selection_overlay: Control

var scroll_x: float = 0.0
var current_playhead_time: float = 0.0
var pixels_per_second: float = 200.0

const ROW_HEIGHT: float = 30.0
const RULER_HEIGHT: float = 30.0
const H_PADDING: float = 20.0

var selected_keyframes: Array = [] 
var drag_start_mouse_x: float = 0.0
var initial_times: Dictionary = {} 

var is_box_selecting: bool = false
var box_start_local: Vector2
var box_current_local: Vector2
var box_additive: bool = false
var box_dragged: bool = false

func _ready() -> void:
	clip_contents = true
	
	var ruler_script = load("res://addons/pro_timeline_dock/ui/timeline_ruler.gd")
	timeline_ruler = ruler_script.new()
	timeline_ruler.name = "Ruler"
	timeline_ruler.set_anchors_preset(PRESET_TOP_WIDE)
	timeline_ruler.offset_bottom = RULER_HEIGHT
	add_child(timeline_ruler)
	
	var sep = HSeparator.new()
	sep.position.y = RULER_HEIGHT
	sep.anchor_right = 1.0
	sep.add_theme_constant_override("separation", 1)
	sep.custom_minimum_size.y = 1
	add_child(sep)
	
	scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.anchor_top = 0.0
	scroll_container.anchor_bottom = 1.0
	scroll_container.anchor_right = 1.0
	scroll_container.offset_top = RULER_HEIGHT + 1.0
	add_child(scroll_container)
	
	var h_bar = scroll_container.get_h_scroll_bar()
	if h_bar:
		h_bar.value_changed.connect(func(val):
			scroll_x = val
			if timeline_ruler: timeline_ruler.queue_redraw()
			_update_playhead_position()
		)
	
	content_container = VBoxContainer.new()
	content_container.name = "Content"
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 0)
	scroll_container.add_child(content_container)
	
	selection_overlay = Control.new()
	selection_overlay.name = "SelectionOverlay"
	selection_overlay.set_anchors_preset(PRESET_FULL_RECT)
	selection_overlay.offset_top = RULER_HEIGHT + 1.0
	selection_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(selection_overlay)
	selection_overlay.draw.connect(_draw_selection_box)
	
	playhead_container = Control.new()
	playhead_container.name = "PlayheadContainer"
	playhead_container.set_anchors_preset(PRESET_FULL_RECT)
	playhead_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(playhead_container)
	
	playhead_line = ColorRect.new()
	playhead_line.color = Color(1, 0.2, 0.2)
	playhead_line.size = Vector2(2, 1000)
	playhead_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	playhead_container.add_child(playhead_line)
	
	playhead_head = Control.new()
	playhead_head.custom_minimum_size = Vector2(40, 18)
	playhead_head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	playhead_container.add_child(playhead_head)
	playhead_head.draw.connect(_draw_playhead_head)
	
	resized.connect(_update_playhead_position)

func _draw_playhead_head() -> void:
	var rect = Rect2(Vector2.ZERO, playhead_head.size)
	playhead_head.draw_rect(rect, Color(1, 0.2, 0.2), true)
	var time_str = "%.2fs" % current_playhead_time
	playhead_head.draw_string(get_theme_default_font(), Vector2(4, 13), time_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

func update_view(start_time: float, end_time: float, pps: float, owners: Array, bridge: AnimationBridge, refresh_callable: Callable) -> void:
	pixels_per_second = pps
	var total_width = (end_time - start_time) * pps
	var padded_width = total_width + H_PADDING * 2
	content_container.custom_minimum_size.x = padded_width
	
	timeline_ruler.start_time = start_time
	timeline_ruler.pixels_per_second = pps
	
	if scroll_container:
		var h_bar = scroll_container.get_h_scroll_bar()
		if h_bar:
			scroll_x = h_bar.value
	
	timeline_ruler.queue_redraw()
	
	for child in content_container.get_children():
		child.queue_free()
		
	var track_canvas_row_script = load("res://addons/pro_timeline_dock/ui/track_canvas_row.gd")
	
	for owner in owners:
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(padded_width, ROW_HEIGHT)
		spacer.draw.connect(func(): 
			spacer.draw_rect(Rect2(0, 0, spacer.size.x, spacer.size.y), Color(0.18, 0.18, 0.18), true)
		)
		content_container.add_child(spacer)
		
		for track in owner.get("tracks", []):
			var track_row = track_canvas_row_script.new()
			track_row.setup(track, start_time, pixels_per_second, padded_width, ROW_HEIGHT, bridge, refresh_callable, H_PADDING)
			content_container.add_child(track_row)
			
	call_deferred("apply_selection_state")

func setup_interactions(player: AnimationPlayer, bridge: AnimationBridge, refresh_callable: Callable) -> void:
	timeline_ruler.setup_scrubbing(player, self)

func update_playhead(current_time: float) -> void:
	if not is_node_ready(): return
	current_playhead_time = max(0.0, current_time)
	_update_playhead_position()

func _update_playhead_position() -> void:
	if not is_node_ready(): return
	var x = (current_playhead_time * pixels_per_second) + H_PADDING - scroll_x
	playhead_line.position.x = x
	playhead_line.size.y = size.y
	playhead_head.position = Vector2(x - 19, 4)
	playhead_head.queue_redraw()

func start_box_selection(additive: bool) -> void:
	is_box_selecting = true
	box_additive = additive
	box_dragged = false
	box_start_local = selection_overlay.get_local_mouse_position()
	box_current_local = box_start_local
	selection_overlay.queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_box_selecting: return
	
	if event is InputEventMouseMotion:
		box_current_local = selection_overlay.get_local_mouse_position()
		if box_start_local.distance_to(box_current_local) > 3.0:
			box_dragged = true
		selection_overlay.queue_redraw()
		accept_event()
		
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_box_selecting = false
		selection_overlay.queue_redraw()
		
		if box_dragged:
			var t = selection_overlay.get_global_transform_with_canvas()
			var g_start = t * box_start_local
			var g_end = t * box_current_local
			var box_rect = Rect2(g_start, g_end - g_start).abs()
			
			if not box_additive:
				selected_keyframes.clear()
				
			if content_container:
				for child in content_container.get_children():
					if child is Control:
						for kf_point in child.get_children():
							if "track_idx" in kf_point:
								if kf_point.get_global_rect().intersects(box_rect):
									var exists = false
									for s in selected_keyframes:
										if s[0] == kf_point.track_idx and s[1] == kf_point.key_idx:
											exists = true
											break
									if not exists:
										selected_keyframes.append([kf_point.track_idx, kf_point.key_idx])
			apply_selection_state()
		else:
			if not box_additive:
				deselect_all_keyframes()
				
		accept_event()

# FIX: Route draw calls to the selection_overlay node
func _draw_selection_box() -> void:
	if not is_box_selecting: return
	var rect = Rect2(box_start_local, box_current_local - box_start_local).abs()
	selection_overlay.draw_rect(rect, Color(0.2, 0.8, 1.0, 0.15), true)
	selection_overlay.draw_rect(rect, Color(0.2, 0.8, 1.0, 0.8), false, 1.0)

func select_single_keyframe(t_idx: int, k_idx: int) -> void:
	selected_keyframes.clear()
	selected_keyframes.append([t_idx, k_idx])
	apply_selection_state()

func toggle_keyframe_selection(t_idx: int, k_idx: int) -> void:
	var found = -1
	for i in range(selected_keyframes.size()):
		if selected_keyframes[i][0] == t_idx and selected_keyframes[i][1] == k_idx:
			found = i
			break
	if found != -1:
		selected_keyframes.remove_at(found)
	else:
		selected_keyframes.append([t_idx, k_idx])
	apply_selection_state()

func range_select_keyframes(t_idx: int, k_idx: int, bridge: AnimationBridge) -> void:
	if selected_keyframes.is_empty():
		select_single_keyframe(t_idx, k_idx)
		return
		
	var anchor = selected_keyframes[0]
	var anchor_time = bridge.animation.track_get_key_time(anchor[0], anchor[1])
	var click_time = bridge.animation.track_get_key_time(t_idx, k_idx)
	
	var t_min = min(anchor_time, click_time)
	var t_max = max(anchor_time, click_time)
	
	selected_keyframes.clear()
	for t in range(bridge.animation.get_track_count()):
		for k in range(bridge.animation.track_get_key_count(t)):
			var kt = bridge.animation.track_get_key_time(t, k)
			if kt >= t_min and kt <= t_max:
				selected_keyframes.append([t, k])
	apply_selection_state()

func select_all_keyframes(bridge: AnimationBridge) -> void:
	if not bridge.animation: return
	if selected_keyframes.size() > 0:
		selected_keyframes.clear()
	else:
		selected_keyframes.clear()
		for t in range(bridge.animation.get_track_count()):
			for k in range(bridge.animation.track_get_key_count(t)):
				selected_keyframes.append([t, k])
	apply_selection_state()

func deselect_all_keyframes() -> void:
	selected_keyframes.clear()
	apply_selection_state()

func start_dragging(mouse_x: float, bridge: AnimationBridge) -> void:
	drag_start_mouse_x = mouse_x
	initial_times.clear()
	for sel in selected_keyframes:
		var key = "%d:%d" % [sel[0], sel[1]]
		initial_times[key] = bridge.animation.track_get_key_time(sel[0], sel[1])

func drag_selected(delta_x: float, bridge: AnimationBridge) -> void:
	var delta_time = delta_x / pixels_per_second
	
	var min_allowed_delta = -INF
	var max_allowed_delta = INF
	
	for sel in selected_keyframes:
		var key = "%d:%d" % [sel[0], sel[1]]
		var init_t = initial_times[key]
		if init_t + delta_time < bridge.dock.start_time:
			min_allowed_delta = max(min_allowed_delta, bridge.dock.start_time - init_t)
		if init_t + delta_time > bridge.dock.end_time:
			max_allowed_delta = min(max_allowed_delta, bridge.dock.end_time - init_t)
			
	if delta_time < min_allowed_delta: delta_time = min_allowed_delta
	if delta_time > max_allowed_delta: delta_time = max_allowed_delta
	
	for sel in selected_keyframes:
		var key = "%d:%d" % [sel[0], sel[1]]
		var init_t = initial_times[key]
		var new_time = init_t + delta_time
		bridge.update_keyframe_time(sel[0], sel[1], new_time, false)
		
	_update_keyframe_ui(bridge)

func commit_drag(bridge: AnimationBridge) -> void:
	bridge.emit_anim_changed()

func apply_selection_state() -> void:
	if not content_container: return
	for child in content_container.get_children():
		if child.has_method("apply_selection_state"):
			child.apply_selection_state(selected_keyframes)

func _update_keyframe_ui(bridge: AnimationBridge) -> void:
	if not content_container: return
	for child in content_container.get_children():
		if child.has_method("update_keyframe_ui"):
			child.update_keyframe_ui(bridge)
