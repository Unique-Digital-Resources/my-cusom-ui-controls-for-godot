@tool
class_name MixGradient
extends Resource

## A custom gradient that mixes two separate Gradients (e.g., by X and Y).
## Create one in the inspector and assign it to your LineSeries or PieSlice.

enum MixMode { 
	AVERAGE,    ## Simple 50/50 blend
	BLEND,      ## Uses blend_amount to lerp between Grad X and Grad Y
	ADD,        ## Adds colors together
	MULTIPLY    ## Multiplies colors together
}

@export var gradient_x: Gradient
@export var gradient_y: Gradient
@export var mix_mode: MixMode = MixMode.AVERAGE
@export_range(0.0, 1.0) var blend_amount: float = 0.5

func sample(t_x: float, t_y: float) -> Color:
	var c1 = gradient_x.sample(t_x) if gradient_x else Color.WHITE
	var c2 = gradient_y.sample(t_y) if gradient_y else Color.WHITE
	
	match mix_mode:
		MixMode.AVERAGE: return (c1 + c2) * 0.5
		MixMode.BLEND: return c1.lerp(c2, blend_amount)
		MixMode.ADD: return c1 + c2
		MixMode.MULTIPLY: return c1 * c2
	return c1
