extends Node
class_name Main

const _loader_scene := preload("res://misc/loader.tscn")
const _start_scene := preload("res://misc/start.tscn")
const _game_scene := preload("res://misc/game.tscn")
var _game: Game


func _ready() -> void:
	if not OS.is_debug_build():
		var loader: Loader = _loader_scene.instantiate()
		add_child(loader)
		await loader.finished
		loader.queue_free()
		await loader.tree_exited
	var start: Start = _start_scene.instantiate()
	add_child(start)
	await start.menu.started
	start.queue_free()
	await start.tree_exited
	_restart()


func _restart() -> void:
	if _game:
		_game.queue_free()
		await _game.tree_exited
	_game = _game_scene.instantiate()
	add_child(_game)
	_game.restarted.connect(_restart)
