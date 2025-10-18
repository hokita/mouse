//
//  ShellGameScene.swift
//  mouse
//
//  Created by Assistant on 2025/10/18.
//

import SpriteKit

class ShellGameScene: SKScene {

    private var shells: [SKShapeNode] = []
    private var ball: SKShapeNode!
    private var ballHiddenUnder: Int = -1

    private var scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var instructionLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private var backLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    private var score = 0
    private var isShuffling = false
    private var isShowingResult = false
    private var hasGuessed = false

    private let shellCount = 3
    private let shellWidth: CGFloat = 80
    private let shellHeight: CGFloat = 60

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.15, blue: 0.2, alpha: 1.0)

        setupLabels()
        setupBackButton()
        setupShells()
        startNewRound()
    }

    private func setupLabels() {
        scoreLabel.fontSize = 24
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.position = CGPoint(x: 16, y: size.height - 16)
        scoreLabel.text = "Score: 0"
        addChild(scoreLabel)

        instructionLabel.fontSize = 20
        instructionLabel.position = CGPoint(x: size.width/2, y: size.height - 80)
        instructionLabel.text = "Watch carefully..."
        instructionLabel.fontColor = .systemCyan
        addChild(instructionLabel)
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

    private func setupShells() {
        let spacing = shellWidth + 40
        let startX = (size.width - CGFloat(shellCount - 1) * spacing) / 2
        let shellY = size.height * 0.45

        for i in 0..<shellCount {
            let shell = createShell()
            shell.position = CGPoint(x: startX + CGFloat(i) * spacing, y: shellY)
            shell.name = "shell_\(i)"
            shell.zPosition = 10
            shells.append(shell)
            addChild(shell)
        }

        // Create ball
        ball = SKShapeNode(circleOfRadius: 15)
        ball.fillColor = .systemRed
        ball.strokeColor = .white
        ball.lineWidth = 2
        ball.zPosition = 5
        ball.alpha = 0
        addChild(ball)
    }

    private func createShell() -> SKShapeNode {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -shellWidth/2, y: -shellHeight/2))
        path.addLine(to: CGPoint(x: -shellWidth/2 + 10, y: shellHeight/2))
        path.addLine(to: CGPoint(x: shellWidth/2 - 10, y: shellHeight/2))
        path.addLine(to: CGPoint(x: shellWidth/2, y: -shellHeight/2))
        path.close()

        let shell = SKShapeNode(path: path.cgPath)
        shell.fillColor = .systemTeal
        shell.strokeColor = .white
        shell.lineWidth = 3
        return shell
    }

    private func startNewRound() {
        hasGuessed = false
        isShowingResult = false
        ballHiddenUnder = Int.random(in: 0..<shellCount)

        // Show ball under random shell (at fixed height, hidden under the shell)
        let shellY = size.height * 0.45
        let ballY = shellY - shellHeight/2 + 10  // Ball sits inside/under the shell
        ball.position = CGPoint(x: getShellX(forSlot: ballHiddenUnder), y: ballY)
        ball.alpha = 1.0

        instructionLabel.text = "Watch the ball..."

        // Lift the shell to show the ball
        let revealShell = shells[ballHiddenUnder]
        let revealX = getShellX(forSlot: ballHiddenUnder)
        revealShell.run(SKAction.sequence([
            SKAction.move(to: CGPoint(x: revealX, y: shellY + 60), duration: 0.3),
            SKAction.wait(forDuration: 1.2),
            SKAction.move(to: CGPoint(x: revealX, y: shellY), duration: 0.3)
        ]))

        // Sequence: show ball -> hide ball -> shuffle -> ask for guess
        let showDuration = 1.8  // Wait for shell lift animation
        let hideDuration = 0.5

        run(SKAction.sequence([
            SKAction.wait(forDuration: showDuration),
            SKAction.run { [weak self] in
                self?.hideBall()
            },
            SKAction.wait(forDuration: hideDuration),
            SKAction.run { [weak self] in
                self?.shuffleShells()
            }
        ]))
    }

    private func hideBall() {
        ball.run(SKAction.fadeOut(withDuration: 0.3))
        instructionLabel.text = "Hiding..."
    }

    private func getShellX(forSlot slot: Int) -> CGFloat {
        let spacing = shellWidth + 40
        let startX = (size.width - CGFloat(shellCount - 1) * spacing) / 2
        return startX + CGFloat(slot) * spacing
    }

    private func shuffleShells() {
        isShuffling = true
        instructionLabel.text = "Follow the shell!"

        // Number of shuffle moves
        let moveCount = 6 + score / 2
        var shuffleSequence: [SKAction] = []
        let shellY = size.height * 0.45  // Keep Y position constant

        for _ in 0..<moveCount {
            let index1 = Int.random(in: 0..<shellCount)
            var index2 = Int.random(in: 0..<shellCount)
            while index2 == index1 {
                index2 = Int.random(in: 0..<shellCount)
            }

            // Compute expected positions based on grid
            let x1 = getShellX(forSlot: index2)  // Shell at index1 will move to slot index2
            let x2 = getShellX(forSlot: index1)  // Shell at index2 will move to slot index1

            let move1 = SKAction.run { [weak self] in
                self?.shells[index1].run(SKAction.move(to: CGPoint(x: x1, y: shellY), duration: 0.4))
                self?.shells[index2].run(SKAction.move(to: CGPoint(x: x2, y: shellY), duration: 0.4))
            }

            let swap = SKAction.run { [weak self] in
                guard let self = self else { return }
                self.shells.swapAt(index1, index2)
                if self.ballHiddenUnder == index1 {
                    self.ballHiddenUnder = index2
                } else if self.ballHiddenUnder == index2 {
                    self.ballHiddenUnder = index1
                }
            }

            shuffleSequence.append(SKAction.sequence([
                move1,
                SKAction.wait(forDuration: 0.4),
                swap
            ]))
        }

        run(SKAction.sequence(shuffleSequence + [
            SKAction.run { [weak self] in
                self?.isShuffling = false
                self?.instructionLabel.text = "Which shell has the ball?"
            }
        ]))
    }

    // MARK: - Input
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let location = t.location(in: self)
        let tappedNodes = nodes(at: location)

        // Check back button
        if tappedNodes.contains(where: { $0.name == "back_button" }) {
            goBackToMenu()
            return
        }

        // If showing result, tap anywhere to continue
        if isShowingResult {
            nextRound()
            return
        }

        // If shuffling, ignore
        if isShuffling {
            return
        }

        // Check which shell was tapped
        for (index, shell) in shells.enumerated() {
            if tappedNodes.contains(shell) {
                makeGuess(index: index)
                return
            }
        }
    }

    private func makeGuess(index: Int) {
        hasGuessed = true
        isShowingResult = true

        // Reveal the ball (update X position only, keep Y fixed)
        let shellY = size.height * 0.45
        let ballY = shellY - shellHeight/2 + 10  // Same height as initial position
        ball.position = CGPoint(x: getShellX(forSlot: ballHiddenUnder), y: ballY)
        ball.alpha = 1.0

        if index == ballHiddenUnder {
            // Correct guess! Lift only the guessed shell
            let liftedShell = shells[index]
            let currentX = getShellX(forSlot: index)
            liftedShell.run(SKAction.sequence([
                SKAction.move(to: CGPoint(x: currentX, y: shellY + 80), duration: 0.3),
                SKAction.wait(forDuration: 1.5),
                SKAction.move(to: CGPoint(x: currentX, y: shellY), duration: 0.3)
            ]))

            score += 1
            updateScore()
            instructionLabel.text = "Correct! 🎉 Tap to continue"
            instructionLabel.fontColor = .systemGreen
            run(SKAction.playSoundFileNamed("coin.caf", waitForCompletion: false))
        } else {
            // Wrong guess - lift both the guessed shell and the correct shell
            let guessedShell = shells[index]
            let guessedX = getShellX(forSlot: index)
            let correctShell = shells[ballHiddenUnder]
            let correctX = getShellX(forSlot: ballHiddenUnder)

            // Lift both shells simultaneously
            guessedShell.run(SKAction.sequence([
                SKAction.move(to: CGPoint(x: guessedX, y: shellY + 80), duration: 0.3),
                SKAction.wait(forDuration: 1.5),
                SKAction.move(to: CGPoint(x: guessedX, y: shellY), duration: 0.3)
            ]))

            correctShell.run(SKAction.sequence([
                SKAction.move(to: CGPoint(x: correctX, y: shellY + 80), duration: 0.3),
                SKAction.wait(forDuration: 1.5),
                SKAction.move(to: CGPoint(x: correctX, y: shellY), duration: 0.3)
            ]))

            instructionLabel.text = "Wrong! Try again - Tap to continue"
            instructionLabel.fontColor = .systemRed
            run(SKAction.playSoundFileNamed("gameover.caf", waitForCompletion: false))
        }
    }

    private func nextRound() {
        // Reset shells to original positions
        let spacing = shellWidth + 40
        let startX = (size.width - CGFloat(shellCount - 1) * spacing) / 2
        let shellY = size.height * 0.45

        for (i, shell) in shells.enumerated() {
            shell.run(SKAction.move(to: CGPoint(x: startX + CGFloat(i) * spacing, y: shellY), duration: 0.3))
        }

        instructionLabel.fontColor = .systemCyan

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in
                self?.startNewRound()
            }
        ]))
    }

    private func updateScore() {
        scoreLabel.text = "Score: \(score)"
    }

    private func goBackToMenu() {
        guard let view = self.view else { return }
        let menu = MenuScene(size: view.bounds.size)
        menu.scaleMode = .resizeFill
        view.presentScene(menu, transition: .push(with: .left, duration: 0.3))
    }
}
