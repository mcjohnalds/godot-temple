extends Node
class_name Loader

signal finished

@onready var container: Node = $Container
@onready var progress_label: Label = %ProgressLabel
@onready var file_label: Label = %FileLabel


func _ready() -> void:
	var file_paths := Util.get_files_recursive("res://")

	var scene_file_paths: Array[String] = []
	for file_path in file_paths:
		# In the web build, files in the exported package have a .remap suffix
		file_path = file_path.rstrip(".remap")
		if file_path.ends_with(".tscn"):
			scene_file_paths.append(file_path)

	for i in scene_file_paths.size():
		var file_path := scene_file_paths[i]
		# Don't want to load the current scene since canvas layers would clash
		# if file_path == "res://misc/loader.tscn":
		# 	continue

		var percent := floori(
			float(i) / float(scene_file_paths.size()) * 100.0
		)
		progress_label.text = "Loading assets (%s%%)" % percent
		file_label.text = file_path.lstrip("res://")
		await get_tree().process_frame

		var scene: Node = load(file_path).instantiate()

		var nodes := Util.get_children_recursive(scene, true)
		nodes.append(scene)

		for node: Node in nodes:
			node.set_script(null)
			# Don't want autoplaying sounds or anything else causing problems
			node.process_mode = Node.PROCESS_MODE_DISABLED
			if "visible" in node:
				node.visible = true
			if (
				node is GPUParticles2D
				or node is GPUParticles3D
				or node is CPUParticles2D
				or node is CPUParticles3D
			):
				node.one_shot = true
				node.emitting = true
				node.process_mode = Node.PROCESS_MODE_ALWAYS
			if node is CanvasItem:
				var canvas_item: CanvasItem = node
				canvas_item.z_index = 0
			if node is ScrollContainer:
				# The ScrollContainer associated with OptionButtons draw on top
				# of everything else and I don't know why so I just hide them
				node.visible = false
			if node is CanvasLayer:
				var canvas_layer: CanvasLayer = node
				# Don't want the scene's layer to clash with our layer
				canvas_layer.layer = 1
		container.add_child(scene)
		await get_tree().process_frame
	finished.emit()
