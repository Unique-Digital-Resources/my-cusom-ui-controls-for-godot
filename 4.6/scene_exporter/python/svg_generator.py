# addons/scene_exporter/python/svg_generator.py
import sys
import json
import os
import re
import xml.etree.ElementTree as ET
from scour import scour

# Register SVG namespace to avoid ns0: prefix
SVG_NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NS)

def S(tag):
    """Helper to create namespace-qualified tags."""
    return f"{{{SVG_NS}}}{tag}"

def sanitize_color(color_str):
    if not color_str or not isinstance(color_str, str): return "none"
    if color_str == "none": return color_str
    if not color_str.startswith('#'): color_str = '#' + color_str
    if len(color_str) == 9: return color_str[:7] # Strip alpha for SVG hex
    return color_str

def draw_stylebox(stylebox, rect, parent_elem, defs):
    sb_type = stylebox.get("type", "empty")
    if sb_type == "empty": return
    
    x, y, w, h = rect
    
    if sb_type == "flat":
        # 1. Draw Shadow with Blur
        ss = stylebox.get("shadow_size", 0)
        if ss > 0:
            so = stylebox.get("shadow_offset", [0,0])
            s_color = sanitize_color(stylebox.get("shadow_color", "#000000"))
            shadow_rect = (x - ss + so[0], y - ss + so[1], w + ss*2, h + ss*2)
            
            # Create a unique filter for the shadow blur
            filter_id = f"blur_{ss}"
            if not any(f.get('id') == filter_id for f in defs):
                f_elem = ET.SubElement(defs, S("filter"), id=filter_id, x="-20%", y="-20%", width="140%", height="140%")
                ET.SubElement(f_elem, S("feGaussianBlur"), stdDeviation=str(ss / 2.0))
            
            ET.SubElement(parent_elem, S("rect"), 
                x=str(shadow_rect[0]), y=str(shadow_rect[1]), 
                width=str(shadow_rect[2]), height=str(shadow_rect[3]), 
                fill=s_color, filter=f"url(#{filter_id})")
            
        # 2. Draw Background
        bg_color = sanitize_color(stylebox.get("bg_color", "none"))
        rx = stylebox.get("corner_radius_top_left", 0)
        ET.SubElement(parent_elem, S("rect"), 
            x=str(x), y=str(y), width=str(w), height=str(h), 
            rx=str(rx), ry=str(rx), fill=bg_color)
            
        # 3. Draw Borders
        bw_left = stylebox.get("border_width_left", 0)
        bw_right = stylebox.get("border_width_right", 0)
        bw_top = stylebox.get("border_width_top", 0)
        bw_bottom = stylebox.get("border_width_bottom", 0)
        b_color = sanitize_color(stylebox.get("border_color", "none"))
        
        if bw_left > 0: ET.SubElement(parent_elem, S("rect"), x=str(x), y=str(y), width=str(bw_left), height=str(h), fill=b_color)
        if bw_right > 0: ET.SubElement(parent_elem, S("rect"), x=str(x+w-bw_right), y=str(y), width=str(bw_right), height=str(h), fill=b_color)
        if bw_top > 0: ET.SubElement(parent_elem, S("rect"), x=str(x), y=str(y), width=str(w), height=str(bw_top), fill=b_color)
        if bw_bottom > 0: ET.SubElement(parent_elem, S("rect"), x=str(x), y=str(y+h-bw_bottom), width=str(w), height=str(bw_bottom), fill=b_color)
            
    elif sb_type == "texture":
        tex_path = stylebox.get("texture", "")
        if tex_path:
            abs_path = os.path.abspath(tex_path.replace("res://", ""))
            ET.SubElement(parent_elem, S("image"), href=abs_path, x=str(x), y=str(y), width=str(w), height=str(h))

def parse_bbcode_to_svg(text_val, attrs):
    # Escape XML characters
    esc_val = text_val.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    
    # Convert basic Godot BBCode to SVG <tspan> elements
    esc_val = re.sub(r'\[b\](.*?)\[/b\]', r'<tspan font-weight="bold">\1</tspan>', esc_val, flags=re.DOTALL)
    esc_val = re.sub(r'\[i\](.*?)\[/i\]', r'<tspan font-style="italic">\1</tspan>', esc_val, flags=re.DOTALL)
    esc_val = re.sub(r'\[font_size=(\d+)\](.*?)\[/font_size\]', r'<tspan font-size="\1">\2</tspan>', esc_val, flags=re.DOTALL)
    esc_val = re.sub(r'\[color=(#[0-9a-fA-F]{6,8})\](.*?)\[/color\]', r'<tspan fill="\1">\2</tspan>', esc_val, flags=re.DOTALL)
    
    # Remove any remaining unsupported BBCode tags
    esc_val = re.sub(r'\[/?[^\]]+\]', '', esc_val)
    
    # Construct the <text> element string
    attr_str = " ".join([f'{k}="{v}"' for k, v in attrs.items()])
    return f'<text xmlns="{SVG_NS}" {attr_str}>{esc_val}</text>'

