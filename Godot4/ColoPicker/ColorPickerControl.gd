extends Control

# Exported variables
@export var radius_factor: float = 0.8
@export var min_value: float = 0.0
@export var max_value: float = 360.0
@export var line_width: float = 12.0
@export var initial_value: float = 0.0
@export var min_radius_factor: float = 0.2
@export var max_radius_factor: float = 1.0

# Internal variables
var value: float = 0.0  # Hue (0-360)
var effective_radius: float = 0.0
var current_radius_factor: float = 0.0
var shape_mode: int = 0  # 0: Square, 1: Triangle, 2: Circle
var handle_pos: Vector2 = Vector2.ZERO  # Square
var triangle_bary: Vector3 = Vector3.ZERO  # Triangle
var circle_pos: Vector2 = Vector2.ZERO  # Circle
var current_color: Color = Color.WHITE  # Base color
var current_color_with_alpha: Dictionary = {"color": Color.WHITE, "alpha": 1.0}  # Color with alpha
var color_plates: Array = [{"name": "Plate1", "colors": []}]  # Array of plates
var current_plate_index: int = 0  # Index of the active plate
var selected_color_index: int = -1  # Index of the selected color
var eyedropper_active: bool = false  # For magnifier
var magnifier_window: Window = null  # Reference to the fullscreen window

# Node references
@onready var darkness: HBoxContainer = $"../../Darkness"
@onready var darkness_slider: HSlider = $"../../Darkness/DarknessSlider"
@onready var darkness_spinbox: SpinBox = $"../../Darkness/SpinBox"
@onready var alpha_slider: HSlider = $"../../Alpha/AlphaSlider"
@onready var alpha_spinbox: SpinBox = $"../../Alpha/SpinBox"
@onready var square_button: Button = $"../VBoxContainer/Shapes/SquareButton"
@onready var triangle_button: Button = $"../VBoxContainer/Shapes/TriangleButton"
@onready var circle_button: Button = $"../VBoxContainer/Shapes/CircleButton"
@onready var eyedropper_button: Button = $"../VBoxContainer/EyeDropper"
@onready var current_alpha_color: ColorRect = $"../VBoxContainer/CheckTexture/CurrentAlphaColor"
@onready var hex_color_code: LineEdit = $"../VBoxContainer/HEXColorCode"
@onready var tab_content: HFlowContainer = $"../../ColorPlatesTabs/TabContent"
@onready var new_color_button: Button = $"../../ColorPlatesTabs/TabContent/NewColorButton"
@onready var tab_headers: VBoxContainer = $"../../ColorPlatesTabs/ScrollContainer/TabHeaders"
@onready var new_plate_tab: Button = $"../../ColorPlatesTabs/ScrollContainer/TabHeaders/NewPlateTab"

const ColorManager = preload("res://ColoPicker/ColorManager.gd")
const ShapeDrawer = preload("res://ColoPicker/ShapeDrawer.gd")
const InputHandler = preload("res://ColoPicker/InputHandler.gd")
const MagnifierWindowScene = preload("res://ColoPicker/MagnifierWindow.tscn")

var color_manager = ColorManager.new()
var shape_drawer = ShapeDrawer.new()
var input_handler = InputHandler.new()

# Predefined color names dictionary
const COLOR_NAMES = {
	Color.RED: "RED",
	Color.GREEN: "GREEN",
	Color.BLUE: "BLUE",
	Color.YELLOW: "YELLOW",
	Color.WHITE: "WHITE",
	Color.BLACK: "BLACK",
	Color.CYAN: "CYAN",
	Color.MAGENTA: "MAGENTA",
	Color.GRAY: "GRAY",
	Color.ORANGE: "ORANGE",
	Color.PURPLE: "PURPLE",
	Color.BROWN: "BROWN"
}

# Signal
signal value_changed(new_value)

