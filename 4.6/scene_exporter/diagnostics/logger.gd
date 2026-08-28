class_name DiagLogger
extends RefCounted

# Specialized logger for diagnostics that routes messages to the ExportReport 
# as well as the Godot console.

var _report: ExportReport

func _init(report: ExportReport):
	_report = report

func info(msg: String):
	ExportUtils.log_message(msg)

func warn(msg: String, node_name: String = ""):
	_report.warnings += 1
	ExportUtils.log_warning("[WARNING] " + msg)

func error(msg: String, node_name: String = ""):
	_report.unsupported += 1
	ExportUtils.log_error("[ERROR] " + msg)
