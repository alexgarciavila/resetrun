extends Node2D

const FLOOR_Y := 493.0
const PLAYER_X := 210.0
const FLIGHT_TIME := 0.8
const GRAVITY := 1800.0
const JUMP_SPEED := -720.0
const DOUBLE_JUMP_SPEED := -820.0
const WorldCatalog := preload("res://scripts/world_catalog.gd")
const ObstacleCatalog := preload("res://scripts/obstacle_catalog.gd")
const BACKGROUND_HEIGHT := 640.0
const WORLD_INTERVAL := 1000.0
const SLIDE_BODY_HEIGHT := 52.0
const BACKGROUND_DIM_ALPHA := 0.18
const OUTLINE_DIRECTIONS := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-0.707, -0.707), Vector2(0.707, -0.707), Vector2(-0.707, 0.707), Vector2(0.707, 0.707)]

# Reach the top speed at 800 m; distances remain independent of frame rate.
const START_SPEED := 360.0
const MAX_SPEED := 720.0
const METERS_TO_MAX_SPEED := 800.0
const BACKGROUND_SPEED_RATIO := 0.80

const SAVE_PATH := "user://record.cfg"

@onready var bot = $Resetbot
@onready var hud: Label = $UI/HUD
@onready var message: Label = $UI/Message
@onready var bottom_status: Label = $UI/Footer/Status
@onready var bottom_controls: Label = $UI/Footer/Controls
@onready var settings = $UI/Settings
@onready var audio = $Audio
var state := "ready"
var speed := START_SPEED
var distance := 0.0
var best := 0
var lives := 3
var height := 0.0
var vertical_speed := 0.0
var jumps_used := 0
var sliding := false
var spawn_in := 1.6
var invincible := 0.0
var hit_time := 0.0
var background_offset := 0.0
var foreground_offset := 0.0
var scroll_step := 0.0
var fps_label: Label
var fps_elapsed := 0.0
var fps_frames := 0
var fps_worst_ms := 0.0
var obstacles: Array[Dictionary] = []
var obstacles_spawned := 0
var obstacle_bag: Array[String] = []
var last_obstacle_id := ""
var obstacle_silhouettes: Dictionary = {}
var world: Dictionary = WorldCatalog.get_world("datacenter")
var ground_y := FLOOR_Y
var background_height := BACKGROUND_HEIGHT
var foreground_fade: GradientTexture2D
var endless_mode := false
var route_worlds: Array[String] = []
var route_start := 0
var world_segment := 0
var world_notice_time := 0.0

func _ready() -> void:
	TranslationServer.set_locale("ca")
	fps_label = Label.new()
	fps_label.position = Vector2(30, 62)
	fps_label.add_theme_font_override("font", hud.get_theme_font("font"))
	fps_label.add_theme_font_size_override("font_size", 12)
	fps_label.visible = false
	fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(fps_label)
	_prepare_obstacle_silhouettes()
	if not InputMap.has_action("slide"):
		InputMap.add_action("slide")
		for key in [KEY_DOWN, KEY_CTRL]:
			var key_event := InputEventKey.new()
			key_event.keycode = key
			InputMap.action_add_event("slide", key_event)
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("slide", mouse_event)
	foreground_fade = GradientTexture2D.new()
	foreground_fade.width = 2
	foreground_fade.height = 128
	foreground_fade.fill_from = Vector2.ZERO
	foreground_fade.fill_to = Vector2(0, 1)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	gradient.colors = PackedColorArray([Color(0.067, 0.082, 0.122, 0), Color(0.067, 0.082, 0.122, 0.95), Color("11151f")])
	foreground_fade.gradient = gradient
	for definition in WorldCatalog.WORLDS:
		if definition.available:
			route_worlds.append(definition.id)
	var save := ConfigFile.new()
	if save.load(SAVE_PATH) == OK:
		best = int(save.get_value("score", "best", 0))
	bot.animation_finished.connect(_on_animation_finished)
	settings.start_requested.connect(_start_run)
	settings.preferences_changed.connect(_apply_preferences)
	settings.audio_requested.connect(_preview_audio)
	_apply_preferences()
	_update_hud()
	_place_bot()

