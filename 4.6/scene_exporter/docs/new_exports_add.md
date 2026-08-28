# Developer Documentation: Scene Exporter Architecture

This document provides a comprehensive guide for developers looking to extend the Scene to SVG Exporter plugin. It covers two main scenarios:
1. **Adding Support for New Godot Nodes (SVG)**
2. **Adding a New Export Backend (e.g., HTML/CSS, PDF)**

---

## Part 1: How to Add Support for New Godot Nodes

The plugin uses a registry system to map Godot nodes to specific exporter scripts. To support a new node (e.g., `Tree`, `ItemList`, or a custom `Control`), you need to create a new exporter script and register it.

### Step 1: Understand the Data Flow
1. The `SceneWalker` traverses the Godot scene and creates a `NodeInfo` object for each node.
2. The `LayoutSolver` calculates the absolute geometry and clipping.
3. The `Exporter` pipeline asks the `ExporterRegistry` for an exporter matching the node's type.
4. The **Node Exporter** reads the `NodeInfo` and creates backend-independent `RenderObject`s (e.g., `RenderShape`, `RenderText`).
5. The `SVGWriter` converts those `RenderObject`s into SVG XML.

### Step 2: Create the Exporter Script
Create a new script in `addons/scene_exporter/exporters/`. It should extend `BaseExporter` or `ControlExporter`.

**Example: Adding a `ProgressBar` Exporter**
```gdscript
# addons/scene_exporter/exporters/progress_bar_exporter.gd
class_name ProgressBarExporter
extends ControlExporter

# Called by the pipeline to convert NodeInfo into RenderObjects
func export_node(info: NodeInfo, context: ExportContext) -> RenderGroup:
	# 1. Call the base class to setup the group, transform, and process children
	var group = super.export_node(info, context)
	
	# 2. Extract specific properties from NodeInfo
	var min_val = info.properties.get("min_value", 0.0)
	var max_val = info.properties.get("max_value", 100.0)
	var val = info.properties.get("value", 0.0)
	var ratio = (val - min_val) / (max_val - min_val) if max_val > min_val else 0.0
	
	# 3. Draw the Background (using theme resolver data)
	var sb_bg_id = info.resolved_theme.get("styleboxes", {}).get("background", "")
	if sb_bg_id != "" and sb_bg_id != "null":
		var sb_bg = context.resource_resolver.get_resource(sb_bg_id)
		if sb_bg is StyleBoxFlat:
			var bg_shape = RenderShape.new()
			bg_shape.node_name = info.node_name + "_bg"
			bg_shape.shape_type = "rounded_rect" if sb_bg.corner_radius_top_left > 0 else "rect"
			bg_shape.rect = Rect2(Vector2.ZERO, info.size)
			bg_shape.style.fill_color = sb_bg.bg_color
			bg_shape.corner_radius = sb_bg.corner_radius_top_left
			group.children.insert(0, bg_shape) # Insert at beginning to render behind fill
			
	# 4. Draw the Fill (based on the ratio)
	var sb_fill_id = info.resolved_theme.get("styleboxes", {}).get("fill", "")
	if sb_fill_id != "" and sb_fill_id != "null":
		var sb_fill = context.resource_resolver.get_resource(sb_fill_id)
		if sb_fill is StyleBoxFlat:
			var fill_shape = RenderShape.new()
			fill_shape.node_name = info.node_name + "_fill"
			fill_shape.shape_type = "rounded_rect" if sb_fill.corner_radius_top_left > 0 else "rect"
			
			# Calculate fill size based on ratio
			var fill_width = info.size.x * ratio
			fill_shape.rect = Rect2(Vector2.ZERO, Vector2(fill_width, info.size.y))
			fill_shape.style.fill_color = sb_fill.bg_color
			fill_shape.corner_radius = sb_fill.corner_radius_top_left
			group.children.insert(1, fill_shape)
			
	return group
```

