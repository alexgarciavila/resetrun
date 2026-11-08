extends Control

signal start_requested
signal preferences_changed
signal audio_requested

const SETTINGS_PATH := "user://settings.cfg"
const FONT := preload("res://fonts/press_start_2p/PressStart2P-Regular.ttf")
const WorldCatalog := preload("res://scripts/world_catalog.gd")
const WORLDS_PER_PAGE := 4

var selected_world := "datacenter"
var endless_mode := false
var preferences_path := SETTINGS_PATH
var music_volume := 0.4
var effects_volume := 0.7
var music_muted := false
var effects_muted := false
var all_muted := false
var options_open := false
var start_menu: HBoxContainer
var modal: Control
var music_slider: HSlider
var options_button: Button
var worlds_open := false
var worlds_modal: Control
var worlds_button: Button
var world_buttons: Array[Button] = []
var world_previews: Array[TextureRect] = []
var world_titles: Array[Label] = []
var world_badges: Array[Label] = []
var world_page := 0
var world_page_label: Label
var world_selection_label: Label
var previous_worlds: Button
var next_worlds: Button
var mode_menu: HBoxContainer
var fixed_mode_button: Button
var endless_mode_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1100, 640)
	_load_preferences()
	_build_theme()
	_build_start_menu()
	_build_options()
	_build_worlds()


func _build_theme() -> void:
	theme = Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 12
	theme.set_color("font_color", "Label", Color("e4eefb"))
	for type in ["Button", "CheckButton"]:
		theme.set_stylebox("normal", type, _box(Color("16283c"), Color("37546f")))
		theme.set_stylebox("hover", type, _box(Color("203c55"), Color("70d7ff")))
		theme.set_stylebox("pressed", type, _box(Color("1c4359"), Color("70d7ff")))
		theme.set_stylebox("focus", type, _box(Color(0, 0, 0, 0), Color("ffffff")))
	theme.set_stylebox("slider", "HSlider", _box(Color("263f56"), Color("37546f")))
	theme.set_stylebox("grabber_area", "HSlider", _box(Color("54caff"), Color("54caff")))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _box(Color("9ae4ff"), Color("9ae4ff")))


func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_content_margin_all(12)
	return style


func _place(control: Control, parent: Node, at: Vector2, dimensions: Vector2) -> void:
	parent.add_child(control)
	control.position = at
	control.size = dimensions


func _label(text: String, parent: Node, at: Vector2, dimensions: Vector2, font_size: int = 12) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	_place(label, parent, at, dimensions)
	return label


