Here is the comprehensive documentation mapping HTML/CSS concepts to the AI Scene Format. This guide is designed to be read by both human developers and AI agents to perfectly translate web layouts into Godot scenes.

You can save this as `addons/ai_scene_format/docs/html_to_ai_format.md`.

---

# HTML/CSS to AI Scene Format Conversion Guide

This document defines the rules and mappings for converting HTML/CSS layouts into the AI Scene Format (Layout Domain). 

Because Godot's UI system (Control nodes) and the Web's DOM (HTML/CSS) have different paradigms, direct 1:1 property mapping is sometimes impossible. However, by using Godot's Container system and `StyleBoxFlat` resources, we can achieve pixel-perfect visual cloning.

## 1. Core Paradigm Shifts

*   **The Box Model:** CSS uses `padding`, `margin`, and `border` on every element. Godot separates these: `PanelContainer` handles background/borders/padding, `MarginContainer` handles margins, and `StyleBoxFlat` defines the visual box.
*   **Flexbox vs. Containers:** CSS `display: flex` is replicated in Godot using `HBoxContainer` (row) and `VBoxContainer` (column). CSS `gap` becomes Godot's `theme_override_constants/separation`.
*   **Right-to-Left (RTL):** HTML uses `dir="rtl"`. Godot doesn't have a global RTL flag for layout. To mimic RTL layouts, you must **reverse the order of children** in `HBoxContainer`s. For text, use `horizontal_alignment = 2` (Right) or BBCode `[right]`.

## 2. HTML Tag to Node Mapping

| HTML Tag | AI Scene Format Node | Notes |
| :--- | :--- | :--- |
| `<div>` (generic) | `Control` | Used for structure with no visual style. |
| `<div>` (styled box) | `PanelContainer` | Use this when the div has a `background-color`, `border`, or `box-shadow`. |
| `<span>` / `<p>` / `<h1>` | `Label` | For plain text. Use `autowrap_mode = 3` for word wrap. |
| Text with mixed styles | `RichTextLabel` | Enable `bbcode_enabled = true` and `fit_content = true`. |
| `<body>` / Root | `Control` | The root node of the format text maps to the selected root node. |

## 3. CSS Flexbox to Godot Container Mapping

CSS flexbox is the hardest to translate. Here is how to map it:

| CSS Property | AI Scene Format Equivalent | Notes |
| :--- | :--- | :--- |
| `display: flex` | `HBoxContainer` or `VBoxContainer` | Row = HBox, Column = VBox. |
| `flex-direction: row/column` | Use `HBox` / `VBox` | |
| `gap: 15px` | `theme_override_constants/separation = 15` | Applied to the Container node. |
| `justify-content: center` | `alignment = 1` | Applied to the Container node. (1 = Center, 0 = Begin, 2 = End). |
| `align-items: center` | `size_flags_vertical = 4` (Fill) | Applied to the *children* of the container. |
| `flex: 1` | `size_flags_horizontal = 3` | (3 = Expand). Tells the item to fill available space. |
| `flex-grow: 2` | `size_flags_stretch_ratio = 2.0` | Used with `size_flags_horizontal = 3`. |
| `width: 55%` | `size_flags_stretch_ratio = 55.0` | (Assuming the other element has `45.0`). Godot uses ratios, not percentages. |

## 4. CSS Box Model to StyleBoxFlat Mapping

In Godot, visual styling (backgrounds, borders, rounded corners) is handled by assigning a `StyleBoxFlat` resource to a `Panel` or `PanelContainer` via `theme_override_styles/panel`.

| CSS Property | StyleBoxFlat Property | Notes |
| :--- | :--- | :--- |
| `background-color` | `bg_color = Color(r,g,b,a)` | |
| `border-radius: 10px` | `corner_radius_top_left = 10` | Must set all 4 corners manually in Godot. |
| `border: 2px solid red` | `border_width_left = 2`<br>`border_color = Color(1,0,0,1)` | Must set all 4 widths manually. |
| `box-shadow: 5px 5px 10px` | `shadow_size = 10`<br>`shadow_offset = Vector2(5,5)` | |
| `padding: 20px` | `content_margin_left = 20` | Can be on StyleBox, or use a `MarginContainer`. |
| `opacity: 0.5` | (On the Panel node) `modulate = Color(1,1,1,0.5)` | |

## 5. Text and Typography Mapping

| CSS Property | AI Scene Format Property | Notes |
| :--- | :--- | :--- |
| `color` | `theme_override_colors/font_color` | For `Label`. |
| `font-size: 24px` | `theme_override_font_sizes/font_size = 24` | For `Label`. |
| `text-align: right` | `horizontal_alignment = 2` | (0=Left, 1=Center, 2=Right, 3=Fill). |
| `font-weight: bold` | `[b]text[/b]` | Requires `RichTextLabel` with `bbcode_enabled = true`. |
| `line-height: 1.6` | *Not directly supported.* | Add empty lines (`\n`) or use custom fonts. |
| `overflow: hidden` | (On any Control) `clip_contents = true` | Prevents children from drawing outside bounds. |

## 6. Unique Identifiers (IDs)

In HTML, multiple elements can share a class (e.g., `<div class="book">`). 
In AI Scene Format, **every node and every resource must have a unique ID** (e.g., `#n_1`, `#r_book_1`). If you duplicate a block of text, you must increment all IDs within it.

## 7. Syntax Rules for the AI

When generating the format code, adhere to these strict syntax rules:

1.  **Indentation:** Use exactly **4 spaces** per level. Do not use tabs.
2.  **Node Declaration:** `NodeType Name #id` (e.g., `Panel Book1 #n_2`).
3.  **Resource Declaration:** `Property ResourceType #id` (e.g., `theme_override_styles/panel StyleBoxFlat #r_1`).
4.  **Properties:** `key = value` (e.g., `bg_color = Color(0.9, 0.2, 0.2, 1.0)`).
5.  **Newlines in Text:** Use `\n` inside quotes for line breaks (e.g., `text = "Line 1\nLine 2"`).
6.  **Nesting:** Children must be indented exactly one level (4 spaces) beneath their parent.

## Example Conversion: A Styled RTL Text Block

**HTML:**
```html
<div class="problem-text" style="background: white; padding: 20px; border-right: 4px solid #3498db; direction: rtl;">
  تُباع القصص مقابل <strong>96 جنيهًا</strong>.
</div>
```

**AI Scene Format:**
```text
PanelContainer ProblemTextPanel #n_55
    layout_mode = 2
    size_flags_horizontal = 3
    theme_override_styles/panel StyleBoxFlat #r_prob
        bg_color = Color(1.0, 1.0, 1.0, 1.0) # white background
        border_width_right = 4                # border-right: 4px
        border_color = Color(0.2, 0.6, 0.86, 1.0) # #3498db
        content_margin_left = 20              # padding: 20px
        content_margin_right = 20
        content_margin_top = 20
        content_margin_bottom = 20
        
    RichTextLabel ProblemText #n_56
        layout_mode = 2
        size_flags_horizontal = 3
        bbcode_enabled = true
        fit_content = true
        text = "[right]تُباع القصص مقابل [b]96 جنيهًا[/b].[/right]"
        theme_override_colors/default_color = Color(0.266, 0.266, 0.266, 1.0)
        theme_override_font_sizes/normal_font_size = 19
```
