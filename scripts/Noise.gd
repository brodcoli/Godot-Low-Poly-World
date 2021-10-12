extends Node

onready var Constants = get_node("/root/Constants")
onready var Biomes = get_node("/root/Biomes")

const biome_merge = 10 #10 50 #5 #higher value = more sudden biome terrain changes
const biome_size = 2000 #decreasing the biome size also makes the biomes merge more suddenly

var biome_noise = OpenSimplexNoise.new()

func _init_biome_noise():
	biome_noise.seed = Constants.SEED
	biome_noise.period = biome_size
	biome_noise.persistence = 0.5 #0.5
	biome_noise.octaves = 8 #3
	
func _get_biome_noise(x: float, y: float):
	var m = 0.5
	var s = 0.2
	
	var v = (biome_noise.get_noise_2d(x, y) + 1) / 2
	v = (v - m) / s
	v = 1 / (exp(-(358 * v)/23 + 111 * atan(37 * v / 294)) + 1)
	
	return v

func _ready():
	_init_biome_noise()

func get_biome_weights(x: float, y: float):
	var value = _get_biome_noise(x, y)
	
	var biome_count = Biomes.dict.values().size()
	var i = 0
	var weights = {}
	for biome in Biomes.dict:
		weights[biome] = pow(1 - abs(value - float(i) / (biome_count - 1)), biome_merge)
		i += 1
	
	var total = 0
	for weight in weights.values():
		total += weight
	
	for biome in Biomes.dict:
		weights[biome] = weights[biome] / total
		
	return weights
	
func get_biome(x: float, y: float):
	var weights = get_biome_weights(x, y)
	
	var biome_with_largest_weight = Biomes.dict.keys()[0]
	for biome in weights:
		var weight = weights[biome]
		
		if weight > weights[biome_with_largest_weight]:
			biome_with_largest_weight = biome
			
	return biome_with_largest_weight

func get_terrain_noise(x: float, y: float):
	var weights = get_biome_weights(x, y)
	var noise = 0
	for biome in Biomes.dict:
		noise += Biomes.dict[biome].get_noise(x, y) * weights[biome]
	return noise

		   
		   
