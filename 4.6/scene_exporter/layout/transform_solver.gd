class_name TransformSolver
extends RefCounted

# Resolves the local transform of a node.
# SVG groups inherit transforms, so we only apply the local transform relative to the parent.

func resolve(info: NodeInfo) -> Transform2D:
	if info.node is Control:
		var ctrl = info.node as Control
		var pivot = ctrl.pivot_offset
		
		# Manually construct the local transform
		# Order: Translate to position+pivot -> Rotate -> Scale -> Translate back by pivot
		var t = Transform2D.IDENTITY
		t = t.translated(ctrl.position + pivot)
		t = t.rotated(ctrl.rotation)
		t = t.scaled(ctrl.scale)
		t = t.translated(-pivot)
		return t
		
	elif info.node is Node2D:
		return info.node.transform
		
	return Transform2D.IDENTITY