func _button(text: String, parent: Node, at: Vector2, dimensions: Vector2, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	_place(button, parent, at, dimensions)
	button.pressed.connect(action)
	return button


func _build_start_menu() -> void:
	start_menu = HBoxContainer.new()
	start_menu.add_theme_constant_override("separation", 16)
	_place(start_menu, self, Vector2(184, 238), Vector2(732, 52))
	var play := _button("JUGAR", start_menu, Vector2.ZERO, Vector2.ZERO, func(): start_requested.emit())
	play.custom_minimum_size = Vector2(180, 52)
	worlds_button = _button("MONS", start_menu, Vector2.ZERO, Vector2.ZERO, open_worlds)
	worlds_button.custom_minimum_size = Vector2(200, 52)
	options_button = _button("SO", start_menu, Vector2.ZERO, Vector2.ZERO, open_options)
	options_button.custom_minimum_size = Vector2(320, 52)
	mode_menu = HBoxContainer.new()
	mode_menu.add_theme_constant_override("separation", 16)
	_place(mode_menu, self, Vector2(310, 178), Vector2(480, 42))
	fixed_mode_button = _button("MÓN FIX", mode_menu, Vector2.ZERO, Vector2.ZERO, set_endless.bind(false))
	fixed_mode_button.custom_minimum_size = Vector2(232, 42)
	fixed_mode_button.toggle_mode = true
	endless_mode_button = _button("SENSE FI", mode_menu, Vector2.ZERO, Vector2.ZERO, set_endless.bind(true))
	endless_mode_button.custom_minimum_size = Vector2(232, 42)
	endless_mode_button.toggle_mode = true
	_update_mode_buttons()


func set_endless(enabled: bool) -> void:
	endless_mode = enabled
	_update_mode_buttons()
	_commit()


func _update_mode_buttons() -> void:
	fixed_mode_button.set_pressed_no_signal(not endless_mode)
	endless_mode_button.set_pressed_no_signal(endless_mode)


func _build_worlds() -> void:
	worlds_modal = Control.new()
	_place(worlds_modal, self, Vector2.ZERO, Vector2(1100, 640))
	worlds_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.055, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(shade, worlds_modal, Vector2.ZERO, Vector2(1100, 640))
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", _box(Color("0d192a"), Color("54caff")))
	_place(panel, worlds_modal, Vector2(140, 52), Vector2(820, 536))
	_label("TRIA EL TEU MÓN", panel, Vector2(30, 24), Vector2(760, 32), 24)
	_label("Cada món, una nova cursa.", panel, Vector2(30, 68), Vector2(760, 20))
	for index in range(WORLDS_PER_PAGE):
		var at := Vector2(30 + (index % 2) * 380, 104 + floori(float(index) / 2) * 170)
		var card := _button("", panel, at, Vector2(360, 154), _select_world_slot.bind(index))
		card.toggle_mode = true
		card.add_theme_stylebox_override("disabled", _box(Color("111e30"), Color("2b3b51")))
		card.add_theme_stylebox_override("pressed", _box(Color("18354a"), Color("54caff")))
		world_buttons.append(card)
		var preview := TextureRect.new()
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(preview, card, Vector2(12, 12), Vector2(336, 82))
		world_previews.append(preview)
		world_titles.append(_label("", card, Vector2(14, 106), Vector2(332, 18)))
		var badge := _label("", card, Vector2(14, 132), Vector2(332, 16), 10)
		badge.modulate = Color("9ae4ff")
		world_badges.append(badge)
	previous_worlds = _button("←", panel, Vector2(30, 452), Vector2(56, 44), _change_world_page.bind(-1))
	world_page_label = _label("", panel, Vector2(94, 464), Vector2(96, 20))
	world_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_worlds = _button("→", panel, Vector2(196, 452), Vector2(56, 44), _change_world_page.bind(1))
	world_selection_label = _label("", panel, Vector2(30, 512), Vector2(760, 16), 10)
	_button("JUGAR", panel, Vector2(430, 452), Vector2(160, 44), func():
		close_worlds()
		start_requested.emit()
	)
	_button("TORNAR", panel, Vector2(606, 452), Vector2(184, 44), close_worlds)
	_update_world_cards()
	worlds_modal.hide()


func _select_world_slot(slot: int) -> void:
	var index := world_page * WORLDS_PER_PAGE + slot
	if index < WorldCatalog.WORLDS.size():
		select_world(WorldCatalog.WORLDS[index].id)


func _change_world_page(direction: int) -> void:
	var last_page := ceili(float(WorldCatalog.WORLDS.size()) / WORLDS_PER_PAGE) - 1
	world_page = clampi(world_page + direction, 0, last_page)
	_update_world_cards()
	world_buttons[0].grab_focus()
	audio_requested.emit()


func _update_world_cards() -> void:
	var pages := ceili(float(WorldCatalog.WORLDS.size()) / WORLDS_PER_PAGE)
	world_page_label.text = "%d / %d" % [world_page + 1, pages]
	previous_worlds.disabled = world_page == 0
	next_worlds.disabled = world_page == pages - 1
	world_selection_label.text = "MÓN: " + WorldCatalog.get_world(selected_world).title.to_upper()
	for slot in range(WORLDS_PER_PAGE):
		var index := world_page * WORLDS_PER_PAGE + slot
		world_buttons[slot].visible = index < WorldCatalog.WORLDS.size()
		if index >= WorldCatalog.WORLDS.size():
			continue
		var world: Dictionary = WorldCatalog.WORLDS[index]
		world_buttons[slot].disabled = not world.available
		world_buttons[slot].set_pressed_no_signal(world.id == selected_world)
		world_previews[slot].texture = world.get("background")
		world_titles[slot].text = "%02d / %s" % [index + 1, world.title.to_upper()]
		world_badges[slot].text = "SELECCIONAT" if world.id == selected_world else ("SELECCIONAR" if world.available else "PROPERAMENT")


func select_world(id: String) -> void:
	if not WorldCatalog.is_available(id):
		return
	selected_world = id
	_update_mode_buttons()
	_update_world_cards()
	_commit()


func open_worlds() -> void:
	worlds_open = true
	options_open = false
	modal.hide()
	start_menu.hide()
	mode_menu.hide()
	for index in range(WorldCatalog.WORLDS.size()):
		if WorldCatalog.WORLDS[index].id == selected_world:
			world_page = floori(float(index) / WORLDS_PER_PAGE)
	_update_world_cards()
	worlds_modal.show()
	for slot in range(world_buttons.size()):
		if world_buttons[slot].button_pressed:
			world_buttons[slot].grab_focus()
	audio_requested.emit()


func close_worlds() -> void:
	worlds_open = false
	worlds_modal.hide()
	start_menu.show()
	mode_menu.show()
	worlds_button.grab_focus()
	audio_requested.emit()


func is_modal_open() -> bool:
	return options_open or worlds_open


func _build_options() -> void:
	modal = Control.new()
	_place(modal, self, Vector2.ZERO, Vector2(1100, 640))
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.055, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(shade, modal, Vector2.ZERO, Vector2(1100, 640))
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", _box(Color("0d192a"), Color("54caff")))
	_place(panel, modal, Vector2(180, 134), Vector2(740, 372))
	_label("SO", panel, Vector2(30, 24), Vector2(680, 24), 24)
	_label("Ajusta la música i els efectes al teu gust.", panel, Vector2(30, 62), Vector2(680, 20))
	_audio_row(panel, "Música", 106, music_volume, music_muted, true)
	_audio_row(panel, "Efectes", 160, effects_volume, effects_muted, false)
	var mute_all := CheckButton.new()
	mute_all.text = "Silenciar-ho tot"
	mute_all.button_pressed = all_muted
	_place(mute_all, panel, Vector2(30, 218), Vector2(300, 42))
	mute_all.toggled.connect(func(enabled: bool):
		all_muted = enabled
		_commit()
	)
	_button("PROVAR EFECTES", panel, Vector2(350, 218), Vector2(360, 42), func(): audio_requested.emit())
	_button("TORNAR", panel, Vector2(490, 296), Vector2(220, 44), close_options)
	_label("Desament automàtic · Esc: tornar", panel, Vector2(30, 340), Vector2(450, 20), 10)
	modal.hide()


func _audio_row(parent: Control, title: String, y: float, value: float, muted: bool, is_music: bool) -> void:
	_label(title, parent, Vector2(30, y + 8), Vector2(112, 24))
	var slider := HSlider.new()
	if is_music:
		music_slider = slider
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = round(value * 100)
	slider.custom_minimum_size.y = 32
	_place(slider, parent, Vector2(150, y), Vector2(280, 36))
	var percent := _label("%d%%" % slider.value, parent, Vector2(448, y + 8), Vector2(64, 24))
	var mute := CheckButton.new()
	mute.text = "Silenciar"
	mute.button_pressed = muted
	_place(mute, parent, Vector2(534, y - 2), Vector2(176, 40))
	slider.value_changed.connect(func(volume: float):
		if is_music:
			music_volume = volume / 100.0
		else:
			effects_volume = volume / 100.0
		percent.text = "%d%%" % volume
		_commit(false)
	)
	mute.toggled.connect(func(enabled: bool):
		if is_music:
			music_muted = enabled
		else:
			effects_muted = enabled
		_commit()
	)
	if not is_music:
		slider.drag_ended.connect(func(_changed: bool): audio_requested.emit())


func open_options() -> void:
	options_open = true
	worlds_open = false
	worlds_modal.hide()
	start_menu.hide()
	mode_menu.hide()
	modal.show()
	music_slider.grab_focus()
	audio_requested.emit()


func close_options() -> void:
	options_open = false
	modal.hide()
	start_menu.show()
	mode_menu.show()
	options_button.grab_focus()
	audio_requested.emit()


func show_start_menu(visible_menu: bool) -> void:
	start_menu.visible = visible_menu
	mode_menu.visible = visible_menu
	if not visible_menu:
		options_open = false
		modal.hide()
		worlds_open = false
		worlds_modal.hide()
		get_viewport().gui_release_focus()


func _input(event: InputEvent) -> void:
	if is_modal_open() and event.is_action_pressed("ui_cancel"):
		if worlds_open:
			close_worlds()
		else:
			close_options()
		get_viewport().set_input_as_handled()


func _commit(play_preview: bool = true) -> void:
	var config := ConfigFile.new()
	config.set_value("world", "selected", selected_world)
	config.set_value("game", "endless", endless_mode)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "effects_volume", effects_volume)
	config.set_value("audio", "music_muted", music_muted)
	config.set_value("audio", "effects_muted", effects_muted)
	config.set_value("audio", "all_muted", all_muted)
	config.save(preferences_path)
	preferences_changed.emit()
	if play_preview:
		audio_requested.emit()


func _load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load(preferences_path) != OK:
		return
	selected_world = WorldCatalog.get_world(str(config.get_value("world", "selected", "datacenter"))).id
	endless_mode = bool(config.get_value("game", "endless", false))
	music_volume = clampf(float(config.get_value("audio", "music_volume", 0.4)), 0, 1)
	effects_volume = clampf(float(config.get_value("audio", "effects_volume", 0.7)), 0, 1)
	music_muted = bool(config.get_value("audio", "music_muted", false))
	effects_muted = bool(config.get_value("audio", "effects_muted", false))
	all_muted = bool(config.get_value("audio", "all_muted", false))
