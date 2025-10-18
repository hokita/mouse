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

    // MARK: - Presenting
    static func present(on skView: SKView, size: CGSize? = nil) {
        let sceneSize = size ?? skView.bounds.size
        let scene = MenuScene(size: sceneSize)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene, transition: .fade(withDuration: 0.25))
    }

    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupUI()
        layoutUI()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutUI()
    }

    private func setupUI() {
        // Title
        titleLabel.text = "Arcade"
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
    }

    private func layoutUI() {
        let w = size.width
        let h = size.height

        titleLabel.position = CGPoint(x: w/2, y: h * 0.65)
        subtitleLabel.position = CGPoint(x: w/2, y: h * 0.56)

        game1Label.position = CGPoint(x: w/2, y: h * 0.42)
        game2Label.position = CGPoint(x: w/2, y: h * 0.34)
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
        }
    }

    private func startCollectCoins() {
        guard let view = self.view else { return }
        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        view.presentScene(scene, transition: .doorsOpenVertical(withDuration: 0.35))
    }

    private func startShellGame() {
        guard let view = self.view else { return }
        let scene = ShellGameScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        view.presentScene(scene, transition: .doorsOpenHorizontal(withDuration: 0.35))
    }
}
