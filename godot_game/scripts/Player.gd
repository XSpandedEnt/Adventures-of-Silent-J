extends CharacterBody2D

class_name Player

# Character stats as specified in requirements
var health: int = 100
var mana: int = 100
var strength: int
var wisdom: int
var karma: int = 0
var gold: int = 0
var experience: int = 0
var level: int = 1
var next_level_xp: int = 100

# Movement speed
var speed: float = 200.0

# Animation and sprite references
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Current facing direction for animations
enum Direction {
	FRONT,
	BACK,
	SIDE
}
var current_direction: Direction = Direction.FRONT
var facing_right: bool = true

# Spell cooldowns
var fireball_cooldown: float = 0.0
var lightning_cooldown: float = 0.0
var chaos_cooldown: float = 0.0
var void_cooldown: float = 0.0

# Unlocked spells
var spells_unlocked = {
	"fireball": true,
	"lightning": true,
	"chaos": false,
	"fire_wall": false,
	"void_magic": false,
	"thunder": false
}

# Signals
signal experience_gained(amount: int)
signal level_up(new_level: int)
signal spell_cast(spell_name: String, damage: int)

func _ready():
	# Initialize random stats
	randomize()
	strength = randi() % 10 + 1
	wisdom = randi() % 10 + 1
	
	print("Player initialized:")
	print("Health: ", health)
	print("Mana: ", mana)
	print("Strength: ", strength)
	print("Wisdom: ", wisdom)
	print("Level: ", level)
	
	# Register with GameManager
	if GameManager.instance:
		GameManager.instance.set_player(self)

func _physics_process(delta):
	# Handle movement input
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
		current_direction = Direction.BACK
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
		current_direction = Direction.FRONT
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
		current_direction = Direction.SIDE
		facing_right = false
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
		current_direction = Direction.SIDE
		facing_right = true
	
	# Normalize diagonal movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		velocity = input_vector * speed
		update_animation("walk")
	else:
		velocity = Vector2.ZERO
		update_animation("idle")
	
	move_and_slide()
	
	# Update cooldowns
	fireball_cooldown = max(0, fireball_cooldown - delta)
	lightning_cooldown = max(0, lightning_cooldown - delta)
	chaos_cooldown = max(0, chaos_cooldown - delta)
	void_cooldown = max(0, void_cooldown - delta)

func _input(event):
	# Handle spell casting
	if event.is_action_pressed("spell_fireball") and spells_unlocked["fireball"]:
		cast_fireball()
	elif event.is_action_pressed("spell_lightning") and spells_unlocked["lightning"]:
		cast_lightning()
	elif event.is_action_pressed("spell_chaos") and spells_unlocked["chaos"]:
		cast_chaos()
	elif event.is_action_pressed("spell_void") and spells_unlocked["void_magic"]:
		cast_void()
	elif event.is_action_pressed("interact"):
		interact()

func update_animation(action: String):
	var animation_name = ""
	
	match current_direction:
		Direction.FRONT:
			animation_name = "front_" + action
		Direction.BACK:
			animation_name = "back_" + action
		Direction.SIDE:
			animation_name = "side_" + action
	
	# Flip sprite for left movement
	if current_direction == Direction.SIDE:
		sprite.flip_h = not facing_right
	
	if animation_player.has_animation(animation_name):
		if animation_player.current_animation != animation_name:
			animation_player.play(animation_name)

func cast_fireball():
	if fireball_cooldown > 0 or mana < 20:
		print("Fireball on cooldown or insufficient mana")
		return
	
	var damage = 5 * wisdom + 15
	mana -= 20
	fireball_cooldown = 2.0
	
	print("Fireball cast! Damage: ", damage, " (burn effect: 15 every 5 sec)")
	spell_cast.emit("fireball", damage)

func cast_lightning():
	if lightning_cooldown > 0 or mana < 15:
		print("Lightning on cooldown or insufficient mana")
		return
	
	var damage = 3 * wisdom
	mana -= 15
	lightning_cooldown = 1.5
	
	print("Lightning cast! Damage: ", damage)
	spell_cast.emit("lightning", damage)

func cast_chaos():
	if not spells_unlocked["chaos"] or chaos_cooldown > 0 or mana < 30:
		print("Chaos spell not unlocked, on cooldown, or insufficient mana")
		return
	
	var damage = 7 * wisdom + 20
	mana -= 30
	chaos_cooldown = 4.0
	
	print("Chaos spell cast! Damage: ", damage)
	spell_cast.emit("chaos", damage)

func cast_void():
	if not spells_unlocked["void_magic"] or void_cooldown > 0 or mana < 40:
		print("Void magic not unlocked, on cooldown, or insufficient mana")
		return
	
	var damage = 10 * wisdom + 25
	mana -= 40
	void_cooldown = 6.0
	
	print("Void magic cast! Damage: ", damage)
	spell_cast.emit("void_magic", damage)

func gain_experience(amount: int):
	experience += amount
	print("Gained ", amount, " XP. Total: ", experience, "/", next_level_xp)
	experience_gained.emit(amount)
	
	if experience >= next_level_xp:
		level_up_character()

func level_up_character():
	level += 1
	experience -= next_level_xp
	next_level_xp = int(next_level_xp * 1.1)  # 10% increase each level
	
	# Increase stats on level up
	health += 10
	mana += 5
	strength += 1
	wisdom += 1
	
	print("LEVEL UP! New level: ", level)
	print("Next level XP required: ", next_level_xp)
	level_up.emit(level)
	
	# Unlock spells at certain levels
	unlock_spells_by_level()

func unlock_spells_by_level():
	match level:
		5:
			spells_unlocked["chaos"] = true
			print("Chaos spell unlocked!")
		10:
			spells_unlocked["fire_wall"] = true
			print("Fire Wall spell unlocked!")
		15:
			spells_unlocked["void_magic"] = true
			print("Void Magic spell unlocked!")
		20:
			spells_unlocked["thunder"] = true
			print("Thunder spell unlocked!")

func interact():
	print("Interact - W key pressed")
	# TODO: Implement interaction with NPCs, objects, etc.

func show_stats():
	print("=== SILENT J STATS ===")
	print("Level: ", level)
	print("Health: ", health)
	print("Mana: ", mana)
	print("Strength: ", strength)
	print("Wisdom: ", wisdom)
	print("Karma: ", karma)
	print("Gold: ", gold)
	print("Experience: ", experience, "/", next_level_xp)
	print("======================")

func take_damage(amount: int):
	health -= amount
	print("Took ", amount, " damage. Health: ", health)
	if health <= 0:
		die()

func die():
	print("Silent J has died!")
	karma = max(0, karma - 10)  # Lose karma on death
	health = 100  # Respawn with full health
	# TODO: Implement proper death/respawn mechanics

func heal(amount: int):
	health = min(100, health + amount)
	print("Healed for ", amount, ". Health: ", health)

func restore_mana(amount: int):
	mana = min(100, mana + amount)
	print("Restored ", amount, " mana. Mana: ", mana)