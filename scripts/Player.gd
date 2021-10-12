extends KinematicBody

# Important nodes and scenes to be used later
onready var head = $Head
onready var _head_mesh = $Head/Mesh
onready var _body_mesh = $BodyMesh
onready var _camera = $Head/Camera
onready var _birds_eye_view_camera = $Head/BirdsEyeViewCamera
onready var _cursor = $Center/Control/Cursor
onready var _options = $"../Options"
onready var _world = $".."
onready var Noise = $"/root/Noise"
onready var _debug_label = $"../Debug/Label"
onready var _nos_label = $"../Debug/Nos"
onready var _Ball = preload("res://scenes/Ball.tscn")

# Player properties (feel free to change any of these)
const mouse_sensitivity = 0.3
const walk_speed = 6
const swim_speed = 3
const sprint_speed = 12
const nos_speed = 50
const move_dist_until_step = 3.1
const max_render_distance = 5

# Variables to be used later
var zoomed = false
var render_distance = max_render_distance
var last_render_distance = max_render_distance
var last_chunk_pos = Vector2.ZERO
var paused = false
var wind_noise = OpenSimplexNoise.new()
var rng = RandomNumberGenerator.new()
var speed = walk_speed
var fall_mode = false
var birds_eye_mode = false
var load_chunks_when_player_slows = false
var last_h_pos: Vector2
var move_dist = 0
var last_step_sfx_name = ""

var mouse_captured = false
var mouse_speed = 1

# Get the coordinate of the current chunk the player is in
func get_chunk_pos():
	return (Vector2(translation.x, translation.z) / Constants.TOTAL_CHUNK_WIDTH).floor()

# Play random step sound in specified directory
func _play_step_sfx(audio_dir: String):
	var sfx = Audio.get_node(audio_dir).get_children()
	while true:
		var s = sfx[floor(rng.randf() * sfx.size())]
		# will not play the same step sound twice in a row
		if not last_step_sfx_name == s.name:
			last_step_sfx_name = s.name
			s.play()
			break

# Ready function
func _ready():
	# Initialize chunks, but synchronously
	Chunk_Manager.handle_chunks(false)
	
	# Initialize procedural wind noise
	Audio.get_node("Misc/Wind").play()
	Audio.get_node("Misc/Wind").volume_db = -999
	wind_noise.seed = OS.get_ticks_msec()
	wind_noise.octaves = 2
	wind_noise.persistence = 0.5

