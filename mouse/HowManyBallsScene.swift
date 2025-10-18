//
//  HowManyBallsScene.swift
//  mouse
//
//  Created by Assistant on 2025/10/18.
//

import SpriteKit

class HowManyBallsScene: SKScene {

    private var scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var instructionLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private var resultLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var backLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    private var wins = 0
    private var losses = 0

    private var correctAnswer = 0
    private var balls: [SKShapeNode] = []
    private var answerButtons: [SKShapeNode] = []
    private var isShowingResult = false

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.05, green: 0.1, blue: 0.15, alpha: 1.0)

        setupLabels()
        setupBackButton()
        startNewRound()
    }

    private func setupLabels() {
        scoreLabel.fontSize = 24
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height - 80)
        scoreLabel.text = "Wins: 0  Losses: 0"
        addChild(scoreLabel)

        instructionLabel.fontSize = 20
        instructionLabel.position = CGPoint(x: size.width/2, y: size.height - 150)
        instructionLabel.text = "How many balls?"
        instructionLabel.fontColor = .systemCyan
        addChild(instructionLabel)

        resultLabel.fontSize = 32
        resultLabel.position = CGPoint(x: size.width/2, y: size.height * 0.55)
        resultLabel.text = ""
        resultLabel.alpha = 0
        resultLabel.zPosition = 100
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

    private func startNewRound() {
        isShowingResult = false
        resultLabel.alpha = 0
        instructionLabel.text = "How many balls?"
        instructionLabel.fontColor = .systemCyan

        // Clear previous balls and buttons
        balls.forEach { $0.removeFromParent() }
        balls.removeAll()
        answerButtons.forEach { $0.removeFromParent() }
        answerButtons.removeAll()

        // Generate random number of balls (1-9)
        correctAnswer = Int.random(in: 1...9)

        // Create and position balls randomly
        createBalls()

        // Wait a bit before showing answer options
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in
                self?.createAnswerButtons()
            }
        ]))
    }

    private func createBalls() {
        let ballRadius: CGFloat = 20
        let displayArea = CGRect(x: size.width * 0.1,
                                y: size.height * 0.25,
                                width: size.width * 0.8,
                                height: size.height * 0.35)

        for i in 0..<correctAnswer {
            let ball = SKShapeNode(circleOfRadius: ballRadius)
            ball.fillColor = .systemOrange
            ball.strokeColor = .white
            ball.lineWidth = 2
            ball.zPosition = 10

            // Random position with some spacing
            var position: CGPoint
            var attempts = 0
            repeat {
                position = CGPoint(
                    x: CGFloat.random(in: (displayArea.minX + ballRadius)...(displayArea.maxX - ballRadius)),
                    y: CGFloat.random(in: (displayArea.minY + ballRadius)...(displayArea.maxY - ballRadius))
                )
                attempts += 1
            } while attempts < 50 && balls.contains(where: { distance($0.position, position) < ballRadius * 2.5 })

            ball.position = position
            ball.alpha = 0
            addChild(ball)
            balls.append(ball)

            // Animate balls appearing
            ball.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.1),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.2),
                    SKAction.scale(to: 1.0, duration: 0.2)
                ])
            ]))
            ball.setScale(0.5)
        }
    }

    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }

    private func createAnswerButtons() {
        // Generate three options: one correct, two incorrect
        var options = [correctAnswer]

        // Add two different incorrect answers
        while options.count < 3 {
            let wrongAnswer = Int.random(in: 1...9)
            if !options.contains(wrongAnswer) {
                options.append(wrongAnswer)
            }
        }

        // Shuffle the options
        options.shuffle()

        let buttonWidth: CGFloat = 80
        let buttonHeight: CGFloat = 80
        let buttonY = size.height * 0.15
        let spacing = size.width / 4

        for (index, number) in options.enumerated() {
            let button = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 15)
            button.fillColor = SKColor(white: 0.2, alpha: 1.0)
            button.strokeColor = .systemBlue
            button.lineWidth = 3
            button.position = CGPoint(x: spacing * CGFloat(index + 1), y: buttonY)
            button.name = "answer_\(number)"
            button.zPosition = 20

            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = "\(number)"
            label.fontSize = 40
            label.verticalAlignmentMode = .center
            label.fontColor = .white
            label.name = "button_label"
            button.addChild(label)

            button.alpha = 0
            addChild(button)
            answerButtons.append(button)

            // Animate buttons appearing
            button.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(index) * 0.1),
                SKAction.fadeIn(withDuration: 0.2)
            ]))
        }
    }

    private func checkAnswer(_ answer: Int) {
        guard !isShowingResult else { return }
        isShowingResult = true

        let isCorrect = answer == correctAnswer

        if isCorrect {
            wins += 1
            resultLabel.text = "Correct! ✓"
            resultLabel.fontColor = .systemGreen
            run(SKAction.playSoundFileNamed("fanfare.mp3", waitForCompletion: false))
        } else {
            losses += 1
            resultLabel.text = "Wrong! It was \(correctAnswer)"
            resultLabel.fontColor = .systemRed
            run(SKAction.playSoundFileNamed("fail.mp3", waitForCompletion: false))
        }

        resultLabel.alpha = 1.0
        updateScore()

        // Highlight the correct answer
        for button in answerButtons {
            if button.name == "answer_\(correctAnswer)" {
                button.fillColor = .systemGreen
            } else if button.name == "answer_\(answer)" && !isCorrect {
                button.fillColor = .systemRed
            }
        }

        // Wait then start new round
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                self?.startNewRound()
            }
        ]))
    }

    private func updateScore() {
        scoreLabel.text = "Wins: \(wins)  Losses: \(losses)"
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

        // Check answer buttons
        if !isShowingResult {
            for node in tappedNodes {
                if let name = node.name, name.hasPrefix("answer_") {
                    let answerString = name.replacingOccurrences(of: "answer_", with: "")
                    if let answer = Int(answerString) {
                        checkAnswer(answer)
                        break
                    }
                }
            }
        }
    }

    private func goBackToMenu() {
        guard let view = self.view else { return }
        let menu = MenuScene(size: view.bounds.size)
        menu.scaleMode = .resizeFill
        view.presentScene(menu, transition: .push(with: .left, duration: 0.3))
    }
}
