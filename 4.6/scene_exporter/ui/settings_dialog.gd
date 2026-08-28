@tool
extends ConfirmationDialog

var settings: ExportSettings = ExportSettings.new()

@onready var path_edit: LineEdit = $VBox/Grid/PathEdit
@onready var embed_images_check: CheckBox = $VBox/Grid/EmbedImagesCheck
@onready var embed_fonts_check: CheckBox = $VBox/Grid/EmbedFontsCheck
@onready var pretty_print_check: CheckBox = $VBox/Grid/PrettyPrintCheck
@onready var ignore_hidden_check: CheckBox = $VBox/Grid/IgnoreHiddenCheck

func _ready():
    if not confirmed.is_connected(_on_confirmed):
        confirmed.connect(_on_confirmed)

func popup_settings(p_settings: ExportSettings) -> void:
    settings = p_settings
    path_edit.text = settings.output_path
    embed_images_check.button_pressed = settings.embed_images
    embed_fonts_check.button_pressed = settings.embed_fonts
    pretty_print_check.button_pressed = settings.pretty_print
    ignore_hidden_check.button_pressed = settings.ignore_hidden_nodes
    popup_centered()

func _on_confirmed() -> void:
    settings.output_path = path_edit.text
    settings.embed_images = embed_images_check.button_pressed
    settings.embed_fonts = embed_fonts_check.button_pressed
    settings.pretty_print = pretty_print_check.button_pressed
    settings.ignore_hidden_nodes = ignore_hidden_check.button_pressed