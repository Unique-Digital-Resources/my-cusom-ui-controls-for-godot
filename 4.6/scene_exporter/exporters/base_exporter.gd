class_name BaseExporter
extends RefCounted

# Base interface for all node exporters.

func export_node(info: NodeInfo, context: ExportContext) -> RenderGroup:
	var group = RenderGroup.new()
	group.node_name = info.node_name
	group.id = info.node_name
	
	# Fix: Skip non-Control nodes (like Camera2D, Node2D) to prevent missing exporter warnings
	if not info.node is Control:
		group.visible = false
		return group
		
	if not info.visibility.get("is_visible_in_tree", true):
		group.visible = false
		
	# Apply Local Transform
	group.transform.from_transform2d(info.absolute_transform)
	
	# Apply Modulate (Opacity and Color Tint)
	var modulate = info.properties.get("modulate", Color.WHITE)
	if modulate != Color.WHITE:
		group.style.opacity = modulate.a
		# Fix: If the modulate has a color tint, apply it via a filter ID
		if modulate.r != 1.0 or modulate.g != 1.0 or modulate.b != 1.0:
			group.style.modulate_color = modulate
			
	# Apply Clip (Local coordinates only!)
	var children_group = group
	if info.properties.get("clip_contents", false):
		var clip_group = RenderGroup.new()
		clip_group.node_name = info.node_name + "_clip"
		clip_group.clip = RenderClip.new()
		clip_group.clip.clip_type = "rect"
		clip_group.clip.rect = Rect2(Vector2.ZERO, info.size)
		group.add_child(clip_group)
		children_group = clip_group
		
	group.animations = info.animations
	
	for child_info in info.children_info:
		# Fix: Skip non-Control children silently
		if not child_info.node is Control:
			continue
			
		var child_exporter = context.registry.get_exporter(child_info.node_type)
		if child_exporter:
			var child_group = child_exporter.export_node(child_info, context)
			children_group.add_child(child_group)
			context.report.exported += 1
		else:
			context.report.unsupported += 1
			context.report.add_issue(child_info.node_name, "No exporter registered for type " + child_info.node_type, "Skipped", "Implement exporter")
			
	return group
