tool
extends VBoxContainer
class_name ColPicker, 'res://ColPicker/ColPick.svg'

const _fonts := [ '', '_hover', '_pressed']

export(Color) var primary_color = Color(1.0, 0.0, 0.0, 1.0) setget set_primary_color
export(Color) var secondary_color = Color(1.0, 0.0, 0.0, 1.0) setget set_secondary_color
export(bool) var use_secondary_color = true setget set_use_secondary_color

onready var _col := ColorRect.new()
onready var _hue := ColorRect.new()
onready var _checker := ColorRect.new()
onready var _alpha := ColorRect.new()
onready var _mat = preload('./ColPicker.material') as Material
onready var _indecator = preload('./Indecator.png') as StreamTexture
onready var _cursor = preload('./Cursor.png') as StreamTexture
onready var _col_pos := Sprite.new()
onready var _hue_pos := Sprite.new()
onready var _alpha_pos := Sprite.new()
onready var primary_button := Button.new()
onready var secondary_button := Button.new()
onready var primary_stylebox := StyleBoxFlat.new()
onready var secondary_stylebox := StyleBoxFlat.new()
onready var buttons_container := PanelContainer.new()
onready var buttons_vbox := VBoxContainer.new()

var color_rect_pressed := false
var hue_rect_pressed := false
var alpha_rect_pressed := false
var mouse_in := false
var _hue_backup := 0.0
var cur_col_ind := 0
var cur_col : Color
var primary_font_col := 'Black'
var secondary_font_col := 'Black'

func _ready() -> void:
	size_flags_horizontal = 3
	size_flags_vertical = 3
	_col.rect_min_size = Vector2(96.0, 96.0)
	_col.material = _mat
	_col.size_flags_horizontal = 3
	_col.size_flags_vertical = 3
	add_child(_col)
	_hue.rect_min_size.y = 8.0
	_hue.material = _mat.duplicate()
	add_child(_hue)
	_checker.rect_min_size.y = 8.0
	_checker.material = _mat.duplicate()
	add_child(_checker)
	_alpha.material = _mat.duplicate()
	_checker.add_child(_alpha)
# warning-ignore:return_value_discarded
	connect('resized', self, '_on_resize')
	_checker.material.set_shader_param('type', 0)
	_col.material.set_shader_param('type', 1)
	_hue.material.set_shader_param('type', 2)
	_hue.show_behind_parent = true
	_alpha.material.set_shader_param('type', 3)
	_col_pos.texture = _indecator
	_hue_pos.texture = _indecator
	_alpha_pos.texture = _indecator
	var _indecators := Node2D.new()
	_col.add_child(_col_pos)
	_hue.add_child(_hue_pos)
	_hue_pos.self_modulate.v = 0.0
	_alpha.add_child(_alpha_pos)
	_alpha_pos.self_modulate.v = 0.0
	set_primary_color(primary_color)
	var checker_panel := StyleBoxFlat.new()
	buttons_container.add_stylebox_override('panel', checker_panel)
	add_child(buttons_container)
	buttons_container.material = _mat.duplicate()
	buttons_container.material.set_shader_param('type', 0)
	buttons_vbox.add_constant_override('separation', 0)
	buttons_vbox.size_flags_horizontal = 3
	buttons_container.add_child(buttons_vbox)
	var buttons := [primary_button, secondary_button]
	primary_stylebox.bg_color = primary_color
	secondary_stylebox.bg_color = secondary_color
	for _button in buttons:
		var button : Button = _button
		button.align = ALIGN_CENTER
		button.focus_mode = Control.FOCUS_NONE
		var styles := ['normal', 'pressed', 'hover']
		if button == primary_button:
			set_button_text(0)
			for i in range(3):
				button.add_stylebox_override(styles[i], primary_stylebox)
				button.add_color_override('font_color%s' % _fonts[i], ColorN(primary_font_col))
		else:
			set_button_text(1)
			for i in range(3):
				button.add_stylebox_override(styles[i], secondary_stylebox)
				button.add_color_override('font_color%s' % _fonts[i], ColorN(secondary_font_col))
		buttons_vbox.add_child(button)
		button.size_flags_horizontal = 3
		button.rect_min_size.y = 16.0
	var _rects = [_col, _hue, _alpha]
	for _rect in _rects:
		_rect.connect('mouse_entered', self, '_on_mouse_enter_exit', [true])
		_rect.connect('mouse_exited', self, '_on_mouse_enter_exit', [false])
		_rect.connect('gui_input', self, '_on_col_gui_input', [_rect])
	if !use_secondary_color:
		secondary_button.hide()
	yield(get_tree(), 'idle_frame')
	cur_col = primary_color
	emit_signal('resized')

