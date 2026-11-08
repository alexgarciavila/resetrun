extends RefCounted

const DEFINITIONS := [
	{"id": "jump_gate", "kind": "jump", "label": "↑ NOMÉS UN SALT", "texture": preload("res://images/obstacles/prepared/jump_gate.svg"), "height": 300.0},
	{"id": "power_crate", "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/power_crate.svg"), "height": 78.0},
	{"id": "computer", "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/computer.png"), "height": 72.0},
	{"id": "peripherals", "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/peripherals.png"), "height": 54.0},
	{"id": "laptops_router", "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/laptops_router.png"), "height": 60.0},
	{"id": "printer", "kind": "jump", "label": "↑ SALT", "texture": preload("res://images/obstacles/prepared/printer.png"), "height": 82.0},
	{"id": "tower", "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/tower.png"), "height": 220.0},
	{"id": "evil_ai_robot", "kind": "double_jump", "label": "↑↑ DOBLE SALT", "texture": preload("res://images/obstacles/prepared/evil_ai_robot.png"), "height": 220.0},
	{"id": "camera", "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/camera.png"), "height": 150.0, "clearance": 66.0, "sensor_ratio": 0.28},
	{"id": "cables", "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/cables.png"), "height": 130.0, "clearance": 66.0, "sensor_ratio": 0.64},
	{"id": "repair_gate", "kind": "slide", "label": "↓ LLISCA", "texture": preload("res://images/obstacles/prepared/repair_gate.png"), "height": 200.0, "clearance": 66.0, "sensor_ratio": 0.36},
]


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
	var texture: Texture2D = obstacle.texture
	var size := Vector2(texture.get_width() * float(obstacle.height) / texture.get_height(), obstacle.height)
	obstacle["x"] = x
	obstacle["draw_size"] = size
	obstacle["draw_y"] = -size.y
	if obstacle.kind == "slide":
		var sensor_width: float = size.x * obstacle.sensor_ratio
		# A visible scanning field reaches the ceiling: it cannot be jumped over.
		obstacle["hitbox"] = Rect2((size.x - sensor_width) * 0.5, -700.0, sensor_width, 700.0 - obstacle.clearance)
		if id == "cables":
			obstacle.draw_y -= obstacle.clearance
	elif obstacle.kind == "double_jump":
		obstacle["hitbox"] = Rect2(size.x * 0.14, -size.y + 4, size.x * 0.72, size.y - 4)
	else:
		obstacle["hitbox"] = Rect2(7, -size.y + 6, size.x - 14, size.y - 6)
	if id == "jump_gate":
		# Two solid laser regions leave a middle window for the normal jump arc.
		obstacle["hitbox"] = Rect2(30, -45, 40, 45)
		obstacle["upper_hitbox"] = Rect2(30, -700, 40, 450)
	return obstacle
