extends RefCounted

const DEFINITIONS := [
	{"worlds": ["taller", "taller2"], "id": "peripherals", "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/taller/peripherals.png"), "height": 54.0},
	{"worlds": ["oficina"], "id": "printer", "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/oficina/printer.png"), "height": 82.0},
	{"worlds": ["datacenter"], "id": "evil_ai_robot", "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/datacenter/evil_ai_robot.png"), "height": 220.0},
	{"id": "datacenter_server_rack", "worlds": ["datacenter"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/datacenter/server_rack.png"), "height": 180.0},
	{"id": "datacenter_boxes", "worlds": ["datacenter"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/datacenter/boxes.png"), "height": 180.0},
	{"id": "datacenter_ups", "worlds": ["datacenter"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/datacenter/ups.png"), "height": 180.0},
	{"id": "datacenter_network_switch", "worlds": ["datacenter"], "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/datacenter/network_switch.png"), "height": 72.0, "clearance": 66.0, "sensor_ratio": 0.72},
	{"id": "datacenter_firewall", "worlds": ["datacenter"], "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/datacenter/firewall.png"), "height": 72.0},
	{"id": "datacenter_rack_servers", "worlds": ["datacenter"], "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/datacenter/rack_servers.png"), "height": 72.0, "clearance": 66.0, "sensor_ratio": 0.72},
	{"id": "botiga_keyboard", "worlds": ["botiga"], "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/botiga/keyboard.png"), "height": 100.0, "clearance": 66.0, "sensor_ratio": 0.72},
	{"id": "botiga_mouse", "worlds": ["botiga"], "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/botiga/mouse.png"), "height": 72.0},
	{"id": "botiga_headphones", "worlds": ["botiga"], "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/botiga/headphones.png"), "height": 100.0, "clearance": 66.0, "sensor_ratio": 0.72},
	{"id": "botiga_monitor", "worlds": ["botiga"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/botiga/monitor.png"), "height": 180.0},
	{"id": "botiga_laptop", "worlds": ["botiga"], "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/botiga/laptop.png"), "height": 72.0},
	{"id": "botiga_gaming_display", "worlds": ["botiga"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/botiga/gaming_display.png"), "height": 180.0},
	{"id": "magatzem_laptop_stack", "worlds": ["magatzem", "magatzem2"], "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/magatzem/laptop_stack.png"), "height": 100.0, "clearance": 66.0, "sensor_ratio": 0.72},
	{"id": "magatzem_pallet", "worlds": ["magatzem", "magatzem2"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/magatzem/pallet.png"), "height": 180.0},
	{"id": "magatzem_patch_panel", "worlds": ["magatzem", "magatzem2"], "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/magatzem/patch_panel.png"), "height": 110.0, "clearance": 66.0, "sensor_ratio": 0.72},
	{"id": "magatzem_ups", "worlds": ["magatzem", "magatzem2"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/magatzem/ups.png"), "height": 180.0},
	{"id": "magatzem_label_printer", "worlds": ["magatzem", "magatzem2"], "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/magatzem/label_printer.png"), "height": 72.0},
	{"id": "magatzem_deployment_cart", "worlds": ["magatzem", "magatzem2"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/magatzem/deployment_cart.png"), "height": 180.0},
	{"id": "oficina_copier", "worlds": ["oficina"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/oficina/copier.png"), "height": 180.0},
	{"id": "oficina_laptop_dock", "worlds": ["oficina"], "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/oficina/laptop_dock.png"), "height": 100.0, "clearance": 66.0, "sensor_ratio": 0.72},
	{"id": "oficina_router", "worlds": ["oficina"], "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/oficina/router.png"), "height": 110.0, "clearance": 66.0, "sensor_ratio": 0.72},
	{"id": "oficina_phone", "worlds": ["oficina"], "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/oficina/phone.png"), "height": 72.0},
	{"id": "oficina_server", "worlds": ["oficina"], "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/oficina/server.png"), "height": 72.0},
	{"id": "oficina_shredder", "worlds": ["oficina"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/oficina/shredder.png"), "height": 180.0},
	{"id": "taller_open_pc", "worlds": ["taller", "taller2"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/taller/open_pc.png"), "height": 180.0},
	{"id": "taller_motherboard", "worlds": ["taller", "taller2"], "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/taller/motherboard.png"), "height": 100.0, "clearance": 66.0, "sensor_ratio": 0.72},
	{"id": "taller_tool_case", "worlds": ["taller", "taller2"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/taller/tool_case.png"), "height": 180.0},
	{"id": "taller_soldering_station", "worlds": ["taller", "taller2"], "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/taller/soldering_station.png"), "height": 72.0},
	{"id": "taller_fan", "worlds": ["taller", "taller2"], "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/taller/fan.png"), "height": 110.0, "clearance": 66.0, "sensor_ratio": 0.72},
	{"id": "taller_power_cables", "worlds": ["taller", "taller2"], "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/taller/power_cables.png"), "height": 72.0},
	{"id": "vendrell_bench", "worlds": ["vendrell"], "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/vendrell/bench.png"), "height": 100.0, "clearance": 66.0, "sensor_ratio": 0.72},
	{"id": "vendrell_streetlamp", "worlds": ["vendrell"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/vendrell/streetlamp.png"), "height": 180.0},
	{"id": "vendrell_planter", "worlds": ["vendrell"], "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/vendrell/planter.png"), "height": 100.0, "clearance": 66.0, "sensor_ratio": 0.72},
	{"id": "vendrell_cafe_table", "worlds": ["vendrell"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/vendrell/cafe_table.png"), "height": 180.0},
	{"id": "vendrell_bollard", "worlds": ["vendrell"], "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/vendrell/bollard.png"), "height": 180.0},
	{"id": "vendrell_parcel", "worlds": ["vendrell"], "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/vendrell/parcel.png"), "height": 72.0},
	{"id": "datacenter_middle_passage", "worlds": ["datacenter"], "kind": "jump", "label": "↑ NOMÉS UN SALT", "floor_id": "datacenter_firewall", "ceiling_id": "datacenter_rack_servers"},
	{"id": "botiga_middle_passage", "worlds": ["botiga"], "kind": "jump", "label": "↑ NOMÉS UN SALT", "floor_id": "botiga_laptop", "ceiling_id": "botiga_keyboard"},
	{"id": "magatzem_middle_passage", "worlds": ["magatzem", "magatzem2"], "kind": "jump", "label": "↑ NOMÉS UN SALT", "floor_id": "magatzem_label_printer", "ceiling_id": "magatzem_patch_panel"},
	{"id": "oficina_middle_passage", "worlds": ["oficina"], "kind": "jump", "label": "↑ NOMÉS UN SALT", "floor_id": "oficina_phone", "ceiling_id": "oficina_router"},
	{"id": "taller_middle_passage", "worlds": ["taller", "taller2"], "kind": "jump", "label": "↑ NOMÉS UN SALT", "floor_id": "taller_power_cables", "ceiling_id": "taller_fan"},
	{"id": "vendrell_middle_passage", "worlds": ["vendrell"], "kind": "jump", "label": "↑ NOMÉS UN SALT", "floor_id": "vendrell_parcel", "ceiling_id": "vendrell_bench"},
]


static func ids_for_world(world_id: String) -> Array[String]:
	var result: Array[String] = []
	for definition in DEFINITIONS:
		if world_id in definition.worlds:
			result.append(definition.id)
	return result


static func ids_for_kind(kind: String) -> Array[String]:
	var result: Array[String] = []
	for definition in DEFINITIONS:
		if definition.kind == kind:
			result.append(definition.id)
	return result


static func create(id: String, x: float) -> Dictionary:
	var definition: Dictionary = DEFINITIONS[0]
	for candidate in DEFINITIONS:
		if candidate.id == id:
			definition = candidate
			break
	var obstacle := definition.duplicate()
	if obstacle.has("floor_id"):
		var floor_piece := create(obstacle.floor_id, x)
		obstacle["texture"] = floor_piece.texture
		obstacle["height"] = 45.0
	var texture: Texture2D = obstacle.texture
	var size := Vector2(texture.get_width() * float(obstacle.height) / texture.get_height(), obstacle.height)
	obstacle["x"] = x
	obstacle["draw_size"] = size
	obstacle["draw_y"] = -size.y
	if obstacle.kind == "slide":
		var sensor_width: float = size.x * obstacle.sensor_ratio
		# The hanging device and its supporting cables require sliding underneath.
		obstacle["hitbox"] = Rect2((size.x - sensor_width) * 0.5, -700.0, sensor_width, 700.0 - obstacle.clearance)
		obstacle.draw_y -= obstacle.clearance
	elif obstacle.kind == "double_jump":
		obstacle["hitbox"] = Rect2(size.x * 0.14, -size.y + 4, size.x * 0.72, size.y - 4)
	else:
		obstacle["hitbox"] = Rect2(7, -size.y + 6, size.x - 14, size.y - 6)
	if obstacle.has("ceiling_id"):
		var ceiling := create(obstacle.ceiling_id, x)
		var ceiling_texture: Texture2D = ceiling.texture
		var ceiling_height := 90.0
		var ceiling_width := ceiling_texture.get_width() * ceiling_height / ceiling_texture.get_height()
		# Keep the whole passage readable without stretching either supplied sprite.
		if ceiling_width > 140.0:
			ceiling_height *= 140.0 / ceiling_width
			ceiling_width = 140.0
		var offset := (size.x - ceiling_width) * 0.5
		var column_width := minf(size.x - 14.0, 65.0)
		var column_x := (size.x - column_width) * 0.5
		obstacle["hitbox"] = Rect2(column_x, -45.0, column_width, 45.0)
		obstacle["upper_hitbox"] = Rect2(column_x, -700.0, column_width, 450.0)
		ceiling["kind"] = "slide"
		ceiling["draw_size"] = Vector2(ceiling_width, ceiling_height)
		ceiling["draw_y"] = -250.0 - ceiling_height
		ceiling["hitbox"] = Rect2(column_x - offset, -700.0, column_width, 450.0)
		ceiling["hide_label"] = true
		obstacle["ceiling"] = ceiling
		obstacle["ceiling_offset"] = offset
	return obstacle
