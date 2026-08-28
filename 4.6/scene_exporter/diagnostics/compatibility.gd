class_name CompatibilityChecker
extends RefCounted

# Checks nodes for features that cannot be exported to SVG.

var _supported_types: Array[String] = [
	"Control", "Container", "VBoxContainer", "HBoxContainer", "GridContainer", 
	"FlowContainer", "MarginContainer", "PanelContainer", "ScrollContainer", 
	"SplitContainer", "TabContainer", "ColorRect", "Panel", "NinePatchRect",
	"Label", "RichTextLabel", "TextureRect", "TextureButton", "Button", 
	"LinkButton", "CheckBox", "CheckButton", "OptionButton", "MenuButton",
	"LineEdit", "TextEdit", "CodeEdit",
	# External Plugin Support
	"Lucide", "SvgVectorControl"
]

# Nodes in this list are utility/system nodes and are ignored silently
var _ignored_types: Array[String] = [
	"Node", "AnimationPlayer", "AnimationTree", "Timer", "AudioStreamPlayer",
	"AudioStreamPlayer2D", "AudioStreamPlayer3D", "ResourcePreloader", 
	"HTTPRequest", "WebSocketPeer", "CanvasLayer", 
	"Camera2D", "Camera3D", "Node2D", "Marker2D", "Path2D", "RayCast2D", "Light2D"
]

func check_node(info: NodeInfo, report: ExportReport) -> void:
	var node = info.node
	
	# 1. Check if node is a utility node that should be ignored silently
	if _ignored_types.has(info.node_type):
		return
		
	# 2. Check if node type is fundamentally supported
	if not _supported_types.has(info.node_type):
		report.unsupported += 1
		report.add_issue(info.node_name, "Node type '%s' is not supported" % info.node_type, "Skipped", "Use supported Control nodes")
		info.is_layout_only = true # Prevent rendering attempts
		return
		
	# 3. Check for custom drawing scripts
	var script = node.get_script()
	if script is GDScript:
		# Skip _draw check for nodes we explicitly support via exporters
		if not _supported_types.has(info.node_type):
			if script.has_method("_draw"):
				report.warnings += 1
				report.add_issue(info.node_name, "Custom _draw() implementation detected", "Skipped Rendering", "Compose visuals using built-in Controls or implement custom exporter")
			
	# 4. Check for custom shaders
	if node is CanvasItem:
		var mat = node.material
		if mat is ShaderMaterial:
			report.warnings += 1
			report.add_issue(info.node_name, "Custom ShaderMaterial detected", "Ignored Material", "SVG does not support Godot shaders; visual differences will occur")
