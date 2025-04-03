# MagnifierWindow.gd
extends Window

var magnifier_widget: Node
signal color_picked(color: Color)

var selected_color: Color = Color.WHITE

func _ready():
	# Configure this window only
	size = DisplayServer.screen_get_size()
	position = Vector2.ZERO
	mode = Window.MODE_FULLSCREEN
	transparent = true
	borderless = true
	
	# Instantiate the MagnifierWidget
	magnifier_widget = preload("res://ColoPicker/MagnifierWidget.tscn").instantiate()
	add_child(magnifier_widget)
	
	magnifier_widget.z_index = 1
	grab_focus()
	
	# Debug
	print("MagnifierWindow size: ", size)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			queue_free()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected_color = get_pixel_color_under_cursor(event.position)
		emit_signal("color_picked", selected_color)
		queue_free()

func get_pixel_color_under_cursor(mouse_pos: Vector2) -> Color:
	var full_img = DisplayServer.screen_get_image(0)
	if not full_img or full_img.is_empty():
		print("Screen capture failed on click!")
		return Color.WHITE
	
	var pixel_color = full_img.get_pixelv(mouse_pos)
	return pixel_color

func _exit_tree():
	# No need to revert root settings; this window’s settings are local
	pass
