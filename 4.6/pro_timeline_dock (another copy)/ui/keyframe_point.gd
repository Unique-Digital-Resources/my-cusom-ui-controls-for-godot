@tool
extends Control

var time_val: float = 0.0
var base_start_time: float = 0.0
var pixels_per_second: float = 200.0
var row_height: float = 30.0

var bridge: AnimationBridge
var track_idx: int = -1
var key_idx: int = -1
var refresh_callable: Callable

var is_dragging: bool = false
var is_selected: bool = false

var key_value: Variant = null
var padding: float = 0.0

const POINT_SIZE := Vector2(12, 12)

func _ready() -> void:
	_update_position()

func setup(p_time: float, p_base_s: float, p_pps: float, p_row: float, p_bridge: AnimationBridge, t_idx: int, k_idx: int, p_refresh: Callable, p_value: Variant = null, p_padding: float = 0.0) -> void:
	time_val = p_time
	base_start_time = p_base_s
	pixels_per_second = p_pps
	row_height = p_row
	bridge = p_bridge
	track_idx = t_idx
	key_idx = k_idx
	refresh_callable = p_refresh
	key_value = p_value
	padding = p_padding
	_update_position()

func _update_position() -> void:
	size = POINT_SIZE
	custom_minimum_size = POINT_SIZE
	var x = (time_val - base_start_time) * pixels_per_second - (POINT_SIZE.x / 2.0) + padding
	var y = (30.0 / 2.0) - (POINT_SIZE.y / 2.0)
	position = Vector2(x, y)
	queue_redraw()

# FIX: Allow external setting of selection state
func set_selected_state(state: bool) -> void:
	is_selected = state
	queue_redraw()

# FIX: Sync time directly from Animation resource during multi-drag
func sync_time_from_bridge(p_bridge: AnimationBridge) -> void:
	if p_bridge and p_bridge.animation:
		time_val = p_bridge.animation.track_get_key_time(track_idx, key_idx)
		_update_position()

func _gui_input(event: InputEvent) -> void:
	if not bridge or track_idx == -1 or key_idx == -1:
		return
		
	if bridge.is_track_locked(track_idx):
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.double_click:
				_spawn_value_editor()
				accept_event()
				return
				
			var rp = bridge.dock.right_panel
			if event.ctrl_pressed:
				rp.toggle_keyframe_selection(track_idx, key_idx)
			elif event.shift_pressed:
				rp.range_select_keyframes(track_idx, key_idx, bridge)
			else:
				# If clicking an already selected item, don't clear selection, just prepare to drag
				if not is_selected:
					rp.select_single_keyframe(track_idx, key_idx)
			
			is_dragging = true
			rp.start_dragging(event.global_position.x, bridge)
			if bridge.dock: bridge.dock.is_interacting = true
			accept_event()
		elif not event.pressed and is_dragging:
			is_dragging = false
			if bridge.dock: bridge.dock.is_interacting = false
			var rp = bridge.dock.right_panel
			if abs(rp.drag_start_mouse_x - event.global_position.x) > 1.0:
				rp.commit_drag(bridge)
			accept_event()
			
	elif event is InputEventMouseMotion and is_dragging:
		var rp = bridge.dock.right_panel
		var delta_x = event.global_position.x - rp.drag_start_mouse_x
		rp.drag_selected(delta_x, bridge)
		accept_event()

func _get_tooltip(_at_position: Vector2) -> String:
	var val_str = str(key_value)
	if key_value is Color:
		val_str = "#%s" % key_value.to_html()
	return "Time: %.2fs\nValue: %s" % [time_val, val_str]

func _spawn_value_editor() -> void:
	if not bridge or not bridge.animation: return
	
	var popup = PopupPanel.new()
	popup.add_theme_constant_override("margin_left", 8)
	popup.add_theme_constant_override("margin_right", 8)
	popup.add_theme_constant_override("margin_top", 8)
	popup.add_theme_constant_override("margin_bottom", 8)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	popup.add_child(vbox)
	
	var lbl_time = Label.new()
	lbl_time.text = "Time: %.3fs" % time_val
	vbox.add_child(lbl_time)
	
	var editor_control: Control = null
	
	if key_value is Color:
		var picker = ColorPickerButton.new()
		picker.color = key_value
		picker.custom_minimum_size = Vector2(120, 30)
		editor_control = picker
	elif key_value is bool:
		var check = CheckBox.new()
		check.text = "Enabled"
		check.button_pressed = key_value
		editor_control = check
	else:
		var line_edit = LineEdit.new()
		line_edit.text = var_to_str(key_value)
		line_edit.custom_minimum_size.x = 120
		line_edit.text_submitted.connect(func(t): _commit_value(str_to_var(t), popup))
		editor_control = line_edit
		
	vbox.add_child(editor_control)
	
	var btn_close = Button.new()
	btn_close.text = "Apply & Close"
	btn_close.pressed.connect(func(): 
		var val = null
		if editor_control is ColorPickerButton:
			val = editor_control.color
		elif editor_control is CheckBox:
			val = editor_control.button_pressed
		elif editor_control is LineEdit:
			val = str_to_var(editor_control.text)
		_commit_value(val, popup)
	)
	vbox.add_child(btn_close)
	
	var main_win = get_window()
	main_win.add_child(popup)
	
	var screen_pos = get_global_rect().position + Vector2(0, size.y + 5)
	popup.position = screen_pos
	popup.popup()
	
	if editor_control is LineEdit:
		editor_control.grab_focus()
		editor_control.select_all()

func _commit_value(new_val: Variant, popup: PopupPanel) -> void:
	if new_val != null:
		bridge.update_keyframe_value(track_idx, key_idx, new_val)
	if is_instance_valid(popup):
		popup.queue_free()

func _draw() -> void:
	var base_color = Color(0.94, 0.78, 0.05)
	if is_selected:
		base_color = Color(0.2, 0.8, 1.0)
		
	var draw_color = base_color
	
	if key_value is Color:
		draw_color = key_value
	elif key_value is bool:
		draw_color = Color(0.1, 0.8, 0.1) if key_value else Color(0.8, 0.1, 0.1)
		
	var half = POINT_SIZE / 2.0
	var points = PackedVector2Array([
		Vector2(half.x, 0), Vector2(POINT_SIZE.x, half.y),
		Vector2(half.x, POINT_SIZE.y), Vector2(0, half.y)
	])
	
	draw_colored_polygon(points, draw_color)
	
	var outline_color = Color(0, 0, 0, 0.8) if not is_selected else Color(1, 1, 1, 0.9)
	draw_polyline(points + PackedVector2Array([points[0]]), outline_color, 1.0, true)
	
	if is_selected and key_value is Color:
		draw_circle(half, 2.0, Color.WHITE)
