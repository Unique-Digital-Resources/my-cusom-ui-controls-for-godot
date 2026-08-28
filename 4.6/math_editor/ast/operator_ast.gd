class_name OperatorAST
extends MathAST

## Represents a mathematical operator (+, -, =, etc.).

var operator: String = ""

func _init(p_op: String = "") -> void:
    operator = p_op
    type = MathConstants.ElementType.OPERATOR

func debug_string(indent: int = 0) -> String:
    var pad = "  ".repeat(indent)
    return pad + "- OPERATOR ('" + operator + "')\n"