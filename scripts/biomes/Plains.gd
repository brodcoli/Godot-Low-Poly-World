extends Node

class_name Plains

onready var Materials = get_node("/root/Materials")
onready var Constants = get_node("/root/Constants")
onready var Base = get_node("/root/Base")

onready var big_oak_tree_node = preload("res://scenes/BigOakTree.tscn")

var rng = RandomNumberGenerator.new()
var bumps = OpenSimplexNoise.new()
var indents = OpenSimplexNoise.new()
var tree_noise = OpenSimplexNoise.new()
var ground_material: Material

func _ready():
	ground_material = Materials.YELLOW_GRASS
	
	rng.seed = Constants.SEED
	bumps.seed = Constants.SEED
	indents.seed = Constants.SEED
	tree_noise.seed = Constants.SEED

	bumps.period = 5
	bumps.persistence = 0.1
	bumps.octaves = 1

	indents.period = 50
	indents.persistence = 0.1
	indents.octaves = 1

func _tree_can_spawn(x: float, y: float):
	var v = rng.randf() * 100
	return v < 0.02
	
func populate_decorations(chunk):
	for ox in range(Constants.CHUNK_WIDTH):
		for oz in range(Constants.CHUNK_WIDTH):
			var x = ox * Constants.TRI_WIDTH
			var z = oz * Constants.TRI_WIDTH
			var height = Noise.get_terrain_noise(x + chunk.global_pos.x, z + chunk.global_pos.y)
			
			if height <= Constants.WATER_LEVEL:
				continue
			
			var tree_can_spawn = _tree_can_spawn(x + chunk.global_pos.x, z + chunk.global_pos.y)
			if tree_can_spawn:
				var rotation = rng.randf() * 2 * PI
				var tree = big_oak_tree_node.instance()
				tree.transform.origin = Vector3(x, height, z)
				tree.rotation = Vector3(0, rotation, 0)
				chunk.add_child(tree)

func get_noise(x: float, y: float):
	return (Base.get_noise(x, y)) \
	+ ((bumps.get_noise_2d(x + 50, y + 100) * 0.5)*0.6) \
	+ (indents.get_noise_2d(x + 50, y + 100) * 2)
