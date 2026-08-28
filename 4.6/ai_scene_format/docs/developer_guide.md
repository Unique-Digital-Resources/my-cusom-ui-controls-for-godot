# AI Scene Format - Developer Guide

This document provides a comprehensive overview of the AI Scene Format plugin architecture. It is intended for developers who want to fix bugs, update existing features, or expand the system to support more of Godot's native capabilities.

## 1. Architectural Overview

The system operates in a **Pipeline** that bridges the gap between human/AI-readable text and Godot's native scene tree.

```text
1. Text Document (User edits this)
	   │
	   ▼
2. Parser Framework (Lexer + Parser) ──► 3. Internal Data Model (Pure GDScript Objects)
	   │                                         │
	   ▼                                         ▼
4. Validation & Formatting                 5. Diff Engine (Compares Old vs New Model)
	   │                                         │
	   ▼                                         ▼
6. Status Bar / UI Feedback               7. Commands & UndoRedo (Applies changes to Godot Nodes)
												 │
												 ▼
									  8. Runtime Generator (Generates script for Interactions/Tweens)
```

**Core Philosophy:** 
*   **Declarative:** The text formats describe *what* the scene should look like, not *how* to build it.
*   **Default Filtering:** Only properties that differ from Godot's defaults are serialized to text.
*   **Stable IDs:** Nodes and Resources are tracked using unique IDs (stored in metadata) so renaming things in the editor doesn't break references.

---

## 2. File Structure & Responsibilities

### 2.1. UI & Dock (`dock/`)
Handles the editor interface, text editing, and routing the "Apply" action to the correct format system.

*   **`plugin.gd`**: Entry point. Adds the dock to the Godot editor.
*   **`editor_dock.gd`**: **(Core Controller)** Manages the 5 tabs (Layout, Anim, Tween, Interact, Combined). It splits the "Combined" tab into the 4 domains, routes the "Apply" button to the correct `_apply_*` functions, and triggers the Runtime Generator.
*   **`code_editor.gd`**: Wraps Godot's `CodeEdit`. Sets up syntax highlighting and auto-indentation.
*   **`inspector_bridge.gd`**: Listens to `EditorInterface.get_selection()` to tell the dock when the user clicks a new node.
*   **`tabs.gd`**: Creates the vertical icon tabs on the left side of the dock.
*   **`toolbar.gd`**: Contains the "Format", "Validate", and "Apply" buttons.
*   **`status_bar.gd`**: Displays validation errors and sync status.

### 2.2. Core Data Model (`core/`)
Pure, in-memory representations of the scene. These do not interact with Godot's `Node` class directly.

*   **`scene_model.gd`**: The root container. Holds dictionaries of all `AINodeModel` and `AIResourceModel` instances. Manages the `AIIds` manager.
*   **`node_model.gd`**: Represents a single node (type, name, ID, parent ID, children IDs, properties).
*   **`property_model.gd`**: Represents a property. Contains flags for `is_resource`, `is_array`, `is_dict`, and `is_default` (crucial for PRD 12: Default Filtering).
*   **`resource_model.gd`**: Represents a Godot Resource recursively. Contains its own `properties` dictionary.
*   **`ids.gd`**: Generates and tracks stable unique IDs (e.g., `n_1`, `r_1`).

### 2.3. Parser Framework (`parser/`)
The generic text-parsing infrastructure used by all 4 formats.

*   **`lexer.gd`**: Tokenizes the text. Handles the indentation-based syntax by emitting `INDENT` and `DEDENT` tokens.
*   **`parser_base.gd`**: Consumes tokens and builds a generic Abstract Syntax Tree (AST) of `Block` objects.
*   **`serializer_base.gd`**: Base class for converting `AIPropertyModel` and `AIResourceModel` back into text.
*   **`validation.gd`**: Checks AST blocks for empty headers, duplicate IDs, and structural issues.
*   **`formatter.gd`**: Re-parses text and serializes it back to enforce consistent 4-space indentation.

### 2.4. Format-Specific Systems (`formats/`)
Each domain (Layout, Animation, Tween, Interaction) has an Importer, Exporter, Parser, and Serializer.

#### Layout (`formats/layout/`)
*   **`layout_importer.gd`**: Reads a Godot `Node` subtree and builds an `AISceneModel`. Uses `property_utils.gd` to filter defaults.
*   **`layout_exporter.gd`**: Applies an `AISceneModel` back onto a Godot `Node`. Creates missing nodes, applies properties, and assigns the `_ai_id_` meta tag.
*   **`layout_parser.gd`**: Converts text AST into `AISceneModel`. Contains `_parse_resource_block` which handles deep recursive resources (like `StyleBoxFlat`).
*   **`layout_serializer.gd`**: Converts `AISceneModel` into text.

#### Animation (`formats/animation/`)
*   **`animation_importer.gd`**: Reads `AnimationPlayer` libraries into `AIAnim` objects.
*   **`animation_exporter.gd`**: Clears old animations and writes new ones into an `AnimationPlayer`. **Note:** Must call `notify_property_list_changed()` so Godot saves the library.
*   **`animation_parser.gd` / `animation_serializer.gd`**: Handle the text conversion for tracks and keyframes.