func set_button_text(_index : int):
	match _index:
		0:
			if ((primary_color.v > 0.5 && primary_font_col != 'Black') || (primary_color.v < 0.5 && primary_font_col != 'White')) || (primary_color.a < 0.5 && primary_font_col != 'Black'):
				primary_font_col = 'Black' if primary_color.v > 0.5 or primary_color.a < 0.5 else 'White'
				for i in range(3):
					primary_button.add_color_override('font_color%s' % _fonts[i], ColorN(primary_font_col))
			primary_button.text = '%s,%s,%s' % [int(primary_color.h * 360), int(primary_color.s * 100), int(primary_color.v * 100)]
		1:
			if ((secondary_color.v > 0.5 && secondary_font_col != 'Black') || (secondary_color.v < 0.5 && secondary_font_col != 'White')) || (secondary_color.a < 0.5 && secondary_font_col != 'Black'):
				secondary_font_col = 'Black' if secondary_color.v > 0.5 or secondary_color.a < 0.5 else 'White'
				for i in range(3):
					secondary_button.add_color_override('font_color%s' % _fonts[i], ColorN(secondary_font_col))
			secondary_button.text = '%s,%s,%s' % [int(secondary_color.h * 360), int(secondary_color.s * 100), int(secondary_color.v * 100)]

func _on_resize():
	_checker.material.set_shader_param('size', _checker.rect_size)
	buttons_container.material.set_shader_param('size', buttons_vbox.rect_size / 2)
	_alpha.rect_size = _checker.rect_size
	cur_col = secondary_color if bool(cur_col_ind) else primary_color
	_col_pos.position = Vector2(cur_col.s * _col.rect_size.x, _col.rect_size.y - (cur_col.v * _col.rect_size.y))
	_hue_pos.position = Vector2(cur_col.h * _hue.rect_size.x , _hue.rect_size.y/2)
	_alpha_pos.position = Vector2(cur_col.a * _alpha.rect_size.x, _alpha.rect_size.y/2)
	yield(get_tree().create_timer(0.1), 'timeout')
	if _col_pos.position != Vector2(cur_col.s * _col.rect_size.x, _col.rect_size.y - (cur_col.v * _col.rect_size.y)):
		emit_signal('resized')

func set_primary_color(_val : Color) -> void:
	primary_color = _val
	if _col != null:
		_col.material.set_shader_param('hue', _val.h)
		_col_pos.position = Vector2(primary_color.s * _col.rect_size.x, (1.0 - primary_color.v) * _col.rect_size.y)
		_hue_pos.position.x = primary_color.h * _hue.rect_size.x 
		_alpha_pos.position.x = primary_color.a * _hue.rect_size.x 
		primary_stylebox.bg_color = primary_color
		set_button_text(0)

func set_secondary_color(_val : Color) -> void:
	secondary_color = _val
	if _col != null:
		_col.material.set_shader_param('hue', _val.h)
		_col_pos.position = Vector2(secondary_color.s * _col.rect_size.x, (1.0 - secondary_color.v) * _col.rect_size.y)
		_hue_pos.position.x = secondary_color.h * _hue.rect_size.x 
		_alpha_pos.position.x = secondary_color.a * _hue.rect_size.x 
		secondary_stylebox.bg_color = secondary_color
		set_button_text(1)

