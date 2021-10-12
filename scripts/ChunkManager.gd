extends Node

onready var _chunk_node = preload("res://scenes/Chunk.tscn")
onready var _player = get_tree().get_nodes_in_group("Player")[0]
onready var _debug_chunks = get_node("../Debug/Chunks")

var chunks = []
var chunk_positions_to_gen = []

func _gen_chunk(pos: Vector2):
	for chunk in chunks:
		if pos == chunk.pos:
			return
			
	var chunk = _chunk_node.instance()
	
	chunk.init(pos)
	chunks.append(chunk)
	add_child(chunk)
	
func _remove_outer_chunks(unload_at_max_render_dist = true):
	var indices_to_remove = []
	for i in range(chunks.size()):
		var chunk = chunks[i]
		var unload_dist = _player.render_distance
		if unload_at_max_render_dist:
			unload_dist = _player.max_render_distance
		var dist = floor((chunk.pos - _player.get_chunk_pos()).length())
		if dist > unload_dist:
			indices_to_remove.append(i)
	
	for i in range(indices_to_remove.size()):
		var index = indices_to_remove[i] - i
		var chunk = chunks[index]
		chunk.queue_free()
		chunks.remove(index)
			
func handle_chunks(async = true, slow = false):
	_remove_outer_chunks()
	
	var area = range(-_player.render_distance, _player.render_distance + 1)
	for x in area:
		for y in area:
			var relative_chunk_pos = Vector2(x, y)
			var chunk_pos = _player.get_chunk_pos() + relative_chunk_pos

			var dist = floor(relative_chunk_pos.length())
			if dist <= _player.render_distance:
				var wait = 0.001
				if slow:
					wait = 0.1
				_gen_chunk(chunk_pos)
				if async: yield(get_tree().create_timer(wait), "timeout")
