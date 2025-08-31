extends Node2D

class_name PuzzleMode

# Puzzle mode - Logic puzzles that gate access or rewards

# Puzzle types
enum PuzzleType {
	TILE_ROTATION,
	MATCH_THREE,
	MAZE_SOLVING,
	SEQUENCE_MEMORY,
	COLOR_PATTERN
}

# Puzzle state
enum PuzzleState {
	SETUP,
	PLAYING,
	COMPLETED,
	FAILED
}

var current_puzzle_type: PuzzleType
var current_state: PuzzleState = PuzzleState.SETUP
var puzzle_timer: float = 0.0
var max_puzzle_time: float = 180.0  # 3 minutes max
var attempts_left: int = 3

# Puzzle data
var puzzle_grid: Array = []
var grid_size: int = 5
var solution_pattern: Array = []
var player_pattern: Array = []

# UI elements
var grid_container: GridContainer
var timer_label: Label
var attempts_label: Label
var instruction_label: Label

# Signals
signal puzzle_started(puzzle_type: PuzzleType)
signal puzzle_completed(success: bool)
signal puzzle_failed

func _ready():
	print("Puzzle Mode initialized")
	setup_puzzle_ui()

func _process(delta):
	if current_state == PuzzleState.PLAYING:
		puzzle_timer += delta
		update_timer_display()
		
		if puzzle_timer > max_puzzle_time:
			fail_puzzle("timeout")

func setup_puzzle_ui():
	# Create UI container
	var ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# Main puzzle container
	var main_container = VBoxContainer.new()
	main_container.anchors_preset = Control.PRESET_CENTER
	ui_layer.add_child(main_container)
	
	# Title
	var title_label = Label.new()
	title_label.text = "PUZZLE CHALLENGE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	main_container.add_child(title_label)
	
	# Timer
	timer_label = Label.new()
	timer_label.text = "Time: 180s"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(timer_label)
	
	# Attempts
	attempts_label = Label.new()
	attempts_label.text = "Attempts: 3"
	attempts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(attempts_label)
	
	# Instructions
	instruction_label = Label.new()
	instruction_label.text = "Loading puzzle..."
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.custom_minimum_size = Vector2(400, 50)
	main_container.add_child(instruction_label)
	
	# Grid container for puzzle
	grid_container = GridContainer.new()
	grid_container.columns = grid_size
	grid_container.add_theme_constant_override("h_separation", 5)
	grid_container.add_theme_constant_override("v_separation", 5)
	main_container.add_child(grid_container)
	
	# Control buttons
	var button_container = HBoxContainer.new()
	main_container.add_child(button_container)
	
	var new_puzzle_btn = Button.new()
	new_puzzle_btn.text = "New Puzzle"
	new_puzzle_btn.pressed.connect(_on_new_puzzle_pressed)
	button_container.add_child(new_puzzle_btn)
	
	var exit_btn = Button.new()
	exit_btn.text = "Exit"
	exit_btn.pressed.connect(_on_exit_pressed)
	button_container.add_child(exit_btn)

func start_puzzle(puzzle_type: PuzzleType):
	current_puzzle_type = puzzle_type
	current_state = PuzzleState.SETUP
	puzzle_timer = 0.0
	attempts_left = 3
	
	update_attempts_display()
	
	match puzzle_type:
		PuzzleType.TILE_ROTATION:
			setup_tile_rotation_puzzle()
		PuzzleType.MATCH_THREE:
			setup_match_three_puzzle()
		PuzzleType.MAZE_SOLVING:
			setup_maze_puzzle()
		PuzzleType.SEQUENCE_MEMORY:
			setup_sequence_memory_puzzle()
		PuzzleType.COLOR_PATTERN:
			setup_color_pattern_puzzle()
	
	current_state = PuzzleState.PLAYING
	puzzle_started.emit(puzzle_type)
	print("Started puzzle: ", PuzzleType.keys()[puzzle_type])

func setup_tile_rotation_puzzle():
	instruction_label.text = "Rotate tiles to match the pattern. Click tiles to rotate them."
	grid_size = 4
	grid_container.columns = grid_size
	clear_grid()
	
	# Create solution pattern (all tiles facing same direction)
	solution_pattern.clear()
	for i in range(grid_size * grid_size):
		solution_pattern.append(0)  # All tiles rotation 0
	
	# Create scrambled puzzle
	puzzle_grid.clear()
	for i in range(grid_size * grid_size):
		var tile = create_tile_button(i)
		var rotation = randi() % 4  # 0-3 rotations
		puzzle_grid.append(rotation)
		tile.rotation_degrees = rotation * 90
		grid_container.add_child(tile)

