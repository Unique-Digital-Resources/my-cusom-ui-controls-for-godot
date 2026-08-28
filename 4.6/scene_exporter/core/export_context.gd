class_name ExportContext
extends RefCounted

# Holds shared state, caches, and settings during a single export operation

var settings: ExportSettings
var report: ExportReport
var render_document: RenderDocument
var registry: ExporterRegistry
var resource_resolver: ResourceResolver

func _init(p_settings: ExportSettings = ExportSettings.new(), p_registry: ExporterRegistry = null, p_resolver: ResourceResolver = null):
	settings = p_settings
	report = ExportReport.new()
	registry = p_registry if p_registry != null else ExporterRegistry.new()
	resource_resolver = p_resolver if p_resolver != null else ResourceResolver.new()
