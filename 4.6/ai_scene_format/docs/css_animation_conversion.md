Here is the comprehensive documentation for converting CSS Animations to the AI Scene Format. This guide incorporates all the edge cases, layout engine rules, and pitfalls we discovered during testing.

You can save this as `addons/ai_scene_format/docs/css_to_animation_format.md`.

---

# CSS Animation to AI Scene Format Conversion Guide

This document defines the rules and mappings for converting CSS animations (`@keyframes`, `transition`, `transform`, `opacity`) into the AI Scene Format (Animation Domain).

Because Godot's animation system is track-based and relies on the Scene Tree hierarchy, direct 1:1 translation requires careful pathing and an understanding of Godot's Container layout engine.

## 1. The Golden Rule: Track Paths

In CSS, animations target HTML classes (`.badge`). In Godot, `AnimationPlayer` targets **NodePaths** relative to itself. 

If your `AnimationPlayer` is a child of the root node, you must provide the **full hierarchical path** to the node, separated by `/`, followed by a `:` and the property name.

*   **CSS:** `.badge { opacity: 0; }`
*   **AI Format:** `track "MainSplit/TextSide/TextMargins/TextContent/Badge:modulate"`

*Note: If the `AnimationPlayer` is a child of the node it is animating, use a relative path: `track ":modulate"`.*

## 2. CSS Property to Godot Property Mapping

| CSS Property | AI Format Track Target | Godot Value Type | Notes |
| :--- | :--- | :--- | :--- |
| `opacity` | `modulate` | `Color(r, g, b, a)` | CSS opacity maps to the Alpha channel (4th number) of the Color. `0` is transparent, `1` is opaque. RGB should usually remain `1, 1, 1`. |
| `transform: translateX/Y` | `position` | `Vector2(x, y)` | **See Section 4 for Container rules.** |
| `transform: scale` | `scale` | `Vector2(x, y)` | |
| `background-color` | `modulate` or `self_modulate` | `Color(r, g, b, a)` | If animating a background color, it multiplies the existing color. For exact color replacement, animate the `bg_color` property of the `StyleBoxFlat` resource. |
| `color` (text) | `theme_override_colors/font_color` | `Color(r, g, b, a)` | |

## 3. Handling CSS Delays (The 3-Keyframe Rule)

CSS allows you to define an animation duration and a separate delay (e.g., `0.8s ease 0.4s delay`). Godot does not have a per-track delay property. 

To mimic a delay, you must **bake it into the keyframe times** using three keyframes:
1.  **Start (0.0):** The initial state.
2.  **Delay End (0.4):** The *same* initial state. This holds the value during the delay.
3.  **Animation End (1.2):** The final state (Delay + Duration).

**CSS:**
```css
.title { animation: slideRight 0.8s ease 0.2s forwards; }
```

**AI Format:**
```text
track "Path/To/Title:modulate"
	type = VALUE
	interp = SINE
	keyframe 0.000 Color(1.0, 1.0, 1.0, 0.0) transition 1.00
	keyframe 0.200 Color(1.0, 1.0, 1.0, 0.0) transition 1.00  <-- Holds invisible during 0.2s delay
	keyframe 1.000 Color(1.0, 1.0, 1.0, 1.0) transition 1.00  <-- Animates to visible by 1.0s
```

## 4. The Container Conflict (Layout Breaking)

This is the most critical difference between HTML and Godot. 

In HTML, `transform: translateX(30px)` visually moves the element without affecting the DOM layout flow. 
In Godot, if a node is inside a `VBoxContainer` or `HBoxContainer`, the container actively controls the node's `position`. If you animate `position`, you override the container, which will **break the layout** (e.g., items will stack on top of each other at coordinate `0, 0`).

### Solution A: Animate Sub-Properties (X or Y only)
If you only need to slide horizontally or vertically, animate `position:x` or `position:y`. This overrides only one axis, allowing the Container to maintain control of the other axis.

```text
# Slides in from the right, but VBoxContainer still controls the Y (vertical) position
track "Path/To/Node:position:x"
    type = VALUE
    interp = SINE
    keyframe 0.000 30.0 transition 1.00
    keyframe 0.800 0.0 transition 1.00
```

### Solution B: The Wrapper Technique
If a node is aligned to the right (`size_flags_horizontal = 8` or `alignment = 2`) and you animate its `position:x`, you will pull it out of its right-alignment. 

To fix this, wrap the node in an `HBoxContainer` that fills the width (`size_flags_horizontal = 3`) and aligns its children to the right (`alignment = 2`). Then, animate the **wrapper's** `position:x`. Because the wrapper starts at `X = 0` (the left edge), animating it from `30` to `0` will not break its internal right-alignment logic.

```text
# 1. The Wrapper (Takes full width, pushes Badge to the right)
HBoxContainer BadgeWrapper #n_53
	layout_mode = 2
	size_flags_horizontal = 3
	alignment = 2
	
	Label Badge #n_61
		text = "استعد!"

# 2. The Animation (Targets the Wrapper, not the Badge)
track "Path/To/BadgeWrapper:position:x"
	type = VALUE
	interp = SINE
	keyframe 0.000 30.0 transition 1.00
	keyframe 0.800 0.0 transition 1.00
```

## 5. Easing and Timing Functions

Godot uses `interp` (Interpolation) and `transition` types. For CSS conversions, you only need to set the `interp` property on the track.

| CSS Timing Function | Godot `interp` Value | Notes |
| :--- | :--- | :--- |
| `ease` / `ease-in-out` | `SINE` | Best general-purpose equivalent for smooth CSS eases. |
| `ease-in` | `CUBIC` | |
| `ease-out` | `CUBIC` | |
| `linear` | `LINEAR` | |
| `cubic-bezier(...)` | `CUBIC` or `QUART` | Approximate using Godot's built-in math curves. |

## 6. Full Example Conversion

**CSS:**
```css
.badge {
    opacity: 0;
    animation: slideRight 0.8s ease 0s forwards;
}
@keyframes slideRight {
    from { opacity: 0; transform: translateX(30px); }
    to { opacity: 1; transform: translateX(0); }
}
```

**AI Scene Format (Animation Domain):**
```text
animation "intro_anim"
    length = 0.8
    loop = false
    
    track "MainSplit/TextSide/TextMargins/TextContent/BadgeWrapper:modulate"
        type = VALUE
        interp = SINE
        keyframe 0.000 Color(1.0, 1.0, 1.0, 0.0) transition 1.00
        keyframe 0.800 Color(1.0, 1.0, 1.0, 1.0) transition 1.00
        
    track "MainSplit/TextSide/TextMargins/TextContent/BadgeWrapper:position:x"
        type = VALUE
        interp = SINE
        keyframe 0.000 30.0 transition 1.00
        keyframe 0.800 0.0 transition 1.00
```
