extends Node

# Game Manager - Handles game states and global systems
class_name GameManager

# Game state enum
enum GameState {
	RPG,
	FIGHTING,
	PUZZLE,
	STRATEGY,
	MINIGOLF
}

# Singleton instance
static var instance: GameManager

# Current game state
var current_state: GameState = GameState.RPG

# Player reference
var player: Player

# Signals
signal game_state_changed(new_state: GameState)
signal player_stats_updated

func _ready():
	instance = self
	print("GameManager initialized")

func _input(event):
	# Handle global input events
	if event.is_action_pressed("character_stats"):
		show_character_stats()
	elif event.is_action_pressed("backpack"):
		show_backpack()

func change_game_state(new_state: GameState):
	if current_state != new_state:
		var old_state = current_state
		current_state = new_state
		print("Game state changed from ", GameState.keys()[old_state], " to ", GameState.keys()[new_state])
		game_state_changed.emit(new_state)

func get_current_state() -> GameState:
	return current_state

func set_player(player_node: Player):
	player = player_node
	print("Player reference set in GameManager")

func show_character_stats():
	if player:
		player.show_stats()
	print("Character Stats - P key pressed")

func show_backpack():
	print("Backpack - I key pressed")