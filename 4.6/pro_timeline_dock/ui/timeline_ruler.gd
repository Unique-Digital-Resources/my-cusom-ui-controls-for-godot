@tool
extends Control

var start_time: float = 0.0
var pixels_per_second: float = 200.0
var anim_player: AnimationPlayer
var right_panel: Control
var dock: Control

const H_PADDING: float = 20.0

func setup_scrubbing(player: AnimationPlayer, rp: Control) -> void:
	anim_player = player
	right_panel = rp

func _gui_input(event: InputEvent) -> void:
	if not anim_player or not right_panel: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: _scrub(event.position.x)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_scrub(event.position.x)

func _scrub(mouse_x: float) -> void:
	if not right_panel or not dock: return
	var sx = right_panel.scroll_x
	var pad = H_PADDING
	
	# FIX: Account for scroll_x and padding accurately
	var clicked_time = start_time + ((mouse_x + sx - pad) / pixels_per_second)
	# FIX: Strictly bound the scrubbing to start and end times
	clicked_time = clamp(clicked_time, dock.start_time, dock.end_time)
	
	anim_player.seek(clicked_time, true)
	dock.current_time = clicked_time
	dock.timeline_header.set_current_time(clicked_time)
	right_panel.update_playhead(clicked_time)

func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.15, 0.15, 0.15), true)
	var font = get_theme_default_font()
	
	if not is_instance_valid(right_panel) or pixels_per_second <= 0.0: return
	
	var sx = right_panel.scroll_x
	var pad = H_PADDING
	
	var start_t = max(0.0, (sx - pad) / pixels_per_second)
	
	var step = 0.1
	while step * pixels_per_second < 8.0:
		step *= 2.0
		if step > 10000.0: break
		
	var i = int(start_t / step)
	while true:
		var t = float(i) * step
		# FIX: Subtract sx so the ruler moves in the correct direction
		var x = (t * pixels_per_second) + pad - sx
		if x > size.x + 5: break
		if x >= -5:
			var major = (i % 5 == 0)
			var h = 12.0 if major else 6.0
			var c = Color(0.7, 0.7, 0.7) if major else Color(0.4, 0.4, 0.4)
			draw_line(Vector2(x, size.y - h), Vector2(x, size.y), c, 1)
			
			if major:
				draw_string(font, Vector2(x + 2, 14), "%.1fs" % t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.9, 0.9, 0.9))
		i += 1
