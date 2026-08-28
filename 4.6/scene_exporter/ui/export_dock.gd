@tool
extends Control

@onready var scene_line_edit: LineEdit = $VBoxContainer/ScenePath/LineEdit
@onready var output_line_edit: LineEdit = $VBoxContainer/OutputPath/LineEdit
@onready var export_button: Button = $VBoxContainer/ExportButton

# Camera UI
@onready var camera_option: OptionButton = $VBoxContainer/CameraSection/CameraOption
@onready var refresh_cam_button: Button = $VBoxContainer/CameraSection/RefreshCamButton

# Video UI
@onready var video_check: CheckBox = $VBoxContainer/VideoSection/VideoCheck
@onready var fps_spin: SpinBox = $VBoxContainer/VideoSection/VideoSettings/FPSSpin
@onready var dur_spin: SpinBox = $VBoxContainer/VideoSection/VideoSettings/DurSpin

func _ready():
	if export_button:
		if not export_button.pressed.is_connected(_on_export_pressed):
			export_button.pressed.connect(_on_export_pressed)
			
	if refresh_cam_button:
		if not refresh_cam_button.pressed.is_connected(_refresh_scene_info):
			refresh_cam_button.pressed.connect(_refresh_scene_info)
			
	_refresh_scene_info()

# Fix: Made it public and using EditorInterface for reliability
func _refresh_scene_info():
	var root = EditorInterface.get_edited_scene_root()
	if root:
		if scene_line_edit:
			scene_line_edit.text = root.scene_file_path if root.scene_file_path != "" else root.name
		_populate_camera_dropdown(root)
	else:
		if scene_line_edit:
			scene_line_edit.text = "No active scene"
		if camera_option:
			camera_option.clear()
			camera_option.add_item("None (Default)")
			camera_option.set_item_metadata(0, NodePath())

func _populate_camera_dropdown(root_node: Node):
	camera_option.clear()
	camera_option.add_item("None (Default)")
	camera_option.set_item_metadata(0, NodePath())
	
	# Find all Camera2D nodes in the scene
	var cameras = root_node.find_children("*", "Camera2D", true, false)
	for cam in cameras:
		var cam_path = cam.get_path()
		camera_option.add_item(cam.name)
		camera_option.set_item_metadata(camera_option.item_count - 1, cam_path)

func _on_export_pressed():
	var settings = ExportSettings.new()
	settings.output_path = output_line_edit.text
	
	# Apply Camera Setting
	var selected_idx = camera_option.selected
	if selected_idx >= 0:
		settings.camera_node_path = camera_option.get_item_metadata(selected_idx)
	
	# Apply Video Settings
	if video_check.button_pressed:
		settings.is_video_export = true
		settings.fps = int(fps_spin.value)
		settings.duration = float(dur_spin.value)
		if settings.output_path.get_extension().to_lower() != "mp4":
			settings.output_path = settings.output_path.get_basename() + ".mp4"
			output_line_edit.text = settings.output_path
	else:
		settings.is_video_export = false
		var ext = settings.output_path.get_extension().to_lower()
		if ext != "svg" and ext != "html":
			settings.output_path = settings.output_path.get_basename() + ".svg"
			output_line_edit.text = settings.output_path
	
	var root_node = EditorInterface.get_edited_scene_root()
	if not root_node:
		ExportUtils.log_error("No active scene to export.")
		return
		
	ExportUtils.log_message("Initiating export...")
	export_button.disabled = true
	export_button.text = "Exporting..."
	
	var exporter = Exporter.new()
	
	await exporter.export_scene(root_node, settings)
	
	export_button.disabled = false
	export_button.text = "Export to SVG"
	ExportUtils.log_message("Export process finished.")
