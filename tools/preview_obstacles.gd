extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.settings.all_muted = true
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		game.settings.selected_world = args[0]
	game._apply_preferences()
	game._start_run()
	game.obstacles.append(game._make_obstacle("jump_gate", 335))
	game.obstacles.append(game._make_obstacle("evil_ai_robot", 585))
	game.obstacles.append(game._make_obstacle("repair_gate", 770))
	game.queue_redraw()
	for frame in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	var suffix := "_" + args[0] if not args.is_empty() else ""
	root.get_texture().get_image().save_png("res://tools/previews/obstacles%s.png" % suffix)
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