def draw_node(node, parent_elem, resources, defs):
    node_type = node.get("type")
    name = node.get("name")
    rect = node.get("rect", [0,0,0,0])
    x, y, w, h = rect
    
    # Use absolute coordinates directly. Do not apply group transforms to avoid layout breaking.
    g = ET.SubElement(parent_elem, S("g"), id=name)
    
    if not node.get("visible", True):
        g.set("visibility", "hidden")
        
    props = node.get("properties", {})
    theme = node.get("theme", {})
    
    # 1. Draw Backgrounds
    if node_type == "ColorRect":
        color = sanitize_color(props.get("color", "#000000"))
        ET.SubElement(g, S("rect"), x=str(x), y=str(y), width=str(w), height=str(h), fill=color)
    elif node_type in ["Panel", "PanelContainer"]:
        sb = theme.get("styleboxes", {}).get("panel", {})
        draw_stylebox(sb, rect, g, defs)
    elif node_type == "Label":
        sb = theme.get("styleboxes", {}).get("normal", {})
        if sb.get("type", "empty") != "empty":
            draw_stylebox(sb, rect, g, defs)
            
    # 2. Draw Text
    if node_type in ["Label", "RichTextLabel", "Button", "LineEdit", "TextEdit"]:
        text_val = props.get("text", "")
        if text_val:
            font_size = theme.get("font_sizes", {}).get("font_size", 16)
            if node_type == "RichTextLabel":
                font_size = theme.get("font_sizes", {}).get("normal_font_size", 16)
                
            # Fallback to 'sans-serif' if font path is missing (e.g. Godot default font)
            font_id = theme.get("fonts", {}).get("font", "sans-serif")
            if node_type == "RichTextLabel":
                font_id = theme.get("fonts", {}).get("normal_font", "sans-serif")
            if not font_id or font_id == "null":
                font_id = "sans-serif"
                
            color = sanitize_color(theme.get("colors", {}).get("font_color", "#000000"))
            if node_type == "RichTextLabel":
                color = sanitize_color(theme.get("colors", {}).get("default_color", "#000000"))
                
            h_align = props.get("horizontal_alignment", 0)
            anchor = "start"
            tx = x
            if h_align == 1: anchor = "middle"; tx = x + w/2.0
            elif h_align == 2: anchor = "end"; tx = x + w
            
            if node_type == "RichTextLabel":
                if "[right]" in text_val: anchor = "end"; tx = x + w
                elif "[center]" in text_val: anchor = "middle"; tx = x + w/2.0
            
            v_align = props.get("vertical_alignment", 1)
            ty = y + h/2.0 + font_size/3.0
            if v_align == 0: ty = y + font_size
            elif v_align == 2: ty = y + h - font_size*0.2
            
            is_rtl = any('\u0600' <= c <= '\u06FF' for c in text_val)
            
            attrs = {
                "x": str(tx), "y": str(ty), 
                "font-size": str(font_size), 
                "font-family": font_id, 
                "fill": color, 
                "text-anchor": anchor
            }
            if is_rtl:
                attrs["direction"] = "rtl"
                attrs["unicode-bidi"] = "embed"
                
            # Use raw XML injection for RichTextLabel to support BBCode tspans
            if node_type == "RichTextLabel":
                svg_text_str = parse_bbcode_to_svg(text_val, attrs)
                try:
                    elem = ET.fromstring(svg_text_str)
                    g.append(elem)
                except ET.ParseError:
                    # Fallback if XML parsing fails for some reason
                    t_elem = ET.SubElement(g, S("text"), attrs)
                    t_elem.text = re.sub(r'\[/?[^\]]+\]', '', text_val)
            else:
                t_elem = ET.SubElement(g, S("text"), attrs)
                t_elem.text = text_val

    # 3. Draw Icons/Images
    if node_type in ["TextureRect", "TextureButton"]:
        tex_path = props.get("texture", props.get("texture_normal", ""))
        if tex_path:
            abs_path = os.path.abspath(tex_path.replace("res://", ""))
            ET.SubElement(g, S("image"), href=abs_path, x=str(x), y=str(y), width=str(w), height=str(h))
            
    # 4. Draw Children
    for child in node.get("children", []):
        draw_node(child, g, resources, defs)

def main():
    if len(sys.argv) < 3:
        print("Usage: svg_generator.py <input.json> <output.svg>")
        sys.exit(1)
        
    json_path = sys.argv[1]
    out_path = sys.argv[2]
    
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    settings = data.get("settings", {})
    width = settings.get("width", 1920)
    height = settings.get("height", 1080)
    resources = data.get("resources", {})
    
    # Create root SVG element (Do not explicitly pass xmlns, register_namespace handles it)
    svg_root = ET.Element(S("svg"), width=str(width), height=str(height), viewBox=f"0 0 {width} {height}")
    
    # Defs for fonts and filters
    defs = ET.SubElement(svg_root, S("defs"))
    for res_id, res_data in resources.items():
        if res_data.get("type") == "font":
            font_path = res_data.get("path", "")
            if font_path:
                style = ET.SubElement(defs, S("style"))
                style.text = f"@font-face {{ font-family: '{res_id}'; src: url('{font_path}'); }}"
                
    # Build Document Tree
    root_node = data.get("root_node", {})
    draw_node(root_node, svg_root, resources, defs)
    
    # Write raw SVG
    tree = ET.ElementTree(svg_root)
    tree.write(out_path, encoding="utf-8", xml_declaration=True)
    
    # Optimize SVG with scour
    with open(out_path, 'r', encoding='utf-8') as f:
        svg_string = f.read()
        
    options = scour.generateDefaultOptions()
    options.enable_viewboxing = True
    options.strip_comments = True
    options.shorten_ids = True
    options.indent_type = ''
    options.newlines = False
    
    optimized_svg = scour.scourString(svg_string, options)
    
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(optimized_svg)

if __name__ == "__main__":
    main()