extends Node

class_name Ocean

onready var Materials = get_node("/root/Materials")
onready var Constants = get_node("/root/Constants")
onready var Base = get_node("/root/Base")

var bumps = OpenSimplexNoise.new()
var ground_material: Material

func _ready():
	ground_material = Materials.BEACH_SAND
	
	bumps.seed = Constants.SEED
	
	bumps.period = 50
	bumps.persistence = 0.1
	bumps.octaves = 1
	
func get_noise(x: float, y: float):
	return (bumps.get_noise_2d(x, y) * 5) - 20
