#@tool
#class_name LayoutEngine
#extends RefCounted
#
### Orchestrates the two-pass layout system.
###
### 1. Measure: Calculates width, height, and baseline recursively.
### 2. Arrange: Assigns final positions to children relative to parent.
#
#static func layout(element: MathElement, context: RenderContext) -> void:
	#if not element or not context:
		#return
		#
	## Pass 1: Measure
	#element.measure(context)
	#
	## Pass 2: Arrange
	## Root element starts at local (0,0)
	#element.arrange(context, Vector2.ZERO)
