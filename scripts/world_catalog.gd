extends RefCounted
## World-specific scenery and hazards. Only available entries can be selected.

const WORLDS := [
	{
		"id": "datacenter",
		"title": "Centre de dades",
		"available": true,
		"background": preload("res://images/background/datacenter.png"),
		# Run down the middle of the walkway, rather than along its rear edge.
		"walkway_ratio": 0.62,
	},
	{
		"id": "botiga", "title": "Botiga", "available": true,
		"background": preload("res://images/background/botiga.png"),
		"walkway_ratio": 0.78,
	},
	{
		"id": "magatzem", "title": "Magatzem", "available": true,
		"background": preload("res://images/background/magatzem.png"),
		"walkway_ratio": 0.71,
	},
	{
		"id": "magatzem2", "title": "Magatzem 2", "available": true,
		"background": preload("res://images/background/magatzem2.png"),
		"background_height": 480.0,
		"walkway_ratio": 0.91,
	},
	{
		"id": "oficina", "title": "Oficina", "available": true,
		"background": preload("res://images/background/oficina.png"),
		"walkway_ratio": 0.72,
	},
	{
		"id": "taller", "title": "Taller", "available": true,
		"background": preload("res://images/background/taller.png"),
		"background_height": 480.0,
		"walkway_ratio": 0.91,
	},
	{
		"id": "taller2", "title": "Taller 2", "available": true,
		"background": preload("res://images/background/taller2.png"),
		"background_height": 480.0,
		"walkway_ratio": 0.94,
	},
	{
		"id": "vendrell", "title": "El Vendrell", "available": true,
		"background": preload("res://images/background/vendrell.png"),
		"walkway_ratio": 0.75,
	},
]

const DEFAULTS := {
	"background_height": 640.0,
}


static func is_available(id: String) -> bool:
	for world in WORLDS:
		if world.id == id:
			return world.available
	return false


static func get_world(id: String) -> Dictionary:
	for world in WORLDS:
		if world.id == id and world.available:
			return DEFAULTS.merged(world, true)
	return DEFAULTS.merged(WORLDS[0], true)
