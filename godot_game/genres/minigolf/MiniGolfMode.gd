extends Node2D

class_name MiniGolfMode

# Mini-Golf mode - Physics-based skill mini-games

# Golf ball and physics
var golf_ball: RigidBody2D
var ball_start_position: Vector2
var ball_in_hole: bool = false

# Course elements
var hole_position: Vector2
var obstacles: Array = []
var course_bounds: Rect2

# Golf mechanics
var shot_power: float = 0.0
var max_shot_power: float = 500.0
var is_aiming: bool = false
var aim_direction: Vector2
var shots_taken: int = 0
var par_score: int = 3

# Course state
enum GolfState {
	SETUP,
	AIMING,
	SHOOTING,
	BALL_MOVING,
	HOLE_COMPLETE,
	COURSE_COMPLETE
}

var current_state: GolfState = GolfState.SETUP
var current_hole: int = 1
var total_holes: int = 3
var total_shots: int = 0

# UI elements
var power_meter: ProgressBar
var score_display: Label
var instructions_label: Label

# Signals
signal hole_completed(shots: int, par: int)
signal course_completed(total_shots: int, total_par: int)

func _ready():
	print("Mini-Golf Mode initialized")
	setup_golf_ui()
	setup_golf_course()

func _process(delta):
	match current_state:
		GolfState.AIMING:
			handle_aiming()
		GolfState.BALL_MOVING:
			check_ball_movement()

func _input(event):
	if current_state == GolfState.AIMING:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					start_power_charge()
				else:
					shoot_ball()

func setup_golf_ui():
	# Create UI layer
	var ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# Power meter
	var power_container = VBoxContainer.new()
	power_container.position = Vector2(10, 10)
	ui_layer.add_child(power_container)
	
	var power_label = Label.new()
	power_label.text = "Shot Power"
	power_container.add_child(power_label)
	
	power_meter = ProgressBar.new()
	power_meter.max_value = 100
	power_meter.value = 0
	power_meter.custom_minimum_size = Vector2(200, 20)
	power_container.add_child(power_meter)
	
	# Score display
	score_display = Label.new()
	score_display.position = Vector2(10, 80)
	score_display.text = "Hole 1/3 - Shots: 0 - Par: 3"
	ui_layer.add_child(score_display)
	
	# Instructions
	instructions_label = Label.new()
	instructions_label.position = Vector2(10, 110)
	instructions_label.text = "Click and hold to aim and charge power. Release to shoot!"
	instructions_label.custom_minimum_size = Vector2(400, 50)
	ui_layer.add_child(instructions_label)
	
	# Exit button
	var exit_btn = Button.new()
	exit_btn.text = "Exit Mini-Golf"
	exit_btn.position = Vector2(10, 180)
	exit_btn.pressed.connect(_on_exit_pressed)
	ui_layer.add_child(exit_btn)

func setup_golf_course():
	course_bounds = Rect2(-400, -300, 800, 600)
	
	# Create course boundary
	create_course_boundary()
	
	# Set up first hole
	setup_hole(current_hole)

func setup_hole(hole_number: int):
	# Clear previous obstacles
	for obstacle in obstacles:
		if is_instance_valid(obstacle):
			obstacle.queue_free()
	obstacles.clear()
	
	match hole_number:
		1:
			setup_hole_1()
		2:
			setup_hole_2()
		3:
			setup_hole_3()
	
	# Create golf ball
	create_golf_ball()
	
	# Create hole
	create_hole()
	
	current_state = GolfState.AIMING
	ball_in_hole = false
	shots_taken = 0
	update_score_display()

func setup_hole_1():
	# Simple straight hole
	ball_start_position = Vector2(-300, 0)
	hole_position = Vector2(300, 0)
	par_score = 2
	
	# Add a simple obstacle
	create_obstacle(Vector2(0, -50), Vector2(100, 20))

