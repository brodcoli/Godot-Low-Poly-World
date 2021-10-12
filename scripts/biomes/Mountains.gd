extends Node

class_name Mountains

onready var Materials = get_node("/root/Materials")
onready var Constants = get_node("/root/Constants")
onready var Base = get_node("/root/Base")

var bumps = OpenSimplexNoise.new()
var indents = OpenSimplexNoise.new()
var hills = OpenSimplexNoise.new()
var mountains = OpenSimplexNoise.new()
var mountains2 = OpenSimplexNoise.new()
var ground_material: Material

func _ready():
	ground_material = Materials.ROCK
	
	bumps.seed = Constants.SEED
	indents.seed = Constants.SEED
	hills.seed = Constants.SEED
	mountains.seed = Constants.SEED
	mountains2.seed = Constants.SEED

	bumps.period = 5
	bumps.persistence = 0.1
	bumps.octaves = 1

	indents.period = 50
	indents.persistence = 0.1
	indents.octaves = 1

	hills.period = 500
	hills.persistence = 1
	hills.octaves = 3
	
	mountains.period = 1000
	mountains.persistence = 1
	mountains.octaves = 3
	
	mountains2.period = 300
	mountains2.persistence = 0.5
	mountains2.octaves = 3
	
func get_noise(x: float, y: float):
	return (Base.get_noise(x, y)) \
	+ ((bumps.get_noise_2d(x + 50, y + 100) * 0.5)*0.6) \
	+ (indents.get_noise_2d(x + 50, y + 100) * 2) \
	+ hills.get_noise_2d(x, y) * 75 \
	+ lerp(-0.5, 1, (mountains.get_noise_2d(x, y) + 1) / 2) * 300 \
	#+ (mountains2.get_noise_2d(x, y) + 1) / 2 * 100
