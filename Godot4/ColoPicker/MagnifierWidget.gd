# MagnifierWidget.gd
extends Control
class_name MagnifierWidget

@export var ZOOM_SIZE: int = 10  # Size of each magnified pixel
@export var GRID_SIZE: int = 5   # Number of pixels in grid (odd number recommended)
@export var OFFSET: int = 10     # Distance from mouse cursor

var texture_rect: TextureRect
var screen_size: Vector2
const BORDER_WIDTH: int = 2
const OUTLINE_COLOR: Color = Color.YELLOW
const BORDER_COLOR: Color = Color.BLACK
const OUTLINE_THICKNESS: int = 1
const UPDATE_INTERVAL: float = 0.05  # Update texture every 50ms

var last_update_time: float = 0.0

func _ready():
	# Set size of widget (including border)
	update_size()
	
	# Store screen size for edge detection
	screen_size = DisplayServer.screen_get_size()
	
	# Ensure visibility and layering
	visible = true
	z_index = 10
	
	# Create texture rect for magnified content
	texture_rect = TextureRect.new()
	texture_rect.size = custom_minimum_size
	texture_rect.position = Vector2.ZERO
	texture_rect.visible = true
	texture_rect.z_index = 10
	add_child(texture_rect)
	
	# Initial texture
	update_initial_texture()
	
	# Start texture update loop
	start_texture_updates()

func update_size():
	custom_minimum_size = Vector2(GRID_SIZE * ZOOM_SIZE + BORDER_WIDTH * 2, GRID_SIZE * ZOOM_SIZE + BORDER_WIDTH * 2)
	size = custom_minimum_size
	if texture_rect:
		texture_rect.size = custom_minimum_size

func _process(delta):
	# Update position instantly
	var mouse_pos = get_global_mouse_position()
	global_position = calculate_dynamic_position(mouse_pos)
	
	# Update texture periodically
	last_update_time += delta
	if last_update_time >= UPDATE_INTERVAL:
		last_update_time = 0.0
		update_magnifier(mouse_pos)

func calculate_dynamic_position(mouse_pos: Vector2) -> Vector2:
	var widget_size = custom_minimum_size
	var pos = mouse_pos
	
	# Define offset vectors
	var right_pos = Vector2(OFFSET, 0)
	var left_pos = Vector2(-OFFSET - widget_size.x, 0)
	var above_pos = Vector2(0, -OFFSET - widget_size.y)
	var below_pos = Vector2(0, OFFSET)
	
	# Check screen edges and choose position
	if mouse_pos.x + widget_size.x + OFFSET > screen_size.x:  # Near right edge
		pos += left_pos
	elif mouse_pos.x < OFFSET + widget_size.x:               # Near left edge
		pos += right_pos
	else:
		pos += right_pos
	
	# Vertical override
	if mouse_pos.y + widget_size.y + OFFSET > screen_size.y:  # Near bottom edge
		pos = mouse_pos + above_pos
	elif mouse_pos.y < OFFSET + widget_size.y:               # Near top edge
		pos = mouse_pos + below_pos
	
	# Clamp to screen bounds
	pos = pos.clamp(Vector2.ZERO, screen_size - widget_size)
	
	return pos

func update_initial_texture():
	var img = Image.create(custom_minimum_size.x, custom_minimum_size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.RED)
	draw_border(img)
	draw_center_outline(img)
	texture_rect.texture = ImageTexture.create_from_image(img)

func start_texture_updates():
	while true:
		await get_tree().create_timer(UPDATE_INTERVAL).timeout
		if not is_inside_tree():
			break
		var mouse_pos = get_global_mouse_position()
		update_magnifier(mouse_pos)

func update_magnifier(center_pos: Vector2):
	# Capture full screen
	var full_img = DisplayServer.screen_get_image(0)
	
	if not full_img or full_img.is_empty():
		print("Screen capture failed! Screen count: ", DisplayServer.get_screen_count())
		return
	
	# Define capture area around mouse
	var capture_rect = Rect2(
		center_pos - Vector2(GRID_SIZE/2, GRID_SIZE/2),
		Vector2(GRID_SIZE, GRID_SIZE)
	)
	
	# Ensure capture rect stays within screen bounds
	capture_rect.position = capture_rect.position.clamp(Vector2.ZERO, screen_size - capture_rect.size)
	
	# Extract region from full screen capture
	var img = full_img.get_region(capture_rect)
	
	# Create magnified image
	var magnified = Image.create(custom_minimum_size.x, custom_minimum_size.y, false, Image.FORMAT_RGBA8)
	
	# Sample and magnify pixels
	for y in GRID_SIZE:
		for x in GRID_SIZE:
			var color = img.get_pixel(x, y)
			magnified.fill_rect(
				Rect2(x * ZOOM_SIZE + BORDER_WIDTH, y * ZOOM_SIZE + BORDER_WIDTH, ZOOM_SIZE, ZOOM_SIZE),
				color
			)
	
	# Draw border and center outline
	draw_border(magnified)
	draw_center_outline(magnified)
	
	# Update texture
	var texture = ImageTexture.create_from_image(magnified)
	texture_rect.texture = texture

func draw_border(img: Image):
	var width = img.get_width()
	var height = img.get_height()
	
	for x in width:
		for i in BORDER_WIDTH:
			img.set_pixel(x, i, BORDER_COLOR)
			img.set_pixel(x, height - 1 - i, BORDER_COLOR)
	
	for y in height:
		for i in BORDER_WIDTH:
			img.set_pixel(i, y, BORDER_COLOR)
			img.set_pixel(width - 1 - i, y, BORDER_COLOR)

func draw_center_outline(img: Image):
	# Calculate center dynamically based on current size
	var center_x = BORDER_WIDTH + ((GRID_SIZE - 1) / 2) * ZOOM_SIZE
	var center_y = BORDER_WIDTH + ((GRID_SIZE - 1) / 2) * ZOOM_SIZE
	
	# Draw outline
	for i in ZOOM_SIZE + OUTLINE_THICKNESS * 2:
		img.set_pixel(center_x + i - OUTLINE_THICKNESS, center_y - OUTLINE_THICKNESS, OUTLINE_COLOR)
		img.set_pixel(center_x + i - OUTLINE_THICKNESS, center_y + ZOOM_SIZE - 1 + OUTLINE_THICKNESS, OUTLINE_COLOR)
		img.set_pixel(center_x - OUTLINE_THICKNESS, center_y + i - OUTLINE_THICKNESS, OUTLINE_COLOR)
		img.set_pixel(center_x + ZOOM_SIZE - 1 + OUTLINE_THICKNESS, center_y + i - OUTLINE_THICKNESS, OUTLINE_COLOR)
