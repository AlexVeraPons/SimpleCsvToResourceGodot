@tool
extends EditorPlugin

const WindowScene := preload("res://addons/CSV_to_resource/csv_to_resource_scene.tscn")

var win: Window

func _enter_tree() -> void:
	add_tool_menu_item("SimpleCsvToResourceGodot", _on_menu_pressed)


func _exit_tree() -> void:
	remove_tool_menu_item("SimpleCsvToResourceGodot")
	if win:
		win.queue_free()


func _on_menu_pressed() -> void:
	if win == null:
		win = WindowScene.instantiate()
		get_editor_interface().get_base_control().add_child(win)
		win.hide()

		var screen_size = DisplayServer.screen_get_size()
		win.size = screen_size * 0.75

		win.close_requested.connect(_on_window_close)

	if win.visible:
		win.hide()
	else:
		win.popup_centered()


func _on_window_close():
	win.hide()  
