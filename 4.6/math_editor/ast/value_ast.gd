class_name ValueAST
extends MathAST

## Represents a leaf node: a symbol (variable), a number, or a command (\alpha).

var value: String = ""

func _init(p_value: String = "", p_type: MathConstants.ElementType = MathConstants.ElementType.SYMBOL) -> void:
    value = p_value
    type = p_type

func debug_string(indent: int = 0) -> String:
    var pad = "  ".repeat(indent)
    return pad + "- " + MathConstants.ElementType.keys()[type] + " ('" + value + "')\n"