func setup_hole_2():
	# L-shaped hole with corner
	ball_start_position = Vector2(-300, 200)
	hole_position = Vector2(200, -200)
	par_score = 3
	
	# Create walls for L-shape
	create_obstacle(Vector2(-100, 100), Vector2(20, 200))
	create_obstacle(Vector2(0, -100), Vector2(200, 20))

func setup_hole_3():
	# Complex hole with multiple obstacles
	ball_start_position = Vector2(-350, 0)
	hole_position = Vector2(350, 0)
	par_score = 4
	
	# Create obstacle course
	create_obstacle(Vector2(-150, -100), Vector2(50, 20))
	create_obstacle(Vector2(-150, 100), Vector2(50, 20))
	create_obstacle(Vector2(50, -150), Vector2(20, 50))
	create_obstacle(Vector2(50, 150), Vector2(20, 50))
	create_obstacle(Vector2(200, 0), Vector2(30, 30))

func create_course_boundary():
	# Create invisible walls around the course
	var boundary_thickness = 20
	
	# Top wall
	create_obstacle(Vector2(0, course_bounds.position.y - boundary_thickness/2), 
		Vector2(course_bounds.size.x, boundary_thickness))
	
	# Bottom wall
	create_obstacle(Vector2(0, course_bounds.position.y + course_bounds.size.y + boundary_thickness/2), 
		Vector2(course_bounds.size.x, boundary_thickness))
	
	# Left wall
	create_obstacle(Vector2(course_bounds.position.x - boundary_thickness/2, 0), 
		Vector2(boundary_thickness, course_bounds.size.y))
	
	# Right wall
	create_obstacle(Vector2(course_bounds.position.x + course_bounds.size.x + boundary_thickness/2, 0), 
		Vector2(boundary_thickness, course_bounds.size.y))

func create_obstacle(pos: Vector2, size: Vector2):
	var obstacle = StaticBody2D.new()
	obstacle.position = pos
	
	# Visual
	var sprite = Sprite2D.new()
	sprite.scale = size
	sprite.texture = PlaceholderTexture2D.new()
	sprite.modulate = Color(0.6, 0.4, 0.2)  # Brown color
	obstacle.add_child(sprite)
	
	# Collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	obstacle.add_child(collision)
	
	obstacles.append(obstacle)
	add_child(obstacle)

func create_golf_ball():
	if golf_ball and is_instance_valid(golf_ball):
		golf_ball.queue_free()
	
	golf_ball = RigidBody2D.new()
	golf_ball.position = ball_start_position
	golf_ball.gravity_scale = 0  # Top-down view, no gravity
	golf_ball.linear_damp = 2.0  # Ball slows down over time
	
	# Visual
	var sprite = Sprite2D.new()
	sprite.scale = Vector2(12, 12)
	sprite.texture = PlaceholderTexture2D.new()
	sprite.modulate = Color.WHITE
	golf_ball.add_child(sprite)
	
	# Collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 6
	collision.shape = shape
	golf_ball.add_child(collision)
	
	# Connect to detect when ball stops
	golf_ball.body_entered.connect(_on_ball_collision)
	
	add_child(golf_ball)

func create_hole():
	var hole = Area2D.new()
	hole.position = hole_position
	
	# Visual
	var sprite = Sprite2D.new()
	sprite.scale = Vector2(25, 25)
	sprite.texture = PlaceholderTexture2D.new()
	sprite.modulate = Color.BLACK
	hole.add_child(sprite)
	
	# Collision for detection
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12
	collision.shape = shape
	hole.add_child(collision)
	
	# Connect hole detection
	hole.body_entered.connect(_on_ball_entered_hole)
	
	add_child(hole)

func handle_aiming():
	if golf_ball and is_instance_valid(golf_ball):
		# Show aim direction from ball to mouse
		var mouse_pos = get_global_mouse_position()
		aim_direction = (mouse_pos - golf_ball.global_position).normalized()
		
		# Visual aim line could be drawn here
		queue_redraw()

