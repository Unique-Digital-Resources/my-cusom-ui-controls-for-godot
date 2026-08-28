class_name ExportSettings
extends Resource

# Serializable export configuration

@export var output_path: String = "res://export.svg"
@export var embed_images: bool = true
@export var embed_fonts: bool = false
@export var pretty_print: bool = true
@export var ignore_hidden_nodes: bool = true

# Phase 15: Optimization Settings
@export var optimize_svg: bool = true
@export var decimal_precision: int = 2
@export var subset_fonts: bool = true

# Internal: Used by VideoExporter to disable SMIL tags on static frames
@export var export_animations: bool = true

# Video Settings
@export var is_video_export: bool = false
@export var fps: int = 30
@export var duration: float = 2.0

# Camera Settings
@export var camera_node_path: NodePath = NodePath()

func _to_string() -> String:
	return "ExportSettings(path=%s, video=%s, fps=%d, camera=%s)" % [output_path, is_video_export, fps, camera_node_path]
