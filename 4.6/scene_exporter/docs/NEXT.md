# Developer Documentation: Adding Video Export Support

Since SVG is inherently a static or vector-animated format, exporting a true video file (like `.mp4`, `.webm`, or `.gif`) requires a hybrid approach. The most reliable way to implement video export in a Godot editor plugin is to generate a sequence of frames and compile them using an external tool like **FFmpeg**.

This guide outlines how to add a `VideoExporter` backend that hooks into the existing SVG pipeline.

---

## Concept: The Frame-by-Frame Approach

Because SVG rendering engines vary in their support for SMIL animations (and Godot cannot natively render SVGs to raster pixels easily), the best approach is:
1. Find all `AnimationPlayer` nodes in the scene.
2. Step through the animation timeline frame-by-frame.
3. For each frame, force the Godot scene to update its layout.
4. Run the existing SVG export pipeline to generate a static SVG for that frame.
5. Use `OS.execute()` to call FFmpeg, converting the sequence of SVGs (or rasterized PNGs) into a video file.

---

## Step 1: Add Video Settings to `ExportSettings`

First, we need to tell the plugin to expect a video output and define the framerate.

Update `addons/scene_exporter/core/export_settings.gd`:
```gdscript
class_name ExportSettings
extends Resource

@export var output_path: String = "res://export.svg"
# ... other settings ...

# Video Settings
@export var is_video_export: bool = false
@export var fps: int = 30
@export var duration: float = 2.0 # In seconds

func _to_string() -> String:
	return "ExportSettings(path=%s, video=%s, fps=%d)" % [output_path, is_video_export, fps]
```

---

## Step 2: Create the Video Exporter Backend

Create a new script at `addons/scene_exporter/backends/video/video_exporter.gd`. This script will handle the frame iteration and FFmpeg compilation.

```gdscript
# addons/scene_exporter/backends/video/video_exporter.gd
class_name VideoExporter
extends RefCounted

var exporter: Exporter

func _init():
	exporter = Exporter.new()

func export_video(root_node: Node, settings: ExportSettings) -> ExportReport:
	var report = ExportReport.new()
	var anim_players = root_node.find_children("*", "AnimationPlayer", true, false)
	
	if anim_players.is_empty():
		ExportUtils.log_error("No AnimationPlayer found for video export.")
		return report
		
	var player = anim_players[0]
	var default_anim = "RESET"
	if player.has_animation("RESET"):
		player.play("RESET")
		await RenderingServer.frame_post_draw
	elif player.get_animation_list().size() > 0:
		default_anim = player.get_animation_list()[0]
		player.play(default_anim)
		await RenderingServer.frame_post_draw
		
	var total_frames = int(settings.duration * settings.fps)
	var temp_dir = "user://video_frames/"
	DirAccess.make_dir_recursive_absolute(temp_dir)
	
	ExportUtils.log_message("Starting video export: %d frames at %d FPS..." % [total_frames, settings.fps])
	
	# 1. Capture Frames
	for i in range(total_frames):
		var time = float(i) / float(settings.fps)
		player.seek(time, true)
		
		# Force Godot to process the frame layout before exporting
		await RenderingServer.frame_post_draw
		
		# Create a temporary export setting for this specific frame
		var frame_settings = settings.duplicate()
		frame_settings.is_video_export = false
		frame_settings.output_path = temp_dir + "frame_%05d.svg" % i
		
		# Run the standard SVG pipeline for this frame
		exporter.export_scene(root_node, frame_settings)
		
	# 2. Compile Video using FFmpeg
	_compile_video(temp_dir, settings.output_path, settings.fps)
	
	# 3. Cleanup frames
	_remove_dir_contents(temp_dir)
	DirAccess.remove_absolute(temp_dir)
	
	ExportUtils.log_message("Video export complete: " + settings.output_path)
	return report

func _compile_video(input_dir: String, output_path: String, fps: int) -> void:
	var input_pattern = ProjectSettings.globalize_path(input_dir) + "frame_%05d.svg"
	var global_output = ProjectSettings.globalize_path(output_path)
	
	# Note: FFmpeg needs to be installed and in the system PATH.
	# You may need to use librsvg or ImageMagick for SVG rendering in FFmpeg depending on OS.
	var args = [
		"-y", # Overwrite output
		"-r", str(fps), # Framerate
		"-i", input_pattern, # Input pattern
		"-c:v", "libx264", # Codec
		"-pix_fmt", "yuv420p",
		global_output
	]
	
	ExportUtils.log_message("Running FFmpeg...")
	var output = []
	var exit_code = OS.execute("ffmpeg", args, output, true)
	
	if exit_code != 0:
		ExportUtils.log_error("FFmpeg failed to compile video. Ensure FFmpeg is installed and in your system PATH.")
		for line in output:
			ExportUtils.log_error(line)

func _remove_dir_contents(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
```

