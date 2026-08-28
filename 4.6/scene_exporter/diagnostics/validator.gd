class_name SceneValidator
extends RefCounted

# Traverses the NodeInfo tree pre-export to validate compatibility and populate the report.

var compatibility_checker: CompatibilityChecker

func _init():
    compatibility_checker = CompatibilityChecker.new()

func validate(root_info: NodeInfo, report: ExportReport) -> void:
    ExportUtils.log_message("Validating scene compatibility...")
    _validate_node(root_info, report)

func _validate_node(info: NodeInfo, report: ExportReport) -> void:
    # Run compatibility checks on the current node
    compatibility_checker.check_node(info, report)
    
    # Recursively validate children
    for child in info.children_info:
        _validate_node(child, report)