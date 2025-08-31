extends Node2D

class_name StrategyMode

# Strategy mode - Resource control and base capturing

# Game resources
var player_gold: int = 100
var player_mana_shards: int = 50
var player_troops: int = 5

var enemy_gold: int = 120
var enemy_mana_shards: int = 60
var enemy_troops: int = 6

# Map and bases
var bases: Array = []
var selected_base: StrategyBase = null
var turn_number: int = 1
var is_player_turn: bool = true

# Strategy state
enum StrategyState {
	SETUP,
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY,
	DEFEAT
}

var current_state: StrategyState = StrategyState.SETUP

# UI elements
var resource_display: Control
var turn_display: Label
var action_buttons: Control

# Base ownership
enum BaseOwner {
	NEUTRAL,
	PLAYER,
	ENEMY
}

# Signals
signal strategy_completed(victory: bool)
signal turn_changed(is_player_turn: bool)
signal resources_updated

func _ready():
	print("Strategy Mode initialized")
	setup_strategy_map()
	setup_strategy_ui()
	start_strategy_game()

func _process(delta):
	match current_state:
		StrategyState.PLAYER_TURN:
			handle_player_turn()
		StrategyState.ENEMY_TURN:
			handle_enemy_turn(delta)

func setup_strategy_map():
	# Create a simple 3x3 grid of bases
	var base_positions = [
		Vector2(-200, -200), Vector2(0, -200), Vector2(200, -200),
		Vector2(-200, 0), Vector2(0, 0), Vector2(200, 0),
		Vector2(-200, 200), Vector2(0, 200), Vector2(200, 200)
	]
	
	for i in range(base_positions.size()):
		var base = StrategyBase.new()
		base.position = base_positions[i]
		base.base_id = i
		base.name = "Base_" + str(i)
		
		# Set initial ownership
		if i < 2:
			base.owner = BaseOwner.PLAYER
			base.troop_count = 2
		elif i > 6:
			base.owner = BaseOwner.ENEMY
			base.troop_count = 2
		else:
			base.owner = BaseOwner.NEUTRAL
			base.troop_count = 1
		
		base.base_selected.connect(_on_base_selected)
		bases.append(base)
		add_child(base)
	
	print("Strategy map created with ", bases.size(), " bases")

func setup_strategy_ui():
	# Create UI layer
	var ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# Resource display
	resource_display = VBoxContainer.new()
	resource_display.position = Vector2(10, 10)
	ui_layer.add_child(resource_display)
	
	var gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "Gold: " + str(player_gold)
	resource_display.add_child(gold_label)
	
	var mana_label = Label.new()
	mana_label.name = "ManaLabel"
	mana_label.text = "Mana Shards: " + str(player_mana_shards)
	resource_display.add_child(mana_label)
	
	var troops_label = Label.new()
	troops_label.name = "TroopsLabel"
	troops_label.text = "Available Troops: " + str(player_troops)
	resource_display.add_child(troops_label)
	
	# Turn display
	turn_display = Label.new()
	turn_display.position = Vector2(10, 150)
	turn_display.text = "Turn 1 - Your Turn"
	turn_display.add_theme_font_size_override("font_size", 18)
	ui_layer.add_child(turn_display)
	
	# Action buttons
	action_buttons = VBoxContainer.new()
	action_buttons.position = Vector2(10, 200)
	ui_layer.add_child(action_buttons)
	
	var recruit_btn = Button.new()
	recruit_btn.text = "Recruit Troops (10 Gold)"
	recruit_btn.pressed.connect(_on_recruit_troops_pressed)
	action_buttons.add_child(recruit_btn)
	
	var upgrade_btn = Button.new()
	upgrade_btn.text = "Upgrade Base (15 Gold, 5 Mana)"
	upgrade_btn.pressed.connect(_on_upgrade_base_pressed)
	action_buttons.add_child(upgrade_btn)
	
	var end_turn_btn = Button.new()
	end_turn_btn.text = "End Turn"
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	action_buttons.add_child(end_turn_btn)
	
	var exit_btn = Button.new()
	exit_btn.text = "Exit Strategy Mode"
	exit_btn.pressed.connect(_on_exit_pressed)
	action_buttons.add_child(exit_btn)

func start_strategy_game():
	current_state = StrategyState.PLAYER_TURN
	update_resource_display()
	print("Strategy game started!")

func handle_player_turn():
	# Player can select bases and perform actions
	# Turn handling is mostly through UI interactions
	pass