func _ready() -> void:
	value = clamp(initial_value, min_value, max_value)
	current_radius_factor = radius_factor
	handle_pos = Vector2(1, -1)
	triangle_bary = Vector3(1, 0, 0)
	circle_pos = Vector2(1, 0)
	darkness_slider.max_value = 100.0
	darkness_slider.value = 100.0
	darkness_spinbox.max_value = 100.0
	darkness_spinbox.value = 100.0
	alpha_slider.max_value = 100.0
	alpha_slider.value = 100.0
	alpha_spinbox.max_value = 100.0
	alpha_spinbox.value = 100.0
	update_radius()
	color_plates[0]["colors"] = [
		{"color": Color.RED, "alpha": 1.0},
		{"color": Color.GREEN, "alpha": 1.0},
		{"color": Color.BLUE, "alpha": 1.0},
		{"color": Color.YELLOW, "alpha": 1.0}
	]
	setup_ui()
	update_color_with_alpha()
	queue_redraw()

func setup_ui() -> void:
	square_button.pressed.connect(func(): set_shape_mode(0))
	triangle_button.pressed.connect(func(): set_shape_mode(1))
	circle_button.pressed.connect(func(): set_shape_mode(2))
	eyedropper_button.pressed.connect(start_eyedropper)
	darkness_slider.value_changed.connect(func(v): 
		darkness_spinbox.value = v
		color_manager.set_darkness_slider(self, v)
		update_color_with_alpha()
		queue_redraw())
	darkness_spinbox.value_changed.connect(func(v): 
		darkness_slider.value = v
		color_manager.set_darkness_slider(self, v)
		update_color_with_alpha()
		queue_redraw())
	alpha_slider.value_changed.connect(func(v): 
		alpha_spinbox.value = v
		update_color_with_alpha()
		queue_redraw())
	alpha_spinbox.value_changed.connect(func(v): 
		alpha_slider.value = v
		update_color_with_alpha()
		queue_redraw())
	hex_color_code.text_changed.connect(update_color_from_hex)
	new_color_button.pressed.connect(add_new_color)
	new_plate_tab.pressed.connect(add_new_plate)
	update_tab_headers()
	update_color_buttons()

func set_shape_mode(mode: int) -> void:
	shape_mode = mode
	darkness.visible = mode == 2
	#darkness_slider.visible = mode == 2
	#darkness_spinbox.visible = mode == 2
	color_manager.switch_shape_mode(self)
	queue_redraw()

func start_eyedropper() -> void:
	if eyedropper_active:
		return
	
	eyedropper_active = true
	eyedropper_button.release_focus()
	
	if not magnifier_window:
		magnifier_window = MagnifierWindowScene.instantiate()
		get_tree().root.add_child(magnifier_window)
		magnifier_window.connect("color_picked", _on_magnifier_color_picked)
		magnifier_window.connect("tree_exited", func(): 
			eyedropper_active = false
			magnifier_window = null
			eyedropper_button.button_pressed = false
		)

func _on_magnifier_color_picked(color: Color):
	current_color = color
	alpha_slider.value = color.a * 100.0
	color_manager.update_handle_from_color(self)
	update_color_with_alpha()
	queue_redraw()
	stop_eyedropper()

func stop_eyedropper() -> void:
	eyedropper_active = false
	if magnifier_window:
		magnifier_window.queue_free()
		magnifier_window = null

func _draw() -> void:
	var center = size / 2
	shape_drawer.draw_shapes(self, center)
	shape_drawer.draw_handle(self, center)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		update_radius()
		queue_redraw()

func update_radius() -> void:
	effective_radius = min(size.x, size.y) * 0.5 * current_radius_factor

func update_color_with_alpha() -> void:
	current_color_with_alpha = {
		"color": current_color,
		"alpha": alpha_slider.value / 100.0
	}
	current_alpha_color.color = Color(current_color.r, current_color.g, current_color.b, current_color_with_alpha["alpha"])
	hex_color_code.text = current_color.to_html(false) + ("%.2X" % int(current_color_with_alpha["alpha"] * 255))
	update_color_buttons()

func update_color_from_hex(text: String) -> void:
	# Remove any leading '#' if present and convert to uppercase for consistency
	text = text.replace("#", "").to_upper()
	if text.is_valid_hex_number():
		if text.length() == 6:  # RGB
			current_color = Color.from_string("#" + text, Color.WHITE)
			alpha_slider.value = 100.0  # Default to full opacity
			color_manager.update_handle_from_color(self)
			update_color_with_alpha()
			queue_redraw()
		elif text.length() == 8:  # RGBA
			current_color = Color.from_string("#" + text.substr(0, 6), Color.WHITE)
			var alpha_hex = text.substr(6, 2)
			alpha_slider.value = float("0x" + alpha_hex) / 255.0 * 100.0
			color_manager.update_handle_from_color(self)
			update_color_with_alpha()
			queue_redraw()

