# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mouse is an iOS arcade game collection built with SpriteKit. The app features a menu system with animated mouse backgrounds and four mini-games. Each game is implemented as a separate SKScene subclass.

## Build and Development Commands

### Building the Project
```bash
# Build for iOS Simulator (default: iPhone 16)
xcodebuild -scheme mouse -destination 'platform=iOS Simulator,name=iPhone 16' build

# Clean build
xcodebuild -scheme mouse -destination 'platform=iOS Simulator,name=iPhone 16' clean build

# List available schemes and targets
xcodebuild -list -project mouse.xcodeproj
```

### Running Tests
This project does not currently have tests configured.

## Architecture

### Scene Navigation Flow

The app uses SpriteKit's scene presentation system for navigation:

1. **GameViewController** (entry point)
   - Presents MenuScene on app launch
   - Configures SKView with debug settings (showsFPS, showsNodeCount)

2. **MenuScene** (main menu)
   - Displays four game options with animated mouse emoji background
   - Static method `present(on:size:)` for presenting from other scenes
   - Each game button triggers scene transition to respective game scene

3. **Game Scenes** (all inherit from SKScene)
   - CollectCoinsScene: Dodge-and-collect game with physics-based movement
   - ShellGameScene: Classic shell game with ball tracking
   - RockPaperScissorsScene: Rock-paper-scissors against computer
   - HowManyBallsScene: Count the number of balls displayed

4. **Back Navigation**
   - All game scenes include a "Back" button (top-left)
   - Returns to MenuScene via `MenuScene.present()` or direct scene initialization
   - Uses SKTransition effects (.push(with: .left, duration: 0.3))

### Physics System (CollectCoinsScene)

CollectCoinsScene implements SpriteKit physics with custom categories:
- Uses bitmasks for collision detection (player, coin, enemy, edge)
- Implements `SKPhysicsContactDelegate` for collision handling
- Physics bodies are dynamic but not affected by gravity (gravity = .zero)

### Game State Management

Games use simple boolean flags for state:
- `isGameOver` (CollectCoinsScene): Controls game loop and input handling
- `isShuffling`, `isShowingResult`, `hasGuessed` (ShellGameScene): Multi-phase round control
- `isShowingResult` (HowManyBallsScene, RockPaperScissorsScene): Prevents input during animations

### Sound Assets

Sound files are located in `mouse/Sounds/`:
- `coin.caf`: Coin collection / tie sound
- `boom.mp3`: Collision/explosion sound
- `fail.mp3`: Wrong answer / loss sound
- `fanfare.mp3`: Win / correct answer sound
- `gameover.caf`: Game over sound (currently unused)

Played via: `SKAction.playSoundFileNamed(filename, waitForCompletion: false)`

### Scene Transitions

Common transition patterns:
- Menu → Game: `.doorsOpenVertical`, `.doorsOpenHorizontal`, `.flipHorizontal`, `.fade`
- Game → Menu: `.push(with: .left, duration: 0.3)`
- Duration typically 0.25-0.35 seconds

## Code Patterns

### Scene Setup Pattern
All scenes follow this structure:
1. `didMove(to:)` - Main setup method
2. `setupLabels()` - Create and position UI labels
3. `setupBackButton()` - Add navigation back button
4. Game-specific setup methods (e.g., `setupPlayer()`, `setupShells()`)

### UI Positioning
Uses relative positioning based on scene size:
- Y positions: `size.height * percentage` (e.g., 0.65 for upper third)
- X positions: `size.width * percentage` or `size.width / divisions`
- Allows dynamic layout across different screen sizes

### Touch Handling
Standard pattern across all scenes:
```swift
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let location = touch.location(in: self)
    let tappedNodes = nodes(at: location)

    // Check back button first
    if tappedNodes.contains(where: { $0.name == "back_button" }) {
        goBackToMenu()
        return
    }

    // Game-specific touch handling...
}
```

### Animation Sequences
Uses `SKAction` sequences extensively:
- Combine `.wait`, `.run`, `.move`, `.fade` actions
- Group simultaneous actions with `.group`
- Chain sequences with `.sequence`
- Loop with `.repeatForever` or `.repeat(_:count:)`

## Project Structure

```
mouse/
├── AppDelegate.swift                  # iOS app lifecycle
├── GameViewController.swift           # Entry point, presents MenuScene
├── MenuScene.swift                    # Main menu with animated background
├── CollectCoinsScene.swift           # Dodge-and-collect game
├── ShellGameScene.swift              # Shell game implementation
├── RockPaperScissorsScene.swift      # RPS game
├── HowManyBallsScene.swift           # Ball counting game
├── Assets.xcassets/                  # App icons and assets
└── Sounds/                           # Game sound effects (.caf, .mp3)
```

## Common Modifications

### Adding a New Game
1. Create new `SKScene` subclass in `mouse/` directory
2. Implement standard setup pattern (labels, back button, game logic)
3. Add game option to `MenuScene.setupUI()` with unique name
4. Add touch handler in `MenuScene.touchesBegan()` for new game
5. Create transition method (e.g., `startNewGame()`)

### Modifying Game Difficulty
Key parameters to adjust:
- **CollectCoinsScene**: Spawn intervals (lines 94-100), fall speeds (lines 144, 170)
- **ShellGameScene**: Shuffle count (line 160: `6 + score / 2`), move duration (line 176: 0.4)
- **HowManyBallsScene**: Ball count range (line 80: `1...9`)

### Changing Colors/Themes
Color definitions use `SKColor` with system colors:
- Menu background: `SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)`
- Game labels: `.systemYellow`, `.systemTeal`, `.systemPurple`, `.systemOrange`
- Update in respective scene's setup methods
