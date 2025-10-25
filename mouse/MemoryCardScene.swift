//
//  MemoryCardScene.swift
//  mouse
//
//  Created by Assistant on 2025/10/25.
//

import SpriteKit

class MemoryCardScene: SKScene {

    private var cards: [CardNode] = []
    private var firstSelectedCard: CardNode?
    private var secondSelectedCard: CardNode?
    private var matchedPairs = 0
    private var moves = 0
    private var isProcessing = false

    private var scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var instructionLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private var backLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    private let cardEmojis = ["🌸", "🌻", "🌹", "🌺"]
    private let cardWidth: CGFloat = 80
    private let cardHeight: CGFloat = 100

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 1.0)

        setupLabels()
        setupBackButton()
        setupCards()
    }

    private func setupLabels() {
        scoreLabel.fontSize = 24
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height - 200)
        scoreLabel.text = "Moves: 0"
        scoreLabel.fontColor = .white
        addChild(scoreLabel)

        instructionLabel.fontSize = 20
        instructionLabel.position = CGPoint(x: size.width/2, y: size.height - 150)
        instructionLabel.text = "Find all matching pairs!"
        instructionLabel.fontColor = .systemPink
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

    private func setupCards() {
        // Create pairs of cards (8 cards total = 4 pairs)
        var cardValues: [String] = []
        for emoji in cardEmojis {
            cardValues.append(emoji)
            cardValues.append(emoji)
        }

        // Shuffle cards
        cardValues.shuffle()

        // Grid layout: 4 columns x 2 rows
        let columns = 4
        let rows = 2
        let horizontalSpacing: CGFloat = 100
        let verticalSpacing: CGFloat = 120

        let totalWidth = CGFloat(columns - 1) * horizontalSpacing
        let totalHeight = CGFloat(rows - 1) * verticalSpacing
        let startX = (size.width - totalWidth) / 2
        let startY = (size.height - totalHeight) / 2 + 50

        for (index, value) in cardValues.enumerated() {
            let row = index / columns
            let col = index % columns

            let x = startX + CGFloat(col) * horizontalSpacing
            let y = startY + CGFloat(row) * verticalSpacing

            let card = CardNode(
                value: value,
                size: CGSize(width: cardWidth, height: cardHeight),
                position: CGPoint(x: x, y: y)
            )
            card.name = "card_\(index)"
            card.zPosition = 10
            cards.append(card)
            addChild(card)
        }
    }

    private func updateScore() {
        scoreLabel.text = "Moves: \(moves)"
    }

    private func checkForMatch() {
        guard let first = firstSelectedCard,
              let second = secondSelectedCard else { return }

        isProcessing = true

        if first.value == second.value {
            // Match found!
            matchedPairs += 1
            instructionLabel.text = "Match! 🎉"
            instructionLabel.fontColor = .systemGreen
            run(SKAction.playSoundFileNamed("fanfare.mp3", waitForCompletion: false))

            // Fade out matched cards after a delay
            let fadeDelay = SKAction.wait(forDuration: 0.5)
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            first.run(SKAction.sequence([fadeDelay, fadeOut]))
            second.run(SKAction.sequence([fadeDelay, fadeOut]))

            // Reset selection after delay
            run(SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.run { [weak self] in
                    self?.resetSelection()
                    self?.checkGameComplete()
                }
            ]))
        } else {
            // No match - flip back
            instructionLabel.text = "Try again!"
            instructionLabel.fontColor = .systemOrange
            run(SKAction.playSoundFileNamed("fail.mp3", waitForCompletion: false))

            run(SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.run { [weak self] in
                    first.flipDown()
                    second.flipDown()
                    self?.resetSelection()
                }
            ]))
        }
    }

    private func resetSelection() {
        firstSelectedCard = nil
        secondSelectedCard = nil
        isProcessing = false
        if matchedPairs < cardEmojis.count {
            instructionLabel.text = "Find all matching pairs!"
            instructionLabel.fontColor = .systemPink
        }
    }

    private func checkGameComplete() {
        if matchedPairs == cardEmojis.count {
            instructionLabel.text = "You Won! 🎊 Tap to restart"
            instructionLabel.fontColor = .systemYellow
            run(SKAction.playSoundFileNamed("coin.caf", waitForCompletion: false))
        }
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

        // Check if game is complete - restart
        if matchedPairs == cardEmojis.count {
            restartGame()
            return
        }

        // Don't allow interaction while processing
        if isProcessing {
            return
        }

        // Check if a card was tapped
        for card in cards {
            if tappedNodes.contains(card) {
                handleCardTap(card)
                return
            }
        }
    }

    private func handleCardTap(_ card: CardNode) {
        // Ignore if card is already flipped or matched
        if card.isFlipped || card.alpha < 1.0 {
            return
        }

        // Flip the card
        card.flipUp()

        if firstSelectedCard == nil {
            // First card selected
            firstSelectedCard = card
        } else if secondSelectedCard == nil && card !== firstSelectedCard {
            // Second card selected
            secondSelectedCard = card
            moves += 1
            updateScore()
            checkForMatch()
        }
    }

    private func restartGame() {
        // Remove all cards
        for card in cards {
            card.removeFromParent()
        }
        cards.removeAll()

        // Reset game state
        firstSelectedCard = nil
        secondSelectedCard = nil
        matchedPairs = 0
        moves = 0
        isProcessing = false

        // Reset labels
        updateScore()
        instructionLabel.text = "Find all matching pairs!"
        instructionLabel.fontColor = .systemPink

        // Setup new game
        setupCards()
    }

    private func goBackToMenu() {
        guard let view = self.view else { return }
        let menu = MenuScene(size: view.bounds.size)
        menu.scaleMode = .resizeFill
        view.presentScene(menu, transition: .push(with: .left, duration: 0.3))
    }
}

