extends Node2D

const FLOOR_Y := 480.0
const PLAYER_X := 210.0
const FLIGHT_TIME := 0.8
const GRAVITY := 1800.0
const JUMP_SPEED := -720.0
const DATACENTER := preload("res://images/background/datacenter.png")
const BACKGROUND_HEIGHT := 640.0
const WALKWAY_RATIO := 0.80

# Reach the top speed at 800 m; distances remain independent of frame rate.
const START_SPEED := 360.0
const MAX_SPEED := 720.0
const METERS_TO_MAX_SPEED := 800.0
const BACKGROUND_SPEED_RATIO := 0.80

const SAVE_PATH := "user://record.cfg"

@onready var bot = $Resetbot
@onready var hud: Label = $UI/HUD
@onready var message: Label = $UI/Message
var state := "ready"
var speed := START_SPEED
var distance := 0.0
var best := 0
var lives := 3
var height := 0.0
var vertical_speed := 0.0
var spawn_in := 1.6
var invincible := 0.0
var hit_time := 0.0
var background_offset := 0.0
var foreground_offset := 0.0
var obstacles: Array[Rect2] = []

func _ready() -> void:
	var save := ConfigFile.new()
	if save.load(SAVE_PATH) == OK:
		best = int(save.get_value("score", "best", 0))
	bot.animation_finished.connect(_on_animation_finished)
	_update_hud()
	_place_bot()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
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
			state = "running"
			message.text = ""
		elif state == "over":
			_reset()
		elif state == "running" and height == 0.0:
			vertical_speed = JUMP_SPEED
			bot.start_jump(FLIGHT_TIME)

func _physics_process(delta: float) -> void:
	if state != "running":
		_place_bot()
		return
	distance += speed * delta / 20.0
	speed = speed_at_distance(distance)
	var tile_width := DATACENTER.get_width() * BACKGROUND_HEIGHT / DATACENTER.get_height()
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
			bot.stop()
	if height == 0.0 and hit_time == 0.0:
		bot.set_ground_motion(speed)
	spawn_in -= delta
	if spawn_in <= 0.0:
		obstacles.append(Rect2(1100.0, FLOOR_Y - 54.0, 32.0, 54.0))
		# Always leave enough room to land before the next jump.
		spawn_in = randf_range(1.35, 2.05)
	var body := Rect2(PLAYER_X - 22.0, FLOOR_Y + height - 92.0, 44.0, 90.0)
	for i in range(obstacles.size() - 1, -1, -1):
		obstacles[i].position.x -= speed * delta
		if obstacles[i].end.x < 0.0:
			obstacles.remove_at(i)
		elif invincible == 0.0 and body.intersects(obstacles[i]):
			obstacles.remove_at(i)
			lives -= 1
			invincible = 1.5
			hit_time = 0.25
			if lives <= 0:
				_end_run()
				break
			bot.show_hit()
	# Keep Resetbot fully opaque, including the fatal-hit frame.
	bot.modulate = Color(1.0, 0.85, 0.75, 1.0) if invincible > 0.0 and state == "running" else Color.WHITE
	_place_bot()
	_update_hud()
	queue_redraw()

func speed_at_distance(meters: float) -> float:
	return lerpf(START_SPEED, MAX_SPEED, clampf(meters / METERS_TO_MAX_SPEED, 0.0, 1.0))

func _place_bot() -> void:
	bot.position = Vector2(PLAYER_X, FLOOR_Y + height)

func _end_run() -> void:
	state = "dying"
	height = 0.0
	bot.modulate = Color.WHITE
	bot.show_game_over()
	best = maxi(best, int(distance))
	var save := ConfigFile.new()
	save.set_value("score", "best", best)
	save.save(SAVE_PATH)

func _on_animation_finished() -> void:
	if state == "dying" and bot.animation == &"game_over":
		state = "over"
		message.text = "GAME OVER\nEspacio o clic para volver a empezar"

func _reset() -> void:
	state = "ready"
	distance = 0.0
	lives = 3
	speed = START_SPEED
	height = 0.0
	vertical_speed = 0.0
	spawn_in = 1.6
	invincible = 0.0
	hit_time = 0.0
	obstacles.clear()
	background_offset = 0.0
	foreground_offset = 0.0
	bot.modulate = Color.WHITE
	bot.speed_scale = 1.0
	bot.play(&"idle")
	message.text = "RESET RUN\nEspacio o clic para comenzar"
	_place_bot()
	_update_hud()
	queue_redraw()

func _update_hud() -> void:
	hud.text = "RESET RUN     %05d m     RÉCORD %05d     VIDAS %d     VELOCIDAD ×%.2f\nEspacio / ↑ / clic: saltar     R: reiniciar" % [int(distance), best, lives, speed / START_SPEED]

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1100, 640), Color("11151f"))
	# Preserve aspect ratio and align Resetbot's feet with the pictured walkway.
	var tile_width := DATACENTER.get_width() * BACKGROUND_HEIGHT / DATACENTER.get_height()
	var top := FLOOR_Y - BACKGROUND_HEIGHT * WALKWAY_RATIO
	var x := -background_offset
	while x < 1100.0:
		draw_texture_rect(DATACENTER, Rect2(x, top, tile_width, BACKGROUND_HEIGHT), false)
		x += tile_width
	# Low foreground streaks reinforce movement without obscuring hazards or sprites.
	if state == "running":
		var intensity := (speed - START_SPEED) / (MAX_SPEED - START_SPEED)
		for i in range(8):
			var streak_x := float(i) * 180.0 - foreground_offset
			var streak_y := FLOOR_Y + 72.0 + float(i % 3) * 18.0
			draw_line(Vector2(streak_x, streak_y), Vector2(streak_x + 35.0 + intensity * 45.0, streak_y), Color(0.45, 0.75, 0.95, 0.12 + intensity * 0.12), 2.0)
	for obstacle in obstacles:
		draw_rect(obstacle, Color("ad2536"))
		draw_rect(obstacle.grow(-4), Color("e94c51"))
		draw_line(obstacle.position + Vector2(6, 8), obstacle.end - Vector2(6, 8), Color("ffe1bb"), 4)
