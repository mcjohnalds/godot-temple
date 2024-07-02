@tool
extends Control
class_name Menu

signal started
signal resumed
signal restarted


@export var start_button_visible := true:
	set(value):
		start_button_visible = value
		if not is_node_ready():
			await ready
		_start_button.visible = value


@export var resume_button_visible := true:
	set(value):
		resume_button_visible = value
		if not is_node_ready():
			await ready
		_resume_button.visible = value


@export var restart_button_visible := true:
	set(value):
		restart_button_visible = value
		if not is_node_ready():
			await ready
		_restart_button.visible = value


@onready var _start_button: Button = %StartButton
@onready var _resume_button: Button = %ResumeButton
@onready var _restart_button: Button = %RestartButton
@onready var _quit_button: Button = %QuitButton
@onready var mouse_sensitivity_slider: Slider = %MouseSensitivitySlider
@onready var sound_slider: Slider = %SoundVolumeSlider
@onready var music_slider: Slider = %MusicVolumeSlider
@onready var invert_mouse_option_button: OptionButton = (
	%InvertMouseOptionButton
)
@onready var vsync_option_button: OptionButton = %VsyncOptionButton
@onready var performance_preset_option_button: OptionButton = (
	%PerformancePresetOptionButton
)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_start_button.button_down.connect(started.emit)
	_resume_button.button_down.connect(resumed.emit)
	_restart_button.button_down.connect(restarted.emit)
	_quit_button.button_down.connect(get_tree().quit)
	_quit_button.visible = not Util.is_web_browser()
	performance_preset_option_button.clear()
	performance_preset_option_button.add_item("Low")
	performance_preset_option_button.add_item("Medium")
	performance_preset_option_button.add_item("High")
	if Util.is_compatibility_renderer():
		vsync_option_button.get_parent().visible = false
	else:
		performance_preset_option_button.add_item("Insane")
	mouse_sensitivity_slider.drag_ended.connect(
		_on_mouse_sensitivity_slider_drag_ended
	)
	sound_slider.drag_ended.connect(
		_on_sound_slider_drag_ended
	)
	music_slider.drag_ended.connect(
		_on_music_slider_drag_ended
	)
	invert_mouse_option_button.item_selected.connect(
		_on_invert_mouse_item_selected
	)
	vsync_option_button.item_selected.connect(
		_on_vsync_item_selected
	)
	performance_preset_option_button.item_selected.connect(
		_on_performance_preset_item_selected
	)
	_read_settings_from_environment()


func _read_settings_from_environment() -> void:
	mouse_sensitivity_slider.value = global.mouse_sensitivity
	sound_slider.value = _db_to_slider_value(
		AudioServer.get_bus_volume_db(AudioServer.get_bus_index("World"))
	)
	music_slider.value = _db_to_slider_value(
		AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	)
	invert_mouse_option_button.selected = int(global.invert_mouse)
	vsync_option_button.selected = (
		DisplayServer.window_get_vsync_mode()
	)
	performance_preset_option_button.selected = global.get_graphics_preset()


func _on_mouse_sensitivity_slider_drag_ended(
	_value_changed: bool
) -> void:
	global.mouse_sensitivity = mouse_sensitivity_slider.value


func _on_sound_slider_drag_ended(
	_value_changed: bool
) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("World"),
		_slider_value_to_db(sound_slider.value)
	)


func _on_music_slider_drag_ended(
	_value_changed: bool
) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		_slider_value_to_db(music_slider.value)
	)


func _on_invert_mouse_item_selected(index: int) -> void:
	global.invert_mouse = bool(index)


func _on_vsync_item_selected(index: int) -> void:
	DisplayServer.window_set_vsync_mode(index)


func _on_performance_preset_item_selected(index: int) -> void:
	global.set_graphics_preset(index as Global.GraphicsPreset)


func _slider_value_to_db(slider_value: float) -> float:
	return -80.0 + 80.0 * pow(slider_value, 1.0 / 4.0)


func _db_to_slider_value(db: float) -> float:
	return pow(db / 80.0 + 1.0, 4.0)
