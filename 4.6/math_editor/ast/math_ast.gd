class_name MathAST
extends RefCounted

## Base AST node.
##
## Represents the intermediate mathematical representation.
## Contains NO rendering information and NO Godot Control references.

var type: MathConstants.ElementType = MathConstants.ElementType.SEQUENCE
var children: Array[MathAST] = []

# Used for fenced elements (parentheses, brackets, etc.)
var open_fence: String = ""
var close_fence: String = ""

func _to_string() -> String:
    return debug_string(0)

func debug_string(indent: int = 0) -> String:
    var pad = "  ".repeat(indent)
    var s = pad + "- " + MathConstants.ElementType.keys()[type]
    
    if type == MathConstants.ElementType.FENCED:
        s += " ('%s' '%s')" % [open_fence, close_fence]
        
    if children.size() > 0:
        s += "\n"
        for child in children:
            s += child.debug_string(indent + 1)
    else:
        s += "\n"
        
    return s