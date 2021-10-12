extends Node

class_name Tundra

onready var Materials = get_node("/root/Materials")
onready var Constants = get_node("/root/Constants")
onready var Base = get_node("/root/Base")

var rng = RandomNumberGenerator.new()
onready var rock_node = preload("res://scenes/Rock.tscn")
	
var rock_noise = OpenSimplexNoise.new()
var ground_material: Material
	
func _ready():
	ground_material = Materials.SNOW
	
	rng.seed = Constants.SEED
	rock_noise.seed = Constants.SEED
	rock_noise.period = 1
	rock_noise.persistence = 1
	rock_noise.octaves = 4
	
func _rock_can_spawn(x: float, y: float):
	var noise = (rock_noise.get_noise_2d(x, y) + 1) / 2
	return noise > 0.75
	
func populate_decorations(chunk):
	for ox in range(Constants.CHUNK_WIDTH):
		for oz in range(Constants.CHUNK_WIDTH):
			var x = ox * Constants.TRI_WIDTH
			var z = oz * Constants.TRI_WIDTH
			var height = Noise.get_terrain_noise(x + chunk.global_pos.x, z + chunk.global_pos.y)
			
			if height <= -7:
				continue
				
			var rock_can_spawn = _rock_can_spawn(x + chunk.global_pos.x, z + chunk.global_pos.y)
			if rock_can_spawn:
				var rotation = rng.randf() * 2 * PI
				var rock = rock_node.instance()
				rock.transform.origin = Vector3(x, height, z)
				rock.rotation = Vector3(0, rotation, 0)
				chunk.add_child(rock)
	
func get_noise(x: float, y: float):
	return Base.get_noise(x, y) + 10
