You are completely right to call this out. The main goal of this project is to provide a complete, high-level mirror of Godot's capabilities. Up until now, we have built the core architecture and a *minimum viable subset* of features to prove the pipeline works. 

To achieve **100% feature parity** with Godot, here is a breakdown of what is currently supported vs. what native Godot features are still missing and need to be mapped into our high-level formats.

---

### 1. Layout Format
**Currently Supported:** Node creation, hierarchy, basic primitives (int, float, bool, string, Vector2/3, Color), and nested Resources (like `StyleBoxFlat`).
**Missing Native Features:**
*   **Instanced Scenes:** Referencing external `.tscn` files (e.g., `Scene MyEnemy instance="res://enemy.tscn"`).
*   **Full Theme Overrides:** We support `theme_override_styles/`, but we need to explicitly support `theme_override_fonts/`, `theme_override_font_sizes/`, and `theme_override_constants/`.
*   **Typed Arrays & Dictionaries:** Deep editing of specific indices/keys (e.g., adding a specific item to an `Array[String]` or updating a key in a `Dictionary` property).
*   **Custom Resource Scripts:** Explicitly instantiating a GDScript resource (e.g., `Resource Stats #r_1 script="res://stats.gd"`).
*   **Node Groups:** Adding nodes to groups (e.g., `groups = ["enemies", "bosses"]`).

### 2. Animation Format
**Currently Supported:** Value tracks, position tracks, length, loop mode, and linear/nearest/cubic interpolation.
**Missing Native Features:**
*   **Multiple Libraries:** Right now, we only write to the default `""` library. We need to support named libraries (e.g., `library "combat" \n animation "punch"`).
*   **Method Call Tracks:** Triggering GDScript functions on specific keyframes (e.g., `track "Player:shoot" type=METHOD keyframe 0.5`).
*   **Bezier Tracks:** Free-form curve editing for properties.
*   **Audio Tracks:** Playing `AudioStreamPlayer` resources at specific times with specific volumes.
*   **Animation Tracks:** Playing an animation *inside* another animation (nesting).
*   **Reset Tracks:** The `RESET` animation convention for reverting to default states.
*   **Track Interp Enums:** Full support for `CUBIC_GLANCE` and tangents.

### 3. Tween Format
**Currently Supported:** Property tweens, duration, transition, ease, relative, and infinite loop (ping-pong).
**Missing Native Features:**
*   **Sequences & Chaining:** Native Tweens can be chained (e.g., move right, *then* move up). Our format currently only supports one property per tween block.
*   **Parallel Tweens:** Animating multiple properties simultaneously in the same tween definition.
*   **Callbacks:** Triggering a function when a tween finishes or starts (e.g., `on_complete = "play_sound"`).
*   **Intervals:** Pausing the tween for a duration without animating anything (`tween_interval`).
*   **Loop Count:** Looping exactly *N* times, rather than just `true` (infinite) or `false` (once).

### 4. Interaction Format
**Currently Supported:** Basic state machine (`default`, `hovered`, `active`), playing/stopping animations, playing/stopping tweens, and basic property overrides.
**Missing Native Features:**
*   **Custom Variables:** Right now, conditions are hardcoded to `is_hovered`, `is_pressed`, and `is_active`. We need to support custom boolean/number variables (e.g., `health < 0` or `has_key == true`).
*   **Input Mapping:** Reacting to keyboard/controller inputs (e.g., `condition = "input == 'ui_accept'"`).
*   **Timed Transitions:** Automatically moving to a state after a timer (e.g., `state "idle" \n auto_transition "patrol" after 5.0`).
*   **Signal Emission:** Emitting Godot signals when entering a state (e.g., `emit signal "died"`).
*   **AnimationTree Integration:** Instead of just `AnimationPlayer.play()`, supporting blend trees and state machine transitions natively via `AnimationTree`.

---

### How we achieve this:
To make *everything* accessible, we don't need to rewrite the engine. We just need to expand our **Parsers**, **Serializers**, and **Runtime Generator** to map these native Godot concepts into our text syntax.

For example, to add Tween Chaining and Callbacks, the format would look like this:
```text
tween "complex_attack"
	target = n_2
	steps = 3
	step 1
		property = position
		final_value = Vector2(100, 0)
		duration = 0.5
		ease = OUT
	step 2
		interval = 0.2 # Waits 0.2 seconds
	step 3
		property = scale
		final_value = Vector2(1.5, 1.5)
		duration = 0.3
		on_complete = "deal_damage" # Calls node.deal_damage()
```

Would you like me to start implementing **Tween Chaining & Callbacks**, or would you rather expand **Interaction Custom Variables & Inputs** first?