func _prepare_obstacle_silhouettes() -> void:
	# Build once with native image operations; the source sprites stay untouched.
	for definition in ObstacleCatalog.DEFINITIONS:
		var mask: Image = definition.texture.get_image()
		if mask.is_compressed():
			mask.decompress()
		var white := Image.create(mask.get_width(), mask.get_height(), false, Image.FORMAT_RGBA8)
		white.fill(Color.WHITE)
		var silhouette := Image.create(mask.get_width(), mask.get_height(), false, Image.FORMAT_RGBA8)
		silhouette.fill(Color.TRANSPARENT)
		silhouette.blit_rect_mask(white, mask, Rect2i(Vector2i.ZERO, mask.get_size()), Vector2i.ZERO)
		obstacle_silhouettes[definition.id] = ImageTexture.create_from_image(silhouette)

func _apply_preferences() -> void:
	if state == "ready":
		endless_mode = settings.endless_mode
		_set_world(settings.selected_world)
		_update_hud()
	audio.apply_settings(settings.music_volume, settings.effects_volume, settings.music_muted, settings.effects_muted, settings.all_muted)

func _set_world(id: String) -> void:
	world = WorldCatalog.get_world(id)
	# Keep each floor visible, including the deep foreground in workshop scenes.
	background_height = world.background_height
	ground_y = maxf(FLOOR_Y, background_height * float(world.walkway_ratio))
	background_offset = 0.0
	scroll_step = 0.0
	_place_bot()
	bot.reset_physics_interpolation()
	queue_redraw()

func _update_endless_world() -> void:
	if not endless_mode or route_worlds.is_empty():
		return
	var segment := floori(distance / WORLD_INTERVAL)
	if segment == world_segment:
		return
	world_segment = segment
	_set_world(route_worlds[(route_start + segment) % route_worlds.size()])
	world_notice_time = 2.0
	message.text = "MÓN: " + world.title.to_upper()

func _preview_audio() -> void:
	audio.activate()
	audio.play_effect("select")

func _start_run() -> void:
	if state != "ready" or settings.is_modal_open():
		return
	audio.activate()
	audio.play_effect("select")
	endless_mode = settings.endless_mode
	route_start = maxi(route_worlds.find(settings.selected_world), 0)
	world_segment = 0
	world_notice_time = 0.0
	_set_world(settings.selected_world)
	state = "running"
	message.text = ""
	settings.show_start_menu(false)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		fps_label.visible = not fps_label.visible
		return
	if event is InputEventMouseButton and event.device == -1:
		# A touch also produces an emulated mouse event; count only the touch.
		return
	if settings.is_modal_open():
		return
	if event.is_action_pressed("slide"):
		_start_slide()
		return
	if event.is_action_released("slide"):
		if sliding and not Input.is_action_pressed("slide"):
			bot.release_slide()
		return
	if state == "ready" and event is InputEventKey and event.pressed and event.keycode == KEY_M:
		settings.open_worlds()
		return
	if state == "ready" and event is InputEventKey and event.pressed and event.keycode == KEY_O:
		settings.open_options()
		return
	var action := event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_up")
	if event is InputEventMouseButton:
		action = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		action = event.pressed
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_reset()
		return
	if action:
		if state == "ready":
			_start_run()
		elif state == "over":
			_reset()
		elif state == "running":
			_try_jump()

func _try_jump() -> void:
	if jumps_used >= 2:
		return
	sliding = false
	bot.release_slide()
	if jumps_used == 0:
		jumps_used = 1
		vertical_speed = JUMP_SPEED
		bot.start_jump(FLIGHT_TIME)
	else:
		jumps_used = 2
		vertical_speed = DOUBLE_JUMP_SPEED
		# Solve the remaining flight time from the current height, including descent.
		var remaining := (-vertical_speed + sqrt(vertical_speed * vertical_speed - 2.0 * GRAVITY * height)) / GRAVITY
		bot.start_double_jump(remaining)
	audio.play_effect("jump")

func _start_slide() -> void:
	if state != "running" or height != 0.0 or vertical_speed != 0.0 or hit_time > 0.0 or sliding:
		return
	sliding = true
	bot.start_slide()

func _body_rect() -> Rect2:
	if sliding and bot.animation == &"slide" and bot.frame >= 2 and bot.frame <= 4:
		return Rect2(PLAYER_X - 55.0, ground_y - SLIDE_BODY_HEIGHT, 110.0, SLIDE_BODY_HEIGHT - 2.0)
	return Rect2(PLAYER_X - 22.0, ground_y + height - 92.0, 44.0, 90.0)

func _make_obstacle(id: String, x: float) -> Dictionary:
	return ObstacleCatalog.create(id, x)

