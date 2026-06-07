# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mouse is an iOS arcade game collection built with SpriteKit. The app features a main menu with an animated mouse-emoji background and seven mini-games, each implemented as a separate `SKScene` subclass.

## Build Commands

```bash
# Build for iOS Simulator
xcodebuild -scheme mouse -destination 'platform=iOS Simulator,name=iPhone 16' build

# Clean build
xcodebuild -scheme mouse -destination 'platform=iOS Simulator,name=iPhone 16' clean build

# List schemes
xcodebuild -list -project mouse.xcodeproj
```

No tests are configured.

## Architecture

### Scene Navigation Flow

```
GameViewController → MenuScene → [any game scene] → MenuScene
```

- **GameViewController**: presents `MenuScene` on launch; configures `SKView` with `showsFPS`/`showsNodeCount`.
- **MenuScene**: lists all seven games; uses `MenuScene.present(on:size:)` static method when returning from a game.
- **Game scenes**: each has a "Back" button (name: `"back_button"`) that calls `goBackToMenu()`, transitioning back with `.push(with: .left, duration: 0.3)`.

### The Seven Games

| Scene | Mechanic | Key state flags |
|-------|----------|-----------------|
| `CollectCoinsScene` | Dodge enemies, collect coins; SpriteKit physics | `isGameOver` |
| `ShellGameScene` | Track ball under shuffling shells | `isShuffling`, `isShowingResult`, `hasGuessed` |
| `RockPaperScissorsScene` | RPS vs computer | `isShowingResult` |
| `HowManyBallsScene` | Count balls before time runs out | `isShowingResult` |
| `MemoryCardScene` | Flip/match 4 emoji pairs (8 cards) | `isProcessing`, `matchedPairs` |
| `SweetStackScene` | Tap to catch a falling dessert inside the timing zone | `isGameOver`, `stackHeight` |
| `CheeseChaseScene` | Swipe to navigate a mouse through a procedural maze | `isGameActive`, `level` (1–5) |

### Custom Node Class

`CardNode` (defined inside `MemoryCardScene.swift`) is an `SKNode` subclass that manages card flip animations by scaling `xScale` to 0 and back. It owns `value: String` and `isFlipped: Bool`.

### Timer vs SpriteKit Update Loop

Most games drive timing via `SKAction.wait` sequences. **CheeseChaseScene** is the exception — it uses a `Foundation.Timer` (`Timer.scheduledTimer`) for its 30-second countdown and invalidates it in `deinit`. Always call `timer?.invalidate()` before presenting another scene from `CheeseChaseScene`.

### Physics (CollectCoinsScene only)

Uses bitmask categories (player, coin, enemy, edge), `SKPhysicsContactDelegate`, and zero gravity. No other scene uses physics bodies.

### Sound

Files are in `mouse/Sounds/`. Played with `SKAction.playSoundFileNamed(_:waitForCompletion: false)`.

| File | Used for |
|------|----------|
| `coin.caf` | Coin collect, tie, card flip, movement step |
| `boom.mp3` | Collision/explosion |
| `fail.mp3` | Wrong answer, time-out |
| `fanfare.mp3` | Win, correct answer, match found |
| `gameover.caf` | Unused |

## Code Patterns

### Adding a New Game
1. Create `NewGameScene.swift` as an `SKScene` subclass in `mouse/`.
2. Follow the setup order in `didMove(to:)`: `setupLabels()` → `setupBackButton()` → game-specific setup.
3. Add a new `gameNLabel` in `MenuScene` and wire it in `setupUI()`, `layoutUI()`, and `touchesBegan(_:with:)`.
4. Use `.push(with: .left, duration: 0.3)` for back navigation; any `SKTransition` is fine for menu → game.

### UI Positioning
All positions are relative to `size`: `size.width * 0.5`, `size.height * 0.85`, etc. Never use hardcoded pixel values for primary layout.

### Touch Handling
```swift
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let location = touch.location(in: self)
    let tappedNodes = nodes(at: location)
    if tappedNodes.contains(where: { $0.name == "back_button" }) {
        goBackToMenu(); return
    }
    // game logic...
}
```

### Difficulty Knobs

- **CollectCoinsScene**: enemy/coin spawn intervals and fall speeds in the `spawnEnemies`/`spawnCoins` methods.
- **ShellGameScene**: shuffle count (`6 + score / 2`) and move duration (`0.4`) in the shuffle sequence.
- **HowManyBallsScene**: ball count range (`1...9`) in `setupBalls()`.
- **SweetStackScene**: `currentSpeed` (starts 200 px/s), `speedIncrement` (30), `speedIncreaseInterval` (every 5 stacks), `perfectThreshold` (±10 px), `goodThreshold` (±25 px).
- **CheeseChaseScene**: grid size grows each level (9×9 / 11×11 / 13×13 / 15×15 / 17×17), timer (60 s flat per level), 5 levels total.
