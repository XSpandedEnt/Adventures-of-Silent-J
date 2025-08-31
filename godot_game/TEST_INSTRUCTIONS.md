# Testing Instructions for Silent J Multi-Genre Game

## How to Test the Game

### Prerequisites
- Godot 4.3 game engine installed
- Open the project by loading `/app/godot_game/project.godot`

### Basic Testing Procedure

#### 1. **Game Startup**
- Press F5 in Godot editor to run the game
- Verify the main scene loads with:
  - Blue player character (Silent J) in center
  - UI showing game state, player stats, and controls
  - Colored gates around the world (Red, Blue, Green, Yellow)

#### 2. **Movement and Controls**
- Test movement with E/D/S/F keys (Up/Down/Left/Right)
- Verify character moves smoothly and camera follows
- Check animation changes based on movement direction
- Test spell casting: J (Fireball), K (Lightning)
- Verify mana consumption and cooldowns work

#### 3. **Character Stats System**
- Press P to display character stats in console
- Cast spells and verify mana decreases
  - Fireball costs 20 mana
  - Lightning costs 15 mana
- Verify damage calculations:
  - Fireball: 5 × wisdom + 15
  - Lightning: 3 × wisdom

#### 4. **RPG Mode (Default)**
- Walk around the world and interact with:
  - NPCs (colored rectangles with name labels)
  - World areas (large colored circles)
- Click on NPCs to see interaction messages in console
- Verify area transitions display area information

#### 5. **Fighting Mode**
- Click on RED gate to enter Fighting Mode
- Verify:
  - Arena boundaries appear
  - AI opponent spawns (red character)
  - Player can cast spells at opponent
  - Combat continues until one character reaches 0 health
  - Experience and gold rewards on victory
  - Automatic return to RPG mode after fight

#### 6. **Puzzle Mode**
- Click on BLUE gate to enter Puzzle Mode
- Test different puzzle types:
  - Tile rotation puzzles
  - Pattern matching
  - Sequence memory
- Verify:
  - Timer counts down from 180 seconds
  - Attempts counter works (starts at 3)
  - Puzzle completion gives rewards
  - Failed attempts reduce counter

#### 7. **Strategy Mode**
- Click on GREEN gate to enter Strategy Mode
- Verify:
  - 3x3 grid of bases appears
  - Player owns 2 bases (blue), enemy owns 2 (red), rest neutral (gray)
  - Resource display shows Gold, Mana Shards, Troops
  - Turn system works (Player turn → Enemy turn)
  - Base clicking and troop management
  - Victory condition at 70% base control

#### 8. **Mini-Golf Mode**
- Click on YELLOW gate to enter Mini-Golf Mode
- Test:
  - Ball positioning at start
  - Mouse aiming system (yellow line)
  - Power charging (hold and release left click)
  - Ball physics and obstacle interaction
  - Hole completion detection
  - 3-hole course progression
  - Scoring system (par calculation)

### Expected Console Output

During testing, you should see debug messages like:
```
GameManager initialized
Player initialized: Health: 100, Mana: 100, Strength: 7, Wisdom: 5
RPG Mode activated
Fireball cast! Damage: 40 (burn effect: 15 every 5 sec)
Entered area: Starting Village
Quest started: Welcome to the Village
Fighting Mode activated
AI Decision: AGGRESSIVE
Player Victory!
```

### Performance Checks

- **Frame Rate**: Should maintain 60 FPS during normal gameplay
- **Memory**: No significant memory leaks during mode transitions
- **Responsiveness**: UI and controls should feel immediate
- **State Persistence**: Player stats should carry between game modes

### Common Issues to Check

1. **Mode Transitions**: All genre gates should work without errors
2. **Player Stats**: Stats should persist and update correctly
3. **AI Behavior**: Fighting mode AI should move and cast spells
4. **Physics**: Mini-golf ball should respond to force properly
5. **UI Updates**: All displays should refresh when values change

### Advanced Testing

#### Faction System
- Perform actions that change karma
- Verify faction relationships update
- Test different karma thresholds

#### Leveling System  
- Use console commands or modify starting XP to test level-ups
- Verify spell unlocking at appropriate levels
- Check exponential XP requirements

#### Edge Cases
- Test with 0 mana (spells should not cast)
- Test with 0 health (death and respawn)
- Test mode switching during active gameplay
- Test extreme stat values

### Debugging Tools

- Use Godot's debugger and remote inspector
- Console output provides detailed game state information
- Player stats accessible via P key
- All interactions logged to console

### Success Criteria

✅ All 5 game modes load and function  
✅ Player movement and spell casting work  
✅ AI opponents behave intelligently  
✅ Puzzle mechanics function correctly  
✅ Strategy mode has working turn system  
✅ Mini-golf physics work properly  
✅ Mode transitions are seamless  
✅ Character progression system works  
✅ Faction relationships update correctly  
✅ No critical errors or crashes  

This comprehensive testing should verify all major systems are working as intended in the Silent J multi-genre game.