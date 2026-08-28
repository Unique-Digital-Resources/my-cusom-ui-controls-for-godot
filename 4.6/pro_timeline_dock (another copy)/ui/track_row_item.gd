@tool
extends Control

var track_data: Dictionary = {}
var name_label: Label
var bridge: AnimationBridge
var refresh_callable: Callable

var btn_vis: Button
var btn_lock: Button
var btn_remove: Button

func _ready() -> void:
	custom_minimum_size = Vector2(0, 30)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	hbox.offset_left = 16
	hbox.offset_right = -4
	hbox.add_theme_constant_override("separation", 4)
	add_child(hbox)
	
	name_label = Label.new()
	name_label.text = "Track"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_label)
	
	# FIX: Use Godot's built-in editor icons instead of letters
	btn_vis = _create_icon_button("GuiVisibilityVisible", true)
	hbox.add_child(btn_vis)
	
	btn_lock = _create_icon_button("Lock", true)
	hbox.add_child(btn_lock)
	
	btn_remove = _create_icon_button("Close", false)
	hbox.add_child(btn_remove)
	
	_setup_toggle_color(btn_vis, Color(0.1, 0.8, 0.1)) # Green
	_setup_toggle_color(btn_lock, Color(0.9, 0.2, 0.2)) # Red
	
	_apply_data()

# FIX: Created a dedicated compact icon button generator
func _create_icon_button(icon_name: String, is_toggle: bool) -> Button:
	var btn = Button.new()
	var icon = get_theme_icon(icon_name, "EditorIcons")
	if icon:
		btn.icon = icon
	else:
		btn.text = icon_name # Fallback if icon not found
		
	btn.toggle_mode = is_toggle
	btn.custom_minimum_size = Vector2(18, 18)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Flat buttons with small padding shrink perfectly to their icons
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.2, 0.2)
	sb.border_width_bottom = 1
	sb.border_color = Color(0.1, 0.1, 0.1)
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	sb.content_margin_left = 2
	sb.content_margin_right = 2
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	return btn

func setup(data: Dictionary, p_bridge: AnimationBridge, p_refresh: Callable) -> void:
	track_data = data
	bridge = p_bridge
	refresh_callable = p_refresh
	if is_inside_tree(): _apply_data()

func _apply_data() -> void:
	if name_label:
		name_label.text = track_data.get("name", "Unknown")
		
	if bridge:
		var t_idx = track_data.get("idx", -1)
		btn_vis.set_pressed_no_signal(track_data.get("visible", true))
		btn_lock.set_pressed_no_signal(track_data.get("locked", false))
		
		if not btn_vis.is_connected("toggled", Callable(self, "_on_vis_toggled")):
			btn_vis.toggled.connect(_on_vis_toggled)
		if not btn_lock.is_connected("toggled", Callable(self, "_on_lock_toggled")):
			btn_lock.toggled.connect(_on_lock_toggled)
		if not btn_remove.is_connected("pressed", Callable(self, "_on_remove_pressed")):
			btn_remove.pressed.connect(_on_remove_pressed)

func _on_vis_toggled(is_on: bool) -> void:
	bridge.set_track_visible(track_data.get("idx", -1), is_on)

func _on_lock_toggled(is_on: bool) -> void:
	bridge.set_track_locked(track_data.get("idx", -1), is_on)
	if refresh_callable.is_valid(): refresh_callable.call()

func _on_remove_pressed() -> void:
	bridge.remove_track(track_data.get("idx", -1))
	if refresh_callable.is_valid(): refresh_callable.call()

func _setup_toggle_color(btn: Button, on_color: Color) -> void:
	var sb_on = StyleBoxFlat.new()
	sb_on.bg_color = on_color
	sb_on.border_width_bottom = 1
	sb_on.border_color = Color(0.1, 0.1, 0.1)
	sb_on.corner_radius_top_left = 2
	sb_on.corner_radius_top_right = 2
	sb_on.corner_radius_bottom_left = 2
	sb_on.corner_radius_bottom_right = 2
	sb_on.content_margin_left = 2
	sb_on.content_margin_right = 2
	sb_on.content_margin_top = 2
	sb_on.content_margin_bottom = 2
	
	btn.add_theme_stylebox_override("pressed", sb_on)
	btn.add_theme_stylebox_override("hover_pressed", sb_on)

func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.15, 0.15, 0.15), true)
