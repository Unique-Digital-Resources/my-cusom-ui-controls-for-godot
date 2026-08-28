Here is the complete file structure for the **Scene to SVG Exporter** project, along with a description of the role and mechanisms of each file.

### `addons/scene_exporter/`
**`plugin.cfg`**
The Godot plugin configuration file. It defines the plugin's name, description, author, version, and the main entry point script (`plugin.gd`), allowing Godot to recognize and load the addon in the Project Settings.

**`plugin.gd`**
The plugin entry point. It handles initializing the plugin when the editor starts, instantiating the main UI dock, adding it to the Godot editor interface, and cleaning up when the plugin is disabled.

### `addons/scene_exporter/core/`
**`exporter.gd`**
The main export pipeline coordinator. It orchestrates the entire export process by executing the pipeline phases in order: Scene Analysis, Layout Resolution, Animation Resolution, Validation, Render Model Building, SVG Generation, and File Saving.

**`export_context.gd`**
A shared state container. It holds the `ExportSettings`, `ExportReport`, `ResourceResolver`, `ExporterRegistry`, and the `RenderDocument`. It is passed down through the pipeline phases so all systems have access to shared data and caches.

**`export_settings.gd`**
A serializable Resource object that stores user-configurable export options, such as the output file path, whether to embed images/fonts, SVG formatting options, and optimization levels (e.g., decimal precision).

**`export_report.gd`**
A data class that accumulates statistics during the export process. It tracks the number of nodes scanned, exported, and unsupported, as well as a list of detailed issues (warnings/errors) encountered, which are later displayed to the user.

**`registry.gd`**
A registry system for node exporters. It maps Godot node class names (like `Button` or `Label`) to their corresponding exporter scripts. If a specific exporter isn't found, it traverses the ClassDB inheritance chain to find a suitable fallback (e.g., falling back to `ControlExporter`).

**`resource_resolver.gd`**
Manages and deduplicates Godot resources (Fonts, Textures, StyleBoxes) encountered during scene analysis. It assigns unique IDs to resources and caches them, allowing the SVG backend to embed them as base64 strings or link them externally in the `<defs>` section.

**`utils.gd`**
A utility class providing static helper functions, primarily centralized logging (`log_message`, `log_warning`, `log_error`) that prefixes output with `[SceneExporter]` for easy debugging in the Godot console.

**`svg_optimizer.gd`**
A post-processing utility for the SVG string. It reduces file size by stripping unnecessary decimal precision, removing default attributes (like `fill="black"`), and optionally compacting whitespace if pretty-printing is disabled.

**`font_subsetter.gd`**
A utility that scans the final `RenderDocument` to collect all unique Unicode characters used in text elements. This simulates font subsetting, allowing the system to know exactly which glyphs are needed, even if the actual subsetting is deferred to an external tool.

### `addons/scene_exporter/analysis/`
**`scene_walker.gd`**
Traverses the Godot scene tree recursively. It creates a `NodeInfo` object for each node, invokes the property, visibility, and theme resolvers to populate it, and builds a hierarchical representation of the scene.

**`node_info.gd`**
A data class (RefCounted) that stores all collected information for a single node, including its properties, resolved theme data, absolute layout transforms, clipping rectangles, and extracted animations.

**`property_resolver.gd`**
Extracts exported properties from Godot nodes using `get_property_list()`. It filters for editor-relevant properties like position, size, anchors, modulate, and custom script variables, storing them in a dictionary.

**`visibility_resolver.gd`**
Determines the visibility state of a node. It checks both the node's own `visible` property and its visibility within the scene tree, as well as whether `clip_contents` is enabled, which is crucial for SVG clipping masks.

**`theme_resolver.gd`**
Resolves the final visual style for a Control node. It bypasses Godot's direct theme queries by iterating through possible theme properties (colors, constants, fonts, icons, styleboxes) to capture fully resolved values, including overrides and inherited themes.

**`animation_resolver.gd`**
Scans the scene for `AnimationPlayer` nodes. It extracts animation tracks (position, rotation, scale, opacity, color) and maps them to their corresponding `NodeInfo` objects as `RenderAnimation` data, which the SVG backend later converts to SMIL.

### `addons/scene_exporter/layout/`
**`layout_solver.gd`**
The layout coordinator. It traverses the `NodeInfo` tree and invokes the anchor, container, transform, and clip solvers to convert Godot's dynamic layout system into explicit absolute geometry.

