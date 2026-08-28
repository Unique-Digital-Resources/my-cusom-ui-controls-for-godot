@tool
extends Control

var start_frame: int = 0
var pixels_per_frame: float = 20.0
var bridge: AnimationBridge
var refresh_callable: Callable
var row_types: Array = []
var fps: float = 30.0

func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.12, 0.12, 0.12), true)
	for i in range(row_types.size()):
		var y = i * 22.0
		var color = Color(0.18, 0.18, 0.18) if row_types[i] == 0 else (Color(0.15, 0.15, 0.15) if i % 2 == 0 else Color(0.13, 0.13, 0.13))
		draw_rect(Rect2(0, y, size.x, 22.0), color)

func populate(owners: Array, row_height: float = 22.0) -> void:
	set_meta("owners", owners)
	row_types.clear()
	for child in get_children():
		if child.name != "Playhead":
			child.queue_free()
		
	var row_idx = 0
	var keyframe_script = load("res://addons/pro_timeline_dock/ui/keyframe_point.gd")
	
	for owner in owners:
		row_idx += 1
		row_types.append(0)
		
		for track in owner.get("tracks", []):
			row_idx += 1
			row_types.append(1)
			
			for kf in track.get("keyframes", []):
				var point = keyframe_script.new()
				var frame = kf.start * fps
				point.setup(frame, start_frame, pixels_per_frame, row_idx, row_height, fps)
				point.setup_editing(bridge, track.get("idx"), kf.get("key_idx"), refresh_callable)
				add_child(point)
				
	custom_minimum_size.y = row_idx * row_height
	queue_redraw()

func setup_editing(p_bridge: AnimationBridge, p_refresh: Callable, p_fps: float) -> void:
	bridge = p_bridge
	refresh_callable = p_refresh
	fps = p_fps
