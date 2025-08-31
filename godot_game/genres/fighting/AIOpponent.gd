extends CharacterBody2D

class_name AIOpponent

# AI opponent for fighting mode

# Stats similar to player
var health: int = 100
var mana: int = 100
var strength: int = 8
var wisdom: int = 7

# Movement and behavior
var speed: float = 150.0
var attack_range: float = 200.0
var retreat_distance: float = 100.0

# AI behavior timers
var spell_cooldown: float = 0.0
var movement_timer: float = 0.0
var decision_timer: float = 0.0

# Combat state
enum AIState {
	AGGRESSIVE,
	DEFENSIVE,
	RETREATING,
	CASTING
}

var current_ai_state: AIState = AIState.AGGRESSIVE
var target_position: Vector2
var player_ref: Player

# Sprite and animation
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# Initialize AI opponent
	randomize()
	strength = randi() % 8 + 5  # 5-12 range
	wisdom = randi() % 8 + 5   # 5-12 range
	
	print("AI Opponent initialized - Health: ", health, ", Strength: ", strength, ", Wisdom: ", wisdom)
	
	# Find player reference
	player_ref = get_tree().get_first_node_in_group("player")
	if not player_ref:
		# Try alternative method to find player
		var players = get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			player_ref = players[0]

func _physics_process(delta):
	# Update timers
	spell_cooldown = max(0, spell_cooldown - delta)
	movement_timer += delta
	decision_timer += delta
	
	# Make AI decisions every 0.5 seconds
	if decision_timer >= 0.5:
		make_ai_decision()
		decision_timer = 0.0
	
	# Execute current behavior
	execute_ai_behavior(delta)
	
	# Apply movement
	move_and_slide()

func make_ai_decision():
	if not player_ref:
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	var health_percentage = float(health) / 100.0
	
	# Decide AI behavior based on conditions
	if health_percentage < 0.3:
		current_ai_state = AIState.RETREATING
	elif distance_to_player > attack_range:
		current_ai_state = AIState.AGGRESSIVE
	elif distance_to_player < retreat_distance and spell_cooldown <= 0:
		current_ai_state = AIState.CASTING
	elif mana < 20:
		current_ai_state = AIState.DEFENSIVE
	else:
		# Random behavior with weighted chances
		var random_choice = randf()
		if random_choice < 0.4:
			current_ai_state = AIState.AGGRESSIVE
		elif random_choice < 0.7:
			current_ai_state = AIState.CASTING
		else:
			current_ai_state = AIState.DEFENSIVE
	
	print("AI Decision: ", AIState.keys()[current_ai_state])

func execute_ai_behavior(delta):
	if not player_ref:
		return
	
	match current_ai_state:
		AIState.AGGRESSIVE:
			move_towards_player()
		AIState.DEFENSIVE:
			maintain_distance()
		AIState.RETREATING:
			retreat_from_player()
		AIState.CASTING:
			cast_spell_at_player()

func move_towards_player():
	if not player_ref:
		return
	
	var direction = (player_ref.global_position - global_position).normalized()
	velocity = direction * speed
	
	# Face the player
	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

func maintain_distance():
	if not player_ref:
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	var ideal_distance = 150.0
	
	if distance_to_player < ideal_distance:
		# Move away
		var direction = (global_position - player_ref.global_position).normalized()
		velocity = direction * speed * 0.7
	elif distance_to_player > ideal_distance + 50:
		# Move closer
		var direction = (player_ref.global_position - global_position).normalized()
		velocity = direction * speed * 0.5
	else:
		# Circle around player
		var angle = global_position.angle_to_point(player_ref.global_position) + PI/2
		var circle_direction = Vector2(cos(angle), sin(angle))
		velocity = circle_direction * speed * 0.6

func retreat_from_player():
	if not player_ref:
		return
	
	var direction = (global_position - player_ref.global_position).normalized()
	velocity = direction * speed * 1.2  # Move faster when retreating
	
	# Face the player while retreating
	if direction.x > 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

func cast_spell_at_player():
	if spell_cooldown > 0 or mana < 15:
		# Can't cast, move defensively
		maintain_distance()
		return
	
	# Stop moving to cast
	velocity = Vector2.ZERO
	
	# Choose spell based on distance and mana
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	if distance_to_player <= 100 and mana >= 20:
		cast_fireball()
	elif mana >= 15:
		cast_lightning()
	else:
		# Not enough mana, retreat
		current_ai_state = AIState.RETREATING

func cast_fireball():
	if mana < 20:
		return
	
	var damage = 4 * wisdom + 10  # Slightly weaker than player
	mana -= 20
	spell_cooldown = 2.5  # Slightly longer cooldown
	
	print("AI casts Fireball! Damage: ", damage)
	
	# Apply damage to player if in range
	if player_ref and global_position.distance_to(player_ref.global_position) <= 150:
		player_ref.take_damage(damage)
	
	# Visual effect (placeholder)
	create_spell_effect("fireball")

func cast_lightning():
	if mana < 15:
		return
	
	var damage = 2 * wisdom + 5  # Weaker than player
	mana -= 15
	spell_cooldown = 2.0
	
	print("AI casts Lightning! Damage: ", damage)
	
	# Apply damage to player if in range
	if player_ref and global_position.distance_to(player_ref.global_position) <= 200:
		player_ref.take_damage(damage)
	
	# Visual effect (placeholder)
	create_spell_effect("lightning")

func create_spell_effect(spell_type: String):
	# Create a simple visual effect for spells
	var effect = ColorRect.new()
	add_child(effect)
	
	match spell_type:
		"fireball":
			effect.color = Color.RED
			effect.size = Vector2(20, 20)
		"lightning":
			effect.color = Color.YELLOW
			effect.size = Vector2(15, 25)
	
	effect.position = Vector2(-10, -12)
	
	# Remove effect after short time
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(effect.queue_free)

func take_damage(amount: int):
	health -= amount
	print("AI took ", amount, " damage. Health: ", health)
	
	# Flash red when taking damage
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		die()

func die():
	print("AI Opponent defeated!")
	# Death animation/effect could go here
	# For now, just disable collision and fade out
	set_collision_layer(0)
	set_collision_mask(0)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

func restore_mana(amount: int):
	mana = min(100, mana + amount)
	
# Passive mana regeneration
func _on_mana_regen_timer_timeout():
	restore_mana(2)