func _obstacle_rect(obstacle: Dictionary) -> Rect2:
	var result: Rect2 = obstacle.hitbox
	result.position += Vector2(obstacle.x, ground_y)
	return result

func _obstacle_hits(obstacle: Dictionary, body: Rect2) -> bool:
	if body.intersects(_obstacle_rect(obstacle)):
		return true
	if obstacle.has("upper_hitbox"):
		var upper: Rect2 = obstacle.upper_hitbox
		upper.position += Vector2(obstacle.x, ground_y)
		return body.intersects(upper)
	return false

func _spawn_obstacle() -> void:
	if obstacle_bag.is_empty():
		for definition in ObstacleCatalog.DEFINITIONS:
			obstacle_bag.append(definition.id)
		obstacle_bag.shuffle()
		if obstacle_bag[-1] == last_obstacle_id:
			var first := obstacle_bag[0]
			obstacle_bag[0] = obstacle_bag[-1]
			obstacle_bag[-1] = first
	var obstacle := _make_obstacle(obstacle_bag.pop_back(), 1140.0)
	last_obstacle_id = obstacle.id
	obstacles.append(obstacle)
	obstacles_spawned += 1
	# Distance-based spacing: normalized seconds at START_SPEED, not wall time.
	# A fixed extra gap after tall hazards allows landing before the next action.
	var gap := randf_range(500.0, 580.0)
	if obstacle.kind == "double_jump":
		gap += 280.0
	spawn_in = (gap + float(obstacle.draw_size.x)) / START_SPEED

func _process(delta: float) -> void:
	# Custom canvas drawing must refresh at the display rate, not the physics rate.
	if state == "running":
		queue_redraw()
	fps_elapsed += delta
	fps_frames += 1
	fps_worst_ms = maxf(fps_worst_ms, delta * 1000.0)
	if fps_elapsed >= 1.0:
		fps_label.text = "%d FPS · %.1f ms · PIC %.1f ms" % [roundi(fps_frames / fps_elapsed), fps_elapsed * 1000.0 / fps_frames, fps_worst_ms]
		fps_elapsed = 0.0
		fps_frames = 0
		fps_worst_ms = 0.0

func _render_scroll(offset: float, ratio: float, period: float, fraction: float = -1.0) -> float:
	if state != "running":
		return offset
	if fraction < 0.0:
		fraction = Engine.get_physics_interpolation_fraction()
	return fposmod(offset - scroll_step * ratio * (1.0 - fraction), period)

func _physics_process(delta: float) -> void:
	if state != "running":
		_place_bot()
		return
	distance += speed * delta / 20.0
	speed = speed_at_distance(distance)
	_update_endless_world()
	world_notice_time = maxf(0.0, world_notice_time - delta)
	if world_notice_time == 0.0:
		message.text = ""
	var background: Texture2D = world.background
	var tile_width := background.get_width() * background_height / background.get_height()
	scroll_step = speed * delta
	background_offset = fmod(background_offset + speed * delta * BACKGROUND_SPEED_RATIO, tile_width)
	foreground_offset = fmod(foreground_offset + speed * delta * 1.2, 180.0)
	invincible = maxf(0.0, invincible - delta)
	hit_time = maxf(0.0, hit_time - delta)
	if height < 0.0 or vertical_speed < 0.0:
		vertical_speed += GRAVITY * delta
		height += vertical_speed * delta
		if height >= 0.0:
			height = 0.0
			vertical_speed = 0.0
			jumps_used = 0
			bot.stop()
	if sliding and not Input.is_action_pressed("slide"):
		bot.release_slide()
	if height == 0.0 and hit_time == 0.0 and not sliding:
		bot.set_ground_motion(speed)
	spawn_in -= delta * speed / START_SPEED
	if spawn_in <= 0.0:
		_spawn_obstacle()
	var body := _body_rect()
	for i in range(obstacles.size() - 1, -1, -1):
		obstacles[i]["previous_x"] = obstacles[i].x
		obstacles[i].x -= speed * delta
		if obstacles[i].x + obstacles[i].draw_size.x < 0.0:
			obstacles.remove_at(i)
		elif invincible == 0.0 and _obstacle_hits(obstacles[i], body):
			obstacles.remove_at(i)
			lives -= 1
			invincible = 1.5
			hit_time = 0.25
			if lives <= 0:
				_end_run()
				break
			bot.show_hit()
			sliding = false
			bot.release_slide()
			audio.play_effect("hit")
	# Keep Resetbot fully opaque, including the fatal-hit frame.
	bot.modulate = Color(1.0, 0.85, 0.75, 1.0) if invincible > 0.0 and state == "running" else Color.WHITE
	_place_bot()
	_update_hud()
	queue_redraw()