func setup_match_three_puzzle():
	instruction_label.text = "Match 3 or more of the same color in a row. Click to swap adjacent tiles."
	grid_size = 6
	grid_container.columns = grid_size
	clear_grid()
	
	# Create colorful grid
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE]
	puzzle_grid.clear()
	
	for i in range(grid_size * grid_size):
		var color_index = randi() % colors.size()
		puzzle_grid.append(color_index)
		
		var tile = create_color_tile_button(i, colors[color_index])
		grid_container.add_child(tile)

func setup_maze_puzzle():
	instruction_label.text = "Navigate from START (green) to END (red). Click adjacent cells to move."
	grid_size = 7
	grid_container.columns = grid_size
	clear_grid()
	
	generate_maze()

func setup_sequence_memory_puzzle():
	instruction_label.text = "Watch the sequence, then repeat it. Click tiles in the correct order."
	grid_size = 4
	grid_container.columns = grid_size
	clear_grid()
	
	# Generate sequence
	solution_pattern.clear()
	var sequence_length = 5 + (randi() % 3)  # 5-7 steps
	for i in range(sequence_length):
		solution_pattern.append(randi() % (grid_size * grid_size))
	
	create_sequence_tiles()
	show_sequence()

func setup_color_pattern_puzzle():
	instruction_label.text = "Recreate the color pattern shown. Click tiles to cycle colors."
	grid_size = 5
	grid_container.columns = grid_size
	clear_grid()
	
	# Generate target pattern
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]
	solution_pattern.clear()
	
	for i in range(grid_size * grid_size):
		solution_pattern.append(randi() % colors.size())
	
	# Show target briefly, then create interactive grid
	show_target_pattern()

func clear_grid():
	for child in grid_container.get_children():
		child.queue_free()

func create_tile_button(index: int) -> Button:
	var button = Button.new()
	button.text = str(index)
	button.custom_minimum_size = Vector2(50, 50)
	button.pressed.connect(_on_tile_pressed.bind(index))
	return button

func create_color_tile_button(index: int, color: Color) -> Button:
	var button = Button.new()
	button.modulate = color
	button.custom_minimum_size = Vector2(40, 40)
	button.pressed.connect(_on_color_tile_pressed.bind(index))
	return button

func _on_tile_pressed(index: int):
	if current_state != PuzzleState.PLAYING:
		return
	
	match current_puzzle_type:
		PuzzleType.TILE_ROTATION:
			handle_tile_rotation(index)
		PuzzleType.SEQUENCE_MEMORY:
			handle_sequence_input(index)
		PuzzleType.COLOR_PATTERN:
			handle_color_pattern_input(index)

func _on_color_tile_pressed(index: int):
	if current_state != PuzzleState.PLAYING:
		return
	
	if current_puzzle_type == PuzzleType.MATCH_THREE:
		handle_match_three_input(index)

func handle_tile_rotation(index: int):
	# Rotate the tile
	puzzle_grid[index] = (puzzle_grid[index] + 1) % 4
	var button = grid_container.get_child(index)
	button.rotation_degrees = puzzle_grid[index] * 90
	
	# Check if puzzle is solved
	if puzzle_grid == solution_pattern:
		complete_puzzle()

func handle_match_three_input(index: int):
	# Simple swap with adjacent tile (for demo)
	if index < puzzle_grid.size() - 1:
		var temp = puzzle_grid[index]
		puzzle_grid[index] = puzzle_grid[index + 1]
		puzzle_grid[index + 1] = temp
		
		# Update visuals
		update_match_three_display()
		check_match_three_completion()

func handle_sequence_input(index: int):
	player_pattern.append(index)
	
	# Highlight clicked tile briefly
	var button = grid_container.get_child(index)
	var original_color = button.modulate
	button.modulate = Color.YELLOW
	
	var tween = create_tween()
	tween.tween_delay(0.3)
	tween.tween_property(button, "modulate", original_color, 0.2)
	
	# Check if sequence is correct so far
	if player_pattern.size() > solution_pattern.size():
		fail_puzzle("sequence_too_long")
		return
	
	for i in range(player_pattern.size()):
		if player_pattern[i] != solution_pattern[i]:
			fail_puzzle("wrong_sequence")
			return
	
	# If complete sequence is correct
	if player_pattern.size() == solution_pattern.size():
		complete_puzzle()

func handle_color_pattern_input(index: int):
	# Cycle through colors
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]
	puzzle_grid[index] = (puzzle_grid[index] + 1) % colors.size()
	
	var button = grid_container.get_child(index)
	button.modulate = colors[puzzle_grid[index]]
	
	# Check if pattern matches
	if puzzle_grid == solution_pattern:
		complete_puzzle()

