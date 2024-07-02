extends Node
class_name Main

@export var loader_scene: PackedScene
@export var start_scene: PackedScene
@export var game_scene: PackedScene
var _game: Game


func _ready() -> void:
	if not OS.is_debug_build():
		var loader: Loader = loader_scene.instantiate()
		add_child(loader)
		await loader.finished
		loader.queue_free()
		await loader.tree_exited
	var start: Start = start_scene.instantiate()
	add_child(start)
	await start.menu.started
	start.queue_free()
	await start.tree_exited
	_restart()


func _restart() -> void:
	if _game:
		_game.queue_free()
		await _game.tree_exited
	_game = game_scene.instantiate()
	add_child(_game)
	_game.restarted.connect(_restart)
