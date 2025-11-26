@tool
extends PanelContainer

@export var csv_path_setter: PathSetter
@export var export_path_setter: PathSetter

@export var variables_container: VBoxContainer
@export var result_variable_scene: PackedScene

@export var template_option_button: OptionButton
@export var save_template_button: Button
@export var save_template_dialog: ConfirmationDialog
@export var template_name_input: LineEdit
@export var preview_code: CodeEdit
@export var progress_bar: ProgressBar

var csv_data: Array = []
var export_path: String = ""
var templates: Dictionary = {}

@export var clear_button: Button
@export var export_button: Button 

@export var generate_resources_checkbox: CheckBox 

func _ready() -> void:
	print("CSV_resource_ui: _ready called")
	if csv_path_setter:
		print("CSV_resource_ui: Connecting csv_path_setter")
		if not csv_path_setter.path_selected.is_connected(_on_csv_path_selected):
			csv_path_setter.path_selected.connect(_on_csv_path_selected)
	else:
		push_error("CSV_resource_ui: csv_path_setter is null")
		
	if export_path_setter:
		if not export_path_setter.path_selected.is_connected(_on_export_path_selected):
			export_path_setter.path_selected.connect(_on_export_path_selected)
			
	if export_button:
		export_button.pressed.connect(_on_export_pressed)

	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
		
	if save_template_button:
		save_template_button.pressed.connect(_on_save_template_pressed)
		
	if save_template_dialog:
		save_template_dialog.confirmed.connect(_on_template_saved)
		
	if template_option_button:
		template_option_button.item_selected.connect(_on_template_selected)
		_load_templates_from_disk()

	# Clear placeholder
	if variables_container:
		for child in variables_container.get_children():
			if child is Control and child.name != "HBoxContainer2": # Keep the header
				child.queue_free()
	else:
		push_error("CSV_resource_ui: variables_container is null")

	if preview_code:
		var highlighter = CodeHighlighter.new()
		highlighter.number_color = Color(0.63, 1.0, 0.88) # Light Green
		highlighter.symbol_color = Color(0.67, 0.78, 1.0) # Light Blue
		highlighter.function_color = Color(0.34, 0.7, 1.0) # Blue
		highlighter.member_variable_color = Color(0.73, 0.87, 1.0) # Light Blue-White
		
		highlighter.add_keyword_color("extends", Color(1.0, 0.44, 0.52)) # Red/Pink
		highlighter.add_keyword_color("class_name", Color(1.0, 0.44, 0.52))
		highlighter.add_keyword_color("export", Color(1.0, 0.44, 0.52))
		highlighter.add_keyword_color("var", Color(1.0, 0.44, 0.52))
		
		preview_code.syntax_highlighter = highlighter

func _on_save_template_pressed() -> void:
	if save_template_dialog:
		save_template_dialog.popup_centered()
		if template_name_input:
			template_name_input.text = ""
			template_name_input.grab_focus()

func _on_template_saved() -> void:
	if not template_name_input or template_name_input.text == "":
		push_error("Template name cannot be empty")
		return
		
	var template_name = template_name_input.text
	var template_data = {
		"class_name": _get_current_class_name(),
		"csv_path": csv_path_setter.get_saved_path(),
		"variables": []
	}
	
	for child in variables_container.get_children():
		if child.has_method("get_data"):
			template_data.variables.append(child.get_data())
			
	_save_template_to_disk(template_name, template_data)
	_load_templates_from_disk() # Reload to show new template
	
	# Select the new template
	for i in range(template_option_button.item_count):
		if template_option_button.get_item_text(i) == template_name:
			template_option_button.selected = i
			break

func _save_template_to_disk(name: String, data: Dictionary) -> void:
	var dir = DirAccess.open("res://addons/CSV_to_resource/")
	if not dir.dir_exists("templates"):
		dir.make_dir("templates")
		
	var path = "res://addons/CSV_to_resource/templates/" + name + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("Template saved: ", path)
		_load_templates_from_disk()
	else:
		push_error("Failed to save template: " + path)

