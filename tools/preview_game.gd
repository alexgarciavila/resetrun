extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.state = "running"
	game.message.text = ""
	for i in range(100):
		game._physics_process(1.0 / 60.0)
	for i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tools/previews/datacenter_game.png")
	quit()
