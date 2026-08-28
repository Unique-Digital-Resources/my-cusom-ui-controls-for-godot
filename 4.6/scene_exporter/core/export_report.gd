class_name ExportReport
extends RefCounted

# Holds warnings, errors and statistics during the export process

var nodes_scanned: int = 0
var exported: int = 0
var unsupported: int = 0
var warnings: int = 0

var issues: Array[Dictionary] = []

func add_issue(node_name: String, reason: String, fallback: String, suggestion: String):
    issues.append({
        "node": node_name,
        "reason": reason,
        "fallback": fallback,
        "suggestion": suggestion
    })

func print_report():
    ExportUtils.log_message("=== Export Report ===")
    ExportUtils.log_message("Nodes scanned: %d" % nodes_scanned)
    ExportUtils.log_message("Exported: %d" % exported)
    ExportUtils.log_message("Unsupported: %d" % unsupported)
    ExportUtils.log_message("Warnings: %d" % warnings)
    
    for issue in issues:
        ExportUtils.log_warning("Issue on node '%s': %s (Fallback: %s)" % [issue.node, issue.reason, issue.fallback])