func _load_templates_from_disk() -> void:
	if not template_option_button: return
	
	template_option_button.clear()
	template_option_button.add_item("No Template")
	templates.clear()
	
	var dir = DirAccess.open("res://addons/CSV_to_resource/templates/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var template_name = file_name.get_basename()
				template_option_button.add_item(template_name)
				
				var file = FileAccess.open("res://addons/CSV_to_resource/templates/" + file_name, FileAccess.READ)
				if file:
					var json = JSON.new()
					var error = json.parse(file.get_as_text())
					if error == OK:
						templates[template_name] = json.data
					file.close()
					
			file_name = dir.get_next()
			
func _on_template_selected(index: int) -> void:
	if index == 0: return # No Template
	
	var template_name = template_option_button.get_item_text(index)
	if templates.has(template_name):
		_apply_template(templates[template_name])

func _apply_template(data: Dictionary) -> void:
	# Load CSV first if present
	if "csv_path" in data and data["csv_path"] != "":
		var path = data["csv_path"]
		if csv_path_setter:
			# This will trigger the signal and reload the CSV data/variables
			csv_path_setter.set_path(path)
			
	# Restore class name
	if "class_name" in data:
		var code = preview_code.text
		var regex = RegEx.new()
		regex.compile("class_name\\s+\\w+")
		var new_class_name = "class_name " + data["class_name"]
		if regex.search(code):
			preview_code.text = regex.sub(code, new_class_name)
		else:
			# Insert after extends if not found, or just prepend
			preview_code.text = new_class_name + "\n" + code

	# Apply variables
	if data.has("variables"):
		var saved_vars = data.variables
		for child in variables_container.get_children():
			if child.has_method("get_data"):
				var current_name = child.name_label.text # Access label directly or add getter
				# Find matching saved var
				for saved_var in saved_vars:
					if saved_var.name == current_name:
						# Apply settings
						# We need to map type string back to int index
						var type_index = 0
						if saved_var.type == "int": type_index = 1
						elif saved_var.type == "float": type_index = 2
						elif saved_var.type == "bool": type_index = 3
						elif saved_var.type == "PackedStringArray": type_index = 4
						elif saved_var.type == "Name": type_index = 5
						
						child.type_selector.selected = type_index
						child._item_selected(type_index) # Trigger visibility updates
						
						child.include_button.button_pressed = saved_var.include
						child.extra_input.text = saved_var.extra
						break
	
	_update_preview()
	# Force class name update again in case _update_preview reset it
	if data.has("class_name"):
		var current_text = preview_code.text
		var class_name_regex = RegEx.new()
		class_name_regex.compile("class_name\\s+(\\w+)")
		var new_text = class_name_regex.sub(current_text, "class_name " + data.class_name)
		preview_code.text = new_text

func _get_current_class_name() -> String:
	if not preview_code: return "NewResource"
	var class_name_regex = RegEx.new()
	class_name_regex.compile("class_name\\s+(\\w+)")
	var match = class_name_regex.search(preview_code.text)
	if match:
		return match.get_string(1)
	return "NewResource"

func _on_export_pressed() -> void:
	if export_path == "":
		push_error("No export path selected!")
		return
	if csv_data.size() <= 1:
		push_error("No CSV data to export!")
		return
		
	var script_path = _save_resource_script()
	
	if generate_resources_checkbox and generate_resources_checkbox.button_pressed:
		if script_path != "":
			if progress_bar:
				progress_bar.visible = true
				progress_bar.value = 0
				progress_bar.max_value = csv_data.size() - 1
				
			await _create_resources(script_path)
			print("Export complete!")
			
			if progress_bar:
				progress_bar.value = progress_bar.max_value
				await get_tree().create_timer(1.0).timeout
				progress_bar.visible = false
				
	# Scan filesystem to show new files
	EditorInterface.get_resource_filesystem().scan()

func _save_resource_script() -> String:
	var script_content = preview_code.text
	var class_name_id = _get_current_class_name()
	var script_path = export_path + "/" + class_name_id + ".gd"
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	if file:
		file.store_string(script_content)
		file.close()
		return script_path
	else:
		push_error("Failed to save resource script to: " + script_path)
		return ""

func _create_resources(script_path: String) -> void:
	var resource_script = load(script_path)
	if not resource_script:
		push_error("Failed to load generated script.")
		return
		
	var headers = csv_data[0]
	var name_column_index = -1
	
	# Find Name column
	var variable_configs = []
	for child in variables_container.get_children():
		if child.has_method("get_data"):
			var data = child.get_data()
			variable_configs.append(data)
			if data.type == "Name":
				# Find index in headers
				name_column_index = headers.find(data.name)
	
	# Iterate rows (skip header)
	for i in range(1, csv_data.size()):
		var row = csv_data[i]
		var instance = resource_script.new()
		var file_name = "Row_" + str(i)
		
		if name_column_index != -1 and name_column_index < row.size():
			file_name = row[name_column_index]
			
		# Set properties
		for j in range(row.size()):
			if j >= headers.size(): break
			
			var header_name = headers[j]
			var value = row[j]
			
			# Find config for this column
			var config = null
			for c in variable_configs:
				if c.name == header_name:
					config = c
					break
			
			if config and config.include:
				var prop_name = _sanitize_name(config.name)
				var typed_value = _cast_value(value, config.type, config.extra)
				instance.set(prop_name, typed_value)
		
		var resource_path = export_path + "/" + file_name + ".tres"
		ResourceSaver.save(instance, resource_path)
		print("Saved resource: ", resource_path)
		
		if progress_bar:
			progress_bar.value = i
		await get_tree().process_frame

func _cast_value(value: String, type: String, extra: String) -> Variant:
	match type:
		"int": return value.to_int()
		"float": return value.to_float()
		"bool": return value.to_lower() == "true"
		"PackedStringArray": return value.split(extra)
		"Name": return value # Name is just a string property if exported, or just used for filename
		_: return value # String

func _on_csv_path_selected(path: String) -> void:
	print("CSV Path Selected: ", path)	
	if not FileAccess.file_exists(path):
		push_error("CSV file not found: " + path)
		return
		
	csv_data.clear()
	var file = FileAccess.open(path, FileAccess.READ)
	while file.get_position() < file.get_length():
		var line = file.get_csv_line()
		csv_data.append(line)
		
	print("CSV Data Parsed. Rows: ", csv_data.size())
	
	if csv_data.size() > 0:
		_populate_variables()

func _populate_variables() -> void:
	# Clear existing variables (except header)
	for child in variables_container.get_children():
		if child.name != "HBoxContainer2":
			variables_container.remove_child(child)
			child.queue_free()
			
	var headers = csv_data[0]
	var first_row: Array[Variant] = []
	if csv_data.size() > 1:
		first_row = csv_data[1]
		
	for i in range(headers.size()):
		var header_name = headers[i]
		var sample_value: String = ""
		if i < first_row.size():
			sample_value = first_row[i]
			
		var estimation: Dictionary = _estimate_type(sample_value)
		print("Instantiating variable: ", header_name, " with estimation: ", estimation)
		var variable_instance = result_variable_scene.instantiate()
		variables_container.add_child(variable_instance)
		variable_instance._initialize(header_name, estimation.type, estimation.extra)
		variable_instance.value_changed.connect(_on_variable_changed)
	
	_update_preview()

func _estimate_type(value: String) -> Dictionary:
	var result: Dictionary[Variant, Variant] = {"type": 0, "extra": ""} # Default to String
	
	if value.is_valid_int():
		result.type = 1 # int
	elif value.is_valid_float():
		result.type = 2 # float
	elif value.to_lower() == "true" or value.to_lower() == "false":
		result.type = 3 # bool
	elif value.contains(";") or value.contains("|") or value.contains(","):
		result.type = 4 # PackedStringArray
		if value.contains(";"):
			result.extra = ";"
		elif value.contains("|"):
			result.extra = "|"
		else:
			result.extra = ","
	
	print("Estimated type for value '", value, "': ", result)
	return result

func _update_preview() -> void:
	if not preview_code:
		return
		
	var current_class_name = "NewResource"
	var current_text = preview_code.text
	var class_name_regex = RegEx.new()
	class_name_regex.compile("class_name\\s+(\\w+)")
	var match = class_name_regex.search(current_text)
	if match:
		current_class_name = match.get_string(1)
		
	var code = "extends Resource\n"
	code += "class_name " + current_class_name + "\n\n"
	
	for child in variables_container.get_children():
		if child.has_method("get_data"):
			var data = child.get_data()
			if data.include:
				var type_str = data.type
				if type_str == "Name": type_str = "String" # Name is exported as String
				code += "@export var " + _sanitize_name(data.name) + ": " + type_str + "\n"
				
	preview_code.text = code

func _sanitize_name(variable_name: String) -> String:
	return variable_name.to_lower().replace(" ", "_")

func _on_variable_changed() -> void:
	_update_preview()

func _on_export_path_selected(path: String) -> void:
	export_path = path
	print("Export path set to: ", export_path)

func _on_clear_pressed() -> void:
	if variables_container:
		for child in variables_container.get_children():
			if child is Control and child.name != "HBoxContainer2": # Keep the header
				child.queue_free()
	
	csv_data.clear()
	if preview_code:
		preview_code.text = ""
	
	if template_option_button:
		template_option_button.selected = 0
