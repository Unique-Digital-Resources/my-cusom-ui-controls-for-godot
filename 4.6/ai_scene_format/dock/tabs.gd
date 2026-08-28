@tool
extends VBoxContainer

signal tab_changed(tab_id: String)

const TabsConfig = [
    { "id": "layout", "icon": "Control", "tooltip": "Layout Format" },
    { "id": "animation", "icon": "AnimationPlayer", "tooltip": "Animation Format" },
    { "id": "tween", "icon": "Tween", "tooltip": "Tween Format" },
    { "id": "interaction", "icon": "Node", "tooltip": "Interaction Format" },
    { "id": "combined", "icon": "Script", "tooltip": "Combined View" }
]

func _ready() -> void:
    _clear_existing()
    _create_tabs()

func _clear_existing() -> void:
    for child in get_children():
        child.queue_free()

func _create_tabs() -> void:
    for config in TabsConfig:
        var btn = Button.new()
        btn.name = config.id
        btn.icon = get_theme_icon(config.icon, "EditorIcons")
        btn.tooltip_text = config.tooltip
        btn.custom_minimum_size = Vector2(32, 32)
        btn.toggle_mode = true
        btn.focus_mode = Control.FOCUS_NONE
        
        # Use a closure to capture the tab_id for the signal
        var tab_id = config.id
        btn.pressed.connect(func(): _on_tab_pressed(tab_id, btn))
        
        add_child(btn)
    
    # Select the first tab by default
    if get_child_count() > 0:
        get_child(0).button_pressed = true

func _on_tab_pressed(tab_id: String, btn: Button) -> void:
    # Set pressed state to true for the clicked button, false for others
    for child in get_children():
        if child is Button:
            child.set_pressed_no_signal(child == btn)
            
    tab_changed.emit(tab_id)