# Physics process function
func _physics_process(delta: float):
	# Useful variables for later
	var translation = self.translation
	var head_underwater = head.global_transform.origin.y < -7
	var body_underwater = translation.y < -7
	var head_dist_underwater = -7 - head.global_transform.origin.y
	
	# Get inputs for later
	var forward = Input.is_action_pressed("move_forward")
	var backward = Input.is_action_pressed("move_backward")
	var left = Input.is_action_pressed("move_left")
	var right = Input.is_action_pressed("move_right")
	var sprint = Input.is_action_pressed("sprint")
	var nos = Input.is_action_pressed("nos")
	var just_paused = Input.is_action_just_pressed("pause")
	var jump = Input.is_action_just_pressed("jump")
	var just_used = Input.is_action_just_pressed("use")
	var zoom = Input.is_action_just_released("zoom")
	var un_zoom = Input.is_action_just_released("un_zoom")
	var just_birds_eye_view = Input.is_action_just_pressed("birds_eye_view")
	var speed_up_time = Input.is_action_pressed("speed_up_time")
	var just_toggled_fullscreen = Input.is_action_just_pressed("toggle_fullscreen")
	
	# If player presses fullscreen key
	if just_toggled_fullscreen:
		OS.window_fullscreen = !OS.window_fullscreen
		
	# If player presses birds-eye-view key
	if just_birds_eye_view:
		birds_eye_mode = not birds_eye_mode
		if birds_eye_mode:
			_birds_eye_view_camera.current = true
			_cursor.visible = false
			_head_mesh.visible = true
		else:
			_camera.current = true
			_cursor.visible = true
			_head_mesh.visible = false
		
	# If player presses the use key spawn ball above player
	if just_used:
		var ball = _Ball.instance()
		var pos = translation + Vector3.UP * 5
		ball.translation = pos
		get_tree().root.add_child(ball)
	
	# Hide the nos debug text in top left corner of screen
	_nos_label.visible = false
	
	# If player is pressing the nos key
	if nos:
		speed = nos_speed
		_nos_label.visible = true
	elif body_underwater:
		speed = swim_speed
	elif sprint:
		speed = sprint_speed
	else:
		speed = walk_speed
		
	# If player zooms in or out
	if zoom:
		zoomed = true
	elif un_zoom:
		zoomed = false
		
	# If player is zoomed in or not
	if zoomed:
		_camera.fov = 10
		mouse_speed = 0.35
	else:
		_camera.fov = 70
		mouse_speed = 1
	
	# If player presses the pause key
	if just_paused:
		paused = not paused
		_options.get_child(0).visible = paused
		if not paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_captured = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_captured = false
	
	# Calculate the player's movement based on inputs
	var input_motion = Vector3(int(forward) - int(backward), 0, int(right) - int(left)) * speed
	input_motion = input_motion.rotated(Vector3(0, 1, 0), head.rotation.y + PI / 2)
	
	# Enable the low-pass filter on the Master audio bus (all audio) if the player's head is underwater
	AudioServer.set_bus_effect_enabled(0, 0, head_underwater)
	
	# Enable the low-pass filter on the Step audio bus (only step sounds) if the player's body is underwater
	AudioServer.set_bus_effect_enabled(2, 0, body_underwater)
	
	# Get horizontal velocity and position
	var h_vel = Vector2(input_motion.x, input_motion.z)
	var h_pos = Vector2(translation.x, translation.z)
	
	# Add distance player has moved in the last physics frame to move_dist
	move_dist += (last_h_pos - h_pos).length()
	
	# Record current horizontal position to calculate the move distance next physics frame
	last_h_pos = h_pos
	
	# If total move distance is enough, reset the move distance
	# and play a step sound based on what biome the player is in
	if move_dist > move_dist_until_step:
		move_dist = 0
		var biome = Noise.get_biome(translation.x, translation.z)
		var step_mat = Biomes.dict[biome].ground_material
		if step_mat == Materials.GRASS or step_mat == Materials.YELLOW_GRASS:
			_play_step_sfx("Steps/Grass")
		elif step_mat == Materials.ROCK:
			_play_step_sfx("Steps/Rock")
		elif step_mat == Materials.SAND or step_mat == Materials.BEACH_SAND:
			_play_step_sfx("Steps/Sand")
	
	# Using open simplex noise, modulate the volume and cutoff of
	# the low-pass filter of the Wind audio bus
	var n = wind_noise.get_noise_1d(OS.get_ticks_msec() / 100)
	var wind_db = ((n * 5) - 15)
	if head_underwater:
		wind_db = head_dist_underwater * -5 - 15
	Audio.get_node("Misc/Wind").volume_db = wind_db
	AudioServer.get_bus_effect(1, 0).cutoff_hz = (n * 1500) + 1000 - rng.randf() * 100
	
	# Get player's horizontal speed from the horizontal velocity
	var h_speed = floor(h_vel.length())
	
	# Set and lower the render distance depending on how fast the player is moving
	var render_distance_mult = 1
	if h_speed >= 100:
		render_distance_mult = 0.25
	elif h_speed >= 50:
		render_distance_mult = 0.5
	elif h_speed >= 25:
		render_distance_mult = 0.75
	render_distance = max(floor(max_render_distance * render_distance_mult), 3)
	
	# If the player was going very fast the render distance will go down
	# If the player suddenly stops moving after travelling fast, the
	# render distance will go back up but the amount of chunks around the
	# player will be still small. To tell the game to render more chunks without
	# it waiting for the player to move, load_chunks_when_player_slows is
	# set to true for later
	if render_distance > last_render_distance:
		load_chunks_when_player_slows = true
	
	# If player moves to another chunk, start
	# generating more chunks
	if not get_chunk_pos() == last_chunk_pos:
		last_chunk_pos = get_chunk_pos()
		Chunk_Manager.handle_chunks()
	# If player is not moving across any chunks but
	# load_chunks_when_player_slows is true, load chunks
	# anyway
	elif load_chunks_when_player_slows and h_speed < 3:
		load_chunks_when_player_slows = false
		last_chunk_pos = get_chunk_pos()
		Chunk_Manager.handle_chunks(true, true)
		
	# Record current render distance to be used next physics frame
	last_render_distance = render_distance
	
	# Move the player based on input motion
	move_and_slide(Vector3(input_motion.x, 0, input_motion.z))
	move_and_collide(Vector3(0, input_motion.y - 5, 0))
	
	# Debug info stuff in the top left corner of screen
	var pos = str(floor(self.translation.x)) + ", " + str(floor(self.translation.y)) + ", " + str(floor(self.translation.z))
	var weights = Noise.get_biome_weights(translation.x, translation.z)
	var weights_text = ""
	for biome in weights:
		var weight = weights[biome]
		weights_text += biome + " " + str(weight) + "\n"
	var biome = Noise.get_biome(translation.x, translation.z)
	
	_debug_label.text = "FPS = " + str(Engine.get_frames_per_second()) + \
						" \nPOS = " + pos + \
						" \nBIOME = " + biome + \
						" \nRENDER = " + str(render_distance) + "/" + str(max_render_distance) + \
						" \nSPEED = " + str(h_speed)# + \
						#" \nTIME = " + str(floor(_world.time * 100) / 100) + " (" + time_hour + ":" + time_minute + ")" + \
						#" \nDAY = " + str(floor(_world.prox_to_day * 1000) / 1000)
						#" \nWEIGHTS = " + weights_text
	
	
# Input function
func _input(event: InputEvent):
	# When the player clicks the game window for the first time, the mouse will be captured
	if event is InputEventMouseButton:
		if not paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_captured = true
	
	# Rotate player's head when moving mouse
	elif event is InputEventMouseMotion:
		if mouse_captured:
			var mouse_motion = event.relative * mouse_sensitivity
			var motion = Vector2(deg2rad(mouse_motion.x), deg2rad(mouse_motion.y)) * -1
			motion *= mouse_speed
			
			var x_axis = _camera.get_camera_transform().basis[0]
			
			head.rotate_y(motion.x)
			
			var d = abs(motion.y + head.rotation.x) < PI / 2
			if d:
				head.rotate(x_axis, motion.y)
				
			head.rotation.z = 0
		
		
		
		
		
		
		
		
		
		
		
		
		
		
