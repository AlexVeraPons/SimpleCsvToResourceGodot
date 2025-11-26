@tool
extends Container
class_name PathSetter

signal path_selected(path: String)

@export_group("Configuration")
@export var title : String
@export var placeholder_text : String
@export var filters : PackedStringArray
@export var select_folders : bool = false

@export_category("External References")
@export var file_dialog: FileDialog

@export_group("Internal References")
@export var title_label : Label
@export var line_edit: LineEdit
@export var browse_button : Button


func get_saved_path() -> String:
	return line_edit.text

func set_path(path: String) -> void:
	line_edit.text = path
	path_selected.emit(path)

func _ready():
	_setup_connections()
	_setup_ui()

func _setup_connections() -> void:
	if browse_button.pressed.is_connected(_on_browse_pressed):
		browse_button.pressed.disconnect(_on_browse_pressed)
	browse_button.pressed.connect(_on_browse_pressed)

	if not file_dialog.file_selected.is_connected(_on_file_selected):
		file_dialog.file_selected.connect(_on_file_selected)
	
	if not file_dialog.files_selected.is_connected(_on_files_selected):
		file_dialog.files_selected.connect(_on_files_selected)

	if not file_dialog.dir_selected.is_connected(_on_dir_selected):
		file_dialog.dir_selected.connect(_on_dir_selected)

	if not line_edit.text_submitted.is_connected(_on_manual_path_entered):
		line_edit.text_submitted.connect(_on_manual_path_entered)

func _setup_ui() -> void:
	title_label.text = title
	line_edit.placeholder_text = placeholder_text
	if Engine.is_editor_hint():
		call_deferred("_apply_icon")

func _apply_icon():
	if browse_button:
		browse_button.icon = get_theme_icon("Load", "EditorIcons")

func _on_browse_pressed():
	if select_folders:
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		file_dialog.clear_filters() 
	else:
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_apply_filters()
		
	file_dialog.popup_centered_ratio(0.5)

func _on_file_selected(path):
	_handle_selection(path)

func _on_files_selected(paths):
	_handle_selection(paths[0])

func _on_dir_selected(path):
	_handle_selection(path)

func _on_manual_path_entered(new_text: String):
	_handle_selection(new_text)

func _handle_selection(path: String):
	line_edit.text = path
	_remove_filters()
	print("Selected path:", path)
	path_selected.emit(path)

func _apply_filters() -> void:
	for filter in filters:
		file_dialog.add_filter(filter)

func _remove_filters() -> void:
	file_dialog.filters = PackedStringArray()
