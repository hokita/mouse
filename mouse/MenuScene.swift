//
//  MenuScene.swift
//  mouse
//
//  Created by Assistant on 2025/10/08.
//

import SpriteKit

final class MenuScene: SKScene {

    private let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let subtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")

    private let game1Label = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let game2Label = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let game3Label = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let game4Label = SKLabelNode(fontNamed: "AvenirNext-Bold")

    // MARK: - Presenting
    static func present(on skView: SKView, size: CGSize? = nil) {
        let sceneSize = size ?? skView.bounds.size
        let scene = MenuScene(size: sceneSize)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene, transition: .fade(withDuration: 0.25))
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
        setupUI()
        layoutUI()
        startMouseAnimation()
    }

    private func startMouseAnimation() {
        // Spawn mice continuously
        let spawnAction = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.spawnMouse()
            },
            SKAction.wait(forDuration: 0.8)
        ])
        run(SKAction.repeatForever(spawnAction), withKey: "mouse_spawner")
    }

    private func spawnMouse() {
        // Create a mouse using emoji
        let mouse = SKLabelNode(text: "🐁")
        mouse.fontSize = CGFloat.random(in: 30...50)
        mouse.zPosition = -1 // Behind everything
        mouse.alpha = 0.6

        // Random starting position from edges
        let edge = Int.random(in: 0...3)
        switch edge {
        case 0: // Left
            mouse.position = CGPoint(x: -50, y: CGFloat.random(in: 0...size.height))
        case 1: // Right
            mouse.position = CGPoint(x: size.width + 50, y: CGFloat.random(in: 0...size.height))
        case 2: // Top
            mouse.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height + 50)
        default: // Bottom
            mouse.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: -50)
        }

        addChild(mouse)

        // Random destination
        let destX = CGFloat.random(in: 0...size.width)
        let destY = CGFloat.random(in: 0...size.height)
        let destination = CGPoint(x: destX, y: destY)

        // Calculate duration based on distance
        let dx = destination.x - mouse.position.x
        let dy = destination.y - mouse.position.y
        let distance = sqrt(dx * dx + dy * dy)
        let duration = TimeInterval(distance / 100)

        // Move and fade out
        let moveAction = SKAction.move(to: destination, duration: duration)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()

        mouse.run(SKAction.sequence([
            moveAction,
            SKAction.group([fadeOut, SKAction.wait(forDuration: 0.5)]),
            remove
        ]))
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutUI()
    }

    private func setupUI() {
        // Title
        titleLabel.text = "Mouse"
        titleLabel.fontSize = 44
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        addChild(titleLabel)

        // Subtitle
        subtitleLabel.text = "Choose a game"
        subtitleLabel.fontSize = 20
        subtitleLabel.fontColor = .lightGray
        subtitleLabel.horizontalAlignmentMode = .center
        subtitleLabel.verticalAlignmentMode = .center
        addChild(subtitleLabel)

        // Game 1
        game1Label.text = "▶︎ Collect Coins"
        game1Label.name = "game_collect_coins"
        game1Label.fontSize = 28
        game1Label.fontColor = .systemYellow
        game1Label.horizontalAlignmentMode = .center
        game1Label.verticalAlignmentMode = .center
        addChild(game1Label)

        // Game 2 - Shell Game
        game2Label.text = "▶︎ Shell Game"
        game2Label.name = "game_shell_game"
        game2Label.fontSize = 28
        game2Label.fontColor = .systemTeal
        game2Label.horizontalAlignmentMode = .center
        game2Label.verticalAlignmentMode = .center
        addChild(game2Label)

        // Game 3 - Rock Paper Scissors
        game3Label.text = "▶︎ Rock Paper Scissors"
        game3Label.name = "game_rps"
        game3Label.fontSize = 28
        game3Label.fontColor = .systemPurple
        game3Label.horizontalAlignmentMode = .center
        game3Label.verticalAlignmentMode = .center
        addChild(game3Label)

        // Game 4 - How Many Balls
        game4Label.text = "▶︎ How Many Balls"
        game4Label.name = "game_how_many_balls"
        game4Label.fontSize = 28
        game4Label.fontColor = .systemOrange
        game4Label.horizontalAlignmentMode = .center
        game4Label.verticalAlignmentMode = .center
        addChild(game4Label)
    }

    private func layoutUI() {
        let w = size.width
        let h = size.height

        titleLabel.position = CGPoint(x: w/2, y: h * 0.65)
        subtitleLabel.position = CGPoint(x: w/2, y: h * 0.56)

        game1Label.position = CGPoint(x: w/2, y: h * 0.42)
        game2Label.position = CGPoint(x: w/2, y: h * 0.34)
        game3Label.position = CGPoint(x: w/2, y: h * 0.26)
        game4Label.position = CGPoint(x: w/2, y: h * 0.18)
    }

    // MARK: - Input
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let location = t.location(in: self)
        let nodes = nodes(at: location)

        if nodes.contains(where: { $0.name == "game_collect_coins" }) {
            startCollectCoins()
        } else if nodes.contains(where: { $0.name == "game_shell_game" }) {
            startShellGame()
        } else if nodes.contains(where: { $0.name == "game_rps" }) {
            startRockPaperScissors()
        } else if nodes.contains(where: { $0.name == "game_how_many_balls" }) {
            startHowManyBalls()
        }
    }

    private func stopMouseAnimation() {
        removeAction(forKey: "mouse_spawner")
    }

    private func startCollectCoins() {
        stopMouseAnimation()
        guard let view = self.view else { return }
        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        view.presentScene(scene, transition: .doorsOpenVertical(withDuration: 0.35))
    }

    private func startShellGame() {
        stopMouseAnimation()
        guard let view = self.view else { return }
        let scene = ShellGameScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        view.presentScene(scene, transition: .doorsOpenHorizontal(withDuration: 0.35))
    }

    private func startRockPaperScissors() {
        stopMouseAnimation()
        guard let view = self.view else { return }
        let scene = RockPaperScissorsScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        view.presentScene(scene, transition: .flipHorizontal(withDuration: 0.35))
    }

    private func startHowManyBalls() {
        stopMouseAnimation()
        guard let view = self.view else { return }
        let scene = HowManyBallsScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        view.presentScene(scene, transition: .fade(withDuration: 0.35))
    }
}
