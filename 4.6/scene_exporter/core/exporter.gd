class_name Exporter
extends RefCounted

# Main export pipeline coordinator

var registry: ExporterRegistry

func _init():
	registry = ExporterRegistry.new()

func export_scene(root_node: Node, settings: ExportSettings) -> ExportReport:
	if settings.is_video_export:
		var video_exporter = VideoExporter.new()
		return await video_exporter.export_video(root_node, settings)
		
	var start_time = Time.get_ticks_msec()
	
	var walker = SceneWalker.new()
	var context = ExportContext.new(settings, registry, walker.resource_resolver)
	
	ExportUtils.log_message("Starting export for scene: " + root_node.name)
	
	var root_info = walker.walk(root_node)
	
	var layout_solver = LayoutSolver.new()
	layout_solver.solve(root_info)
	
	if settings.export_animations:
		var anim_resolver = AnimationResolver.new()
		anim_resolver.resolve(root_node, root_info)
	
	context.report.nodes_scanned = _count_nodes(root_info)
	
	var validator = SceneValidator.new()
	validator.validate(root_info, context.report)
	
	# Phase 7: Backend Generation
	var output_content = ""
	var ext = settings.output_path.get_extension().to_lower()
	
	if ext == "svg":
		# Build Render Model for SVG
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
			
		if settings.subset_fonts:
			var subsetter = FontSubsetter.new()
			_collect_text_for_subset(context.render_document, subsetter)
			
		# Phase 2: Resolve Camera2D Transform as a raw SVG string
		var camera_transform_str = _get_camera_transform_string(root_node, settings.camera_node_path, render_doc.width, render_doc.height)
		
		ExportUtils.log_message("Generating SVG document...")
		var svg_writer = SVGWriter.new()
		# Pass the camera transform string to the writer
		output_content = svg_writer.write(context.render_document, context, camera_transform_str)
		if settings.optimize_svg:
			var optimizer = SVGOptimizer.new(settings.decimal_precision, settings.pretty_print)
			output_content = optimizer.optimize(output_content)
			
	elif ext == "html":
		# Generate Semantic HTML directly from NodeInfo tree (Camera transform is ignored for HTML)
		ExportUtils.log_message("Generating Semantic HTML document...")
		var html_writer = HTMLWriter.new(walker.resource_resolver, settings)
		output_content = html_writer.write(root_info)
		
	else:
		ExportUtils.log_error("Unsupported export format: ." + ext)
		return context.report
		
	_save_file(output_content, settings.output_path)
	
	var report_writer = ReportWriter.new()
	report_writer.write_report(context.report, settings.output_path)
	
	ExportUtils.log_message("Export completed in %d ms." % (Time.get_ticks_msec() - start_time))
	context.report.print_report()
	
	return context.report

# Extracts the Camera2D transform and converts it to an SVG transform string
func _get_camera_transform_string(root_node: Node, camera_path: NodePath, doc_width: float, doc_height: float) -> String:
	if camera_path == null or camera_path.is_empty():
		return ""
		
	var cam = root_node.get_node_or_null(camera_path)
	if not cam is Camera2D:
		ExportUtils.log_warning("Selected camera node is not a Camera2D: " + str(camera_path))
		return ""
		
	ExportUtils.log_message("Applying Camera2D transform: " + cam.name)
	
	var cam_pos = cam.global_position
	var cam_offset = cam.offset if "offset" in cam else Vector2.ZERO
	var viewport_center = Vector2(doc_width / 2.0, doc_height / 2.0)
	
	var parts: PackedStringArray = PackedStringArray()
	
	# SVG transforms are applied right-to-left.
	# So this translates the world by -cam_pos, then applies zoom/rotation, 
	# then translates the result to the center of the SVG viewport.
	
	# 1. Translate to viewport center (screen space)
	parts.append("translate(%.2f, %.2f)" % [viewport_center.x, viewport_center.y])
	
	# 2. Rotate
	if "rotation" in cam and cam.rotation != 0.0:
		parts.append("rotate(%.2f)" % rad_to_deg(cam.rotation))
		
	# 3. Scale (Zoom)
	var zoom = cam.zoom if "zoom" in cam else Vector2.ONE
	if zoom != Vector2.ONE:
		parts.append("scale(%.2f, %.2f)" % [zoom.x, zoom.y])
		
	# 4. Translate by -(cam_pos + cam_offset) (world space)
	var final_offset = cam_pos + cam_offset
	parts.append("translate(%.2f, %.2f)" % [-final_offset.x, -final_offset.y])
	
	return " ".join(parts)

func _count_nodes(info: NodeInfo) -> int:
	var count = 1
	for child in info.children_info:
		count += _count_nodes(child)
	return count

func _collect_text_for_subset(obj: RenderObject, subsetter: FontSubsetter) -> void:
	if obj is RenderText:
		subsetter.collect_text((obj as RenderText).text)
	elif obj is RenderGroup:
		for child in (obj as RenderGroup).children:
			_collect_text_for_subset(child, subsetter)

func _save_file(content: String, path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		ExportUtils.log_message("File successfully saved to: " + path)
	else:
		ExportUtils.log_error("Failed to save file to: " + path)
