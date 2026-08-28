class_name AnchorSolver
extends RefCounted

# Resolves anchors and offsets into explicit local geometry.
# For hierarchical SVG groups, we need the local position relative to the parent.

func resolve(info: NodeInfo) -> Vector2:
	if info.node is Control:
		var ctrl = info.node as Control
		# Return local position, not global
		return ctrl.position
	return Vector2.ZERO
