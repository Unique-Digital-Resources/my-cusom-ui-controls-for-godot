@tool
extends Control

var start_time: float = 0.0
var pixels_per_second: float = 200.0
var row_height: float = 30.0
var track_idx: int = -1
var bridge: AnimationBridge
var refresh_callable: Callable
var padding: float = 0.0

func setup(track_data: Dictionary, p_start: float, p_pps: float, p_width: float, p_height: float, p_bridge: AnimationBridge, p_refresh: Callable, p_padding: float = 0.0) -> void:
	custom_minimum_size = Vector2(p_width, p_height)
	size = Vector2(p_width, p_height)
	start_time = p_start
	pixels_per_second = p_pps
	row_height = p_height
	bridge = p_bridge
	refresh_callable = p_refresh
	track_idx = track_data.get("idx", -1)
	padding = p_padding
	
	for child in get_children():
		child.queue_free()
		
	var keyframe_script = load("res://addons/pro_timeline_dock/ui/keyframe_point.gd")
	for kf in track_data.get("keyframes", []):
		var point = keyframe_script.new()
		point.setup(kf.time, start_time, pixels_per_second, row_height, bridge, track_idx, kf.key_idx, refresh_callable, kf.get("value", null), padding)
		add_child(point)
		
	queue_redraw()

func apply_selection_state(selected: Array) -> void:
	for child in get_children():
		if child.has_method("set_selected_state"):
			var is_sel = false
			for s in selected:
				if s[0] == child.track_idx and s[1] == child.key_idx:
					is_sel = true
					break
			child.set_selected_state(is_sel)

func update_keyframe_ui(p_bridge: AnimationBridge) -> void:
	for child in get_children():
		if child.has_method("sync_time_from_bridge"):
			child.sync_time_from_bridge(p_bridge)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			var y = row_height / 2.0
			if abs(event.position.y - y) < 15.0:
				var clicked_x = event.position.x
				if not bridge or not bridge.animation: return
				var key_count = bridge.animation.track_get_key_count(track_idx)
				for k_idx in range(key_count - 1):
					var t1 = bridge.animation.track_get_key_time(track_idx, k_idx)
					var t2 = bridge.animation.track_get_key_time(track_idx, k_idx + 1)
					var x1 = (t1 - start_time) * pixels_per_second + padding
					var x2 = (t2 - start_time) * pixels_per_second + padding
					if clicked_x >= x1 and clicked_x <= x2:
						_spawn_segment_editor(k_idx)
						accept_event()
						return
		
		if bridge and bridge.dock and bridge.dock.right_panel:
			bridge.dock.right_panel.start_box_selection(event.shift_pressed or event.ctrl_pressed)
		accept_event()

func _spawn_segment_editor(k_idx: int) -> void:
	if not bridge or not bridge.animation: return
	
	var popup = PopupPanel.new()
	popup.add_theme_constant_override("margin_left", 8)
	popup.add_theme_constant_override("margin_right", 8)
	popup.add_theme_constant_override("margin_top", 8)
	popup.add_theme_constant_override("margin_bottom", 8)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	popup.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "Segment Mode (Key %d -> %d)" % [k_idx, k_idx + 1]
	vbox.add_child(lbl)
	
	var seg_data = bridge.get_segment_mode(track_idx, k_idx)
	
	var opt = OptionButton.new()
	opt.add_item("Continuous", 0)
	opt.add_item("Discrete", 1)
	opt.add_item("Intermittent (Advanced)", 2)
	opt.selected = seg_data.get("mode", 0)
	vbox.add_child(opt)
	
	var grid = GridContainer.new()
	grid.columns = 2
	vbox.add_child(grid)
	
	var lbl_in = Label.new(); lbl_in.text = "In Steps (frames):"; grid.add_child(lbl_in)
	var spin_in = SpinBox.new(); spin_in.min_value = 1; spin_in.max_value = 60; spin_in.value = seg_data.get("in_steps", 1); grid.add_child(spin_in)
	
	var lbl_out = Label.new(); lbl_out.text = "Out Steps (frames):"; grid.add_child(lbl_out)
	var spin_out = SpinBox.new(); spin_out.min_value = 1; spin_out.max_value = 60; spin_out.value = seg_data.get("out_steps", 1); grid.add_child(spin_out)
	
	var lbl_start = Label.new(); lbl_start.text = "Start With:"; grid.add_child(lbl_start)
	var opt_start = OptionButton.new()
	opt_start.add_item("In Steps", 0)
	opt_start.add_item("Out Steps", 1)
	opt_start.selected = seg_data.get("start_with", 0)
	grid.add_child(opt_start)
	
	grid.visible = (opt.selected == 2)
	opt.item_selected.connect(func(idx): grid.visible = (idx == 2))
	
	var btn = Button.new()
	btn.text = "Apply & Close"
	btn.pressed.connect(func():
		bridge.set_segment_mode(track_idx, k_idx, opt.selected, int(spin_in.value), int(spin_out.value), opt_start.selected)
		popup.queue_free()
	)
	vbox.add_child(btn)
	
	var main_win = get_window()
	main_win.add_child(popup)
	popup.position = get_global_mouse_position()
	popup.popup()

func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.15, 0.15, 0.15), true)
	
	if not bridge or not bridge.animation or track_idx == -1: return
	var key_count = bridge.animation.track_get_key_count(track_idx)
	for k_idx in range(key_count):
		if k_idx == key_count - 1: break
		
		var t1 = bridge.animation.track_get_key_time(track_idx, k_idx)
		var t2 = bridge.animation.track_get_key_time(track_idx, k_idx + 1)
		
		var x1 = (t1 - start_time) * pixels_per_second + padding
		var x2 = (t2 - start_time) * pixels_per_second + padding
		var y = row_height / 2.0
		
		var seg_data = bridge.get_segment_mode(track_idx, k_idx)
		_draw_segment(x1, x2, y, seg_data)

# FIX: Restored step-based pattern rendering
func _draw_segment(x1: float, x2: float, y: float, seg_data: Dictionary) -> void:
	var mode = seg_data.get("mode", 0)
	var col = Color(0.5, 0.5, 0.5, 0.8)
	
	if mode == 0: # Continuous
		draw_line(Vector2(x1, y), Vector2(x2, y), col, 2.0)
		
	elif mode == 1: # Discrete
		pass # No line drawing at all
		
	elif mode == 2: # Intermittent
		var in_steps = seg_data.get("in_steps", 1)
		var out_steps = seg_data.get("out_steps", 1)
		var start_with = seg_data.get("start_with", 0)
		
		# Represent 1 frame as 4 pixels so steps are clearly visible
		var step_px = 4.0 
		var in_len = in_steps * step_px
		var out_len = out_steps * step_px
		
		var cx = x1
		if start_with == 1:
			cx += out_len # Start with a gap
			
		while cx < x2:
			var draw_end = min(cx + in_len, x2)
			# Draw pattern line segment for in-steps
			draw_line(Vector2(cx, y), Vector2(draw_end, y), Color(0.2, 0.8, 1.0, 0.9), 2.0)
			cx += in_len + out_len
