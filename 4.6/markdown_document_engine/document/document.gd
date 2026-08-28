class_name Document extends RefCounted

var registry: SyntaxRegistry = SyntaxRegistry.new()
var paragraphs: Array[DocParagraph] = []

func _init() -> void:
	paragraphs.append(DocParagraph.new(registry))

func insert_text(paragraph_idx: int, char_offset: int, text_to_insert: String) -> void:
	if paragraph_idx < 0 or paragraph_idx >= paragraphs.size(): return
	var para = paragraphs[paragraph_idx]
	var text_before = para.raw_text.substr(0, char_offset)
	var text_after = para.raw_text.substr(char_offset)
	para.raw_text = text_before + text_to_insert + text_after
	para.parse_markdown()

func delete_text(paragraph_idx: int, char_offset: int, amount: int = 1) -> void:
	if paragraph_idx < 0 or paragraph_idx >= paragraphs.size(): return
	if char_offset <= 0: return
	var para = paragraphs[paragraph_idx]
	var text_before = para.raw_text.substr(0, char_offset - amount)
	var text_after = para.raw_text.substr(char_offset)
	para.raw_text = text_before + text_after
	para.parse_markdown()

func split_paragraph(paragraph_idx: int, char_offset: int) -> void:
	if paragraph_idx < 0 or paragraph_idx >= paragraphs.size(): return
	var para = paragraphs[paragraph_idx]
	var text_before = para.raw_text.substr(0, char_offset)
	var text_after = para.raw_text.substr(char_offset)
	para.raw_text = text_before
	para.parse_markdown()
	var new_para = DocParagraph.new(registry)
	new_para.raw_text = text_after
	new_para.parse_markdown()
	paragraphs.insert(paragraph_idx + 1, new_para)

func merge_with_previous(paragraph_idx: int) -> void:
	if paragraph_idx <= 0 or paragraph_idx >= paragraphs.size(): return
	var prev_para = paragraphs[paragraph_idx - 1]
	var curr_para = paragraphs[paragraph_idx]
	prev_para.raw_text += curr_para.raw_text
	prev_para.parse_markdown()
	paragraphs.remove_at(paragraph_idx)
