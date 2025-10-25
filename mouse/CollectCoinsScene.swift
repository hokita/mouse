//
//  CollectCoinsScene.swift
//  mouse
//
//  Created by Hidetaka Okita on 2025/10/08.
//

import SpriteKit
import GameplayKit

class CollectCoinsScene: SKScene, SKPhysicsContactDelegate {

    private enum Physics: UInt32 {
        case player = 1
        case coin   = 2
        case enemy  = 4
        case edge   = 8
    }

    private var player: SKShapeNode!
    private var scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var stateLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var backLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var score = 0
    private var isGameOver = false

    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.categoryBitMask = Physics.edge.rawValue
        physicsBody?.collisionBitMask = 0

        setupLabels()
        setupPlayer()
        setupBackButton()
        startGame()
    }

    private func setupLabels() {
        scoreLabel.fontSize = 24
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.position = CGPoint(x: 16, y: size.height - 80)
        scoreLabel.text = "Score: 0"
        addChild(scoreLabel)

        stateLabel.fontSize = 28
        stateLabel.alpha = 0.0
        stateLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(stateLabel)
    }

    private func setupBackButton() {
        backLabel.text = "〈 Back"
        backLabel.fontSize = 20
        backLabel.fontColor = .systemBlue
        backLabel.horizontalAlignmentMode = .left
        backLabel.verticalAlignmentMode = .top
        backLabel.position = CGPoint(x: 16, y: size.height - 50)
        backLabel.name = "back_button"
        backLabel.zPosition = 10
        addChild(backLabel)
    }

    private func setupPlayer() {
        let radius: CGFloat = 18
        player = SKShapeNode(circleOfRadius: radius)
        player.fillColor = .white
        player.strokeColor = .clear
        player.position = CGPoint(x: size.width/2, y: size.height * 0.2)
        player.zPosition = 5

        player.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.categoryBitMask = Physics.player.rawValue
        player.physicsBody?.collisionBitMask = 0
        player.physicsBody?.contactTestBitMask = Physics.coin.rawValue | Physics.enemy.rawValue
        addChild(player)
    }

    private func startGame() {
        isGameOver = false
        score = 0
        updateScore()
        stateLabel.alpha = 0.0

        removeAllActions()
        // Start spawners
        let coinSpawner = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 0.4, withRange: 0.4),
            SKAction.run { [weak self] in self?.spawnCoin() }
        ]))
        let enemySpawner = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 1.2, withRange: 0.6),
            SKAction.run { [weak self] in self?.spawnEnemy() }
        ]))
        run(coinSpawner, withKey: "coinSpawner")
        run(enemySpawner, withKey: "enemySpawner")
    }

    private func gameOver() {
        guard !isGameOver else { return }
        isGameOver = true
        removeAction(forKey: "coinSpawner")
        removeAction(forKey: "enemySpawner")

        // Fade remaining falling objects
        enumerateChildNodes(withName: "coin") { node, _ in node.removeAllActions(); node.run(.fadeOut(withDuration: 0.2)) }
        enumerateChildNodes(withName: "enemy") { node, _ in node.removeAllActions(); node.run(.fadeOut(withDuration: 0.2)) }

        stateLabel.text = "Game Over — Tap to Restart"
        stateLabel.alpha = 1.0
    }

    private func updateScore() {
        scoreLabel.text = "Score: \(score)"
    }

    private func spawnCoin() {
        let r: CGFloat = 10
        let node = SKShapeNode(circleOfRadius: r)
        node.name = "coin"
        node.fillColor = .systemYellow
        node.strokeColor = .clear
        let x = CGFloat.random(in: r...(size.width - r))
        node.position = CGPoint(x: x, y: size.height + r)
        node.zPosition = 1

        let body = SKPhysicsBody(circleOfRadius: r)
        body.isDynamic = true
        body.affectedByGravity = false
        body.categoryBitMask = Physics.coin.rawValue
        body.collisionBitMask = 0
        body.contactTestBitMask = Physics.player.rawValue
        node.physicsBody = body
        addChild(node)

        // Motion
        let speed: CGFloat = CGFloat.random(in: 180...280)
        let duration = TimeInterval((node.position.y + 20) / speed)
        let move = SKAction.moveTo(y: -20, duration: duration)
        node.run(SKAction.sequence([move, .removeFromParent()]))
    }

    private func spawnEnemy() {
        let s: CGFloat = 90
        let node = SKShapeNode(rectOf: CGSize(width: s, height: s), cornerRadius: 4)
        node.name = "enemy"
        node.fillColor = .systemRed
        node.strokeColor = .clear
        let x = CGFloat.random(in: s...(size.width - s))
        node.position = CGPoint(x: x, y: size.height + s)
        node.zPosition = 2

        let body = SKPhysicsBody(rectangleOf: CGSize(width: s, height: s))
        body.isDynamic = true
        body.affectedByGravity = false
        body.categoryBitMask = Physics.enemy.rawValue
        body.collisionBitMask = 0
        body.contactTestBitMask = Physics.player.rawValue
        node.physicsBody = body
        addChild(node)

        // Motion
        let speed: CGFloat = CGFloat.random(in: 260...380)
        let duration = TimeInterval((node.position.y + 20) / speed)
        let move = SKAction.moveTo(y: -20, duration: duration)
        node.run(SKAction.sequence([move, .removeFromParent()]))
    }

    // MARK: - Input
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Back to menu if back button tapped
        if let t = touches.first {
            let location = t.location(in: self)
            let tappedNodes = nodes(at: location)
            if tappedNodes.contains(where: { $0.name == "back_button" }) {
                goBackToMenu()
                return
            }
        }
        
        if isGameOver {
            // Restart
            removeAllChildren()
            setupLabels()
            setupPlayer()
            setupBackButton()
            startGame()
            return
        }
        guard let t = touches.first else { return }
        movePlayer(t.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, !isGameOver else { return }
        movePlayer(t.location(in: self))
    }

    private func movePlayer(_ position: CGPoint) {
        let clampedX = max(16, min(size.width - 16, position.x))
        let clampedY = max(16, min(size.height - 16, position.y))
        player.run(SKAction.move(to: CGPoint(x: clampedX, y: clampedY), duration: 0.05))
    }

    // MARK: - Physics
    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA.categoryBitMask
        let b = contact.bodyB.categoryBitMask

        let playerMask = Physics.player.rawValue
        let coinMask = Physics.coin.rawValue
        let enemyMask = Physics.enemy.rawValue

        // Player & coin
        if (a == playerMask && b == coinMask) || (a == coinMask && b == playerMask) {
            if let node = (a == coinMask ? contact.bodyA.node : contact.bodyB.node) {
                node.removeFromParent()
            }
            score += 1
            updateScore()
            // Play coin collection sound
            run(SKAction.playSoundFileNamed("coin.caf", waitForCompletion: false))
            return
        }

        // Player & enemy
        if (a == playerMask && b == enemyMask) || (a == enemyMask && b == playerMask) {
            // Play boom sound
            run(SKAction.playSoundFileNamed("boom.mp3", waitForCompletion: false))
            gameOver()
            return
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Keep player inside the scene bounds just in case
        guard player != nil else { return }
        var p = player.position
        p.x = max(16, min(size.width - 16, p.x))
        p.y = max(16, min(size.height - 16, p.y))
        player.position = p

        // Keep back button anchored to top-left
        if backLabel.parent != nil {
            backLabel.position = CGPoint(x: 16, y: size.height - 50)
        }
    }

    private func goBackToMenu() {
        guard let view = self.view else { return }
        let menu = MenuScene(size: view.bounds.size)
        menu.scaleMode = .resizeFill
        view.presentScene(menu, transition: .push(with: .left, duration: 0.3))
    }
}
