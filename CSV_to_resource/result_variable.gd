@tool
extends Control

@export var name_label : Label
@export var type_selector : OptionButton
@export var include_button : CheckButton
@export var extra_input : LineEdit

enum Type {
	STRING,
	INT,
	FLOAT,
	BOOL,
	PACKED_STRING_ARRAY,
	NAME
}

const TYPE_NAMES: Array[Variant] = ["String", "int", "float", "bool", "PackedStringArray", "Name"]

signal value_changed

func _ready() -> void:
	_connections()
	_setup()
	
func _connections() -> void:
	type_selector.item_selected.connect(_item_selected)
	include_button.toggled.connect(_include_toggled)
	extra_input.text_changed.connect(func(_text): value_changed.emit())
	
func _item_selected(index : int) -> void:
	match index:
		Type.PACKED_STRING_ARRAY:
			extra_input.visible = true
			extra_input.placeholder_text = "Separator (default: ;)"
		_:
			extra_input.visible = false
	value_changed.emit()
	
func _include_toggled(on : bool) -> void:
	value_changed.emit()

func _setup() -> void:
	type_selector.clear()
	for type_name in TYPE_NAMES:
		type_selector.add_item(type_name)
	
	extra_input.visible = false

func _initialize(variable_name : String, estimated_type : int = Type.STRING, estimated_extra : String = "") -> void:
	name_label.text = variable_name
	type_selector.selected = estimated_type
	_item_selected(estimated_type)
	
	if estimated_extra != "":
		extra_input.text = estimated_extra

func get_data() -> Dictionary:
	var type_index = type_selector.selected
	var type_name = TYPE_NAMES[type_index]
	
	return {
		"name": name_label.text,
		"type": type_name,
		"extra": extra_input.text,
		"include": include_button.button_pressed
	}
