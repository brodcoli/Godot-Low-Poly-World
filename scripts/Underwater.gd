extends Sprite

onready var _player = get_node("..")

func _process(delta: float):
	var screen = OS.window_size
	visible = _player.head.global_transform.origin.y <= -6.97
	scale = screen
