@tool
extends Control

# Preview Panel: Renders the Godot Scene and the generated SVG side-by-side,
# and provides a difference overlay mode using a shader.

const DIFF_SHADER = preload("res://addons/scene_exporter/ui/diff_overlay.gdshader")

@onready var viewport_container: SubViewportContainer = $HSplit/SubViewportContainer
@onready var sub_viewport: SubViewport = $HSplit/SubViewportContainer/SubViewport
@onready var svg_texture_rect: TextureRect = $HSplit/SVGTextureRect
@onready var mode_slider: HSlider = $VBox/Controls/ModeSlider
@onready var refresh_button: Button = $VBox/Controls/RefreshButton

var diff_material: ShaderMaterial

func _ready():
    if not refresh_button.pressed.is_connected(_on_refresh):
        refresh_button.pressed.connect(_on_refresh)
        
    if not mode_slider.value_changed.is_connected(_on_mode_changed):
        mode_slider.value_changed.connect(_on_mode_changed)
        
    # Setup difference shader material
    diff_material = ShaderMaterial.new()
    diff_material.shader = DIFF_SHADER
    svg_texture_rect.material = diff_material

func _on_refresh():
    _update_preview()

func _on_mode_changed(value: float):
    if diff_material:
        # 0.0 = Godot Only, 0.5 = Difference, 1.0 = SVG Only
        diff_material.set_shader_parameter("mode", value)

func _update_preview():
    var root = get_tree().edited_scene_root
    if not root:
        return
        
    # 1. Capture Godot Scene natively
    # Add root to our viewport, render, capture texture, remove
    var root_parent = root.get_parent()
    var root_owner = root.owner
    
    if root_parent:
        root_parent.remove_child(root)
        
    sub_viewport.add_child(root)
    
    # Force update
    await RenderingServer.frame_post_draw
    
    var godot_tex = sub_viewport.get_texture().get_image()
    
    # Restore root
    sub_viewport.remove_child(root)
    if root_parent:
        root_parent.add_child(root)
        root.owner = root_owner
        
    # 2. Generate SVG and load it
    var settings = ExportSettings.new()
    settings.output_path = "user://preview_temp.svg"
    settings.ignore_hidden_nodes = false
    
    var exporter = Exporter.new()
    exporter.export_scene(root, settings)
    
    var svg_image = Image.load_from_file(settings.output_path)
    var svg_tex = ImageTexture.create_from_image(svg_image)
    
    # 3. Apply to shader
    if diff_material:
        diff_material.set_shader_parameter("godot_tex", ImageTexture.create_from_image(godot_tex))
        diff_material.set_shader_parameter("svg_tex", svg_tex)
        
    # Resize viewport to match
    sub_viewport.size = root.size