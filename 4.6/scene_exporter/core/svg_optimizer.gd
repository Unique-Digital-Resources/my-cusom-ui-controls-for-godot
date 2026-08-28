class_name SVGOptimizer
extends RefCounted

# Post-processes the SVG string to reduce file size.
# Handles precision rounding, whitespace removal, and stripping default attributes.

var _precision: int = 2
var _pretty_print: bool = true

func _init(precision: int = 2, pretty_print: bool = true):
	_precision = precision
	_pretty_print = pretty_print

func optimize(svg_string: String) -> String:
	ExportUtils.log_message("Optimizing SVG output...")
	
	var optimized = svg_string
	
	# 1. Precision optimization (e.g., 12.34000 -> 12.34)
	# Fix: Godot 4 RegEx.sub() requires a String replacement, not a Callable. 
	# We use a capturing group to keep the desired precision and strip the rest.
	var regex = RegEx.new()
	regex.compile("(\\d+\\.\\d{%d})\\d+" % _precision)
	optimized = regex.sub(optimized, "$1", true)
	
	# 2. Default attribute stripping
	optimized = optimized.replace(" fill=\"black\"", "")
	optimized = optimized.replace(" stroke=\"none\"", "")
	optimized = optimized.replace(" opacity=\"1.000\"", "")
	optimized = optimized.replace(" fill-opacity=\"1.000\"", "")
	
	# 3. Whitespace optimization (if not pretty printing)
	if not _pretty_print:
		# Remove leading/trailing whitespace per line
		var lines = optimized.split("\n")
		var compact_lines: PackedStringArray = []
		for line in lines:
			var trimmed = line.strip_edges()
			if trimmed != "":
				compact_lines.append(trimmed)
		optimized = "".join(compact_lines)
		
	return optimized
