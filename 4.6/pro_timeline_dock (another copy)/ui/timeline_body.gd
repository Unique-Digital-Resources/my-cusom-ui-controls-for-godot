@tool
extends HSplitContainer

var left_panel: VBoxContainer
var right_panel: Control # FIXED: Changed from VBoxContainer to Control
var left_scroll: ScrollContainer
var right_scroll: ScrollContainer
var syncing_scrolls: bool = false

func _ready() -> void:
	clip_contents = true
	
	var left_script = load("res://addons/pro_timeline_dock/ui/left_panel.gd")
	left_panel = left_script.new()
	left_panel.name = "LeftPanel"
	add_child(left_panel)
	
	var right_script = load("res://addons/pro_timeline_dock/ui/right_panel.gd")
	right_panel = right_script.new()
	right_panel.name = "RightPanel"
	add_child(right_panel)
	
	call_deferred("_sync_scrolls")

func _sync_scrolls() -> void:
	left_scroll = left_panel.get_node("ScrollContainer")
	right_scroll = right_panel.get_node("ScrollContainer")
	
	var lv = left_scroll.get_v_scroll_bar()
	var rv = right_scroll.get_v_scroll_bar()
	
	lv.value_changed.connect(_on_left_scroll_changed)
	rv.value_changed.connect(_on_right_scroll_changed)

func _on_left_scroll_changed(v: float) -> void:
	if syncing_scrolls: return
	syncing_scrolls = true
	right_scroll.scroll_vertical = int(v)
	syncing_scrolls = false

func _on_right_scroll_changed(v: float) -> void:
	if syncing_scrolls: return
	syncing_scrolls = true
	left_scroll.scroll_vertical = int(v)
	syncing_scrolls = false
