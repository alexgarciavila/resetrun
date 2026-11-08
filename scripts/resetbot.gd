extends AnimatedSprite2D
## Call these methods from the movement controller.
@export var reference_run_speed: float = 360.0
# Match head width, rather than total pose height (crouching must stay crouched).
const HEAD_WIDTHS := {&"run": 185.0, &"idle": 228.0, &"jump": 191.0, &"double_jump": 160.0, &"slide": 200.0, &"hit": 175.0, &"game_over": 175.0}
const DISPLAY_HEAD_WIDTH := 102.0
var _anchors: Dictionary = {}
var _slide_held := false


func set_ground_motion(horizontal_speed: float) -> void:
	if animation in [&"jump", &"double_jump", &"slide", &"hit", &"game_over"] and is_playing():
		return
	if absf(horizontal_speed) < 0.1:
		speed_scale = 1.0
		play(&"idle")
	else:
		speed_scale = clampf(absf(horizontal_speed) / reference_run_speed, 0.25, 3.0)
		play(&"run")

func start_jump(duration_seconds: float = 0.7) -> void:
	# Preserve all supplied poses; synchronize their total duration with flight.
	speed_scale = 1.0
	play(&"jump", (sprite_frames.get_frame_count(&"jump") / sprite_frames.get_animation_speed(&"jump")) / maxf(duration_seconds, 0.01))

func show_hit() -> void:
	speed_scale = 1.0
	play(&"hit")


func start_double_jump(duration_seconds: float) -> void:
	speed_scale = 1.0
	# Reuse the upright jump poses for the second impulse, without a somersault.
	stop()
	play(&"jump", (sprite_frames.get_frame_count(&"jump") / sprite_frames.get_animation_speed(&"jump")) / maxf(duration_seconds, 0.01))

func show_game_over() -> void:
	speed_scale = 1.0
	play(&"game_over")


func start_slide() -> void:
	_slide_held = true
	speed_scale = 1.0
	stop()
	play(&"slide")


func release_slide() -> void:
	_slide_held = false
	if animation == &"slide" and not is_playing():
		play()


func _hold_slide_pose() -> void:
	if animation == &"slide" and _slide_held and frame == 5:
		frame = 4
		pause()

func _ready() -> void:
	animation_changed.connect(_update_idle_alignment)
	frame_changed.connect(_update_geometry)
	frame_changed.connect(_hold_slide_pose)
	z_index = 10
	_update_idle_alignment()

func _update_idle_alignment() -> void:
	(material as ShaderMaterial).set_shader_parameter("align_idle", animation == &"idle")
	_update_geometry()

func _update_geometry() -> void:
	if sprite_frames == null or not sprite_frames.has_animation(animation):
		return
	var index := clampi(frame, 0, sprite_frames.get_frame_count(animation) - 1)
	var key := str(animation) + ":" + str(index)
	var texture: Texture2D = sprite_frames.get_frame_texture(animation, index)
	if not _anchors.has(key):
		var bounds := texture.get_image().get_used_rect()
		_anchors[key] = Vector2(bounds.position.x + bounds.size.x * 0.5, bounds.end.y)
	var anchor: Vector2 = _anchors[key]
	var factor: float = DISPLAY_HEAD_WIDTH / float(HEAD_WIDTHS.get(animation, 185.0))
	scale = Vector2.ONE * factor
	# Feet are at the node origin for every pose; physics controls jump height once.
	offset = texture.get_size() * 0.5 - anchor

