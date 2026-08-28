class_name ExportUtils
extends RefCounted

# Centralized logging system for the exporter

static func log_message(msg: String):
    print("[SceneExporter] ", msg)

static func log_warning(msg: String):
    push_warning("[SceneExporter] " + msg)

static func log_error(msg: String):
    push_error("[SceneExporter] " + msg)