func add_new_color() -> void:
	var current_plate = color_plates[current_plate_index]["colors"]
	if current_plate.size() < 10:
		current_plate.insert(0, current_color_with_alpha.duplicate())
		selected_color_index = 0
	else:
		current_plate[0] = current_color_with_alpha.duplicate()
		selected_color_index = 0
	update_color_buttons()

func get_color_name(col: Color) -> String:
	for named_color in COLOR_NAMES.keys():
		if col == named_color:
			return COLOR_NAMES[named_color]
	return col.to_html(false)

func update_color_buttons() -> void:
	var current_plate = color_plates[current_plate_index]["colors"]
	# Clear all children except new_color_button
	for child in tab_content.get_children():
		if child != new_color_button:
			child.queue_free()
	
	# Ensure new_color_button is at index 0
	tab_content.move_child(new_color_button, 0)
	
	# Add colors starting from index 1, newest first
	for i in range(current_plate.size()):
		var col = current_plate[i]["color"]
		var alpha = current_plate[i]["alpha"]
		var button = Button.new()
		button.custom_minimum_size = Vector2(60, 30)
		button.toggle_mode = true
		
		var texture_rect = TextureRect.new()
		texture_rect.texture = load("res://_icons/checkerboard.png")
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
		texture_rect.modulate = Color(1, 1, 1, 1.0 - alpha)
		texture_rect.anchor_right = 1.0
		texture_rect.anchor_bottom = 1.0
		button.add_child(texture_rect)
		
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = col
		if i == selected_color_index:
			normal_style.border_width_left = 2
			normal_style.border_width_right = 2
			normal_style.border_width_top = 2
			normal_style.border_width_bottom = 2
			normal_style.border_color = Color.WHITE
		button.add_theme_stylebox_override("normal", normal_style)
		
		var pressed_style = StyleBoxFlat.new()
		pressed_style.bg_color = col
		pressed_style.border_width_left = 2
		pressed_style.border_width_right = 2
		pressed_style.border_width_top = 2
		pressed_style.border_width_bottom = 2
		pressed_style.border_color = Color.WHITE
		button.add_theme_stylebox_override("pressed", pressed_style)
		
		button.text = get_color_name(col)
		var text_color = Color.WHITE if col.get_luminance() < 0.5 else Color.BLACK
		button.add_theme_color_override("font_color", text_color)
		button.add_theme_color_override("font_pressed_color", text_color)
		button.add_theme_color_override("font_hover_color", col)
		
		button.pressed.connect(func():
			selected_color_index = i
			current_color = current_plate[i]["color"]
			alpha_slider.value = current_plate[i]["alpha"] * 100.0
			color_manager.update_handle_from_color(self)
			update_color_with_alpha()
			queue_redraw(), CONNECT_ONE_SHOT)
		tab_content.add_child(button)
		# Place at index i + 1 to keep new_color_button first
		tab_content.move_child(button, i + 1)

func add_new_plate() -> void:
	color_plates.append({"name": "Plate" + str(color_plates.size() + 1), "colors": []})
	current_plate_index = color_plates.size() - 1
	selected_color_index = -1
	update_tab_headers()
	update_color_buttons()
	queue_redraw()

func update_tab_headers() -> void:
	for child in tab_headers.get_children():
		if child != new_plate_tab:
			child.queue_free()
	
	tab_headers.move_child(new_plate_tab, 0)
	
	for i in range(color_plates.size()):
		var plate = color_plates[i]
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 30)
		button.text = plate["name"]
		button.pressed.connect(func():
			current_plate_index = i
			selected_color_index = -1
			update_color_buttons()
			queue_redraw())
		tab_headers.add_child(button)
		tab_headers.move_child(button, i + 1)

func _gui_input(event: InputEvent) -> void:
	input_handler.handle_input(self, event)
