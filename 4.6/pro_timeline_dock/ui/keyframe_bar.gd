@tool
extends Control

var start_frame_val: float = 0
var end_frame_val: float = 10
var base_start_frame: int = 0
var pixels_per_frame: float = 20.0
var row_index: int = 0
var row_height: float = 22.0

var bridge: AnimationBridge
var track_idx: int = -1
var key_idx: int = -1
var refresh_callable: Callable

var is_dragging: bool = false
var is_selected: bool = false
var drag_start_x: float = 0.0
var initial_start: float = 0.0
var initial_end: float = 0.0

func _ready() -> void:
	# FIX: Ensure size/position are applied when added to the tree
	_update_position()

func setup(s: float, e: float, base_s: int, ppf: float, row: int, r_height: float) -> void:
	start_frame_val = s
	end_frame_val = e
	base_start_frame = base_s
	pixels_per_frame = ppf
	row_index = row
	row_height = r_height
	_update_position()

func setup_editing(p_bridge: AnimationBridge, t_idx: int, k_idx: int, p_refresh: Callable) -> void:
	bridge = p_bridge
	track_idx = t_idx
	key_idx = k_idx
	refresh_callable = p_refresh

func _update_position() -> void:
	var x = (start_frame_val - base_start_frame) * pixels_per_frame
	var w = max(2, (end_frame_val - start_frame_val) * pixels_per_frame)
	var y = (row_index - 1) * row_height + 4.0
	position = Vector2(x, y)
	size = Vector2(w, row_height - 8.0)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not bridge or track_idx == -1:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			is_selected = true
			drag_start_x = event.position.x
			initial_start = start_frame_val
			initial_end = end_frame_val
			queue_redraw()
		elif event.is_released() and is_dragging:
			is_dragging = false
			bridge.update_keyframe_time(track_idx, key_idx, start_frame_val / 30.0)
			refresh_callable.call()

	elif event is InputEventMouseMotion and is_dragging:
		var delta_x = event.position.x - drag_start_x
		var delta_frames = delta_x / pixels_per_frame
		start_frame_val = initial_start + delta_frames
		end_frame_val = initial_end + delta_frames
		_update_position()

func _draw() -> void:
	var rect = Rect2(Vector2.ZERO, size)
	if is_selected:
		draw_rect(rect, Color(0, 0.5, 0.8), true)
	else:
		draw_rect(rect, Color(0.94, 0.78, 0.05), true)
		
	draw_rect(rect, Color(0, 0, 0, 0.5), false, 1.0)
