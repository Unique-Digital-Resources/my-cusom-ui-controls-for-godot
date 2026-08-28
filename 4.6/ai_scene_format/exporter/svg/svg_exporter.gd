@tool
class_name SVGExporter
extends RefCounted

## Main entry point for exporting a Godot Control subtree to an SVG file.

static func export_tree(root: Control, path: String) -> Error:
    if not root:
        push_error("SVG Exporter: Root node is null.")
        return ERR_INVALID_PARAMETER
        
    var root_size = root.size
    var visitor = SVGNodeVisitor.new()
    
    var svg_content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    svg_content += "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%d\" height=\"%d\" viewBox=\"0 0 %d %d\">\n" % [int(root_size.x), int(root_size.y), int(root_size.x), int(root_size.y)]
    
    # Defs for shadows and future filters
    svg_content += "  <defs>\n"
    svg_content += "    <filter id=\"godot_shadow\" x=\"-50%\" y=\"-50%\" width=\"200%\" height=\"200%\">\n"
    svg_content += "      <feDropShadow dx=\"2\" dy=\"2\" stdDeviation=\"3\" flood-opacity=\"0.3\"/>\n"
    svg_content += "    </filter>\n"
    svg_content += "  </defs>\n"
    
    # Traverse the tree starting at the root, indent level 1
    svg_content += visitor.traverse(root, 1)
    
    svg_content += "</svg>\n"
    
    # Save to disk
    var file = FileAccess.open(path, FileAccess.WRITE)
    if file:
        file.store_string(svg_content)
        file.close()
        print("✅ SVG Tree Exported successfully to: ", path)
        return OK
    else:
        push_error("Failed to open file for SVG export: " + path)
        return ERR_CANT_OPEN