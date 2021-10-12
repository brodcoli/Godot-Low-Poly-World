extends Node

onready var Constants = get_node("/root/Constants")
var noise = OpenSimplexNoise.new()

func _ready():
	noise.seed = Constants.SEED
	noise.period = 500#100
	noise.persistence = 0.2
	noise.octaves = 6
	
func get_noise(x: float, y: float):
	#return noise.get_noise_2d(x, y) * 30 + 20
	return noise.get_noise_2d(x, y) * 30 + 20
