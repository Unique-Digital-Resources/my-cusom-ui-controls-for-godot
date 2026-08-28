class_name JsonExporter
extends RefCounted

## Reconstructs a JSON tree representation from the generated Control hierarchy.

static func export(root: Control) -> String:
    if not root:
        return "{}"
    var dict = _traverse(root)
    return JSON.stringify(dict, "  ")

static func _traverse(node: Control) -> Dictionary:
    var d: Dictionary = {}
    
    if node is SequenceControl:
        d["type"] = "Sequence"
        var children: Array = []
        for c in node.get_children():
            if c is MathElement:
                children.append(_traverse(c))
        d["children"] = children
        
    elif node is ScriptControl:
        d["type"] = "Script"
        d["base"] = _traverse(node.get_node_or_null("Base")) if node.get_node_or_null("Base") else {}
        d["super"] = _traverse(node.get_node_or_null("Super")) if node.get_node_or_null("Super") else {}
        d["sub"] = _traverse(node.get_node_or_null("Sub")) if node.get_node_or_null("Sub") else {}
        
    elif node is FractionControl:
        d["type"] = "Fraction"
        d["numerator"] = _traverse(node.get_node_or_null("Numerator")) if node.get_node_or_null("Numerator") else {}
        d["denominator"] = _traverse(node.get_node_or_null("Denominator")) if node.get_node_or_null("Denominator") else {}
        
    elif node is RootControl:
        d["type"] = "Root"
        d["radicand"] = _traverse(node.get_node_or_null("Radicand")) if node.get_node_or_null("Radicand") else {}
        var idx = node.get_node_or_null("Index")
        if idx: 
            d["index"] = _traverse(idx)
            
    elif node is FencedControl:
        d["type"] = "Fenced"
        d["open"] = node.open_char
        d["close"] = node.close_char
        d["content"] = _traverse(node.get_node_or_null("Content")) if node.get_node_or_null("Content") else {}
        
    elif node is MatrixControl:
        d["type"] = "Matrix"
        d["matrix_type"] = node.matrix_type
        d["columns"] = node.columns
        var cells: Array = []
        for c in node.get_children():
            if c is MathElement:
                cells.append(_traverse(c))
        d["cells"] = cells
        
    elif node is UnderOverControl:
        d["type"] = "UnderOver"
        d["base"] = _traverse(node.get_node_or_null("Base")) if node.get_node_or_null("Base") else {}
        d["super"] = _traverse(node.get_node_or_null("Super")) if node.get_node_or_null("Super") else {}
        d["sub"] = _traverse(node.get_node_or_null("Sub")) if node.get_node_or_null("Sub") else {}
        
    elif node is SymbolControl:
        d["type"] = "Symbol"
        d["value"] = node.text
        
    return d