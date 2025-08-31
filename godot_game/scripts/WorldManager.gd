extends Node

class_name WorldManager

# World Manager - Handles transitions between different game modes

# Current active mode
var current_mode: Node2D
var player_ref: Player

# Mode instances (preloaded)
var rpg_mode: RPGMode
var fighting_mode: FightingMode
var puzzle_mode: PuzzleMode  
var strategy_mode: StrategyMode
var minigolf_mode: MiniGolfMode

# Signals
signal mode_changed(new_mode: String)

func _ready():
	print("WorldManager initialized")
	
	# Connect to GameManager state changes
	if GameManager.instance:
		GameManager.instance.game_state_changed.connect(_on_game_state_changed)
	
	# Find player reference
	player_ref = get_tree().get_first_node_in_group("player")
	if not player_ref:
		# Alternative method
		call_deferred("find_player_reference")

func find_player_reference():
	player_ref = get_tree().get_first_node_in_group("player")
	if not player_ref:
		# Try to find any Player node
		var players = get_tree().get_nodes_in_group("players") 
		if players.size() > 0:
			player_ref = players[0]
	
	if player_ref:
		print("WorldManager found player reference")
		setup_initial_mode()
	else:
		print("WorldManager: No player found, retrying...")
		get_tree().create_timer(1.0).timeout.connect(find_player_reference)

func setup_initial_mode():
	# Start with RPG mode
	switch_to_mode(GameManager.GameState.RPG)

func _on_game_state_changed(new_state: GameManager.GameState):
	print("WorldManager received state change: ", GameManager.GameState.keys()[new_state])
	switch_to_mode(new_state)

func switch_to_mode(mode_state: GameManager.GameState):
	# Clean up current mode
	if current_mode and is_instance_valid(current_mode):
		remove_child(current_mode)
		current_mode.queue_free()
		current_mode = null
	
	# Create new mode
	match mode_state:
		GameManager.GameState.RPG:
			create_rpg_mode()
		GameManager.GameState.FIGHTING:
			create_fighting_mode()
		GameManager.GameState.PUZZLE:
			create_puzzle_mode()
		GameManager.GameState.STRATEGY:
			create_strategy_mode()
		GameManager.GameState.MINIGOLF:
			create_minigolf_mode()
	
	mode_changed.emit(GameManager.GameState.keys()[mode_state])

func create_rpg_mode():
	rpg_mode = preload("res://genres/rpg/RPGMode.gd").new()
	add_child(rpg_mode)
	current_mode = rpg_mode
	
	if player_ref:
		rpg_mode.set_player_reference(player_ref)
		# Position player in RPG world
		player_ref.position = Vector2(0, 0)
	
	print("RPG Mode activated")

func create_fighting_mode():
	fighting_mode = preload("res://genres/fighting/FightingMode.gd").new()
	add_child(fighting_mode)
	current_mode = fighting_mode
	
	if player_ref:
		fighting_mode.start_fight(player_ref)
	
	# Connect to fighting mode completion
	fighting_mode.fight_ended.connect(_on_fighting_mode_ended)
	
	print("Fighting Mode activated")

func create_puzzle_mode():
	puzzle_mode = preload("res://genres/puzzle/PuzzleMode.gd").new()
	add_child(puzzle_mode)
	current_mode = puzzle_mode
	
	# Start a random puzzle
	var puzzle_types = [
		PuzzleMode.PuzzleType.TILE_ROTATION,
		PuzzleMode.PuzzleType.MATCH_THREE,
		PuzzleMode.PuzzleType.MAZE_SOLVING,
		PuzzleMode.PuzzleType.SEQUENCE_MEMORY,
		PuzzleMode.PuzzleType.COLOR_PATTERN
	]
	var random_type = puzzle_types[randi() % puzzle_types.size()]
	puzzle_mode.start_puzzle(random_type)
	
	# Connect to puzzle completion
	puzzle_mode.puzzle_completed.connect(_on_puzzle_mode_completed)
	
	print("Puzzle Mode activated")

func create_strategy_mode():
	strategy_mode = preload("res://genres/strategy/StrategyMode.gd").new()
	add_child(strategy_mode)
	current_mode = strategy_mode
	
	# Connect to strategy completion
	strategy_mode.strategy_completed.connect(_on_strategy_mode_completed)
	
	print("Strategy Mode activated")