func handle_enemy_turn(delta):
	# Simple AI for enemy turn
	static var ai_timer: float = 0.0
	ai_timer += delta
	
	if ai_timer > 2.0:  # AI acts every 2 seconds
		perform_enemy_action()
		ai_timer = 0.0
		
		# End enemy turn after 3 actions or if no valid actions
		static var enemy_actions: int = 0
		enemy_actions += 1
		if enemy_actions >= 3:
			enemy_actions = 0
			end_turn()

func perform_enemy_action():
	# Enemy AI logic
	var enemy_bases = get_bases_owned_by(BaseOwner.ENEMY)
	var neutral_bases = get_bases_owned_by(BaseOwner.NEUTRAL)
	var player_bases = get_bases_owned_by(BaseOwner.PLAYER)
	
	# Try to attack player bases
	for enemy_base in enemy_bases:
		if enemy_base.troop_count > 2:
			var nearby_targets = get_adjacent_bases(enemy_base)
			for target in nearby_targets:
				if target.owner == BaseOwner.PLAYER and target.troop_count < enemy_base.troop_count:
					attack_base(enemy_base, target)
					return
	
	# Try to capture neutral bases
	for enemy_base in enemy_bases:
		if enemy_base.troop_count > 1:
			var nearby_neutrals = get_adjacent_bases(enemy_base)
			for neutral in nearby_neutrals:
				if neutral.owner == BaseOwner.NEUTRAL:
					attack_base(enemy_base, neutral)
					return
	
	# Recruit troops if possible
	if enemy_gold >= 10:
		enemy_gold -= 10
		enemy_troops += 2
		print("Enemy recruited troops")

func attack_base(attacker: StrategyBase, target: StrategyBase):
	print("Attack: ", attacker.name, " attacks ", target.name)
	
	var attack_power = attacker.troop_count - 1  # Leave 1 troop to defend
	var defense_power = target.troop_count
	
	if attack_power > defense_power:
		# Successful attack
		target.owner = attacker.owner
		target.troop_count = attack_power - defense_power
		attacker.troop_count = 1  # Defender left behind
		
		target.update_visual()
		attacker.update_visual()
		
		print("Attack successful! ", target.name, " captured by ", BaseOwner.keys()[attacker.owner])
		
		# Check victory conditions
		check_victory_conditions()
	else:
		# Failed attack
		attacker.troop_count = 1
		target.troop_count = defense_power - attack_power
		
		attacker.update_visual()
		target.update_visual()
		
		print("Attack failed!")

func get_bases_owned_by(owner: BaseOwner) -> Array:
	var owned_bases = []
	for base in bases:
		if base.owner == owner:
			owned_bases.append(base)
	return owned_bases

func get_adjacent_bases(base: StrategyBase) -> Array:
	# Simple adjacency - bases within 250 units
	var adjacent = []
	for other_base in bases:
		if other_base != base and base.position.distance_to(other_base.position) < 250:
			adjacent.append(other_base)
	return adjacent

func _on_base_selected(base: StrategyBase):
	if current_state != StrategyState.PLAYER_TURN:
		return
	
	# Deselect previous base
	if selected_base:
		selected_base.set_selected(false)
	
	# Select new base
	selected_base = base
	base.set_selected(true)
	
	print("Selected base: ", base.name, " (Owner: ", BaseOwner.keys()[base.owner], ", Troops: ", base.troop_count, ")")

func _on_recruit_troops_pressed():
	if current_state != StrategyState.PLAYER_TURN or player_gold < 10:
		print("Cannot recruit troops - insufficient gold or not your turn")
		return
	
	player_gold -= 10
	player_troops += 2
	update_resource_display()
	print("Recruited 2 troops for 10 gold")

func _on_upgrade_base_pressed():
	if current_state != StrategyState.PLAYER_TURN or not selected_base or selected_base.owner != BaseOwner.PLAYER:
		print("Cannot upgrade - no base selected or not your base")
		return
	
	if player_gold < 15 or player_mana_shards < 5:
		print("Cannot upgrade - insufficient resources")
		return
	
	player_gold -= 15
	player_mana_shards -= 5
	selected_base.upgrade_base()
	update_resource_display()
	print("Upgraded base: ", selected_base.name)

func _on_end_turn_pressed():
	if current_state == StrategyState.PLAYER_TURN:
		end_turn()

