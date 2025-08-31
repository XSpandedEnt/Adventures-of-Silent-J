extends Node2D

class_name FightingMode

# Fighting mode - 1v1 spell duels with AI opponents

# Fight participants
@onready var player: Player
@onready var ai_opponent: AIOpponent

# Fight state
enum FightState {
	PREPARATION,
	FIGHTING,
	VICTORY,
	DEFEAT
}

var current_state: FightState = FightState.PREPARATION
var fight_timer: float = 0.0
var max_fight_time: float = 120.0  # 2 minutes max fight

# Fight arena bounds
var arena_bounds: Rect2 = Rect2(-400, -300, 800, 600)

# Signals
signal fight_started
signal fight_ended(winner: String)
signal player_victory
signal player_defeat

func _ready():
	print("Fighting Mode initialized")
	setup_fight_arena()

func _process(delta):
	fight_timer += delta
	
	match current_state:
		FightState.PREPARATION:
			handle_preparation()
		FightState.FIGHTING:
			handle_fighting(delta)
		FightState.VICTORY:
			handle_victory()
		FightState.DEFEAT:
			handle_defeat()

func setup_fight_arena():
	# Create arena boundaries
	var arena_border = ColorRect.new()
	arena_border.size = Vector2(arena_bounds.size.x, arena_bounds.size.y)
	arena_border.position = Vector2(arena_bounds.position.x, arena_bounds.position.y)
	arena_border.color = Color(0.2, 0.2, 0.3, 0.5)
	add_child(arena_border)
	
	print("Fight arena set up with bounds: ", arena_bounds)

func start_fight(player_ref: Player):
	player = player_ref
	
	# Create AI opponent
	ai_opponent = preload("res://genres/fighting/AIOpponent.tscn").instantiate()
	add_child(ai_opponent)
	ai_opponent.position = Vector2(200, 0)
	
	# Position player
	player.position = Vector2(-200, 0)
	
	current_state = FightState.FIGHTING
	fight_timer = 0.0
	
	print("Fight started!")
	fight_started.emit()

func handle_preparation():
	# Wait for fight to start
	pass

func handle_fighting(delta):
	# Check fight conditions
	if fight_timer > max_fight_time:
		end_fight("timeout")
		return
	
	# Check if player or opponent is defeated
	if player and player.health <= 0:
		end_fight("defeat")
		return
	
	if ai_opponent and ai_opponent.health <= 0:
		end_fight("victory")
		return
	
	# Keep fighters in arena bounds
	enforce_arena_bounds()

func handle_victory():
	if Input.is_action_just_pressed("interact"):
		exit_fighting_mode()

func handle_defeat():
	if Input.is_action_just_pressed("interact"):
		restart_fight()

func enforce_arena_bounds():
	if player:
		var player_pos = player.global_position
		player_pos.x = clamp(player_pos.x, arena_bounds.position.x + 20, arena_bounds.position.x + arena_bounds.size.x - 20)
		player_pos.y = clamp(player_pos.y, arena_bounds.position.y + 20, arena_bounds.position.y + arena_bounds.size.y - 20)
		player.global_position = player_pos
	
	if ai_opponent:
		var ai_pos = ai_opponent.global_position
		ai_pos.x = clamp(ai_pos.x, arena_bounds.position.x + 20, arena_bounds.position.x + arena_bounds.size.x - 20)
		ai_pos.y = clamp(ai_pos.y, arena_bounds.position.y + 20, arena_bounds.position.y + arena_bounds.size.y - 20)
		ai_opponent.global_position = ai_pos

func end_fight(result: String):
	match result:
		"victory":
			current_state = FightState.VICTORY
			print("Player Victory!")
			# Reward player
			if player:
				player.gain_experience(50)
				player.gold += 25
				player.karma += 5
			player_victory.emit()
		
		"defeat":
			current_state = FightState.DEFEAT
			print("Player Defeat!")
			# Penalty for player
			if player:
				player.karma -= 5
			player_defeat.emit()
		
		"timeout":
			current_state = FightState.DEFEAT
			print("Fight timed out!")
			player_defeat.emit()
	
	fight_ended.emit(result)

func restart_fight():
	if ai_opponent:
		ai_opponent.queue_free()
	
	# Reset player health
	if player:
		player.health = 100
		player.mana = 100
	
	start_fight(player)

func exit_fighting_mode():
	print("Exiting Fighting Mode")
	# Return to RPG mode
	if GameManager.instance:
		GameManager.instance.change_game_state(GameManager.GameState.RPG)
	
	# Clean up
	if ai_opponent:
		ai_opponent.queue_free()
	
	queue_free()

func get_fight_status() -> Dictionary:
	var status = {
		"state": FightState.keys()[current_state],
		"time_remaining": max_fight_time - fight_timer,
		"player_health": player.health if player else 0,
		"ai_health": ai_opponent.health if ai_opponent else 0
	}
	return status