#### Tween & Interaction (`formats/tween/`, `formats/interaction/`)
*Because Godot doesn't serialize Tweens or State Machines natively, these systems save data into the Node's `meta` dictionary.*
*   **`*_importer.gd`**: Reads `_ai_tweens_` and `_ai_interactions_` metadata into GDScript classes.
*   **`*_exporter.gd`**: Writes GDScript classes back into node metadata. Searches the subtree for the correct target node using `_ai_id_`.
*   **`*_parser.gd` / `*_serializer.gd`**: Handle text conversion.

### 2.5. Sync & Commands (`sync/`, `commands/`)
The bridge between the internal model and the Godot Scene Tree.

*   **`diff_engine.gd`**: Compares an old model (from Godot) and a new model (from text) to generate a list of `DiffCommand` objects (create, delete, rename, move, property).
*   **`undo_redo.gd`**: Wraps `diff_engine` commands in Godot's `EditorUndoRedoManager`.
*   **`apply_changes.gd`**: The entry point for applying a layout model safely using UndoRedo.
*   **`property_utils.gd`**: **(Crucial)** Handles the deep application of properties. This file knows how to instantiate Resources, handle typed Arrays, Dictionaries, and apply Theme Overrides correctly using Godot's native `set()` and `add_theme_stylebox_override()`.

### 2.6. Runtime System (`runtime/`)
*   **`runtime_generator.gd`**: When a scene is applied, this generates a generic GDScript (`_generated_scripts/AIInteractionRuntime.gd`) and attaches it to the root node. This script contains the logic to read the Tween/Interaction metadata at runtime, connect mouse signals, evaluate state priorities, and execute the tweens/animations.

---

## 3. How to Expand Features

### Goal 1: Add a new Node Property or Theme Override (e.g., `theme_override_fonts/`)
1.  **Check `property_utils.gd`**: Look at `apply_property_to_target()`. If Godot requires a specific method (like `add_theme_font_override`), add a condition block for `prop.name.begins_with("theme_override_fonts/")` and route it correctly.
2.  **Check `layout_parser.gd`**: Ensure `_parse_resource_block()` can handle the nested structure if the font is a dynamic font resource.
3.  **Test**: Write a combined format block using the new property and hit Apply. Check the `.tscn` file to ensure Godot saved it.

### Goal 2: Add a new Animation Track Type (e.g., Method Calls)
1.  **`animation_importer.gd`**: Add logic to read `Animation.TYPE_METHOD` tracks into the `AIAnimTrack` model.
2.  **`animation_serializer.gd`**: Add a string representation (e.g., `type = METHOD`).
3.  **`animation_parser.gd`**: Add a case in `_parse_track_type()` to convert it back.
4.  **`animation_exporter.gd`**: The `apply_changes` function already loops through keys and inserts them, but you may need to ensure method arguments are parsed correctly.

### Goal 3: Add a new Interaction Condition (e.g., `input == "ui_accept"`)
1.  **`runtime_generator.gd`**: Update the `RUNTIME_CODE` string.
	*   In `_on_gui_input` or `_unhandled_input`, detect the input action and set a meta flag (e.g., `node.set_meta("_ai_input_triggered", true)`).
	*   Update `_evaluate_conditions()` to read this flag.
	*   Update `_check_single()` to parse `input==ui_accept`.
	*   Update `_get_priority()` so inputs override standard clicks if needed.
2.  **Format**: No parser changes needed, conditions are read as raw strings until the runtime evaluates them.

### Goal 4: Add Tween Chaining (Step 1, Step 2)
1.  **`tween_importer.gd`**: Update `AITween` class to hold an array of `AITweenStep` objects instead of a single `final_value`. Update `to_dict()` and `from_dict()`.
2.  **`tween_serializer.gd`**: Change the output to list `step 1`, `step 2` blocks.
3.  **`tween_parser.gd`**: Update `_parse_tween()` to loop through children and build the step array.
4.  **`runtime_generator.gd`**: Update `_play_tween()` to loop through the steps and chain them using `tween.tween_property().set_trans().set_ease()` sequentially.

---

## 4. Common Troubleshooting

*   **Issue: Properties are not applying to the scene.**
	*   **Cause:** Godot 4's container system (`layout_mode`) often overrides manual `offset_` properties.
    *   **Fix:** Ensure the text format explicitly sets `layout_mode = 1` and `anchors_preset = 0` on Control nodes.
	*   **Cause:** The Diff Engine skips properties it thinks haven't changed.
	*   **Fix:** Check `diff_engine.gd`. For resources, you may need to force the diff command (as done with Theme Overrides).

*   **Issue: Colors tween to Black instead of the target color.**
	*   **Cause:** Animating `modulate` multiplies colors (Blue * Red = Black).
	*   **Fix:** Tween `bg_color` instead. The `runtime_generator.gd` has a specific `if property == "bg_color"` block that uses `tween_method` to animate the `StyleBoxFlat` directly.

*   **Issue: Animations stop each other when clicking multiple circles.**
	*   **Cause:** A single `AnimationPlayer` can only play one animation at a time.
	*   **Fix:** Give each interactive node its own `AnimationPlayer` child, and use track paths relative to the player (`:position` instead of `Circle1:position`).

*   **Issue: Tween loops get stuck on the second loop.**
	*   **Cause:** When a tween is killed, Godot leaves the property at the current value. Starting it again uses that "stuck" value as the start point.
	*   **Fix:** Provide a `start_value` in the Tween format so the runtime knows exactly where to begin the loop every time.
