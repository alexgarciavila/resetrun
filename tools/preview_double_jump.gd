extends SceneTree
var preview_animation: StringName = &"double_jump"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		preview_animation = StringName(args[0])
	call_deferred("capture")

func capture() -> void:
	for row in range(2):
		var backdrop := ColorRect.new()
		backdrop.position = Vector2(0, row * 320)
		backdrop.size = Vector2(1100, 320)
		backdrop.color = Color("24384f") if row == 0 else Color("d6e2ed")
		root.add_child(backdrop)
	for index in range(8):
		var bot = load("res://scenes/resetbot.tscn").instantiate()
		root.add_child(bot)
		bot.position = Vector2(140 + (index % 4) * 270, 235 + floori(float(index) / 4) * 320)
		bot.animation = preview_animation
		bot.frame = index
		bot.pause()
		var label := Label.new()
		label.text = "POSE %d" % (index + 1)
		label.position = bot.position + Vector2(-45, 30)
		label.add_theme_font_override("font", load("res://fonts/press_start_2p/PressStart2P-Regular.ttf"))
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color.WHITE if index < 4 else Color("152235"))
		root.add_child(label)
	for frame in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tools/previews/%s_frames.png" % preview_animation)
	quit()
