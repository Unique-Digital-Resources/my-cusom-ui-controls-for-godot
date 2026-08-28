class_name SceneWalker
extends RefCounted

# Traverses the scene tree, maintains hierarchy, and collects NodeInfo

var property_resolver: PropertyResolver
var visibility_resolver: VisibilityResolver
var theme_resolver: ThemeResolver
var resource_resolver: ResourceResolver

func _init():
	property_resolver = PropertyResolver.new()
	visibility_resolver = VisibilityResolver.new()
	
	resource_resolver = ResourceResolver.new()
	theme_resolver = ThemeResolver.new(resource_resolver)

func walk(root: Node) -> NodeInfo:
	ExportUtils.log_message("Walking scene tree starting from: " + root.name)
	var root_info = _process_node(root, null)
	return root_info

func _process_node(node: Node, parent_info: NodeInfo) -> NodeInfo:
	var info = NodeInfo.new()
	info.node = node
	
	# Fix: Detect custom GDScript class names (like SvgVectorControl or Lucide)
	var script = node.get_script()
	if script is GDScript:
		var global_name = script.get_global_name()
		if global_name != "":
			info.node_type = global_name
		else:
			info.node_type = node.get_class()
	else:
		info.node_type = node.get_class()
		
	info.node_name = node.name
	info.parent_info = parent_info
	
	info.properties = property_resolver.resolve(node)
	info.visibility = visibility_resolver.resolve(node)
	
	if node is Control:
		info.transform = node.get_global_transform_with_canvas()
		info.global_position = node.global_position
		info.size = node.size
		info.resolved_theme = theme_resolver.resolve(node)
	
	for child in node.get_children():
		var child_info = _process_node(child, info)
		info.children_info.append(child_info)
		
	return info

func print_info_tree(info: NodeInfo, indent: int = 0):
	var prefix = ""
	for i in range(indent):
		prefix += "  "
		
	var theme_info = ""
	if info.resolved_theme.size() > 0:
		theme_info = " [Theme: %d colors, %d styles]" % [info.resolved_theme.colors.size(), info.resolved_theme.styleboxes.size()]
		
	ExportUtils.log_message(prefix + "- " + info.node_name + " (" + info.node_type + ") [Visible: " + str(info.visibility.get("is_visible_in_tree", false)) + "]" + theme_info)
	
	for child in info.children_info:
		print_info_tree(child, indent + 1)
