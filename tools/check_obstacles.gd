extends SceneTree

var game

func _initialize() -> void:
	call_deferred("verify")

func simulate(id: String, maneuver: String, test_speed: float) -> bool:
	Input.action_release("slide")
	game._reset()
	game._start_run()
	game.spawn_in = 100.0
	var obstacle: Dictionary = game._make_obstacle(id, 0)
	var arrival := 0.4 if obstacle.kind == "jump" else 0.65
	var local_box: Rect2 = obstacle.hitbox
	obstacle.x = game.PLAYER_X + test_speed * arrival - local_box.get_center().x
	game.obstacles.append(obstacle)
	if maneuver in ["jump", "double_jump"]:
		game._try_jump()
	elif maneuver == "slide":
		Input.action_press("slide")
		game._start_slide()
		game.bot.frame = 5
	for frame in range(120):
		if maneuver == "double_jump" and frame == 12:
			game._try_jump()
		game.distance = 800.0 if test_speed == 720.0 else 0.0
		game.speed = test_speed
		game._physics_process(1.0 / 60.0)
	Input.action_release("slide")
	return game.lives == 3 and game.obstacles.is_empty()

func verify() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	game.get_node("UI/Settings").preferences_path = "user://obstacles-check-%d.cfg" % OS.get_process_id()
	root.add_child(game)
	game.set_physics_process(false)
	game.settings.endless_mode = false
	game.settings.all_muted = true
	game._apply_preferences()
	game.state = "running"
	game.scroll_step = 6.0
	assert(is_equal_approx(game._render_scroll(1.0, 0.8, 100.0, 0.25), 97.4), "Scroll interpolation must wrap backwards across tile edges")
	assert(is_equal_approx(game._render_scroll(1.0, 0.8, 100.0, 0.75), 99.8), "Scroll must advance between physics ticks")
	assert(is_equal_approx(game._render_scroll(20.0, 0.8, 100.0, 0.5), 17.6))
	game.state = "ready"
	assert(game._render_scroll(20.0, 0.8, 100.0, 0.5) == 20.0, "Stopped scenery must not interpolate")
	for definition in game.ObstacleCatalog.DEFINITIONS:
		var image: Image = game.ObstacleCatalog.create(definition.id, 0).texture.get_image()
		assert(image.get_pixel(0, 0).a == 0.0, "Prepared sprite must have transparent padding")
		for test_speed in [360.0, 720.0]:
			assert(not simulate(definition.id, "none", test_speed), "Standing must hit " + definition.id)
			assert(simulate(definition.id, definition.kind, test_speed), "Required maneuver must clear " + definition.id)
			if definition.kind == "double_jump":
				assert(not simulate(definition.id, "jump", test_speed), "Single jump must not clear " + definition.id)
			elif definition.kind == "slide":
				assert(not simulate(definition.id, "jump", test_speed), "Hanging device must require sliding")
				assert(not simulate(definition.id, "double_jump", test_speed), "Supporting cables must block double jumping")
			if definition.has("ceiling_id"):
				assert(not simulate(definition.id, "double_jump", test_speed), "Passage ceiling must block double jump: " + definition.id)
				assert(not simulate(definition.id, "slide", test_speed), "Passage floor must block sliding: " + definition.id)
	assert(game.ObstacleCatalog.DEFINITIONS.size() == 45)
	assert("evil_ai_robot" in game.ObstacleCatalog.ids_for_world("datacenter"))
	assert("peripherals" in game.ObstacleCatalog.ids_for_world("taller"))
	assert("printer" in game.ObstacleCatalog.ids_for_world("oficina"))
	for definition in game.ObstacleCatalog.DEFINITIONS:
		assert(game.ObstacleCatalog.create(definition.id, 0).texture.resource_path.get_base_dir().get_file() in definition.worlds)
	for world_definition in game.WorldCatalog.WORLDS:
		game._reset()
		game._set_world(world_definition.id)
		var pool = game.ObstacleCatalog.ids_for_world(world_definition.id)
		assert(pool.size() >= 6, "Each world must include its new sprites")
		var counts := {"jump": 0, "double_jump": 0, "slide": 0}
		for id in pool:
			counts[game.ObstacleCatalog.create(id, 0).kind] += 1
		assert(counts.slide >= 2 and counts.double_jump >= 2, "Every world needs ceiling and tall variety")
		var previous := ""
		for cycle in range(3):
			var seen: Dictionary = {}
			for index in range(pool.size()):
				game._spawn_obstacle()
				var obstacle: Dictionary = game.obstacles[-1]
				assert(obstacle.id in pool, "Wrong scenery for obstacle")
				assert(not seen.has(obstacle.id), "Bag must include each world obstacle once")
				assert(previous != obstacle.id, "Bag boundaries must not repeat")
				seen[obstacle.id] = true
				previous = obstacle.id
		game._set_world("datacenter" if world_definition.id != "datacenter" else "botiga")
		assert(game.obstacle_bag.is_empty(), "Changing scenery must discard the old spawn bag")
	for test_speed in [360.0, 720.0]:
		game._reset()
		game._start_run()
		game.spawn_in = 100.0
		var traveled := 0.0
		for frame in range(30):
			game.distance = 800.0 if test_speed == 720.0 else 0.0
			game.speed = test_speed
			game._physics_process(1.0 / 60.0)
			traveled += game.speed / 60.0
		assert(absf((100.0 - game.spawn_in) * game.START_SPEED - traveled) < 0.01, "Spawn countdown must consume distance at both speeds")
	game._reset()
	assert(game.obstacles_spawned == 0 and game.obstacle_bag.is_empty() and game.last_obstacle_id.is_empty())
	game.audio.music_player.stop()
	for player in game.audio.effect_players:
		player.stop()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("PASS: all transparent assets, all three maneuvers at initial/max speed, single-vs-double height, hanging clearance, world-specific spawn bags, spacing and reset")
	quit()
