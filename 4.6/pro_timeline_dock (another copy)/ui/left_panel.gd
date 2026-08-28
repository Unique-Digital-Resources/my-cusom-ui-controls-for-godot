@tool
extends VBoxContainer

var content_container: VBoxContainer
var bridge: AnimationBridge
var refresh_callable: Callable

func _ready() -> void:
	custom_minimum_size = Vector2(280, 0)
	add_theme_constant_override("separation", 0)
	
	var filter_box = HBoxContainer.new()
	filter_box.custom_minimum_size = Vector2(0, 30)
	filter_box.add_theme_constant_override("separation", 4)
	filter_box.offset_left = 6
	filter_box.offset_top = 4
	
	var filter_label = Label.new()
	filter_label.text = "Filter"
	filter_box.add_child(filter_label)
	add_child(filter_box)
	
	var sep = HSeparator.new()
	# FIX: Force exact 1px height separator to match right panel
	sep.add_theme_constant_override("separation", 1)
	sep.custom_minimum_size.y = 1
	add_child(sep)
	
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	
	content_container = VBoxContainer.new()
	content_container.name = "Content"
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 0)
	scroll.add_child(content_container)

func setup_editing(p_bridge: AnimationBridge, p_refresh: Callable) -> void:
	bridge = p_bridge
	refresh_callable = p_refresh

func populate(owners: Array) -> void:
	if not content_container: return
	for child in content_container.get_children():
		child.queue_free()
		
	var owner_script = load("res://addons/pro_timeline_dock/ui/owner_header_item.gd")
	var track_script = load("res://addons/pro_timeline_dock/ui/track_row_item.gd")
	
	for owner_data in owners:
		var owner_item = owner_script.new()
		owner_item.setup(owner_data, bridge, refresh_callable)
		content_container.add_child(owner_item)
		
		for track_data in owner_data.get("tracks", []):
			var track_item = track_script.new()
			track_item.setup(track_data, bridge, refresh_callable)
			content_container.add_child(track_item)