// MARK: - Card Node
class CardNode: SKNode {
    let value: String
    var isFlipped = false

    private let cardSize: CGSize
    private var cardBack: SKShapeNode!
    private var cardFront: SKShapeNode!
    private var emojiLabel: SKLabelNode!

    init(value: String, size: CGSize, position: CGPoint) {
        self.value = value
        self.cardSize = size
        super.init()

        self.position = position
        setupCard()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCard() {
        // Card back (face down)
        cardBack = SKShapeNode(rectOf: cardSize, cornerRadius: 8)
        cardBack.fillColor = .systemIndigo
        cardBack.strokeColor = .white
        cardBack.lineWidth = 3
        cardBack.zPosition = 1
        addChild(cardBack)

        // Add pattern to back
        let pattern = SKLabelNode(text: "?")
        pattern.fontSize = 50
        pattern.fontColor = .white
        pattern.verticalAlignmentMode = .center
        pattern.horizontalAlignmentMode = .center
        pattern.zPosition = 2
        cardBack.addChild(pattern)

        // Card front (face up)
        cardFront = SKShapeNode(rectOf: cardSize, cornerRadius: 8)
        cardFront.fillColor = .white
        cardFront.strokeColor = .systemIndigo
        cardFront.lineWidth = 3
        cardFront.zPosition = 1
        cardFront.alpha = 0
        addChild(cardFront)

        // Emoji on front
        emojiLabel = SKLabelNode(text: value)
        emojiLabel.fontSize = 50
        emojiLabel.verticalAlignmentMode = .center
        emojiLabel.horizontalAlignmentMode = .center
        emojiLabel.zPosition = 2
        cardFront.addChild(emojiLabel)
    }

    func flipUp() {
        guard !isFlipped else { return }
        isFlipped = true

        // Flip animation
        let scaleDown = SKAction.scaleX(to: 0.0, duration: 0.15)
        let scaleUp = SKAction.scaleX(to: 1.0, duration: 0.15)

        cardBack.run(SKAction.sequence([
            scaleDown,
            SKAction.run { [weak self] in
                self?.cardBack.alpha = 0
                self?.cardFront.alpha = 1
                self?.cardFront.xScale = 0.0
            },
            SKAction.run { [weak self] in
                self?.cardFront.run(scaleUp)
            }
        ]))

        run(SKAction.playSoundFileNamed("coin.caf", waitForCompletion: false))
    }

    func flipDown() {
        guard isFlipped else { return }
        isFlipped = false

        // Flip animation
        let scaleDown = SKAction.scaleX(to: 0.0, duration: 0.15)
        let scaleUp = SKAction.scaleX(to: 1.0, duration: 0.15)

        cardFront.run(SKAction.sequence([
            scaleDown,
            SKAction.run { [weak self] in
                self?.cardFront.alpha = 0
                self?.cardBack.alpha = 1
                self?.cardBack.xScale = 0.0
            },
            SKAction.run { [weak self] in
                self?.cardBack.run(scaleUp)
            }
        ]))
    }
}
