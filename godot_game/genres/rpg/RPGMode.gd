extends Node2D

class_name RPGMode

# RPG mode - Main exploration with quests and progression

# World areas and NPCs  
var world_areas: Array = []
var npcs: Array = []
var current_area: WorldArea

# Quest system
var active_quests: Array = []
var completed_quests: Array = []

# World exploration
var player_ref: Player
var exploration_bounds: Rect2 = Rect2(-800, -600, 1600, 1200)

# Genre transition gates
var genre_gates: Array = []

# Signals
signal area_entered(area_name: String)
signal quest_started(quest_name: String)
signal quest_completed(quest_name: String)
signal genre_gate_activated(genre_type: GameManager.GameState)

func _ready():
	print("RPG Mode initialized")
	setup_world()
	create_genre_gates()
	create_npcs()

func setup_world():
	# Create different world areas
	create_world_area("Starting Village", Vector2(0, 0), 200, "A peaceful village where survivors gather")
	create_world_area("Syndicate Outpost", Vector2(400, -300), 150, "A fortified corporate settlement")
	create_world_area("Tribal Camp", Vector2(-400, 300), 180, "A nomadic tribe's temporary camp")
	create_world_area("Ruins of Old City", Vector2(600, 400), 250, "Devastated remains of pre-invasion civilization")
	create_world_area("Mystic Grove", Vector2(-600, -200), 120, "A strange forest where magic feels stronger")

func create_world_area(name: String, position: Vector2, radius: float, description: String):
	var area = WorldArea.new()
	area.area_name = name
	area.position = position
	area.radius = radius
	area.description = description
	area.area_entered.connect(_on_area_entered)
	world_areas.append(area)
	add_child(area)
	
	print("Created world area: ", name, " at ", position)

func create_genre_gates():
	# Fighting Gate - guarded by a tough opponent
	create_genre_gate("Combat Arena", Vector2(300, -100), GameManager.GameState.FIGHTING, 
		"A makeshift arena where warriors test their skills. Defeat a champion to prove your worth.")
	
	# Puzzle Gate - ancient mechanism
	create_genre_gate("Ancient Mechanism", Vector2(-250, -150), GameManager.GameState.PUZZLE,
		"Strange ancient technology that requires solving complex puzzles to activate.")
	
	# Strategy Gate - territorial conflict
	create_genre_gate("Contested Territory", Vector2(150, 250), GameManager.GameState.STRATEGY,
		"A strategic location where factions battle for control. Lead forces to victory.")
	
	# Mini-Golf Gate - recreational challenge
	create_genre_gate("Recreation Center", Vector2(-150, 200), GameManager.GameState.MINIGOLF,
		"Survivors built this course for entertainment. Master it to unlock new areas.")

func create_genre_gate(name: String, position: Vector2, genre: GameManager.GameState, description: String):
	var gate = GenreGate.new()
	gate.gate_name = name
	gate.position = position
	gate.target_genre = genre
	gate.description = description
	gate.gate_activated.connect(_on_genre_gate_activated)
	genre_gates.append(gate)
	add_child(gate)
	
	print("Created genre gate: ", name, " leading to ", GameManager.GameState.keys()[genre])

func create_npcs():
	# Create various NPCs with different purposes
	create_npc("Elder Marcus", Vector2(50, 50), "village_elder", 
		"Welcome, Silent J. Our settlement needs your magical abilities.")
	
	create_npc("Trader Zara", Vector2(-100, 80), "trader",
		"I have rare items for someone with your skills. Gold talks here.")
	
	create_npc("Scout Riley", Vector2(200, -50), "scout",
		"The syndicates are moving. We need someone to investigate their plans.")
	
	create_npc("Mystic Kael", Vector2(-300, -100), "mystic",
		"Your magical aura is strong, young wizard. I can teach you new spells... for a price.")
	
	create_npc("Rebel Captain", Vector2(100, 300), "rebel",
		"The corporations think they own this world. Help us prove them wrong.")

func create_npc(name: String, position: Vector2, npc_type: String, dialogue: String):
	var npc = NPC.new()
	npc.npc_name = name
	npc.position = position
	npc.npc_type = npc_type
	npc.dialogue_text = dialogue
	npc.npc_interacted.connect(_on_npc_interacted)
	npcs.append(npc)
	add_child(npc)
	
	print("Created NPC: ", name, " (", npc_type, ")")

func set_player_reference(player: Player):
	player_ref = player
	if player_ref:
		# Follow player with camera
		var camera = player_ref.get_node("Camera2D")
		if camera:
			camera.enabled = true

func _process(delta):
	if player_ref:
		check_area_transitions()
		update_exploration_bounds()

