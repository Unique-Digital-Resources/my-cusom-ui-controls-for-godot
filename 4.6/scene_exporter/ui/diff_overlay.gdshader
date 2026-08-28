shader_type canvas_item;
render_mode unshaded;

uniform sampler2D godot_tex;
uniform sampler2D svg_tex;
uniform float mode : hint_range(0.0, 1.0) = 0.5; // 0 = Godot, 0.5 = Difference, 1 = SVG

void fragment() {
    vec4 c_godot = texture(godot_tex, UV);
    vec4 c_svg = texture(svg_tex, UV);
    
    vec4 diff = abs(c_godot - c_svg);
    
    if (mode < 0.33) {
        // Godot Only
        COLOR = vec4(c_godot.rgb, 1.0);
    } else if (mode < 0.66) {
        // Difference Overlay (inverted to show errors as dark spots)
        COLOR = vec4(1.0 - diff.rgb, 1.0);
    } else {
        // SVG Only
        COLOR = vec4(c_svg.rgb, 1.0);
    }
}