func create_minigolf_mode():
	minigolf_mode = preload("res://genres/minigolf/MiniGolfMode.gd").new()
	add_child(minigolf_mode)
	current_mode = minigolf_mode
	
	# Connect to course completion
	minigolf_mode.course_completed.connect(_on_minigolf_mode_completed)
	
	print("Mini-Golf Mode activated")

func _on_fighting_mode_ended(result: String):
	print("Fighting mode ended with result: ", result)
	# Could add rewards or consequences based on result
	
	# Return to RPG mode after a delay
	get_tree().create_timer(2.0).timeout.connect(return_to_rpg)

func _on_puzzle_mode_completed(success: bool):
	print("Puzzle mode completed. Success: ", success)
	
	# Return to RPG mode after a delay
	get_tree().create_timer(2.0).timeout.connect(return_to_rpg)

func _on_strategy_mode_completed(victory: bool):
	print("Strategy mode completed. Victory: ", victory)
	
	# Return to RPG mode after a delay
	get_tree().create_timer(2.0).timeout.connect(return_to_rpg)

func _on_minigolf_mode_completed(total_shots: int, total_par: int):
	print("Mini-golf completed. Shots: ", total_shots, " Par: ", total_par)
	
	# Return to RPG mode after a delay
	get_tree().create_timer(2.0).timeout.connect(return_to_rpg)

func return_to_rpg():
	if GameManager.instance:
		GameManager.instance.change_game_state(GameManager.GameState.RPG)

func get_current_mode_name() -> String:
	if not current_mode:
		return "None"
	
	if current_mode is RPGMode:
		return "RPG"
	elif current_mode is FightingMode:
		return "Fighting"
	elif current_mode is PuzzleMode:
		return "Puzzle"
	elif current_mode is StrategyMode:
		return "Strategy"
	elif current_mode is MiniGolfMode:
		return "Mini-Golf"
	else:
		return "Unknown"

func save_game_state() -> Dictionary:
	# Save current game state
	var save_data = {
		"current_mode": get_current_mode_name(),
		"player_position": player_ref.global_position if player_ref else Vector2.ZERO,
		"player_stats": get_player_stats() if player_ref else {}
	}
	
	return save_data

func load_game_state(save_data: Dictionary):
	# Load game state
	if save_data.has("current_mode"):
		var mode_name = save_data["current_mode"]
		match mode_name:
			"RPG":
				switch_to_mode(GameManager.GameState.RPG)
			"Fighting":
				switch_to_mode(GameManager.GameState.FIGHTING)
			"Puzzle":
				switch_to_mode(GameManager.GameState.PUZZLE)
			"Strategy":
				switch_to_mode(GameManager.GameState.STRATEGY)
			"Mini-Golf":
				switch_to_mode(GameManager.GameState.MINIGOLF)
	
	if save_data.has("player_position") and player_ref:
		player_ref.global_position = save_data["player_position"]
	
	if save_data.has("player_stats") and player_ref:
		load_player_stats(save_data["player_stats"])

func get_player_stats() -> Dictionary:
	if not player_ref:
		return {}
	
	return {
		"health": player_ref.health,
		"mana": player_ref.mana,
		"strength": player_ref.strength,
		"wisdom": player_ref.wisdom,
		"karma": player_ref.karma,
		"gold": player_ref.gold,
		"experience": player_ref.experience,
		"level": player_ref.level,
		"next_level_xp": player_ref.next_level_xp
	}

func load_player_stats(stats: Dictionary):
	if not player_ref:
		return
	
	if stats.has("health"):
		player_ref.health = stats["health"]
	if stats.has("mana"):
		player_ref.mana = stats["mana"]
	if stats.has("strength"):
		player_ref.strength = stats["strength"]
	if stats.has("wisdom"):
		player_ref.wisdom = stats["wisdom"]
	if stats.has("karma"):
		player_ref.karma = stats["karma"]
	if stats.has("gold"):
		player_ref.gold = stats["gold"]
	if stats.has("experience"):
		player_ref.experience = stats["experience"]
	if stats.has("level"):
		player_ref.level = stats["level"]
	if stats.has("next_level_xp"):
		player_ref.next_level_xp = stats["next_level_xp"]