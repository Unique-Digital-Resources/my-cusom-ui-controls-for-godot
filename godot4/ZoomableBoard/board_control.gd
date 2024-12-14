extends Control

@onready var canvas: TextureRect = $Canvas
@onready var h_scroll_bar: HScrollBar = $HScrollBar
@onready var v_scroll_bar: VScrollBar = $VScrollBar

var min_zoom = 1.0
var max_zoom = 15.0
var zoom_step = 0.1
var zoom = 1.0
var original_canvas_width: int
var original_canvas_height: int

func _ready():
	original_canvas_width = canvas.size.x
	original_canvas_height = canvas.size.y
	# Initialize the scrollbars when the scene starts
	update_scrollbars()

func _input(event):
	# Handle zooming with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_canvas(event.global_position, zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_canvas(event.global_position, -zoom_step)

func zoom_canvas(mouse_position: Vector2, zoom_delta: float):
	var new_zoom = clamp(zoom + zoom_delta, min_zoom, max_zoom)
	if new_zoom == zoom:
		return

	var scale_factor = new_zoom / zoom
	zoom = new_zoom

	# Calculate the new scale
	var old_size = canvas.size
	var new_size = old_size * scale_factor

	# Adjust the position so that zooming centers around the mouse
	var offset = mouse_position - canvas.position
	var zoom_offset = offset * (1 - scale_factor)
	canvas.size = new_size
	canvas.position += zoom_offset

	# Update scrollbars
	update_scrollbars()



func update_scrollbars():
	var canvas_size_x_ratio: float = (original_canvas_width/ size.x)
	var canvas_size_y_ratio: float = (original_canvas_height/ size.y)
	h_scroll_bar.page = ( canvas_size_x_ratio / zoom )  * h_scroll_bar.max_value
	v_scroll_bar.page = ( canvas_size_y_ratio / zoom )  * v_scroll_bar.max_value
	var x = 0.5
	var y = 0.5
	h_scroll_bar.value = (h_scroll_bar.max_value-h_scroll_bar.page) - (x * (h_scroll_bar.max_value-h_scroll_bar.page))
	v_scroll_bar.value = (v_scroll_bar.max_value-v_scroll_bar.page) - (y * (v_scroll_bar.max_value-v_scroll_bar.page))
