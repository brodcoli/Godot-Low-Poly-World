extends Node

#var Forest = preload("res://scripts/biomes/Forest.gd")
#var Plains = preload("res://scripts/biomes/Plains.gd")
#var Desert = preload("res://scripts/biomes/Desert.gd")
#var Ocean = preload("res://scripts/biomes/Ocean.gd")
#var Mountains = preload("res://scripts/biomes/Mountains.gd")
#var Tundra = preload("res://scripts/biomes/Tundra.gd")

var Forest = preload("res://scripts/biomes/Forest.tscn").instance()
var Plains = preload("res://scripts/biomes/Plains.tscn").instance()
var Desert = preload("res://scripts/biomes/Desert.tscn").instance()
var Ocean = preload("res://scripts/biomes/Ocean.tscn").instance()
var Mountains = preload("res://scripts/biomes/Mountains.tscn").instance()
var Tundra = preload("res://scripts/biomes/Tundra.tscn").instance()

var dict = {
	"MOUNTAINS": Mountains,
	"DESERT": Desert,
	"FOREST": Forest,
	"OCEAN": Ocean,
	"PLAINS": Plains,
	"TUNDRA": Tundra
}

func _ready():
	for biome in dict.values():
		add_child(biome)
		
	var s = "12345"
	s = s.insert(1, "a")
	s = s.insert(3, "b")
	
	