func _input(event: InputEvent) -> void:
	if !color_rect_pressed && !hue_rect_pressed && !alpha_rect_pressed:
		return
	if event is InputEventMouseMotion:
		if color_rect_pressed:
			_col_pos.position = event.position - rect_position
			_col_pos.position.x = clamp(_col_pos.position.x, _col.rect_position.x, _col.rect_size.x)
			_col_pos.position.y = clamp(_col_pos.position.y, _col.rect_position.y, _col.rect_size.y)
			col_pos_changed(cur_col_ind)
		elif hue_rect_pressed:
			_hue_pos.position.x = event.position.x - rect_position.x
			_hue_pos.position.x = clamp(_hue_pos.position.x, _hue.rect_position.x, _hue.rect_size.x - 0.001)
			hue_pos_changed(cur_col_ind)
		else:
			_alpha_pos.position.x = event.position.x - rect_position.x
			_alpha_pos.position.x = clamp(_alpha_pos.position.x, _alpha.rect_position.x, _alpha.rect_size.x)
			alpha_pos_changed(cur_col_ind)
	if !event is InputEventMouseButton && !event.is_pressed():
		return
	if event.is_pressed():
		if event.button_index != BUTTON_LEFT or event.button_index != BUTTON_RIGHT:
			return
	else:
		if event.button_index != BUTTON_LEFT && event.button_index != BUTTON_RIGHT:
			return
		color_rect_pressed = false
		hue_rect_pressed = false
		alpha_rect_pressed = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		warp_mouse(get_local_mouse_position())
		if !mouse_in:
			Input.set_custom_mouse_cursor(null)

func col_pos_changed(_index : int) -> void:
	match _index:
		0:
			primary_color.s = _col_pos.position.x / _col.rect_size.x
			primary_color.v = 1.0 - _col_pos.position.y / _col.rect_size.y
			primary_color.h = _hue_backup
			primary_stylebox.bg_color = primary_color
			_col.material.set_shader_param('hue', primary_color.h)
		1:
			secondary_color.s = _col_pos.position.x / _col.rect_size.x
			secondary_color.v = 1.0 - _col_pos.position.y / _col.rect_size.y
			secondary_color.h = _hue_backup
			secondary_stylebox.bg_color = secondary_color
			_col.material.set_shader_param('hue', secondary_color.h)
	set_button_text(cur_col_ind)

func hue_pos_changed(_index : int) -> void:
	match _index:
		0:
			primary_color.h = _hue_pos.position.x / _hue.rect_size.x
			primary_stylebox.bg_color = primary_color
			_col.material.set_shader_param('hue', primary_color.h)
		1:
			secondary_color.h = _hue_pos.position.x / _hue.rect_size.x
			secondary_stylebox.bg_color = secondary_color
			_col.material.set_shader_param('hue', secondary_color.h)
	set_button_text(cur_col_ind)

func alpha_pos_changed(_index : int) -> void:
	match _index:
		0:
			primary_color.a = _alpha_pos.position.x / _alpha.rect_size.x
			primary_stylebox.bg_color = primary_color
		1:
			secondary_color.a = _alpha_pos.position.x / _alpha.rect_size.x
			secondary_stylebox.bg_color = secondary_color
	set_button_text(cur_col_ind)

func _on_col_gui_input(event : InputEvent, rect : ColorRect) -> void:
	if !event is InputEventMouseButton:
		return
	if event.is_pressed():
		if event.button_index == BUTTON_LEFT:
			cur_col_ind = 0
			cur_col = primary_color
			if rect == _col:
				color_rect_pressed = true
				_col_pos.position = event.position
				_hue_backup = cur_col.h
				Input.warp_mouse_position(event.position)
				col_pos_changed(cur_col_ind)
			elif rect == _hue:
				hue_rect_pressed = true
				_hue_pos.position.x = event.position.x
				hue_pos_changed(cur_col_ind)
			else:
				alpha_rect_pressed = true
				_alpha_pos.position.x = event.position.x
				alpha_pos_changed(cur_col_ind)
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

		if event.button_index == BUTTON_RIGHT:
			if use_secondary_color:
				cur_col_ind = 1
				cur_col = secondary_color
				if rect == _col:
					color_rect_pressed = true
					_col_pos.position = event.position
					_hue_backup = cur_col.h
					Input.warp_mouse_position(event.position)
					col_pos_changed(cur_col_ind)
				elif rect == _hue:
					hue_rect_pressed = true
					_hue_pos.position.x = event.position.x
					hue_pos_changed(cur_col_ind)
				else:
					alpha_rect_pressed = true
					_alpha_pos.position.x = event.position.x
					alpha_pos_changed(cur_col_ind)
				Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func set_use_secondary_color(_val : bool) -> void:
	use_secondary_color = _val
	if secondary_button != null:
		secondary_button.visible = _val
		yield(get_tree().create_timer(0.001), 'timeout')
		emit_signal('resized')

func _on_mouse_enter_exit(entered : bool) -> void:
	mouse_in = entered
	Input.set_custom_mouse_cursor(_cursor if entered else null, 0, Vector2(3, 3))