extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("677688")
	backdrop.size = Vector2(1100, 640)
	root.add_child(backdrop)
	var floor_line := ColorRect.new()
	floor_line.color = Color("fa5860")
	floor_line.position = Vector2(0, 430)
	floor_line.size = Vector2(1100, 2)
	root.add_child(floor_line)
	var names := [&"idle", &"run", &"jump", &"hit", &"game_over"]
	for i in range(names.size()):
		var bot = load("res://scenes/resetbot.tscn").instantiate()
		root.add_child(bot)
		bot.play(names[i])
		bot.pause()
		bot.frame = 0
		bot.position = Vector2(130 + i * 210, 430)
		var label := Label.new()
		label.text = str(names[i])
		label.position = Vector2(90 + i * 210, 460)
		root.add_child(label)
	for i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tools/previews/animation_sizes.png")
	quit()
