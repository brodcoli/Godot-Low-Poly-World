extends StaticBody


var rng = RandomNumberGenerator.new()
var last_bird_sfx_time = 0
var next_wait_time = 0

func _ready():
	rng.seed = OS.get_ticks_msec()
	next_wait_time = rng.randf() * 40000 + 5000

func _process(delta: float):
	var now = OS.get_ticks_msec()
	if now - last_bird_sfx_time > next_wait_time:
		last_bird_sfx_time = now
		next_wait_time = rng.randf() * 40000 + 5000
		var sfx = Audio.rand("Ambience/Birds")
		sfx.global_transform.origin = self.global_transform.origin
		sfx.play()
