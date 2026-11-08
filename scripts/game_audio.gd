extends Node

const MUSIC := preload("res://audio/music.wav")
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


func _ready() -> void:
	for bus_name in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			# Growing bus_count preserves routing in 4.7 web sample playback.
			AudioServer.bus_count += 1
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	var loop: AudioStreamWAV = MUSIC.duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_end = roundi(loop.get_length() * loop.mix_rate)
	music_player.stream = loop
	add_child(music_player)
	music_player.finished.connect(func(): music_player.play())
	for index in range(4):
		var player := AudioStreamPlayer.new()
		player.bus = "Effects"
		add_child(player)
		effect_players.append(player)


func activate() -> void:
	# Start only after a player gesture, including on the web.
	if not activated:
		activated = true
		music_player.play()


func apply_settings(music_volume: float, effects_volume: float, music_muted: bool, effects_muted: bool, all_muted: bool) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), linear_to_db(maxf(effects_volume, 0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), music_muted or music_volume == 0.0)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Effects"), effects_muted or effects_volume == 0.0)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), all_muted)


func play_effect(cue: String) -> void:
	if not activated or not EFFECTS.has(cue):
		return
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