func end_turn():
	if is_player_turn:
		# Switch to enemy turn
		is_player_turn = false
		current_state = StrategyState.ENEMY_TURN
		turn_display.text = "Turn " + str(turn_number) + " - Enemy Turn"
		
		# Collect resources from bases
		collect_turn_resources()
	else:
		# Switch to player turn
		is_player_turn = true
		current_state = StrategyState.PLAYER_TURN
		turn_number += 1
		turn_display.text = "Turn " + str(turn_number) + " - Your Turn"
		
		collect_turn_resources()
	
	turn_changed.emit(is_player_turn)
	print("Turn ended. Now: ", "Player" if is_player_turn else "Enemy", " turn")

func collect_turn_resources():
	# Collect resources from owned bases
	var player_base_count = get_bases_owned_by(BaseOwner.PLAYER).size()
	var enemy_base_count = get_bases_owned_by(BaseOwner.ENEMY).size()
	
	if is_player_turn:
		player_gold += player_base_count * 5
		player_mana_shards += player_base_count * 2
		update_resource_display()
	else:
		enemy_gold += enemy_base_count * 5
		enemy_mana_shards += enemy_base_count * 2

func update_resource_display():
	resource_display.get_node("GoldLabel").text = "Gold: " + str(player_gold)
	resource_display.get_node("ManaLabel").text = "Mana Shards: " + str(player_mana_shards)
	resource_display.get_node("TroopsLabel").text = "Available Troops: " + str(player_troops)
	resources_updated.emit()

func check_victory_conditions():
	var player_bases = get_bases_owned_by(BaseOwner.PLAYER).size()
	var enemy_bases = get_bases_owned_by(BaseOwner.ENEMY).size()
	var total_bases = bases.size()
	
	if player_bases >= total_bases * 0.7:  # Control 70% of bases
		win_strategy_game()
	elif enemy_bases >= total_bases * 0.7:
		lose_strategy_game()

func win_strategy_game():
	current_state = StrategyState.VICTORY
	print("STRATEGY VICTORY!")
	
	# Reward player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.gain_experience(75)
		player.gold += 50
		player.karma += 10
	
	turn_display.text = "VICTORY! You conquered the region!"
	strategy_completed.emit(true)

func lose_strategy_game():
	current_state = StrategyState.DEFEAT
	print("STRATEGY DEFEAT!")
	
	# Penalty for player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.karma -= 5
	
	turn_display.text = "DEFEAT! The enemy has conquered the region."
	strategy_completed.emit(false)

func _on_exit_pressed():
	exit_strategy_mode()

func exit_strategy_mode():
	print("Exiting Strategy Mode")
	if GameManager.instance:
		GameManager.instance.change_game_state(GameManager.GameState.RPG)
	queue_free()

# Strategy Base class
class StrategyBase extends Area2D:
	var base_id: int
	var owner: BaseOwner = BaseOwner.NEUTRAL
	var troop_count: int = 1
	var is_upgraded: bool = false
	var is_selected: bool = false
	
	var sprite: Sprite2D
	var troops_label: Label
	
	signal base_selected(base: StrategyBase)
	
	func _ready():
		# Create visual representation
		sprite = Sprite2D.new()
		sprite.scale = Vector2(40, 40)
		sprite.texture = PlaceholderTexture2D.new()
		add_child(sprite)
		
		# Collision for clicking
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(40, 40)
		collision.shape = shape
		add_child(collision)
		
		# Troops label
		troops_label = Label.new()
		troops_label.position = Vector2(-10, -30)
		troops_label.text = str(troop_count)
		add_child(troops_label)
		
		# Connect signals
		input_event.connect(_on_input_event)
		
		update_visual()
	
	func _on_input_event(viewport, event, shape_idx):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			base_selected.emit(self)
	
	func update_visual():
		match owner:
			BaseOwner.NEUTRAL:
				sprite.modulate = Color.GRAY
			BaseOwner.PLAYER:
				sprite.modulate = Color.BLUE
			BaseOwner.ENEMY:
				sprite.modulate = Color.RED
		
		troops_label.text = str(troop_count)
		
		if is_upgraded:
			sprite.scale = Vector2(50, 50)
	
	func set_selected(selected: bool):
		is_selected = selected
		if selected:
			sprite.modulate = sprite.modulate.lightened(0.3)
		else:
			update_visual()
	
	func upgrade_base():
		is_upgraded = true
		troop_count += 1
		update_visual()