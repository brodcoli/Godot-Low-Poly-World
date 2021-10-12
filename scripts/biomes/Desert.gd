extends Node

class_name Desert

onready var Materials = get_node("/root/Materials")
onready var Constants = get_node("/root/Constants")
onready var Base = get_node("/root/Base")

onready var cactus_node = preload("res://scenes/Cactus.tscn")
onready var shrub_node = preload("res://scenes/Shrub.tscn")

var rng = RandomNumberGenerator.new()
var bumps = OpenSimplexNoise.new()
var indents = OpenSimplexNoise.new()
var cactus_noise = OpenSimplexNoise.new()
var ground_material: Material

func _ready():
	ground_material = Materials.SAND

	rng.seed = Constants.SEED
	bumps.seed = Constants.SEED
	indents.seed = Constants.SEED
	cactus_noise.seed = Constants.SEED

	bumps.period = 5
	bumps.persistence = 0.1
	bumps.octaves = 1

	indents.period = 50
	indents.persistence = 0.1
	indents.octaves = 1
	
	cactus_noise.period = 1
	cactus_noise.persistence = 0.5
	cactus_noise.octaves = 4

func _decor_can_spawn(x: float, y: float):
	#var noise = (cactus_noise.get_noise_2d(x, y) + 1) / 2
	var v = rng.randf() * 100
	return v < 0.2

func _get_decor():
	if rng.randf() < 0.75:
		return cactus_node.instance()
	else:
		return shrub_node.instance()

func populate_decorations(chunk):
	for ox in range(Constants.CHUNK_WIDTH):
		for oz in range(Constants.CHUNK_WIDTH):
			var x = ox * Constants.TRI_WIDTH
			var z = oz * Constants.TRI_WIDTH
			var height = Noise.get_terrain_noise(x + chunk.global_pos.x, z + chunk.global_pos.y)
			
			if height <= Constants.WATER_LEVEL:
				continue
				
			var decor_can_spawn = _decor_can_spawn(x + chunk.global_pos.x, z + chunk.global_pos.y)
			if decor_can_spawn:
				var rotation = rng.randf() * 2 * PI
				var decor = _get_decor()
				decor.transform.origin = Vector3(x, height, z)
				decor.rotation = Vector3(0, rotation, 0)
				chunk.add_child(decor)

func get_noise(x: float, y: float):
	return Base.get_noise(x, y) \
	+ ((bumps.get_noise_2d(x + 50, y + 100) * 0.5)*0.6) \
	+ (indents.get_noise_2d(x + 50, y + 100) * 1)
