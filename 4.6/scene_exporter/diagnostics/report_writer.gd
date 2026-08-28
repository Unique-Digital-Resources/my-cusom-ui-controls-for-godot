class_name ReportWriter
extends RefCounted

# Generates a human-readable text file summarizing the export process.

func write_report(report: ExportReport, output_path: String) -> void:
    var txt_path = output_path.get_basename() + "_report.txt"
    var file = FileAccess.open(txt_path, FileAccess.WRITE)
    
    if not file:
        ExportUtils.log_error("Failed to save export report to: " + txt_path)
        return
        
    file.store_line("=== Godot Scene to SVG Export Report ===")
    file.store_line("Timestamp: %s" % Time.get_datetime_string_from_system())
    file.store_line("")
    file.store_line("Statistics:")
    file.store_line("  Nodes Scanned: %d" % report.nodes_scanned)
    file.store_line("  Exported:      %d" % report.exported)
    file.store_line("  Unsupported:   %d" % report.unsupported)
    file.store_line("  Warnings:      %d" % report.warnings)
    file.store_line("")
    
    if report.issues.is_empty():
        file.store_line("No issues detected. Perfect export!")
    else:
        file.store_line("Issues encountered:")
        for issue in report.issues:
            file.store_line("  - Node: %s" % issue.node)
            file.store_line("    Reason: %s" % issue.reason)
            file.store_line("    Fallback: %s" % issue.fallback)
            file.store_line("    Suggestion: %s" % issue.suggestion)
            file.store_line("")
            
    file.close()
    ExportUtils.log_message("Export report saved to: " + txt_path)