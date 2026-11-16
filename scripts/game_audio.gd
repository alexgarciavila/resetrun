extends Node

const MUSIC := preload("res://audio/arcade_pulse.ogg")
const EFFECTS := {
	"jump": preload("res://audio/jump.wav"),
	"hit": preload("res://audio/hit.wav"),
	"game_over": preload("res://audio/game_over.wav"),
	"select": preload("res://audio/select.wav"),
}

var music_player: AudioStreamPlayer
var effect_players: Array[AudioStreamPlayer] = []
var next_effect := 0
var activated := false
var impact_tween: Tween


func _ready() -> void:
	for bus_name in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			# Growing bus_count preserves routing in 4.7 web sample playback.
			AudioServer.bus_count += 1
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	var loop: AudioStreamOggVorbis = MUSIC.duplicate()
	loop.loop = true
	music_player.stream = loop
	add_child(music_player)
	for index in range(4):
		var player := AudioStreamPlayer.new()
		player.bus = "Effects"
		add_child(player)
		effect_players.append(player)


func activate() -> void:
	# Unlock effects after a player gesture without starting the race music.
	activated = true


func start_music() -> void:
	activate()
	if impact_tween:
		impact_tween.kill()
	music_player.volume_db = 0.0
	music_player.play(0.0)


func stop_music() -> void:
	music_player.stop()


func apply_settings(music_volume: float, effects_volume: float, music_muted: bool, effects_muted: bool, all_muted: bool) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), linear_to_db(maxf(effects_volume, 0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), music_muted or music_volume == 0.0)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Effects"), effects_muted or effects_volume == 0.0)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), all_muted)


func play_effect(cue: String) -> void:
	if not activated or not EFFECTS.has(cue):
		return
	if cue == "hit":
		if impact_tween:
			impact_tween.kill()
		music_player.volume_db = -7.0
		impact_tween = create_tween()
		impact_tween.tween_interval(0.12)
		impact_tween.tween_property(music_player, "volume_db", 0.0, 0.22)
	var player := effect_players[next_effect]
	next_effect = (next_effect + 1) % effect_players.size()
	player.stream = EFFECTS[cue]
	player.play()


func _exit_tree() -> void:
	music_player.stop()
	music_player.stream = null
	for player in effect_players:
		player.stop()
		player.stream = null