func _draw():
	if current_state == GolfState.AIMING and golf_ball and is_instance_valid(golf_ball):
		# Draw aim line
		var start_pos = golf_ball.global_position - global_position
		var end_pos = start_pos + aim_direction * 100
		draw_line(start_pos, end_pos, Color.YELLOW, 3.0)

func start_power_charge():
	is_aiming = true
	# Start power charging animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_method(update_power_meter, 0.0, 100.0, 1.0)
	tween.tween_method(update_power_meter, 100.0, 0.0, 1.0)

func update_power_meter(value: float):
	if power_meter:
		power_meter.value = value
		shot_power = (value / 100.0) * max_shot_power

func shoot_ball():
	if not is_aiming or not golf_ball or not is_instance_valid(golf_ball):
		return
	
	is_aiming = false
	
	# Stop power charging
	get_tree().tween_kill_all()
	
	# Apply force to ball
	var force = aim_direction * shot_power
	golf_ball.apply_central_impulse(force)
	
	shots_taken += 1
	total_shots += 1
	current_state = GolfState.BALL_MOVING
	
	update_score_display()
	print("Shot fired! Power: ", shot_power, " Direction: ", aim_direction)

func check_ball_movement():
	if golf_ball and is_instance_valid(golf_ball):
		# Check if ball has stopped moving
		if golf_ball.linear_velocity.length() < 10.0:
			current_state = GolfState.AIMING
			print("Ball stopped. Ready for next shot.")

func _on_ball_entered_hole(body):
	if body == golf_ball:
		ball_in_hole = true
		print("Ball in hole! Shots taken: ", shots_taken)
		complete_hole()

func _on_ball_collision(body):
	# Handle ball collisions with obstacles
	print("Ball hit obstacle")

func complete_hole():
	current_state = GolfState.HOLE_COMPLETE
	
	# Calculate score
	var score_text = ""
	if shots_taken == 1:
		score_text = "HOLE IN ONE!"
	elif shots_taken <= par_score:
		score_text = "UNDER PAR!"
	elif shots_taken == par_score + 1:
		score_text = "BOGEY"
	else:
		score_text = "OVER PAR"
	
	instructions_label.text = score_text + " - " + str(shots_taken) + " shots on par " + str(par_score)
	hole_completed.emit(shots_taken, par_score)
	
	# Move to next hole after delay
	var tween = create_tween()
	tween.tween_delay(2.0)
	tween.tween_callback(next_hole)

func next_hole():
	current_hole += 1
	
	if current_hole > total_holes:
		complete_course()
	else:
		setup_hole(current_hole)

func complete_course():
	current_state = GolfState.COURSE_COMPLETE
	
	var total_par = 9  # Sum of all par scores
	var performance = ""
	
	if total_shots <= total_par - 3:
		performance = "EXCELLENT!"
	elif total_shots <= total_par:
		performance = "GOOD!"
	elif total_shots <= total_par + 3:
		performance = "AVERAGE"
	else:
		performance = "NEEDS PRACTICE"
	
	instructions_label.text = "COURSE COMPLETE! " + performance + " - Total shots: " + str(total_shots)
	
	# Reward player based on performance
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var xp_reward = max(20, 50 - (total_shots - total_par) * 5)
		var gold_reward = max(5, 20 - (total_shots - total_par) * 2)
		
		player.gain_experience(xp_reward)
		player.gold += gold_reward
		
		if total_shots <= total_par:
			player.karma += 3
	
	course_completed.emit(total_shots, total_par)
	
	# Auto-exit after showing results
	var tween = create_tween()
	tween.tween_delay(3.0)
	tween.tween_callback(exit_minigolf_mode)

func update_score_display():
	if score_display:
		score_display.text = "Hole " + str(current_hole) + "/" + str(total_holes) + " - Shots: " + str(shots_taken) + " - Par: " + str(par_score)

func _on_exit_pressed():
	exit_minigolf_mode()

func exit_minigolf_mode():
	print("Exiting Mini-Golf Mode")
	if GameManager.instance:
		GameManager.instance.change_game_state(GameManager.GameState.RPG)
	queue_free()