# Silent J - Multi-Genre Game

**A 2D multi-genre wizard survival game set 100 years after alien invasion**

## Game Overview

Silent J is an ambitious multi-genre game that combines RPG, Fighting, Strategy, Puzzle, and Mini-Golf mechanics into a cohesive experience. Players control Silent J, a lightning/fire wizard surviving in a post-apocalyptic world divided between corporate syndicates and free tribes.

## Core Features

### Character System
- **Health**: 100 starting health
- **Mana**: 100 starting mana  
- **Strength**: Random 1-10 starting value
- **Wisdom**: Random 1-10 starting value
- **Karma**: Affects faction relationships
- **Gold**: Currency for upgrades and trading
- **Experience/Levels**: Exponential growth system (Level 2 at 100 XP, +10% each level, max level 70)

### Spell System
- **J Key - Fireball**: Damage = 5 × wisdom + 15 (burn effect: 15 damage every 5 seconds)
- **K Key - Lightning**: Damage = 3 × wisdom
- **L Key - Chaos**: Unlocked at level 5
- **N Key - Void Magic**: Unlocked at level 15

### Controls
- **Movement**: E (Up), D (Down), S (Left), F (Right)
- **Interact**: W
- **Character Stats**: P
- **Backpack**: I
- **Spells**: J, K, L, N

## Game Modes

### 1. RPG Mode (Main Hub)
- Explore different world areas
- Interact with NPCs and complete quests
- Manage faction relationships through karma system
- Access gates to other game modes

**World Areas:**
- Starting Village (peaceful survivors)
- Syndicate Outpost (corporate survivors)
- Tribal Camp (nomadic communities)
- Ruins of Old City (devastated urban areas)
- Mystic Grove (magical enhancement zone)

### 2. Fighting Mode
- 1v1 spell duels with AI opponents
- Arena-based combat with movement restrictions
- Win condition: Defeat opponent or survive time limit
- Rewards: Experience, gold, karma

### 3. Puzzle Mode
- **Tile Rotation**: Rotate tiles to match target pattern
- **Match Three**: Create matching sequences
- **Maze Solving**: Navigate from start to finish
- **Sequence Memory**: Memorize and repeat patterns
- **Color Pattern**: Recreate shown color arrangements

### 4. Strategy Mode
- Resource management (gold, mana shards, troops)
- Base capture and control
- Turn-based gameplay against AI
- Win condition: Control 70% of bases

### 5. Mini-Golf Mode
- Physics-based ball mechanics
- 3 holes with increasing difficulty
- Par-based scoring system
- Obstacle courses with strategic challenges

## Faction System

### Syndicates (Corporate Survivors)
- **Iron Syndicate**: Militant, prefers neutral/low karma
- **Tech Syndicate**: Peaceful, prefers positive karma

### Tribes (Free Communities)  
- **Green Tribes**: Cooperative, strongly prefers positive karma
- **Wanderer Tribes**: Neutral, unaffected by karma
- **Fire Clans**: Anarchist, prefers negative karma

## Technical Implementation

### Architecture
- **Built with**: Godot 4.3 using GDScript
- **Core Systems**: GameManager, FactionManager, WorldManager
- **Modular Design**: Each game mode is a separate scene/script
- **State Management**: Seamless transitions between genres

### Key Classes
- `Player`: Main character with stats, spells, and progression
- `GameManager`: Handles global game state transitions
- `FactionManager`: Manages relationships and karma effects
- `WorldManager`: Coordinates mode switching and world state
- `RPGMode`: Main exploration and quest system
- `FightingMode`: Combat arena with AI opponents
- `PuzzleMode`: Logic puzzle collection
- `StrategyMode`: Resource management and base capture
- `MiniGolfMode`: Physics-based golf mechanics

## Development Features

### Progression System
- Exponential experience requirements
- Spell unlocking at specific levels
- Stat growth on level up
- Karma-based faction relationships

### AI Systems
- **Fighting AI**: Dynamic behavior states (aggressive, defensive, retreating, casting)
- **Strategy AI**: Base management and tactical decisions
- **Adaptive Difficulty**: AI scales with player progress

### Visual Design
- Placeholder art using colored rectangles
- Color-coded systems (factions, game modes, UI elements)
- Animated character states (front_idle, side_idle, back_idle)
- Visual feedback for all interactions

## Installation & Running

1. **Open in Godot 4.3**: Load the `project.godot` file
2. **Run Project**: Press F5 or click the play button
3. **Controls**: Use ESDF for movement, mouse for interactions

## Project Structure

```
/godot_game/
├── project.godot              # Main project configuration
├── scenes/
│   ├── Main.tscn             # Main game scene
│   └── Player.tscn           # Player character scene
├── scripts/
│   ├── GameManager.gd        # Global game state management
│   ├── Player.gd             # Player character logic
│   ├── FactionManager.gd     # Faction relationship system
│   └── WorldManager.gd       # Mode switching coordination
├── genres/
│   ├── fighting/             # Combat mode implementation
│   ├── puzzle/               # Logic puzzle collection
│   ├── strategy/             # Resource management mode
│   ├── minigolf/             # Physics-based golf
│   └── rpg/                  # Main exploration mode
└── assets/                   # Game assets (sprites, sounds, fonts)
```

## Future Enhancements

- **Audio System**: Sound effects and background music
- **Visual Assets**: Custom sprites and animations  
- **Save/Load System**: Persistent game state
- **Extended Content**: More areas, quests, and challenges
- **Multiplayer**: Cooperative or competitive modes
- **Advanced AI**: More sophisticated opponent behaviors

## Credits

Built as part of the Silent J Multi-Genre Game project demonstrating integrated gameplay systems across multiple genres in a cohesive game world.