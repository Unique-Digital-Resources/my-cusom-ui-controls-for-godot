class_name SVGShapeWriter
extends RefCounted

# Serializes RenderShape objects into SVG shape tags

func write(shape: RenderShape, style_attrs: String, transform_attrs: String, clip_attrs: String) -> String:
	var attrs = transform_attrs + " " + style_attrs + " " + clip_attrs
	attrs = attrs.strip_edges()
	if attrs != "":
		attrs = " " + attrs
		
	match shape.shape_type:
		"rect":
			return "<rect x=\"%.2f\" y=\"%.2f\" width=\"%.2f\" height=\"%.2f\"%s />" % [shape.rect.position.x, shape.rect.position.y, shape.rect.size.x, shape.rect.size.y, attrs]
		"rounded_rect":
			return "<rect x=\"%.2f\" y=\"%.2f\" width=\"%.2f\" height=\"%.2f\" rx=\"%.2f\" ry=\"%.2f\"%s />" % [shape.rect.position.x, shape.rect.position.y, shape.rect.size.x, shape.rect.size.y, shape.corner_radius, shape.corner_radius, attrs]
		"circle":
			var r = shape.corner_radius
			return "<circle cx=\"%.2f\" cy=\"%.2f\" r=\"%.2f\"%s />" % [shape.rect.position.x, shape.rect.position.y, r, attrs]
		_:
			return ""