---

## Step 3: Integrate into the Main Pipeline

Modify `addons/scene_exporter/core/exporter.gd` to detect when a video export is requested and route it to the `VideoExporter`. Because video export involves `await` (waiting for the engine to draw frames), the main export function must be async if it's a video export.

Update the `export_scene` function in `addons/scene_exporter/core/exporter.gd`:

```gdscript
class_name Exporter
extends RefCounted

var registry: ExporterRegistry

func _init():
	registry = ExporterRegistry.new()

# Change to async function to support frame waiting
func export_scene(root_node: Node, settings: ExportSettings) -> ExportReport:
	# 1. Check if this is a video export
	if settings.is_video_export:
		var video_exporter = VideoExporter.new()
		return await video_exporter.export_video(root_node, settings)
		
	# 2. Standard Static SVG Export (Existing Code)
	var start_time = Time.get_ticks_msec()
	
	var walker = SceneWalker.new()
	var context = ExportContext.new(settings, registry, walker.resource_resolver)
	
	ExportUtils.log_message("Starting export for scene: " + root_node.name)
	
	var root_info = walker.walk(root_node)
	
	var layout_solver = LayoutSolver.new()
	layout_solver.solve(root_info)
	
	var anim_resolver = AnimationResolver.new()
	anim_resolver.resolve(root_node, root_info)
	
	context.report.nodes_scanned = _count_nodes(root_info)
	
	var validator = SceneValidator.new()
	validator.validate(root_info, context.report)
	
	var render_doc = RenderDocument.new()
	render_doc.node_name = "RootDocument"
	if root_node is Control:
		render_doc.width = root_node.size.x
		render_doc.height = root_node.size.y
	context.render_document = render_doc
	
	ExportUtils.log_message("Building render model...")
	var root_exporter = registry.get_exporter(root_info.node_type)
	if root_exporter:
		var root_group = root_exporter.export_node(root_info, context)
		for child in root_group.children:
			context.render_document.add_child(child)
		context.report.exported += 1
	
	ExportUtils.log_message("Generating SVG document...")
	var svg_writer = SVGWriter.new()
	var svg_content = svg_writer.write(context.render_document, context)
	
	if settings.optimize_svg:
		var optimizer = SVGOptimizer.new(settings.decimal_precision, settings.pretty_print)
		svg_content = optimizer.optimize(svg_content)
	
	_save_svg(svg_content, settings.output_path)
	
	var report_writer = ReportWriter.new()
	report_writer.write_report(context.report, settings.output_path)
	
	ExportUtils.log_message("Export completed in %d ms." % (Time.get_ticks_msec() - start_time))
	context.report.print_report()
	
	return context.report

# ... keep _count_nodes and _save_svg functions ...
```

---

## Step 4: Update the UI

Update `addons/scene_exporter/ui/export_dock.gd` to add a checkbox for video export and adjust the file extension.

```gdscript
# Inside export_dock.gd

func _on_export_pressed():
	var settings = ExportSettings.new()
	settings.output_path = output_line_edit.text
	
	# Example: Add UI elements for video export
	# If the user checked the "Export as Video" checkbox:
	# settings.is_video_export = true
	# settings.fps = 30
	# settings.duration = 2.0
	# settings.output_path = settings.output_path.replace(".svg", ".mp4")
	
	var root_node = get_tree().edited_scene_root
	if not root_node:
		ExportUtils.log_error("No active scene to export.")
		return
		
	ExportUtils.log_message("Initiating export...")
	var exporter = Exporter.new()
	
	# If video export, we must await the async function
	if settings.is_video_export:
		await exporter.export_scene(root_node, settings)
	else:
		exporter.export_scene(root_node, settings)
```

## Important Considerations for Video Export

1. **FFmpeg Dependency**: This implementation relies entirely on FFmpeg being installed on the user's OS. You should add a check in the plugin or documentation instructing users to install FFmpeg and add it to their system `PATH`.
2. **Performance**: Stepping through a Godot scene frame-by-frame and walking the tree 60+ times is computationally heavy. It is recommended to hide the UI or show a progress bar during video export.
3. **SVG Rasterization in FFmpeg**: By default, FFmpeg might not render SVGs perfectly (it depends on how it was compiled, often requiring `librsvg`). An alternative approach is to use Godot's `SubViewport` to capture the screen as PNGs, and then use FFmpeg to compile the PNGs into a video.
4. **Restoring Scene State**: After the video export is complete, the `AnimationPlayer` will be left at the last frame. You should add logic at the end of `VideoExporter.export_video` to seek back to time `0.0` or play the `"RESET"` animation to restore the editor scene to its original state.