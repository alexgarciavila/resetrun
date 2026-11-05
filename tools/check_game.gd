extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	assert(game.state == "ready")
	# Every frame anchors its visible lower edge to the same ground origin.
	for animation in game.bot.sprite_frames.get_animation_names():
		for index in range(game.bot.sprite_frames.get_frame_count(animation)):
			game.bot.animation = animation
			game.bot.frame = index
			var texture: Texture2D = game.bot.sprite_frames.get_frame_texture(animation, index)
			var bounds := texture.get_image().get_used_rect()
			var foot_y: float = bounds.end.y - texture.get_height() * 0.5 + game.bot.offset.y
			assert(absf(foot_y) < 0.01, str(animation) + " ground anchor")
	assert(game.speed_at_distance(0.0) == 360.0)
	assert(game.speed_at_distance(400.0) == 540.0)
	assert(game.speed_at_distance(800.0) == 720.0)
	assert(game.speed_at_distance(10000.0) == 720.0)
	game.bot.play(&"idle")
	var press := InputEventAction.new()
	press.action = "ui_accept"
	press.pressed = true
	game._unhandled_input(press)
	assert(game.state == "running")
	game._unhandled_input(press)
	assert(game.vertical_speed < 0)
	for i in range(55):
		game._physics_process(1.0 / 60.0)
	assert(game.height == 0.0)
	assert(game.bot.animation == &"run")
	for i in range(3):
		game.invincible = 0.0
		game.obstacles.clear()
		game.obstacles.append(Rect2(210, 426, 32, 54))
		game._physics_process(1.0 / 60.0)
		assert(game.bot.modulate.a == 1.0, "Character must remain opaque after damage")
		assert(game.obstacles.is_empty(), "Consumed obstacle must not cover character")
	assert(game.state == "dying")
	assert(game.bot.animation == &"game_over")
	game._on_animation_finished()
	assert(game.state == "over")
	game._unhandled_input(press)
	assert(game.state == "ready" and game.lives == 3 and game.obstacles.is_empty())
	assert(game.speed == game.START_SPEED and game.foreground_offset == 0.0)
	print("PASS: speed progression/cap/reset, all frame anchors, start, jump, landing, opaque damage/game over, obstacle removal, restart")
	game.queue_free()
	quit()
