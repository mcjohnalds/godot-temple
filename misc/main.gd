extends Node
class_name Main

const loader_scene := preload("res://misc/loader.tscn")
const start_scene := preload("res://misc/start.tscn")


func _ready() -> void:
	var loader: Loader = loader_scene.instantiate()
	add_child(loader)
	await loader.finished
	loader.queue_free()
	await loader.tree_exited
	var start := start_scene.instantiate()
	add_child(start)
