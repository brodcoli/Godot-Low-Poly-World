extends Node

class_name AudioNode

var rng = RandomNumberGenerator.new()

func _ready():
	rng.seed = OS.get_ticks_msec()

func rand(audio_dir: String):
	var sfx = Audio.get_node(audio_dir).get_children()
	return sfx[floor(rng.randf() * sfx.size())]