func check_area_transitions():
	# Check if player enters new areas
	for area in world_areas:
		var distance = player_ref.global_position.distance_to(area.global_position)
		if distance <= area.radius and current_area != area:
			enter_area(area)

func enter_area(area: WorldArea):
	if current_area:
		current_area.set_active(false)
	
	current_area = area
	area.set_active(true)
	area_entered.emit(area.area_name)
	
	print("Entered area: ", area.area_name)
	show_area_info(area)

func show_area_info(area: WorldArea):
	# Display area information to player
	print("Area: ", area.area_name)
	print("Description: ", area.description)
	
	# Check for area-specific events or quests
	check_area_events(area)

func check_area_events(area: WorldArea):
	# Trigger area-specific events
	match area.area_name:
		"Starting Village":
			if not has_completed_quest("village_introduction"):
				start_quest("village_introduction")
		"Syndicate Outpost":
			if player_ref.karma < -10:
				print("The syndicate welcomes you...")
			else:
				print("The syndicate guards eye you suspiciously...")
		"Tribal Camp":
			if player_ref.karma > 10:
				print("The tribe greets you as a friend...")
			else:
				print("The tribe is cautious around you...")

func update_exploration_bounds():
	# Keep player within world bounds
	var pos = player_ref.global_position
	pos.x = clamp(pos.x, exploration_bounds.position.x, exploration_bounds.position.x + exploration_bounds.size.x)
	pos.y = clamp(pos.y, exploration_bounds.position.y, exploration_bounds.position.y + exploration_bounds.size.y)
	player_ref.global_position = pos

func start_quest(quest_name: String):
	var quest = create_quest(quest_name)
	if quest:
		active_quests.append(quest)
		quest_started.emit(quest_name)
		print("Quest started: ", quest_name)

func create_quest(quest_name: String) -> Dictionary:
	# Create quest data based on name
	match quest_name:
		"village_introduction":
			return {
				"name": "Welcome to the Village",
				"description": "Speak with Elder Marcus to learn about the settlement",
				"objectives": ["Talk to Elder Marcus"],
				"rewards": {"experience": 25, "gold": 10, "karma": 5},
				"completed": false
			}
		"syndicate_investigation":
			return {
				"name": "Corporate Secrets",
				"description": "Investigate the syndicate's activities in the region",
				"objectives": ["Enter Syndicate Outpost", "Gather intelligence", "Report back"],
				"rewards": {"experience": 50, "gold": 25, "karma": -5},
				"completed": false
			}
		"tribal_alliance":
			return {
				"name": "Tribal Cooperation",
				"description": "Help establish peaceful relations with the local tribe",
				"objectives": ["Visit Tribal Camp", "Complete tribal trial", "Sign alliance"],
				"rewards": {"experience": 40, "gold": 15, "karma": 10},
				"completed": false
			}
	
	return {}

func complete_quest(quest_name: String):
	for i in range(active_quests.size()):
		if active_quests[i]["name"] == quest_name:
			var quest = active_quests[i]
			quest["completed"] = true
			
			# Give rewards
			if player_ref:
				player_ref.gain_experience(quest["rewards"]["experience"])
				player_ref.gold += quest["rewards"]["gold"]
				player_ref.karma += quest["rewards"]["karma"]
			
			completed_quests.append(quest)
			active_quests.remove_at(i)
			quest_completed.emit(quest_name)
			
			print("Quest completed: ", quest_name)
			break

func has_completed_quest(quest_name: String) -> bool:
	for quest in completed_quests:
		if quest["name"] == quest_name:
			return true
	return false

func _on_area_entered(area_name: String):
	print("Player entered: ", area_name)

func _on_npc_interacted(npc: NPC):
	print("Interacting with NPC: ", npc.npc_name)
	
	# Handle NPC-specific interactions
	match npc.npc_type:
		"village_elder":
			handle_elder_interaction(npc)
		"trader":
			handle_trader_interaction(npc)
		"scout":
			handle_scout_interaction(npc)
		"mystic":
			handle_mystic_interaction(npc)
		"rebel":
			handle_rebel_interaction(npc)

func handle_elder_interaction(npc: NPC):
	print(npc.dialogue_text)
	if not has_completed_quest("village_introduction"):
		complete_quest("village_introduction")

func handle_trader_interaction(npc: NPC):
	print(npc.dialogue_text)
	print("Trading interface would open here...")
	# TODO: Implement trading system

func handle_scout_interaction(npc: NPC):
	print(npc.dialogue_text)
	if not has_active_quest("syndicate_investigation"):
		start_quest("syndicate_investigation")

