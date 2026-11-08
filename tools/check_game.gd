extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var game = load("res://scenes/game.tscn").instantiate()
	var settings_path := "user://settings-check-%d.cfg" % OS.get_process_id()
	game.get_node("UI/Settings").preferences_path = settings_path
	root.add_child(game)
	game.set_physics_process(false)
	assert(game.state == "ready")
	assert(game.bot.sprite_frames.get_frame_count(&"double_jump") == 8)
	assert(game.bot.sprite_frames.get_frame_count(&"slide") == 8)
	var hud_font: Font = game.hud.get_theme_font("font")
	assert(TranslationServer.get_locale() == "ca")
	assert(game.settings.worlds_button.text == "MONS" and game.settings.options_button.text == "SO")
	assert(game.settings.fixed_mode_button.text == "MÓN FIX" and game.settings.endless_mode_button.text == "SENSE FI")
	assert(game.hud.text.contains("RÈCORD") and game.hud.text.contains("VIDES") and game.hud.text.contains("VELOCITAT"))
	assert(game.bottom_controls.text.contains("comença"))
	assert(game.bottom_status.text.contains("CENTRE DE DADES"))
	for character in "↑↓àèéíïòóúüçÀÈÉÍÏÒÓÚÜÇ·×":
		assert(hud_font.has_char(character.unicode_at(0)), "Missing UI glyph: " + character)
	for label in [game.hud, game.bottom_status, game.bottom_controls]:
		for line in label.text.split("\n"):
			assert(hud_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x <= 1040.0, "HUD/footer must fit the viewport")
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
	game.settings.open_worlds()
	assert(game.settings.worlds_open and game.settings.world_buttons.size() == 4)
	game._unhandled_input(press)
	assert(game.state == "ready", "World selector must block gameplay input")
	game.settings.select_world("world_02")
	assert(game.settings.selected_world == "datacenter", "Unknown worlds must not be selectable")
	for definition in game.WorldCatalog.WORLDS:
		game.settings.select_world(definition.id)
		assert(game.world.id == definition.id and game.world.background != null)
		assert(is_equal_approx(game.bot.position.y, game.ground_y))
		var top: float = game.ground_y - game.background_height * definition.walkway_ratio
		assert(top <= 100 and top + game.background_height > game.ground_y, "Scenery must include the running surface")
		assert(is_equal_approx((game.ground_y - top) / game.background_height, definition.walkway_ratio))
		if definition.id in ["taller", "taller2", "magatzem2"]:
			assert(game.background_height == 480.0 and game.ground_y == game.FLOOR_Y, "Workshop scenery must be smaller without changing character scale")
	game.settings._change_world_page(1)
	assert(game.settings.world_page == 1 and game.settings.next_worlds.disabled)
	game.settings._select_world_slot(3)
	assert(game.settings.selected_world == "vendrell" and game.settings.world_buttons[3].button_pressed)
	game.settings._change_world_page(-1)
	assert(game.settings.world_page == 0 and game.settings.previous_worlds.disabled)
	game.settings.select_world("datacenter")
	assert(game.world.id == "datacenter" and game.world.background != null)
	game.settings.close_worlds()
	game.settings.open_options()
	game._unhandled_input(press)
	assert(game.state == "ready", "Options must not start gameplay")
	game.settings.set_endless(true)
	game.settings.music_volume = 0.25
	game.settings.effects_volume = 0.65
	game.settings.music_muted = true
	game.settings.effects_muted = false
	game.settings._commit(false)
	var music_bus := AudioServer.get_bus_index("Music")
	var effects_bus := AudioServer.get_bus_index("Effects")
	assert(AudioServer.is_bus_mute(music_bus) and not AudioServer.is_bus_mute(effects_bus))
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(music_bus)), 0.25))
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(effects_bus)), 0.65))
	game.settings.all_muted = true
	game.settings._commit(false)
	assert(AudioServer.is_bus_mute(0), "Master mute must silence every channel")
	var restored = load("res://scripts/settings_menu.gd").new()
	restored.preferences_path = settings_path
	restored._load_preferences()
	assert(restored.music_volume == 0.25 and restored.effects_volume == 0.65)
	assert(restored.selected_world == "datacenter")
	assert(restored.endless_mode, "Selected game mode must persist")
	assert(restored.music_muted and not restored.effects_muted and restored.all_muted)
	restored.free()
	game.settings.all_muted = false
	game.settings.music_muted = false
	game.settings.effects_muted = true
	game.settings._commit(false)
	assert(not AudioServer.is_bus_mute(0) and not AudioServer.is_bus_mute(music_bus) and AudioServer.is_bus_mute(effects_bus))
	game.settings.effects_muted = false
	game.settings.music_volume = 0.0
	game.settings._commit(false)
	assert(AudioServer.is_bus_mute(music_bus), "Zero music volume must be silent")
	game.settings.close_options()
	game.settings.set_endless(false)
	game._unhandled_input(press)
	assert(game.state == "running")
	game._unhandled_input(press)
	assert(game.vertical_speed < 0)
	var single_peak := 0.0
	for i in range(55):
		game._physics_process(1.0 / 60.0)
		single_peak = minf(single_peak, game.height)
	assert(game.height == 0.0)
	assert(game.bot.animation == &"run")
	assert(game.jumps_used == 0)
	game.spawn_in = 100.0
	game.obstacles.clear()
	game._unhandled_input(press)
	for i in range(20):
		game._physics_process(1.0 / 60.0)
	game._unhandled_input(press)
	assert(game.jumps_used == 2 and game.vertical_speed == game.DOUBLE_JUMP_SPEED)
	assert(game.bot.animation == &"jump", "Second impulse must use upright poses without spinning")
	assert(is_equal_approx(game.bot.scale.x * game.bot.HEAD_WIDTHS[&"jump"], game.bot.DISPLAY_HEAD_WIDTH))
	var second_speed: float = game.vertical_speed
	game._unhandled_input(press)
	assert(game.jumps_used == 2 and game.vertical_speed == second_speed, "A third jump must be rejected")
	var double_peak: float = game.height
	for i in range(100):
		game._physics_process(1.0 / 60.0)
		double_peak = minf(double_peak, game.height)
	assert(double_peak < single_peak - 100.0, "Double jump must rise significantly higher than a single jump")
	assert(game.height == 0.0 and game.jumps_used == 0 and game.bot.animation == &"run")
	game._unhandled_input(press)
	for i in range(32):
		game._physics_process(1.0 / 60.0)
	assert(game.vertical_speed > 0.0 and game.height < 0.0)
	game._unhandled_input(press)
	assert(game.vertical_speed == game.DOUBLE_JUMP_SPEED, "Double jump must work during descent too")
	game._reset()
	assert(game.jumps_used == 0)
	game._start_run()
	game._unhandled_input(press)
	game._unhandled_input(press)
	game._unhandled_input(press)
	assert(game.jumps_used == 2, "Rapid presses must still allow at most two jumps")
	game._reset()
	game._start_run()
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	game._unhandled_input(touch)
	var emulated_click := InputEventMouseButton.new()
	emulated_click.pressed = true
	emulated_click.button_index = MOUSE_BUTTON_LEFT
	emulated_click.device = -1
	game._unhandled_input(emulated_click)
	assert(game.jumps_used == 1, "One touch must not consume both jumps")
	game._unhandled_input(touch)
	assert(game.jumps_used == 2)
	game._reset()
	game._start_run()
	var slide_events: Array[InputEvent] = []
	for key in [KEY_DOWN, KEY_CTRL]:
		var key_event := InputEventKey.new()
		key_event.keycode = key
		key_event.pressed = true
		slide_events.append(key_event)
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	slide_events.append(right_click)
	for slide_event in slide_events:
		Input.action_press("slide")
		game._unhandled_input(slide_event)
		assert(game.sliding and game.bot.animation == &"slide", "Down, Ctrl and right mouse must start a slide")
		var overhead := Rect2(game.PLAYER_X - 10, game.ground_y - 85, 20, 25)
		assert(game._body_rect().intersects(overhead), "Entering the slide is not yet the low posture")
		game.bot.frame = 5
		assert(game.bot.frame == 4 and not game.bot.is_playing(), "Holding slide must keep the low pose")
		var slide_texture: Texture2D = game.bot.sprite_frames.get_frame_texture(&"slide", 4)
		var slide_bounds := slide_texture.get_image().get_used_rect()
		assert(slide_bounds.size.y * game.bot.scale.y <= 65.0, "Low slide must look almost flat")
		assert(slide_bounds.size.x * game.bot.scale.x >= 125.0, "Low slide must visibly extend the body")
		assert(not game._body_rect().intersects(overhead), "Low hitbox must pass below overhead hazards")
		assert(game._body_rect().size.y == 50.0)
		assert(game._body_rect().intersects(Rect2(game.PLAYER_X, game.ground_y - 54, 32, 54)), "Sliding must not grant immunity to ground obstacles")
		Input.action_release("slide")
		slide_event.pressed = false
		game._unhandled_input(slide_event)
		assert(game.bot.is_playing(), "Releasing slide must resume the recovery poses")
		game._on_animation_finished()
		assert(not game.sliding and game.bot.animation == &"run" and game._body_rect().intersects(overhead))
	Input.action_press("slide")
	game._start_slide()
	game._unhandled_input(press)
	assert(not game.sliding and game.jumps_used == 1 and game.bot.animation == &"jump", "Jump must interrupt the slide")
	game._physics_process(1.0 / 60.0)
	game._start_slide()
	assert(not game.sliding, "Sliding must not start in midair")
	Input.action_release("slide")
	game._reset()
	game._start_run()
	game._start_slide()
	game._reset()
	assert(not game.sliding and game.bot.animation == &"idle", "Restart must clear the slide")
	game._start_run()
	for i in range(3):
		game.invincible = 0.0
		game.obstacles.clear()
		game.obstacles.append(game._make_obstacle("computer", game.PLAYER_X))
		game._physics_process(1.0 / 60.0)
		assert(game.bot.modulate.a == 1.0, "Character must remain opaque after damage")
		assert(game.obstacles.is_empty(), "Consumed obstacle must not cover character")
	assert(game.state == "dying")
	assert(game.bot.animation == &"game_over")
	game._on_animation_finished()
	assert(game.state == "over")
	assert(game.message.text.begins_with("FI DE LA PARTIDA"))
	assert(game.bottom_controls.text.contains("torna a l'inici"))
	game._unhandled_input(press)
	assert(game.state == "ready" and game.lives == 3 and game.obstacles.is_empty())
	assert(game.speed == game.START_SPEED and game.foreground_offset == 0.0)
	# Endless starts in the selected world, changes exactly at each kilometer,
	# wraps through the catalog, and preserves the ongoing jump/hazards/run.
	game.settings.select_world("vendrell")
	game.settings.set_endless(true)
	game._start_run()
	game.distance = 999.9
	game._update_endless_world()
	assert(game.world.id == "vendrell")
	game.lives = 2
	game.speed = game.MAX_SPEED
	game.height = -30.0
	game.jumps_used = 2
	game.vertical_speed = -100.0
	game.invincible = 0.6
	game.spawn_in = 0.8
	game.obstacles.append(game._make_obstacle("computer", 900))
	game.distance = 1000.0
	game._update_endless_world()
	assert(game.world.id == "datacenter" and game.world_segment == 1)
	assert(game.distance == 1000 and game.lives == 2 and game.speed == game.MAX_SPEED)
	assert(game.height == -30 and game.vertical_speed == -100 and game.invincible == 0.6 and game.spawn_in == 0.8)
	assert(game.jumps_used == 2, "World transitions must not grant extra jumps")
	assert(game.obstacles.size() == 1 and game.obstacles[0].x == 900)
	game.background_offset = 45.0
	game.distance = 1000.1
	game._update_endless_world()
	assert(game.background_offset == 45.0, "A milestone must trigger only once")
	game.distance = 2000.0
	game._update_endless_world()
	assert(game.world.id == "botiga" and is_equal_approx(game._obstacle_rect(game.obstacles[0]).end.y, game.ground_y))
	game.distance = 8000.0
	game._update_endless_world()
	assert(game.world.id == "vendrell", "Endless must cycle through all worlds")
	game.distance = 17000.0
	game._update_endless_world()
	assert(game.world.id == "datacenter", "Large distance steps must choose the correct segment")
	game._reset()
	assert(game.world.id == "vendrell" and game.distance == 0 and game.lives == 3 and game.world_segment == 0)
	game._start_run()
	game.distance = 999.9
	game.speed = game.MAX_SPEED
	game.spawn_in = 10.0
	game._physics_process(1.0 / 60.0)
	assert(game.distance > 1000 and game.world.id == "datacenter", "Physics must trigger the world change")
	game._reset()
	game.settings.set_endless(false)
	game._start_run()
	game.distance = 2000.0
	game._update_endless_world()
	assert(game.world.id == "vendrell", "Fixed-world mode must never rotate worlds")
	print("PASS: slide keys/mouse/hold/release/hitbox/jump/reset, all pose anchors, double jump, Endless transitions, worlds, audio and gameplay")
	game.audio.music_player.stop()
	for player in game.audio.effect_players:
		player.stop()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	DirAccess.remove_absolute(settings_path)
	quit()
