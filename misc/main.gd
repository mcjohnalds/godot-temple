extends Node
class_name Main

const _loader_scene := preload("res://misc/loader.tscn")
const _start_scene := preload("res://misc/start.tscn")
const _level_scene := preload("res://misc/level.tscn")


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
	var level: Level = _level_scene.instantiate()
	add_child(level)