func speed_at_distance(meters: float) -> float:
	return lerpf(START_SPEED, MAX_SPEED, clampf(meters / METERS_TO_MAX_SPEED, 0.0, 1.0))

func _place_bot() -> void:
	bot.position = Vector2(PLAYER_X, ground_y + height)

func _end_run() -> void:
	state = "dying"
	world_notice_time = 0.0
	message.text = ""
	height = 0.0
	jumps_used = 0
	sliding = false
	bot.release_slide()
	bot.modulate = Color.WHITE
	bot.show_game_over()
	audio.play_effect("game_over")
	best = maxi(best, int(distance))
	var save := ConfigFile.new()
	save.set_value("score", "best", best)
	save.save(SAVE_PATH)

func _on_animation_finished() -> void:
	if sliding and bot.animation == &"slide":
		sliding = false
		bot.stop()
		bot.set_ground_motion(speed)
	if state == "dying" and bot.animation == &"game_over":
		state = "over"
		message.text = "FI DE LA PARTIDA"
		_update_hud()

func _reset() -> void:
	state = "ready"
	distance = 0.0
	lives = 3
	speed = START_SPEED
	height = 0.0
	vertical_speed = 0.0
	jumps_used = 0
	sliding = false
	bot.release_slide()
	spawn_in = 1.6
	invincible = 0.0
	hit_time = 0.0
	obstacles.clear()
	obstacles_spawned = 0
	obstacle_bag.clear()
	last_obstacle_id = ""
	background_offset = 0.0
	foreground_offset = 0.0
	world_segment = 0
	world_notice_time = 0.0
	endless_mode = settings.endless_mode
	_set_world(settings.selected_world)
	bot.modulate = Color.WHITE
	bot.speed_scale = 1.0
	bot.play(&"idle")
	message.text = "RESET RUN"
	settings.show_start_menu(true)
	_place_bot()
	_update_hud()
	queue_redraw()

func _update_hud() -> void:
	var title := "SENSE FI" if endless_mode else "RESET RUN"
	hud.text = "%s  %05d m  RÈCORD %05d  VIDES %d  VELOCITAT ×%.2f" % [title, int(distance), best, lives, speed / START_SPEED]
	if endless_mode:
		var remaining := ceili(WORLD_INTERVAL - fmod(distance, WORLD_INTERVAL))
		bottom_status.text = "SENSE FI · %s · SEGÜENT EN %04d m" % [world.title.to_upper(), remaining]
	else:
		bottom_status.text = "MÓN FIX · " + world.title.to_upper()
	if state == "ready":
		bottom_controls.text = "Espai / ↑ / clic: comença   M: mons   O: so"
	elif state == "over":
		bottom_controls.text = "Espai / ↑ / clic: torna a l'inici   R: reinicia"
	elif state == "dying":
		bottom_controls.text = "Espera un moment..."
	else:
		bottom_controls.text = "Espai / ↑ / clic: salt i doble salt   ↓ / Ctrl / clic dret: llisca   R: reinicia"

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1100, 640), Color("11151f"))
	# Preserve aspect ratio and align Resetbot's feet with the pictured walkway.
	var background: Texture2D = world.background
	var tile_width := background.get_width() * background_height / background.get_height()
	var top: float = ground_y - background_height * world.walkway_ratio
	var bottom := top + background_height
	var x := -_render_scroll(background_offset, BACKGROUND_SPEED_RATIO, tile_width)
	while x < 1100.0:
		draw_texture_rect(background, Rect2(x, top, tile_width, background_height), false)
		if bottom < 640.0:
			# Extend only the foreground edge; scenery keeps its uniform scale.
			var edge := Rect2(0, background.get_height() - 1, background.get_width(), 1)
			draw_texture_rect_region(background, Rect2(x, bottom, tile_width, 640.0 - bottom), edge)
		x += tile_width
	if bottom < 640.0:
		# Fade the extended floor into the foreground below the playable lane.
		var fade_top := ground_y + 12.0
		draw_texture_rect(foreground_fade, Rect2(0, fade_top, 1100, 640.0 - fade_top), false)
	# Dim scenery before drawing the character, hazards, fields and labels.
	draw_rect(Rect2(0, 0, 1100, 640), Color(0, 0, 0, BACKGROUND_DIM_ALPHA))
	# Low foreground streaks reinforce movement without obscuring hazards or sprites.
	if state == "running":
		var intensity := (speed - START_SPEED) / (MAX_SPEED - START_SPEED)
		for i in range(8):
			var streak_x := float(i) * 180.0 - _render_scroll(foreground_offset, 1.2, 180.0)
			var streak_y := ground_y + 72.0 + float(i % 3) * 18.0
			draw_line(Vector2(streak_x, streak_y), Vector2(streak_x + 35.0 + intensity * 45.0, streak_y), Color(0.45, 0.75, 0.95, 0.12 + intensity * 0.12), 2.0)
	for obstacle in obstacles:
		_draw_obstacle(obstacle)