func generate_maze():
	# Simple maze generation (placeholder)
	puzzle_grid.clear()
	for i in range(grid_size * grid_size):
		# 0 = wall, 1 = path, 2 = start, 3 = end
		if i == 0:
			puzzle_grid.append(2)  # Start
		elif i == grid_size * grid_size - 1:
			puzzle_grid.append(3)  # End
		else:
			puzzle_grid.append(1 if randf() > 0.3 else 0)  # Path or wall
	
	# Create maze tiles
	for i in range(puzzle_grid.size()):
		var button = Button.new()
		button.custom_minimum_size = Vector2(30, 30)
		button.pressed.connect(_on_maze_tile_pressed.bind(i))
		
		match puzzle_grid[i]:
			0:  # Wall
				button.modulate = Color.BLACK
				button.disabled = true
			1:  # Path
				button.modulate = Color.WHITE
			2:  # Start
				button.modulate = Color.GREEN
			3:  # End
				button.modulate = Color.RED
		
		grid_container.add_child(button)

func _on_maze_tile_pressed(index: int):
	# Simple maze navigation (placeholder)
	print("Maze tile ", index, " pressed")
	if puzzle_grid[index] == 3:  # Reached end
		complete_puzzle()

func show_sequence():
	# Show the sequence to memorize
	var delay = 0.0
	for step in solution_pattern:
		var tween = create_tween()
		tween.tween_delay(delay)
		tween.tween_callback(highlight_sequence_tile.bind(step))
		delay += 0.8
	
	# After showing sequence, allow input
	var final_tween = create_tween()
	final_tween.tween_delay(delay + 1.0)
	final_tween.tween_callback(enable_sequence_input)

func highlight_sequence_tile(index: int):
	if index < grid_container.get_child_count():
		var button = grid_container.get_child(index)
		button.modulate = Color.YELLOW
		
		var tween = create_tween()
		tween.tween_delay(0.5)
		tween.tween_property(button, "modulate", Color.WHITE, 0.2)

func enable_sequence_input():
	player_pattern.clear()
	instruction_label.text = "Now repeat the sequence by clicking the tiles in order."

func create_sequence_tiles():
	puzzle_grid.clear()
	for i in range(grid_size * grid_size):
		puzzle_grid.append(0)
		var button = create_tile_button(i)
		button.modulate = Color.WHITE
		grid_container.add_child(button)

func show_target_pattern():
	# Show target pattern for color puzzle
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]
	puzzle_grid.clear()
	
	# Create target display
	for i in range(grid_size * grid_size):
		puzzle_grid.append(0)  # Start with first color
		var button = create_tile_button(i)
		button.modulate = colors[solution_pattern[i]]
		grid_container.add_child(button)
	
	# After 3 seconds, reset to interactive mode
	var tween = create_tween()
	tween.tween_delay(3.0)
	tween.tween_callback(start_color_pattern_interaction)

func start_color_pattern_interaction():
	instruction_label.text = "Now recreate the pattern you saw. Click tiles to change colors."
	for i in range(grid_container.get_child_count()):
		var button = grid_container.get_child(i)
		button.modulate = Color.RED  # Reset all to first color

func update_match_three_display():
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE]
	for i in range(puzzle_grid.size()):
		var button = grid_container.get_child(i)
		button.modulate = colors[puzzle_grid[i]]

func check_match_three_completion():
	# Simple completion check - if first row is all same color
	var first_row_color = puzzle_grid[0]
	var match = true
	for i in range(grid_size):
		if puzzle_grid[i] != first_row_color:
			match = false
			break
	
	if match:
		complete_puzzle()

func complete_puzzle():
	current_state = PuzzleState.COMPLETED
	print("Puzzle completed successfully!")
	
	# Reward player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.gain_experience(30)
		player.gold += 15
		player.karma += 2
	
	instruction_label.text = "PUZZLE SOLVED! Well done!"
	puzzle_completed.emit(true)

func fail_puzzle(reason: String):
	attempts_left -= 1
	update_attempts_display()
	
	print("Puzzle failed: ", reason, ". Attempts left: ", attempts_left)
	
	if attempts_left <= 0:
		current_state = PuzzleState.FAILED
		instruction_label.text = "PUZZLE FAILED! No attempts remaining."
		puzzle_failed.emit()
		puzzle_completed.emit(false)
	else:
		instruction_label.text = "Try again! Attempts left: " + str(attempts_left)
		# Reset puzzle
		player_pattern.clear()

func update_timer_display():
	var time_left = max_puzzle_time - puzzle_timer
	timer_label.text = "Time: " + str(int(time_left)) + "s"

func update_attempts_display():
	attempts_label.text = "Attempts: " + str(attempts_left)

func _on_new_puzzle_pressed():
	# Start a random puzzle
	var random_type = randi() % PuzzleType.size()
	start_puzzle(random_type as PuzzleType)

func _on_exit_pressed():
	exit_puzzle_mode()

func exit_puzzle_mode():
	print("Exiting Puzzle Mode")
	if GameManager.instance:
		GameManager.instance.change_game_state(GameManager.GameState.RPG)
	queue_free()