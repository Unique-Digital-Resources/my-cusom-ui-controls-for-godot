@tool
extends HBoxContainer

signal play_pressed(is_playing: bool)
signal play_backwards_pressed(is_playing: bool)
signal stop_pressed
signal frame_step_requested(amount: float)
signal step_key_requested(direction: int)
signal loop_toggled(is_on: bool)
signal speed_changed(value: float)
signal range_changed(start: float, end: float)
signal zoom_changed(value: float)

var btn_play: Button
var btn_rev_play: Button
var btn_stop: Button
var btn_loop: Button
var inp_start: SpinBox
var inp_end: SpinBox
var inp_current: SpinBox
var inp_speed: SpinBox
var zoom_slider: HSlider

func _ready() -> void:
	custom_minimum_size = Vector2(0, 30)
	add_theme_constant_override("separation", 4)
	
	# Group 1: Frames
	var grp1 = _create_group_box()
	add_child(grp1)
	inp_start = _add_spinbox(grp1, "Start", 0.0, 0.0, 999.0, 0.1)
	inp_current = _add_spinbox(grp1, "Cur", 0.0, 0.0, 999.0, 0.01)
	inp_end = _add_spinbox(grp1, "End", 1.0, 0.1, 999.0, 0.1)
	
	inp_start.value_changed.connect(func(v): range_changed.emit(v, inp_end.value))
	inp_end.value_changed.connect(func(v): range_changed.emit(inp_start.value, v))
	
	add_child(_create_separator())
	
	# Group 2: Transport
	var grp2 = _create_group_box()
	add_child(grp2)
	
	btn_stop = _add_button(grp2, "■", "Stop")
	btn_stop.pressed.connect(func(): 
		btn_play.text = "▶"
		btn_rev_play.text = "◀"
		stop_pressed.emit()
	)
	
	_add_button(grp2, "◀◀", "Rewind", func(): frame_step_requested.emit(-0.1))
	_add_button(grp2, "|◀", "Prev Key", func(): step_key_requested.emit(-1))
	
	btn_rev_play = _add_button(grp2, "◀", "Reverse Play", func(): 
		var is_playing = btn_rev_play.text == "◀"
		btn_rev_play.text = "||" if is_playing else "◀"
		btn_play.text = "▶"
		play_backwards_pressed.emit(is_playing)
	)
	
	btn_play = _add_button(grp2, "▶", "Play/Pause", func(): 
		var is_playing = btn_play.text == "▶"
		btn_play.text = "||" if is_playing else "▶"
		btn_rev_play.text = "◀"
		play_pressed.emit(is_playing)
	)
	
	_add_button(grp2, "▶|", "Next Key", func(): step_key_requested.emit(1))
	_add_button(grp2, "▶▶", "Fast Forward", func(): frame_step_requested.emit(0.1))
	
	add_child(_create_separator())
	
	# Group 3: Loop & Speed
	var grp3 = _create_group_box()
	add_child(grp3)
	
	btn_loop = _add_button(grp3, "↻", "Loop", Callable(), true)
	btn_loop.set_pressed_no_signal(true)
	btn_loop.toggled.connect(func(is_on): loop_toggled.emit(is_on))
	_setup_toggle_color(btn_loop, Color(0.2, 0.8, 1.0)) # Blue
	
	inp_speed = _add_spinbox(grp3, "Spd", 1.0, 0.1, 5.0, 0.1)
	inp_speed.value_changed.connect(func(v): speed_changed.emit(v))
	
	add_child(_create_separator())
	
	# Group 4: Zoom
	var grp4 = _create_group_box()
	add_child(grp4)
	var lbl_zoom = Label.new()
	lbl_zoom.text = "Zoom"
	lbl_zoom.add_theme_font_size_override("font_size", 9)
	lbl_zoom.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grp4.get_child(0).add_child(lbl_zoom)
	
	zoom_slider = HSlider.new()
	zoom_slider.min_value = 1.0
	zoom_slider.max_value = 10.0
	zoom_slider.value = 1.0
	zoom_slider.step = 0.5
	zoom_slider.custom_minimum_size = Vector2(100, 16)
	zoom_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grp4.get_child(0).add_child(zoom_slider)
	zoom_slider.value_changed.connect(func(v): zoom_changed.emit(v))

func _create_separator() -> VSeparator:
	var sep = VSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	return sep

func _create_group_box() -> PanelContainer:
	var box = PanelContainer.new()
	box.add_theme_constant_override("margin_left", 4)
	box.add_theme_constant_override("margin_right", 4)
	box.add_theme_constant_override("margin_top", 2)
	box.add_theme_constant_override("margin_bottom", 2)
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	box.add_child(hbox)
	return box

# FIX: Reduced size, added SHRINK_CENTER, and adjusted StyleBox margins
func _add_button(parent: Node, text: String, tooltip: String, callback: Callable = Callable(), is_toggle: bool = false) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.tooltip_text = tooltip
	btn.toggle_mode = is_toggle
	btn.custom_minimum_size = Vector2(18, 18)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 10)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.2, 0.2)
	sb.border_width_bottom = 1
	sb.border_color = Color(0.1, 0.1, 0.1)
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 2
	sb.content_margin_left = 3
	sb.content_margin_right = 3
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	
	parent.get_child(0).add_child(btn)
	if callback.is_valid(): btn.pressed.connect(callback)
	return btn

func _add_spinbox(parent: Node, name: String, val: float, min_val: float, max_val: float, step: float = 1.0) -> SpinBox:
	var hbox = parent.get_child(0)
	var lbl = Label.new()
	lbl.text = name
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(lbl)
	var spin = SpinBox.new()
	spin.value = val
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = step
	spin.custom_minimum_size.x = 45
	spin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(spin)
	return spin

func _setup_toggle_color(btn: Button, on_color: Color) -> void:
	var sb_off = StyleBoxFlat.new()
	sb_off.bg_color = Color(0.2, 0.2, 0.2)
	sb_off.border_width_bottom = 1
	sb_off.border_color = Color(0.1, 0.1, 0.1)
	sb_off.corner_radius_top_left = 2
	sb_off.corner_radius_top_right = 2
	sb_off.corner_radius_bottom_left = 2
	sb_off.corner_radius_bottom_right = 2
	sb_off.content_margin_left = 3
	sb_off.content_margin_right = 3
	sb_off.content_margin_top = 1
	sb_off.content_margin_bottom = 1
	
	var sb_on = sb_off.duplicate()
	sb_on.bg_color = on_color
	
	btn.add_theme_stylebox_override("normal", sb_off)
	btn.add_theme_stylebox_override("hover", sb_off)
	btn.add_theme_stylebox_override("pressed", sb_on)
	btn.add_theme_stylebox_override("hover_pressed", sb_on)

func set_playing_state(is_playing: bool) -> void:
	if btn_play: btn_play.text = "||" if is_playing else "▶"
	if btn_rev_play: btn_rev_play.text = "◀"
	
func set_current_time(time: float) -> void:
	if inp_current and not inp_current.has_focus():
		inp_current.set_value_no_signal(time)

func set_range(s: float, e: float) -> void:
	if inp_start: inp_start.set_value_no_signal(s)
	if inp_end: inp_end.set_value_no_signal(e)

func set_loop_state(is_on: bool) -> void:
	if btn_loop:
		btn_loop.set_pressed_no_signal(is_on)
