//
//  SweetStackScene.swift
//  mouse
//
//  A precision timing game where you stack falling desserts.
//  Tap at the perfect moment to place each dessert on your tower.
//  Miss the timing and your tower collapses!
//

import SpriteKit

class SweetStackScene: SKScene {

    // Game state
    private var isGameOver = false
    private var stackHeight = 0
    private var currentSpeed: CGFloat = 200.0  // Starting fall speed (pixels/second)
    private let speedIncrement: CGFloat = 30.0
    private let speedIncreaseInterval = 5  // Increase speed every 5 successful stacks

    // Game objects
    private var fallingDessert: SKLabelNode?
    private var stackedDesserts: [SKLabelNode] = []
    private var platform: SKNode!
    private var timingZone: SKShapeNode!

    // UI elements
    private var scoreLabel: SKLabelNode!
    private var instructionLabel: SKLabelNode!
    private var backButton: SKLabelNode!

    // Dessert emojis
    private let dessertEmojis = ["🍰", "🍩", "🧁", "🍪", "🎂", "🍮"]

    // Constants
    private let dessertSize: CGFloat = 60.0
    private let perfectThreshold: CGFloat = 10.0  // ±10 px for perfect
    private let goodThreshold: CGFloat = 25.0     // ±25 px for good
    private let platformHeight: CGFloat = 100.0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.95, green: 0.85, blue: 0.95, alpha: 1.0)  // Light pink/cream

        setupLabels()
        setupBackButton()
        setupPlatform()
        setupTimingZone()
        spawnNextDessert()
    }

    func setupLabels() {
        // Score label
        scoreLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = .systemPink
        scoreLabel.text = "Stack: 0"
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.85)
        addChild(scoreLabel)

        // Instruction label
        instructionLabel = SKLabelNode(fontNamed: "Arial")
        instructionLabel.fontSize = 20
        instructionLabel.fontColor = .systemPurple
        instructionLabel.text = "Tap to stack!"
        instructionLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        addChild(instructionLabel)
    }

    func setupBackButton() {
        backButton = SKLabelNode(fontNamed: "Arial-BoldMT")
        backButton.fontSize = 24
        backButton.fontColor = .systemGray
        backButton.text = "← Back"
        backButton.position = CGPoint(x: 80, y: size.height - 50)
        backButton.name = "back_button"
        addChild(backButton)
    }

    func setupPlatform() {
        // Visual platform at bottom
        platform = SKNode()
        platform.position = CGPoint(x: size.width / 2, y: platformHeight)

        let platformShape = SKShapeNode(rectOf: CGSize(width: 200, height: 20), cornerRadius: 5)
        platformShape.fillColor = .brown
        platformShape.strokeColor = .clear
        platform.addChild(platformShape)

        addChild(platform)
    }

    func setupTimingZone() {
        // Visual indicator showing the target zone
        timingZone = SKShapeNode(rectOf: CGSize(width: size.width, height: goodThreshold * 2))
        timingZone.strokeColor = SKColor.systemGreen.withAlphaComponent(0.3)
        timingZone.lineWidth = 2
        timingZone.fillColor = .clear
        updateTimingZonePosition()
        addChild(timingZone)
    }

    func updateTimingZonePosition() {
        let targetY = stackedDesserts.isEmpty ? platformHeight : stackedDesserts.last!.position.y + dessertSize
        timingZone.position = CGPoint(x: size.width / 2, y: targetY)
    }

    func spawnNextDessert() {
        guard !isGameOver else { return }

        // Random dessert emoji
        let randomEmoji = dessertEmojis.randomElement()!

        // Create falling dessert
        let dessert = SKLabelNode(text: randomEmoji)
        dessert.fontSize = dessertSize
        dessert.name = "falling_dessert"

        // Random X position but not too far from center
        let minX = size.width * 0.25
        let maxX = size.width * 0.75
        let randomX = CGFloat.random(in: minX...maxX)

        // Start from top
        dessert.position = CGPoint(x: randomX, y: size.height + 50)

        addChild(dessert)
        fallingDessert = dessert

        // Calculate fall duration based on current speed
        let distance = size.height + 50 - platformHeight
        let duration = TimeInterval(distance / currentSpeed)

        // Move down action
        let moveDown = SKAction.moveBy(x: 0, y: -size.height - 100, duration: duration)
        let missAction = SKAction.run { [weak self] in
            self?.handleMiss()
        }

        dessert.run(SKAction.sequence([moveDown, missAction]))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        // Check back button
        if tappedNodes.contains(where: { $0.name == "back_button" }) {
            goBackToMenu()
            return
        }

        // Check if game is over
        if isGameOver {
            return
        }

        // Handle tapping to stack
        if let dessert = fallingDessert {
            checkTiming(for: dessert)
        }
    }

    func checkTiming(for dessert: SKLabelNode) {
        let targetY = stackedDesserts.isEmpty ? platformHeight : stackedDesserts.last!.position.y + dessertSize
        let distance = abs(dessert.position.y - targetY)

        dessert.removeAllActions()

        if distance <= perfectThreshold {
            // Perfect placement!
            handlePerfectPlacement(dessert: dessert, targetY: targetY)
        } else if distance <= goodThreshold {
            // Good placement
            handleGoodPlacement(dessert: dessert, targetY: targetY)
        } else {
            // Miss - too early or too late
            handleMiss()
        }
    }

    func handlePerfectPlacement(dessert: SKLabelNode, targetY: CGFloat) {
        run(SKAction.playSoundFileNamed("fanfare.mp3", waitForCompletion: false))

        stackHeight += 10

        // Center the dessert perfectly
        dessert.position = CGPoint(x: size.width / 2, y: targetY)
        stackedDesserts.append(dessert)

        // Sparkle effect
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        dessert.run(SKAction.sequence([scaleUp, scaleDown]))

        // Update score
        updateScore()

        // Check for speed increase
        if stackedDesserts.count % speedIncreaseInterval == 0 {
            currentSpeed += speedIncrement
        }

        // Update timing zone and spawn next
        fallingDessert = nil
        updateTimingZonePosition()

        let wait = SKAction.wait(forDuration: 0.3)
        let spawn = SKAction.run { [weak self] in
            self?.spawnNextDessert()
        }
        run(SKAction.sequence([wait, spawn]))
    }

    func handleGoodPlacement(dessert: SKLabelNode, targetY: CGFloat) {
        run(SKAction.playSoundFileNamed("coin.caf", waitForCompletion: false))

        stackHeight += 5

        // Place with slight offset
        let offset = dessert.position.x - size.width / 2
        let clampedOffset = max(-30, min(30, offset))  // Limit offset
        dessert.position = CGPoint(x: size.width / 2 + clampedOffset, y: targetY)
        stackedDesserts.append(dessert)

        // Wobble effect
        let wobbleLeft = SKAction.rotate(byAngle: 0.1, duration: 0.1)
        let wobbleRight = SKAction.rotate(byAngle: -0.2, duration: 0.2)
        let wobbleBack = SKAction.rotate(byAngle: 0.1, duration: 0.1)
        dessert.run(SKAction.sequence([wobbleLeft, wobbleRight, wobbleBack]))

        // Update score
        updateScore()

        // Check for speed increase
        if stackedDesserts.count % speedIncreaseInterval == 0 {
            currentSpeed += speedIncrement
        }

        // Update timing zone and spawn next
        fallingDessert = nil
        updateTimingZonePosition()

        let wait = SKAction.wait(forDuration: 0.3)
        let spawn = SKAction.run { [weak self] in
            self?.spawnNextDessert()
        }
        run(SKAction.sequence([wait, spawn]))
    }

    func handleMiss() {
        guard !isGameOver else { return }

        isGameOver = true

        run(SKAction.playSoundFileNamed("fail.mp3", waitForCompletion: false))

        // Remove falling dessert if it exists
        fallingDessert?.removeFromParent()
        fallingDessert = nil

        // Collapse animation - stack falls apart
        for (index, dessert) in stackedDesserts.enumerated() {
            let delay = SKAction.wait(forDuration: TimeInterval(index) * 0.05)
            let randomX = CGFloat.random(in: -100...100)
            let fall = SKAction.moveBy(x: randomX, y: -size.height, duration: 0.8)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -CGFloat.pi...CGFloat.pi), duration: 0.8)
            let fadeOut = SKAction.fadeOut(withDuration: 0.8)
            let group = SKAction.group([fall, rotate, fadeOut])
            let remove = SKAction.removeFromParent()

            dessert.run(SKAction.sequence([delay, group, remove]))
        }

        // Show game over message
        let gameOverLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        gameOverLabel.fontSize = 36
        gameOverLabel.fontColor = .systemRed
        gameOverLabel.text = "Tower Collapsed!"
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 30)
        gameOverLabel.alpha = 0
        addChild(gameOverLabel)

        let finalScoreLabel = SKLabelNode(fontNamed: "Arial")
        finalScoreLabel.fontSize = 24
        finalScoreLabel.fontColor = .systemPurple
        finalScoreLabel.text = "Final Score: \(stackHeight)"
        finalScoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 30)
        finalScoreLabel.alpha = 0
        addChild(finalScoreLabel)

        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        gameOverLabel.run(fadeIn)
        finalScoreLabel.run(fadeIn)

        // Reset after delay
        let wait = SKAction.wait(forDuration: 2.5)
        let reset = SKAction.run { [weak self] in
            self?.resetGame()
        }
        run(SKAction.sequence([wait, reset]))
    }

    func updateScore() {
        scoreLabel.text = "Stack: \(stackHeight)"
    }

    func resetGame() {
        isGameOver = false
        stackHeight = 0
        currentSpeed = 200.0
        stackedDesserts.removeAll()

        // Remove all nodes except permanent UI
        for node in children {
            if node.name != "back_button" && node !== scoreLabel && node !== instructionLabel && node !== platform && node !== timingZone {
                node.removeFromParent()
            }
        }

        updateScore()
        updateTimingZonePosition()
        spawnNextDessert()
    }

    func goBackToMenu() {
        let transition = SKTransition.push(with: .left, duration: 0.3)
        let menuScene = MenuScene(size: size)
        view?.presentScene(menuScene, transition: transition)
    }
}
