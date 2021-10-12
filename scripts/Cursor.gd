extends Sprite

const size = 3

func _draw():
	draw_line((Vector2(0, -1) * size), (Vector2(0, 1) * size), Color.white, 1)
	draw_line((Vector2(-1, 0) * size), (Vector2(1, 0) * size), Color.white, 1)
