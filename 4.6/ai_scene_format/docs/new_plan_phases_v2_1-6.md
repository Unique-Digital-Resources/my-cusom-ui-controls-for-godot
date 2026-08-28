Here is the revised development plan. Instead of creating new `v2_` files, this plan upgrades the existing architecture to support the new brace-based syntax, dynamic data binding, and strict default filtering.

---

# Development Phases: AI Scene Format v2.0 (Integrated Upgrade)

This plan transitions the system from a pure scene-serializer into a fully reactive, declarative UI framework by upgrading the existing files.

---

### Phase 1 — Strict Defaults & Unified Parser

**Goal:** Establish the strict default value registry to guarantee minimal serialization, and upgrade the lexer/parser to handle the new block-based `.aiui` syntax.

**Deliverables:**
* Custom Default Registry (Godot type inheritance mapping)
* Upgraded Lexer (handles `{}`, `=`, `()`, `[]`, and `ease()` tags)
* Upgraded Parser (builds an AST of the 4 main blocks: `vars`, `tree`, `interactivity`, `animations`)

**Files:**
```text
core/
	defaults_registry.gd          # NEW: Static class mapping Node/Resource types to strict defaults.
parser/
	lexer.gd                      # UPDATE: Tokenize braces, keywords, and ease tags.
	parser_base.gd                # UPDATE: Consume tokens to build the 4 main AST blocks.
	validation.gd                 # UPDATE: Validate the new block structure and syntax.
```

---

### Phase 2 — Path-Based Tree Application

**Goal:** Parse the `tree` block and instantiate Godot nodes. Map hierarchical paths (e.g., `Root/MainMenu/PlayBtn`) to stable internal IDs so that animations and logic don't break if the tree changes.

**Deliverables:**
* Path Resolution (maps string paths to actual Godot NodePaths)
* Tree Builder (instantiates nodes and applies properties using strict default filtering)

**Files:**
```text
core/
    ids.gd                        # UPDATE: Convert string paths to NodePaths and track IDs.
formats/layout/
    layout_exporter.gd            # UPDATE: Apply the AST tree block to the Godot SceneTree.
utils/
    property_utils.gd             # UPDATE: Use defaults_registry.gd to omit defaults.
```

---

### Phase 3 — Data Binding & Vars

**Goal:** Implement the `vars` block. Allow the UI to react to external JSON files and backend Godot Autoloads/Nodes.

**Deliverables:**
* Vars Parsing (extract `source()`, `backend()`, and reactive expressions)
* Reactive Binding Manager (updates UI properties when backend variables change)

**Files:**
```text
core/
    binding_manager.gd            # NEW: Connects to Godot signals/properties to update vars dynamically.
parser/
    parser_base.gd                # UPDATE: Parse var definitions and expressions.
sync/
    live_sync.gd                  # UPDATE: Apply var values to tree properties at runtime.
```

---

### Phase 4 — Enhanced Animations & Easing

**Goal:** Parse the `animations` block. Support per-keyframe easing and explicit `AnimationPlayer` path targeting.

**Deliverables:**
* Animation Parsing (handles `ease(CURVE, DIR)` tags)
* Animation Builder (generates Godot `Animation` resources)
* Player Resolver (routes `play()` actions to the correct `AnimationPlayer`)

**Files:**
```text
formats/animation/
    animation_parser.gd           # UPDATE: Extract per-keyframe transitions and ease tags.
    animation_exporter.gd         # UPDATE: Generate tracks and apply to explicit players.
sync/
    animation_sync.gd             # UPDATE: Resolve explicit player paths from the AST.
```

---

### Phase 5 — Declarative Interactivity

**Goal:** Implement the `interactivity` block. Map known states (`ready`, `hovered`), input triggers, and conditions to backend actions.

**Deliverables:**
* Interactivity Parsing (states, triggers, conditions, actions)
* Action Dispatcher (evaluates conditions and calls `run()`, `play()`, and `set()`)

**Files:**
```text
formats/interaction/
    interaction_parser.gd         # UPDATE: Parse state, trigger, condition, and action blocks.
sync/
    live_sync.gd                  # UPDATE: Evaluate conditions and dispatch actions.
```

---

### Phase 6 — Runtime Generation & Editor Integration

**Goal:** Generate the GDScript glue code that runs the declarative logic at runtime, and wire the new architecture into the existing Godot Editor plugin dock.

**Deliverables:**
* V2 Runtime Generator (writes the reactive runtime script)
* Updated Dock UI (V2 Syntax Highlighting and Apply Pipeline)

**Files:**
```text
runtime/
    runtime_generator.gd          # UPDATE: Generate signal connections, condition checks, and var bindings.
dock/
    code_editor.gd                # UPDATE: Syntax highlighting for {} and ease().
    editor_dock.gd                # UPDATE: Route the .aiui text through the updated builders.
docs/
    format_spec.md                # UPDATE: Documentation for the new syntax.
```
