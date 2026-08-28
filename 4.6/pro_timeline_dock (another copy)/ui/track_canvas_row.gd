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

# FIX: Trigger box selection on empty click instead of immediate deselect
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if bridge and bridge.dock and bridge.dock.right_panel:
			bridge.dock.right_panel.start_box_selection(event.shift_pressed or event.ctrl_pressed)
		accept_event()

func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.15, 0.15, 0.15), true)
