class_name ExporterRegistry
extends RefCounted

# Registry for node exporters.

var _exporters: Dictionary = {}

func _init():
	# Base
	register_exporter("Control", ControlExporter.new())
	register_exporter("Container", ContainerExporter.new())
	
	# Containers
	register_exporter("VBoxContainer", ContainerExporter.new())
	register_exporter("HBoxContainer", ContainerExporter.new())
	register_exporter("GridContainer", ContainerExporter.new())
	register_exporter("MarginContainer", ContainerExporter.new())
	register_exporter("PanelContainer", ContainerExporter.new())
	register_exporter("ScrollContainer", ContainerExporter.new())
	
	# Phase 8: Basic Controls
	register_exporter("ColorRect", PanelExporter.new())
	register_exporter("Panel", PanelExporter.new())
	register_exporter("NinePatchRect", PanelExporter.new())
	
	register_exporter("Label", LabelExporter.new())
	register_exporter("RichTextLabel", LabelExporter.new())
	
	register_exporter("TextureRect", TextureExporter.new())
	register_exporter("TextureButton", TextureExporter.new())
	
	# External Plugin Support
	register_exporter("Lucide", LucideExporter.new())
	register_exporter("SvgVectorControl", SvgVectorExporter.new())
	
	# Phase 9: Interactive Controls
	register_exporter("Button", ButtonExporter.new())
	register_exporter("LinkButton", ButtonExporter.new())
	register_exporter("CheckBox", ButtonExporter.new())
	register_exporter("CheckButton", ButtonExporter.new())
	register_exporter("OptionButton", ButtonExporter.new())
	register_exporter("MenuButton", ButtonExporter.new())
	
	register_exporter("LineEdit", TextInputExporter.new())
	register_exporter("TextEdit", TextInputExporter.new())
	register_exporter("CodeEdit", TextInputExporter.new())

func register_exporter(node_class: String, exporter: BaseExporter) -> void:
	_exporters[node_class.to_lower()] = exporter
	ExportUtils.log_message("Registered exporter for: " + node_class)

func get_exporter(node_class: String) -> BaseExporter:
	var class_lower = node_class.to_lower()
	if _exporters.has(class_lower):
		return _exporters[class_lower]
		
	# Fallback: check ClassDB inheritance chain
	var current_class = node_class
	while current_class != "" and current_class != "RefCounted" and current_class != "Object":
		var current_lower = current_class.to_lower()
		if _exporters.has(current_lower):
			return _exporters[current_lower]
		current_class = ClassDB.get_parent_class(current_class)
		
	return null