**`anchor_solver.gd`**
Extracts the final absolute position of a `Control` node. In Godot 4, the engine resolves anchors and offsets automatically; this solver simply reads the computed `position` relative to its parent.

**`container_solver.gd`**
Identifies container nodes (VBox, HBox, Grid, etc.). It flags them as "layout only" in the `NodeInfo` so the render model knows not to draw the container itself, while extracting container-specific properties like separation for potential debug/export use.

**`transform_solver.gd`**
Calculates the final local transform of a node. For `Control` nodes, it manually constructs a `Transform2D` using the node's position, rotation, scale, and pivot offset, as Godot doesn't expose a single `transform` property for Controls.

**`clip_solver.gd`**
Computes the clipping rectangle for a node. If a node has `clip_contents` enabled, it defines a clip rect of its own size; otherwise, it inherits the clip rect of its parent.

### `addons/scene_exporter/render_model/`
This directory contains the backend-independent Intermediate Representation (IR) of the UI.

**`render_object.gd`**
The base class for all renderable objects. It contains common properties like `object_type`, `id`, `node_name`, `transform`, `style`, `clip`, `visible`, and `animations`.

**`render_document.gd`**
The root of the render model (extends `RenderGroup`). It holds document-level metadata like total width, height, and background color.

**`render_group.gd`**
Represents a hierarchical group (like a Godot `Control` or `Container`). It contains an array of child `RenderObject`s. It maps to an SVG `<g>` element.

**`render_shape.gd`**
Represents a shape primitive (Rectangle, Rounded Rectangle, Circle). It holds geometry data (`rect`, `corner_radius`) and maps to SVG `<rect>` or `<circle>` elements.

**`render_style.gd`**
Stores visual styling properties independent of the backend, such as fill color, stroke color/width, opacity, font details, and shadow parameters (color, size, offset).

**`render_transform.gd`**
Stores 2D transformation data (origin, rotation, scale) extracted from Godot's `Transform2D`, which the SVG writer converts into `matrix()` or `translate/rotate/scale` attributes.

**`render_text.gd`**
Represents a text primitive. It stores the raw string, position, and alignment, mapping to an SVG `<text>` element.

**`render_image.gd`**
Represents an image primitive. It stores the resource ID and the target rectangle, mapping to an SVG `<image>` element.

**`render_clip.gd`**
Represents a clipping region. It defines a rectangle or path that restricts the visible area of render objects, mapping to an SVG `<clipPath>` element.

**`render_animation.gd`**
Represents a serialized animation track. It stores the target property (e.g., "transform.translate"), keyframes, duration, and loop mode, mapping to SVG SMIL `<animate>` or `<animateTransform>` elements.

### `addons/scene_exporter/exporters/`
This directory contains the logic for converting `NodeInfo` into `RenderObject`s.

