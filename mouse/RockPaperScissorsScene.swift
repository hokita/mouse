//
//  RockPaperScissorsScene.swift
//  mouse
//
//  Created by Assistant on 2025/10/18.
//

import SpriteKit

class RockPaperScissorsScene: SKScene {

    private enum Choice: String, CaseIterable {
        case rock = "✊"
        case paper = "✋"
        case scissors = "✌️"
    }

    private var scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var resultLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var playerChoiceLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private var computerChoiceLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private var instructionLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private var backLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    private var wins = 0
    private var losses = 0
    private var ties = 0

    private var rockButton: SKShapeNode!
    private var paperButton: SKShapeNode!
    private var scissorsButton: SKShapeNode!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.15, green: 0.1, blue: 0.2, alpha: 1.0)

        setupLabels()
        setupBackButton()
        setupButtons()
    }

    private func setupLabels() {
        scoreLabel.fontSize = 24
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height - 80)
        scoreLabel.text = "W: 0  L: 0  T: 0"
        addChild(scoreLabel)

        instructionLabel.fontSize = 20
        instructionLabel.position = CGPoint(x: size.width/2, y: size.height - 150)
        instructionLabel.text = "Choose your move!"
        instructionLabel.fontColor = .systemCyan
        addChild(instructionLabel)

        playerChoiceLabel.fontSize = 60
        playerChoiceLabel.position = CGPoint(x: size.width * 0.3, y: size.height * 0.55)
        playerChoiceLabel.text = "?"
        playerChoiceLabel.alpha = 0.5
        addChild(playerChoiceLabel)

        computerChoiceLabel.fontSize = 60
        computerChoiceLabel.position = CGPoint(x: size.width * 0.7, y: size.height * 0.55)
        computerChoiceLabel.text = "?"
        computerChoiceLabel.alpha = 0.5
        addChild(computerChoiceLabel)

        resultLabel.fontSize = 32
        resultLabel.position = CGPoint(x: size.width/2, y: size.height * 0.7)
        resultLabel.text = ""
        resultLabel.alpha = 0
        addChild(resultLabel)
    }

    private func setupBackButton() {
        backLabel.text = "〈 Back"
        backLabel.fontSize = 20
        backLabel.fontColor = .systemBlue
        backLabel.horizontalAlignmentMode = .left
        backLabel.verticalAlignmentMode = .top
        backLabel.position = CGPoint(x: 16, y: size.height - 50)
        backLabel.name = "back_button"
        backLabel.zPosition = 100
        addChild(backLabel)
    }

    private func setupButtons() {
        let buttonY = size.height * 0.3
        let buttonSize = CGSize(width: 100, height: 100)
        let buttonSpacing = size.width / 4

        // Rock button
        rockButton = createButton(emoji: Choice.rock.rawValue,
                                  position: CGPoint(x: buttonSpacing, y: buttonY),
                                  size: buttonSize)
        rockButton.name = "rock_button"
        addChild(rockButton)

        // Paper button
        paperButton = createButton(emoji: Choice.paper.rawValue,
                                   position: CGPoint(x: size.width/2, y: buttonY),
                                   size: buttonSize)
        paperButton.name = "paper_button"
        addChild(paperButton)

        // Scissors button
        scissorsButton = createButton(emoji: Choice.scissors.rawValue,
                                      position: CGPoint(x: size.width - buttonSpacing, y: buttonY),
                                      size: buttonSize)
        scissorsButton.name = "scissors_button"
        addChild(scissorsButton)
    }

    private func createButton(emoji: String, position: CGPoint, size: CGSize) -> SKShapeNode {
        let button = SKShapeNode(rectOf: size, cornerRadius: 20)
        button.fillColor = SKColor(white: 0.2, alpha: 1.0)
        button.strokeColor = .systemTeal
        button.lineWidth = 3
        button.position = position

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = emoji
        label.fontSize = 50
        label.verticalAlignmentMode = .center
        label.name = "emoji_label"
        button.addChild(label)

        return button
    }

    private func play(playerChoice: Choice) {
        // Disable buttons during animation
        isUserInteractionEnabled = false

        // Computer makes random choice
        let computerChoice = Choice.allCases.randomElement()!

        // Show choices
        playerChoiceLabel.text = playerChoice.rawValue
        playerChoiceLabel.alpha = 1.0

        // Animate computer choice reveal
        var revealCount = 0
        let revealAction = SKAction.repeat(SKAction.sequence([
            SKAction.run { [weak self] in
                self?.computerChoiceLabel.text = Choice.allCases.randomElement()!.rawValue
                self?.computerChoiceLabel.alpha = 1.0
            },
            SKAction.wait(forDuration: 0.15)
        ]), count: 8)

        computerChoiceLabel.run(SKAction.sequence([
            revealAction,
            SKAction.run { [weak self] in
                self?.computerChoiceLabel.text = computerChoice.rawValue
                self?.determineWinner(player: playerChoice, computer: computerChoice)
            }
        ]))
    }

    private func determineWinner(player: Choice, computer: Choice) {
        var result: String
        var color: SKColor
        var soundFile: String

        if player == computer {
            result = "Tie!"
            color = .systemYellow
            ties += 1
            soundFile = "coin.caf"
        } else if (player == .rock && computer == .scissors) ||
                  (player == .paper && computer == .rock) ||
                  (player == .scissors && computer == .paper) {
            result = "You Win!"
            color = .systemGreen
            wins += 1
            soundFile = "fanfare.mp3"
        } else {
            result = "You Lose!"
            color = .systemRed
            losses += 1
            soundFile = "fail.mp3"
        }

        resultLabel.text = result
        resultLabel.fontColor = color
        resultLabel.alpha = 1.0

        updateScore()
        run(SKAction.playSoundFileNamed(soundFile, waitForCompletion: false))

        // Reset after delay
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.resetRound()
            }
        ]))
    }

    private func resetRound() {
        playerChoiceLabel.text = "?"
        playerChoiceLabel.alpha = 0.5
        computerChoiceLabel.text = "?"
        computerChoiceLabel.alpha = 0.5
        resultLabel.alpha = 0
        instructionLabel.text = "Choose your move!"
        isUserInteractionEnabled = true
    }

    private func updateScore() {
        scoreLabel.text = "W: \(wins)  L: \(losses)  T: \(ties)"
    }

    // MARK: - Input
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        // Check back button
        if tappedNodes.contains(where: { $0.name == "back_button" }) {
            goBackToMenu()
            return
        }

        // Check choice buttons
        if tappedNodes.contains(where: { $0.name == "rock_button" }) {
            play(playerChoice: .rock)
        } else if tappedNodes.contains(where: { $0.name == "paper_button" }) {
            play(playerChoice: .paper)
        } else if tappedNodes.contains(where: { $0.name == "scissors_button" }) {
            play(playerChoice: .scissors)
        }
    }

    private func goBackToMenu() {
        guard let view = self.view else { return }
        let menu = MenuScene(size: view.bounds.size)
        menu.scaleMode = .resizeFill
        view.presentScene(menu, transition: .push(with: .left, duration: 0.3))
    }
}