func _draw_obstacle(obstacle: Dictionary) -> void:
	# Interpolate only a copy: collision boxes retain their fixed-step positions.
	obstacle = obstacle.duplicate()
	if state == "running":
		obstacle.x = lerpf(obstacle.get("previous_x", obstacle.x), obstacle.x, Engine.get_physics_interpolation_fraction())
	var sprite_rect := Rect2(Vector2(obstacle.x, ground_y + obstacle.draw_y), obstacle.draw_size)
	if obstacle.has("upper_hitbox"):
		for local_box in [obstacle.hitbox, obstacle.upper_hitbox]:
			var field: Rect2 = local_box
			field.position += Vector2(obstacle.x, ground_y)
			field = field.intersection(Rect2(0, 0, 1100, ground_y))
			if not field.has_area():
				continue
			draw_rect(field, Color(1.0, 0.12, 0.20, 0.22))
			draw_rect(field, Color("ff5464"), false, 2.0)
			for y in range(int(field.position.y), int(field.end.y), 12):
				draw_line(Vector2(field.position.x, y), Vector2(field.end.x, y), Color(1, 0.3, 0.35, 0.6), 2)
	if obstacle.kind == "slide":
		var sensor := _obstacle_rect(obstacle)
		var visible_top := maxf(0, sensor.position.y)
		var visible := Rect2(sensor.position.x, visible_top, sensor.size.x, sensor.end.y - visible_top)
		draw_rect(visible, Color(1.0, 0.12, 0.20, 0.10))
		for edge in [visible.position.x, visible.end.x]:
			draw_line(Vector2(edge, visible_top), Vector2(edge, visible.end.y), Color(1.0, 0.20, 0.25, 0.7), 2)
		for y in range(int(visible_top), int(visible.end.y), 24):
			draw_line(Vector2(visible.position.x, y), Vector2(visible.end.x, y), Color(1.0, 0.20, 0.25, 0.2), 1)
		draw_line(Vector2(visible.position.x, visible.end.y), visible.end, Color("65e7cb"), 2)
	var silhouette: Texture2D = obstacle_silhouettes[obstacle.id]
	for direction in OUTLINE_DIRECTIONS:
		var outer := sprite_rect
		outer.position += direction * 2.5
		draw_texture_rect(silhouette, outer, false, Color(0.02, 0.03, 0.05, 0.95))
	for direction in OUTLINE_DIRECTIONS:
		var inner := sprite_rect
		inner.position += direction * 1.25
		draw_texture_rect(silhouette, inner, false, Color(0.87, 0.97, 1.0, 0.92))
	draw_texture_rect(obstacle.texture, sprite_rect, false)
	var font: Font = hud.get_theme_font("font")
	var text_width := font.get_string_size(obstacle.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var at := Vector2(obstacle.x + (float(obstacle.draw_size.x) - text_width) * 0.5, sprite_rect.position.y - 16)
	if obstacle.kind == "slide":
		at.y = ground_y - obstacle.clearance - 22
	var cue_color: Color = {"jump": Color("ffdf72"), "double_jump": Color("ffad66"), "slide": Color("7bf0de")}[obstacle.kind]
	var badge := Rect2(at + Vector2(-6, -14), Vector2(text_width + 12, 22))
	draw_rect(badge, Color(0.035, 0.05, 0.08, 0.96))
	draw_rect(badge, cue_color, false, 1.0)
	draw_string(font, at + Vector2(0, 2), obstacle.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, cue_color)