func handle_mystic_interaction(npc: NPC):
	print(npc.dialogue_text)
	# Offer spell upgrades or new spells
	if player_ref.gold >= 50:
		print("Learn new spell for 50 gold? (Not implemented)")

func handle_rebel_interaction(npc: NPC):
	print(npc.dialogue_text)
	if not has_active_quest("tribal_alliance"):
		start_quest("tribal_alliance")

func has_active_quest(quest_name: String) -> bool:
	for quest in active_quests:
		if quest["name"] == quest_name:
			return true
	return false

func _on_genre_gate_activated(gate: GenreGate):
	genre_gate_activated.emit(gate.target_genre)
	
	print("Activating genre gate: ", gate.gate_name)
	print("Switching to: ", GameManager.GameState.keys()[gate.target_genre])
	
	# Switch game state
	if GameManager.instance:
		GameManager.instance.change_game_state(gate.target_genre)

# World Area class
class WorldArea extends Area2D:
	var area_name: String
	var description: String
	var radius: float
	var is_active: bool = false
	
	var visual_indicator: Sprite2D
	
	signal area_entered(area_name: String)
	
	func _ready():
		# Create visual representation
		visual_indicator = Sprite2D.new()
		visual_indicator.scale = Vector2(radius/25, radius/25)
		visual_indicator.texture = PlaceholderTexture2D.new()
		visual_indicator.modulate = Color(0.5, 0.7, 1.0, 0.3)
		add_child(visual_indicator)
		
		# Create collision area
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = radius
		collision.shape = shape
		add_child(collision)
	
	func set_active(active: bool):
		is_active = active
		if active:
			visual_indicator.modulate = Color(0.7, 1.0, 0.7, 0.5)
		else:
			visual_indicator.modulate = Color(0.5, 0.7, 1.0, 0.3)

# NPC class
class NPC extends Area2D:
	var npc_name: String
	var npc_type: String
	var dialogue_text: String
	
	var sprite: Sprite2D
	var name_label: Label
	
	signal npc_interacted(npc: NPC)
	
	func _ready():
		# Create visual representation
		sprite = Sprite2D.new()
		sprite.scale = Vector2(30, 40)
		sprite.texture = PlaceholderTexture2D.new()
		
		# Color code by NPC type
		match npc_type:
			"village_elder":
				sprite.modulate = Color.BROWN
			"trader":
				sprite.modulate = Color.GOLD
			"scout":
				sprite.modulate = Color.GREEN
			"mystic":
				sprite.modulate = Color.PURPLE
			"rebel":
				sprite.modulate = Color.DARK_RED
			_:
				sprite.modulate = Color.WHITE
		
		add_child(sprite)
		
		# Name label
		name_label = Label.new()
		name_label.text = npc_name
		name_label.position = Vector2(-30, -60)
		name_label.add_theme_font_size_override("font_size", 10)
		add_child(name_label)
		
		# Collision for interaction
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(30, 40)
		collision.shape = shape
		add_child(collision)
		
		# Connect interaction
		input_event.connect(_on_input_event)
	
	func _on_input_event(viewport, event, shape_idx):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			npc_interacted.emit(self)

# Genre Gate class
class GenreGate extends Area2D:
	var gate_name: String
	var description: String
	var target_genre: GameManager.GameState
	var is_unlocked: bool = true
	
	var gate_sprite: Sprite2D
	var gate_label: Label
	
	signal gate_activated(gate: GenreGate)
	
	func _ready():
		# Create visual representation
		gate_sprite = Sprite2D.new()
		gate_sprite.scale = Vector2(60, 80)
		gate_sprite.texture = PlaceholderTexture2D.new()
		
		# Color code by genre
		match target_genre:
			GameManager.GameState.FIGHTING:
				gate_sprite.modulate = Color.RED
			GameManager.GameState.PUZZLE:
				gate_sprite.modulate = Color.BLUE
			GameManager.GameState.STRATEGY:
				gate_sprite.modulate = Color.GREEN
			GameManager.GameState.MINIGOLF:
				gate_sprite.modulate = Color.YELLOW
			_:
				gate_sprite.modulate = Color.WHITE
		
		add_child(gate_sprite)
		
		# Gate label
		gate_label = Label.new()
		gate_label.text = gate_name
		gate_label.position = Vector2(-50, -100)
		gate_label.add_theme_font_size_override("font_size", 12)
		add_child(gate_label)
		
		# Collision for activation
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(60, 80)
		collision.shape = shape
		add_child(collision)
		
		# Connect activation
		input_event.connect(_on_input_event)
	
	func _on_input_event(viewport, event, shape_idx):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if is_unlocked:
				gate_activated.emit(self)
			else:
				print("Gate is locked!")