### Step 3: Register the Exporter
Open `addons/scene_exporter/core/registry.gd` and add your new exporter in the `_init()` function.

```gdscript
# addons/scene_exporter/core/registry.gd
func _init():
	# ... existing registrations ...
	
	# Register the new ProgressBar exporter
	register_exporter("ProgressBar", ProgressBarExporter.new())
```

### Best Practices for Node Exporters
* **Always call `super.export_node()`**: This ensures the node's transform, visibility, clipping, and children are processed correctly.
* **Use `info.resolved_theme`**: Never call `node.get_theme_color()` directly. The `ThemeResolver` has already collected all theme overrides and inherited themes into the `info.resolved_theme` dictionary. Use `info.resolved_theme.get("colors", {}).get("font_color", Color.BLACK)`.
* **Insert backgrounds first**: If your node has a background, insert it at index `0` of the `group.children` array so it renders behind the text or icon children.
* **Use `context.resource_resolver`**: When dealing with textures or fonts, always register them with the resolver so they can be embedded or linked properly in the `<defs>` block.

---

## Part 2: How to Add a New Export Backend (e.g., HTML/CSS)

The plugin is designed with a strict separation between the **Render Model** (backend-independent IR) and the **Backends** (SVG, HTML, etc.). To add a new output format, you do not need to touch the Scene Walker, Layout Solver, or Node Exporters. You only need to write a new Writer.

### Step 1: Understand the Render Model
The `RenderDocument` is a tree of `RenderObject`s.
* `RenderDocument`: Root object. Contains width, height, background color, and children.
* `RenderGroup`: Maps to `<g>` in SVG, `<div>` in HTML. Contains children, a transform, and a clip.
* `RenderShape`: Maps to `<rect>` / `<circle>` in SVG, `<div>` with `background-color` and `border-radius` in HTML.
* `RenderText`: Maps to `<text>` in SVG, `<span>` or `<p>` in HTML.
* `RenderImage`: Maps to `<image>` in SVG, `<img>` in HTML.
* `RenderStyle`: Contains fill, stroke, opacity, font data.
* `RenderTransform`: Contains origin, rotation, scale.

### Step 2: Create the Backend Directory
Create a new folder in `addons/scene_exporter/backends/` for your new format (e.g., `html/`).

### Step 3: Implement the Writer
Create a script that takes a `RenderDocument` and outputs a string. You can model this after `addons/scene_exporter/backends/svg/svg_writer.gd`.

