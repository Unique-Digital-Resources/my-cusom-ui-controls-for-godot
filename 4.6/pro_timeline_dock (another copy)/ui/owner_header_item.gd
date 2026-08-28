@tool
extends Control

var owner_data: Dictionary = {}
var name_label: Label
var bridge: AnimationBridge
var refresh_callable: Callable
var btn_remove: Button

func _ready() -> void:
	custom_minimum_size = Vector2(0, 30)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	hbox.offset_left = 6
	hbox.offset_right = -6
	add_child(hbox)
	
	name_label = Label.new()
	name_label.text = "Unknown"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_label)
	
	btn_remove = Button.new()
	btn_remove.text = "x"
	btn_remove.custom_minimum_size = Vector2(20, 18)
	btn_remove.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_remove.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.2, 0.2)
	sb.border_width_bottom = 1
	sb.border_color = Color(0.1, 0.1, 0.1)
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	
	btn_remove.add_theme_stylebox_override("normal", sb)
	btn_remove.add_theme_stylebox_override("hover", sb)
	btn_remove.add_theme_stylebox_override("pressed", sb)
	
	hbox.add_child(btn_remove)
	
	_apply_data()

func setup(data: Dictionary, p_bridge: AnimationBridge, p_refresh: Callable) -> void:
	owner_data = data
	bridge = p_bridge
	refresh_callable = p_refresh
	if is_inside_tree(): _apply_data()

func _apply_data() -> void:
	if name_label:
		name_label.text = owner_data.get("name", "Unknown")
		
	if btn_remove and bridge:
		if not btn_remove.is_connected("pressed", Callable(self, "_on_remove_pressed")):
			btn_remove.pressed.connect(_on_remove_pressed)

func _on_remove_pressed() -> void:
	bridge.remove_owner(owner_data.get("name", ""))
	if refresh_callable.is_valid(): refresh_callable.call()

func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.2, 0.2, 0.2), true)
