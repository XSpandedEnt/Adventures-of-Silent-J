extends Node

class_name FactionManager

# Faction types
enum FactionType {
	SYNDICATE_MILITANT,
	SYNDICATE_PEACEFUL,
	TRIBE_COOPERATIVE,
	TRIBE_NEUTRAL,
	TRIBE_ANARCHIST
}

# Faction relationship levels
enum RelationshipLevel {
	HOSTILE = -2,
	UNFRIENDLY = -1,
	NEUTRAL = 0,
	FRIENDLY = 1,
	ALLIED = 2
}

# Faction data structure
class Faction:
	var name: String
	var type: FactionType
	var relationship: RelationshipLevel
	var description: String
	
	func _init(n: String, t: FactionType, desc: String):
		name = n
		type = t
		relationship = RelationshipLevel.NEUTRAL
		description = desc

# All factions in the game
var factions: Array[Faction] = []

# Player's karma affects faction relationships
var player_karma: int = 0

# Signals
signal faction_relationship_changed(faction_name: String, new_level: RelationshipLevel)

func _ready():
	initialize_factions()
	print("FactionManager initialized with ", factions.size(), " factions")

func initialize_factions():
	# Initialize all factions
	factions.append(Faction.new("Iron Syndicate", FactionType.SYNDICATE_MILITANT, "Militaristic corporate survivors focused on control and order"))
	factions.append(Faction.new("Tech Syndicate", FactionType.SYNDICATE_PEACEFUL, "Technology-focused survivors trying to rebuild civilization"))
	factions.append(Faction.new("Green Tribes", FactionType.TRIBE_COOPERATIVE, "Peaceful tribes focused on sustainable living and cooperation"))
	factions.append(Faction.new("Wanderer Tribes", FactionType.TRIBE_NEUTRAL, "Nomadic tribes that remain neutral in conflicts"))
	factions.append(Faction.new("Fire Clans", FactionType.TRIBE_ANARCHIST, "Radical tribes that reject all forms of organized society"))
	
	print("Factions initialized:")
	for faction in factions:
		print("- ", faction.name, " (", FactionType.keys()[faction.type], ")")

func update_karma(new_karma: int):
	var old_karma = player_karma
	player_karma = new_karma
	
	# Update faction relationships based on karma changes
	update_faction_relationships_by_karma(old_karma, new_karma)

func update_faction_relationships_by_karma(old_karma: int, new_karma: int):
	var karma_change = new_karma - old_karma
	
	for faction in factions:
		var old_relationship = faction.relationship
		
		# Different faction types react differently to karma
		match faction.type:
			FactionType.SYNDICATE_MILITANT:
				# Militant syndicates prefer neutral/low karma
				if new_karma > 50:
					faction.relationship = RelationshipLevel.UNFRIENDLY
				elif new_karma < -20:
					faction.relationship = RelationshipLevel.FRIENDLY
				else:
					faction.relationship = RelationshipLevel.NEUTRAL
			
			FactionType.SYNDICATE_PEACEFUL:
				# Peaceful syndicates prefer positive karma
				if new_karma > 30:
					faction.relationship = RelationshipLevel.FRIENDLY
				elif new_karma < -30:
					faction.relationship = RelationshipLevel.UNFRIENDLY
				else:
					faction.relationship = RelationshipLevel.NEUTRAL
			
			FactionType.TRIBE_COOPERATIVE:
				# Cooperative tribes strongly prefer positive karma
				if new_karma > 20:
					faction.relationship = RelationshipLevel.ALLIED
				elif new_karma < -40:
					faction.relationship = RelationshipLevel.HOSTILE
				else:
					faction.relationship = RelationshipLevel.NEUTRAL
			
			FactionType.TRIBE_NEUTRAL:
				# Neutral tribes don't care much about karma
				if new_karma > 60 or new_karma < -60:
					faction.relationship = RelationshipLevel.UNFRIENDLY
				else:
					faction.relationship = RelationshipLevel.NEUTRAL
			
			FactionType.TRIBE_ANARCHIST:
				# Anarchist tribes prefer negative karma
				if new_karma < -20:
					faction.relationship = RelationshipLevel.FRIENDLY
				elif new_karma > 40:
					faction.relationship = RelationshipLevel.HOSTILE
				else:
					faction.relationship = RelationshipLevel.NEUTRAL
		
		# Emit signal if relationship changed
		if old_relationship != faction.relationship:
			print("Faction relationship changed: ", faction.name, " is now ", RelationshipLevel.keys()[faction.relationship])
			faction_relationship_changed.emit(faction.name, faction.relationship)

func get_faction_relationship(faction_name: String) -> RelationshipLevel:
	for faction in factions:
		if faction.name == faction_name:
			return faction.relationship
	return RelationshipLevel.NEUTRAL

func get_all_factions() -> Array[Faction]:
	return factions

func perform_faction_action(faction_name: String, action_karma_impact: int):
	# Perform an action that affects relationship with a specific faction
	var faction = get_faction_by_name(faction_name)
	if faction:
		var old_relationship = faction.relationship
		
		# Adjust relationship based on action
		var new_value = int(faction.relationship) + (action_karma_impact / 10)
		faction.relationship = clamp(new_value, RelationshipLevel.HOSTILE, RelationshipLevel.ALLIED) as RelationshipLevel
		
		if old_relationship != faction.relationship:
			print("Action changed relationship with ", faction_name, " to ", RelationshipLevel.keys()[faction.relationship])
			faction_relationship_changed.emit(faction_name, faction.relationship)

func get_faction_by_name(faction_name: String) -> Faction:
	for faction in factions:
		if faction.name == faction_name:
			return faction
	return null

func can_access_area(faction_name: String) -> bool:
	# Check if player can access faction-controlled areas
	var relationship = get_faction_relationship(faction_name)
	return relationship >= RelationshipLevel.NEUTRAL

func get_faction_dialogue_tone(faction_name: String) -> String:
	var relationship = get_faction_relationship(faction_name)
	match relationship:
		RelationshipLevel.HOSTILE:
			return "hostile"
		RelationshipLevel.UNFRIENDLY:
			return "unfriendly"
		RelationshipLevel.NEUTRAL:
			return "neutral"
		RelationshipLevel.FRIENDLY:
			return "friendly"
		RelationshipLevel.ALLIED:
			return "allied"
		_:
			return "neutral"