**Example: HTML Writer Structure**
```gdscript
# addons/scene_exporter/backends/html/html_writer.gd
class_name HTMLWriter
extends RefCounted

var resource_resolver: ResourceResolver

func _init(p_resolver: ResourceResolver):
	resource_resolver = p_resolver

func write(document: RenderDocument) -> String:
	var html = "<!DOCTYPE html>\n<html>\n<head>\n<style>\n"
	html += "body { margin: 0; padding: 0; width: %dpx; height: %dpx; position: relative; background: #%s; }\n" % [document.width, document.height, document.background_color.to_html(false)]
	html += "</style>\n</head>\n<body>\n"
	
	for child in document.children:
		html += _write_object(child, 1)
		
	html += "</body>\n</html>"
	return html

func _write_object(obj: RenderObject, indent: int) -> String:
	if not obj.visible:
		return ""
		
	var tabs = "\t".repeat(indent)
	var html = ""
	
	if obj is RenderGroup:
		var group = obj as RenderGroup
		var style = _get_style_string(obj.transform, obj.style, obj.clip)
		html += "%s<div style=\"%s\">\n" % [tabs, style]
		for child in group.children:
			html += _write_object(child, indent + 1)
		html += "%s</div>\n" % tabs
		
	elif obj is RenderShape:
		var shape = obj as RenderShape
		var style = _get_shape_style(shape, obj.transform, obj.clip)
		html += "%s<div style=\"%s\"></div>\n" % [tabs, style]
		
	elif obj is RenderText:
		var text_obj = obj as RenderText
		var style = _get_text_style(text_obj, obj.transform, obj.clip)
		html += "%s<span style=\"%s\">%s</span>\n" % [tabs, style, text_obj.text]
		
	elif obj is RenderImage:
		var img_obj = obj as RenderImage
		var style = _get_image_style(img_obj, obj.transform, obj.clip)
		html += "%s<img src=\"%s\" style=\"%s\" />\n" % [tabs, _get_image_src(img_obj.resource_id), style]
		
	return html

func _get_style_string(transform: RenderTransform, style: RenderStyle, clip: RenderClip) -> String:
	var attrs: PackedStringArray = PackedStringArray()
	
	# Position and Size
	attrs.append("position: absolute")
	attrs.append("left: %.2fpx" % transform.origin.x)
	attrs.append("top: %.2fpx" % transform.origin.y)
	
	# Transform (CSS transform)
	var css_transform = ""
	if transform.rotation != 0.0:
		css_transform += "rotate(%.2frad) " % transform.rotation
	if transform.scale != Vector2.ONE:
		css_transform += "scale(%.2f, %.2f) " % [transform.scale.x, transform.scale.y]
	if css_transform != "":
		attrs.append("transform: %s" % css_transform.strip_edges())
		
	# Opacity
	if style.opacity < 1.0:
		attrs.append("opacity: %.3f" % style.opacity)
		
	# Clipping (CSS overflow)
	if clip != null:
		var r = clip.rect
		attrs.append("overflow: hidden")
		attrs.append("clip-path: inset(%dpx %dpx %dpx %dpx)" % [r.position.y, document.width - r.size.x, document.height - r.size.y, r.position.x]) # Simplified
		
	return "; ".join(attrs)

# ... implement _get_shape_style, _get_text_style, _get_image_src ...
```

### Step 4: Integrate into the Main Pipeline
Open `addons/scene_exporter/core/exporter.gd`. Add a condition to check the output file extension (or an export setting) and route to the appropriate writer.

```gdscript
# addons/scene_exporter/core/exporter.gd
func export_scene(root_node: Node, settings: ExportSettings) -> ExportReport:
	# ... (Phases 1-6 remain identical: Analysis, Layout, Render Model) ...
	
	# Phase 7: Backend Generation
	var output_content = ""
	var ext = settings.output_path.get_extension().to_lower()
	
	if ext == "svg":
		ExportUtils.log_message("Generating SVG document...")
		var svg_writer = SVGWriter.new()
		output_content = svg_writer.write(context.render_document, context)
		
	elif ext == "html":
		ExportUtils.log_message("Generating HTML document...")
		var html_writer = HTMLWriter.new(walker.resource_resolver)
		output_content = html_writer.write(context.render_document)
		
	else:
		ExportUtils.log_error("Unsupported export format: ." + ext)
		return context.report
		
	_save_file(output_content, settings.output_path)
	
	# ... (Save report, cleanup) ...
	return context.report
```

### Best Practices for New Backends
* **Map Transformations Carefully**: SVG and CSS handle transforms differently (SVG uses `transform="translate(x,y) rotate(a)"`, CSS uses `transform: translate(x, y) rotate(a)`). Ensure your writer formats the string correctly for the target language.
* **Handle Resources**: Use the `ResourceResolver` to get base64 strings for images/fonts. For HTML, you can embed them as `data:image/png;base64,...` in `img` tags or CSS `url()`.
* **Respect Z-Index**: The `RenderDocument` tree maintains the exact child order of the Godot scene. As long as your backend respects document order (e.g., SVG paints later elements on top, HTML `position: absolute` also paints later elements on top), the z-indexing will be correct.
* **Separate Styling**: If your target format prefers styling separate from layout (like CSS), consider generating a `<style>` block with class names based on `node_name`, and applying those classes to the HTML elements.