**`base_exporter.gd`**
The base interface for all node exporters. It handles the creation of the base `RenderGroup`, applies local transforms, manages clipping (creating an inner clip group if `clip_contents` is true to prevent clipping the node's own shadow), and recursively processes children.

**`control_exporter.gd`**
A generic exporter for `Control` nodes. It calls the base exporter and serves as a fallback for controls that don't have specific visual elements.

**`container_exporter.gd`**
Handles container nodes. It ensures containers are flagged as layout-only (so they don't render a visual shape), except for `PanelContainer`, which renders its background stylebox before processing children.

**`panel_exporter.gd`**
Exports `Panel`, `ColorRect`, and `NinePatchRect`. It extracts `StyleBoxFlat` or `StyleBoxTexture` data to create `RenderShape` or `RenderImage` primitives. It correctly handles complex features like non-uniform borders, corner radii, and SVG-compatible drop shadows using filter IDs.

**`label_exporter.gd`**
Exports `Label` and `RichTextLabel`. It resolves font, color, and size from the theme. It handles BBCode tags (like `[right]`, `[font_size]`) to determine alignment and text spans. It also adjusts vertical alignment specifically for RichTextLabels to match Godot's top-aligned default behavior.

**`button_exporter.gd`**
Exports the `Button` family (`Button`, `LinkButton`, `CheckBox`, etc.). It extracts the 'normal' state stylebox for the background, resolves the icon texture, and creates a `RenderText` object for the button's label, handling specific alignment centering.

**`text_input_exporter.gd`**
Exports `LineEdit`, `TextEdit`, and `CodeEdit`. It extracts the background stylebox and text content, handling placeholder text and placeholder colors if the input is empty.

**`texture_exporter.gd`**
Exports `TextureRect` and `TextureButton`. It extracts the texture resource, registers it with the `ResourceResolver`, and creates a `RenderImage` primitive, applying modulation as an opacity modifier if necessary.

### `addons/scene_exporter/backends/svg/`
This directory handles the serialization of the `RenderDocument` into the final SVG XML string.

**`svg_writer.gd`**
The main SVG serialization coordinator. It initializes the `SVGDocument`, generates the `<defs>` block, and recursively writes all `RenderObject`s to the document by delegating to specialized sub-writers.

**`svg_document.gd`**
A string builder utility specifically for XML/SVG. It manages indentation, open/close tags, and self-closing tags, ensuring the output is well-formed and optionally pretty-printed.

**`svg_defs_writer.gd`**
Generates the `<defs>` block. It traverses the render model to collect unique resources (Fonts, Images), clipping rectangles, and shadow filters. It writes them as `<font-face>`, `<image>`, `<clipPath>`, and `<filter>` elements, ensuring strict 6-character hex codes for maximum SVG viewer compatibility.

**`svg_style_writer.gd`**
Converts `RenderStyle` and `RenderTransform` objects into SVG attribute strings. It handles `fill`, `stroke`, `opacity`, `clip-path`, and `filter` references, ensuring colors are formatted correctly.

**`svg_shape_writer.gd`**
Converts `RenderShape` objects into SVG geometry tags (`<rect>`, `<circle>`), applying the style and transform attributes generated by the style writer.

**`svg_text_writer.gd`**
Converts `RenderText` objects into SVG `<text>` tags. It contains complex logic for parsing Godot BBCode (`[b]`, `[color]`, `[font_size]`) into SVG `<tspan>` elements. It also handles multi-line text (`\n`) with proper `dy` line spacing, and implements Bidirectional (BiDi) text support (`direction="rtl"`, `unicode-bidi="embed"`) to correctly render Arabic/RTL text and punctuation without displacing the text block.

**`svg_image_writer.gd`**
Converts `RenderImage` objects into SVG `<image>` tags, linking the `href` to the embedded base64 data or external path defined in the `<defs>` block.

**`svg_animation_writer.gd`**
Converts `RenderAnimation` objects into SVG SMIL animation tags (`<animate>`, `<animateTransform>`), formatting keyframes, durations, and interpolation modes.

### `addons/scene_exporter/diagnostics/`
**`logger.gd`**
A specialized logger for the diagnostics phase that routes messages to both the Godot console and the `ExportReport`.

**`compatibility.gd`**
Checks nodes for features that cannot be exported to SVG. It flags custom `_draw()` methods, custom `ShaderMaterial`s, and unsupported node types, adding them to the report as warnings or unsupported items.

**`validator.gd`**
Traverses the `NodeInfo` tree pre-export to run compatibility checks. It ensures the export process won't crash on unsupported features and that the user is informed of visual discrepancies.

**`report_writer.gd`**
Generates a human-readable text file summarizing the export process. It outputs statistics (scanned, exported, unsupported) and details every issue encountered, including the node name, reason, fallback behavior, and a suggestion for fixing it.

### `addons/scene_exporter/ui/`
**`export_dock.tscn` / `export_dock.gd`**
The main editor dock UI. It provides a simple interface with a "Refresh" button to auto-detect the active scene, an input field for the output SVG path, and an "Export to SVG" button that triggers the `Exporter` pipeline.

**`settings_dialog.tscn` / `settings_dialog.gd`**
An optional configuration dialog. It allows users to toggle settings like embedding images/fonts, pretty-printing XML, ignoring hidden nodes, and setting decimal precision.

**`preview_panel.tscn` / `preview_panel.gd`**
A preview window (accessible via a UI button). It captures a live render of the Godot scene using a `SubViewport`, generates the SVG, loads it back as a texture, and uses a custom shader to display a split-screen or difference overlay, allowing the user to visually verify the 1:1 export accuracy.

**`diff_overlay.gdshader`**
A canvas item shader used by the preview panel. It takes two textures (the live Godot render and the generated SVG render) and blends them or calculates the absolute difference to highlight visual discrepancies.