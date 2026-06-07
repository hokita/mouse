//
//  CheeseChaseScene.swift
//  mouse
//
//  A quick maze navigation game where you guide a mouse
//  through a maze to collect cheese before time runs out.
//

import SpriteKit

class CheeseChaseScene: SKScene {

    // Game state
    private var isGameActive = false
    private var level = 1
    private var totalScore = 0
    private var timeRemaining: TimeInterval = 30.0
    private var timer: Timer?

    // Grid settings
    private var gridSize = 7  // Start with 7x7
    private var tileSize: CGFloat = 0
    private var maze: [[Bool]] = []  // true = wall, false = path

    // Player and goal positions (grid coordinates)
    private var playerGridX = 0
    private var playerGridY = 0
    private var cheeseGridX = 0
    private var cheeseGridY = 0

    // Game objects
    private var playerNode: SKLabelNode!
    private var cheeseNode: SKLabelNode!
    private var mazeContainer: SKNode!

    // UI elements
    private var levelLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var timerLabel: SKLabelNode!
    private var backButton: SKLabelNode!

    // Touch tracking for swipe detection
    private var touchStartPosition: CGPoint?

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.95, green: 0.90, blue: 0.85, alpha: 1.0)  // Light tan/beige

        setupLabels()
        setupBackButton()
        setupMazeContainer()
        startNewLevel()
    }

    func setupLabels() {
        // Level and Score on same line (left and right)
        levelLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        levelLabel.fontSize = 24
        levelLabel.fontColor = .systemOrange
        levelLabel.text = "Level 1"
        levelLabel.position = CGPoint(x: 100, y: size.height - 100)
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.verticalAlignmentMode = .top
        levelLabel.zPosition = 50
        addChild(levelLabel)

        scoreLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .systemBrown
        scoreLabel.text = "Score: 0"
        scoreLabel.position = CGPoint(x: size.width - 100, y: size.height - 100)
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.zPosition = 50
        addChild(scoreLabel)

        // Timer centered on its own line below
        timerLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        timerLabel.fontSize = 40
        timerLabel.fontColor = .systemGreen
        timerLabel.text = "30"
        timerLabel.position = CGPoint(x: size.width / 2, y: size.height - 145)
        timerLabel.horizontalAlignmentMode = .center
        timerLabel.verticalAlignmentMode = .top
        timerLabel.zPosition = 50
        addChild(timerLabel)
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

    func setupMazeContainer() {
        mazeContainer = SKNode()
        mazeContainer.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        addChild(mazeContainer)
    }

    func startNewLevel() {
        // Clear previous maze
        mazeContainer.removeAllChildren()

        // Determine grid size based on level
        gridSize = 7 + (level * 2)  // 9, 11, 13, 15, 17

        // Calculate tile size to fit on screen
        let maxMazeSize = min(size.width, size.height) * 0.65
        tileSize = maxMazeSize / CGFloat(gridSize)

        // Generate maze
        generateMaze()

        // Place player at top-left area
        playerGridX = 1
        playerGridY = 1

        // Place cheese at bottom-right area
        cheeseGridX = gridSize - 2
        cheeseGridY = gridSize - 2

        // Ensure cheese position is on a path
        while maze[cheeseGridY][cheeseGridX] {
            cheeseGridX -= 1
            if cheeseGridX < gridSize / 2 {
                cheeseGridX = gridSize - 2
                cheeseGridY -= 1
            }
        }

        // Draw the maze
        drawMaze()

        // Create player and cheese
        createPlayer()
        createCheese()

        // Update UI
        levelLabel.text = "Level \(level)"
        updateScore()

        // Start timer — less time at higher levels
        let levelTimes: [Int: TimeInterval] = [1: 60, 2: 60, 3: 60, 4: 60, 5: 60]
        timeRemaining = levelTimes[level] ?? 12.0
        timerLabel.text = "\(Int(timeRemaining))"
        startTimer()

        isGameActive = true
    }

    func generateMaze() {
        // Initialize maze with all walls
        maze = Array(repeating: Array(repeating: true, count: gridSize), count: gridSize)

        // Simple maze generation: Create paths using recursive backtracking
        var stack: [(Int, Int)] = []
        let startX = 1
        let startY = 1

        maze[startY][startX] = false  // Create starting path
        stack.append((startX, startY))

        let directions = [(0, 2), (2, 0), (0, -2), (-2, 0)]  // Right, Down, Up, Left (step by 2)

        while !stack.isEmpty {
            let (currentX, currentY) = stack.last!
            var unvisitedNeighbors: [(Int, Int)] = []

            // Check all four directions
            for (dx, dy) in directions {
                let newX = currentX + dx
                let newY = currentY + dy

                // Check if neighbor is within bounds and is a wall (unvisited)
                if newX > 0 && newX < gridSize - 1 && newY > 0 && newY < gridSize - 1 && maze[newY][newX] {
                    unvisitedNeighbors.append((newX, newY))
                }
            }

            if !unvisitedNeighbors.isEmpty {
                // Choose random unvisited neighbor
                let (nextX, nextY) = unvisitedNeighbors.randomElement()!

                // Carve path to neighbor
                let wallX = currentX + (nextX - currentX) / 2
                let wallY = currentY + (nextY - currentY) / 2
                maze[wallY][wallX] = false
                maze[nextY][nextX] = false

                stack.append((nextX, nextY))
            } else {
                // Backtrack
                stack.removeLast()
            }
        }

        // Ensure edges are walls
        for i in 0..<gridSize {
            maze[0][i] = true
            maze[gridSize - 1][i] = true
            maze[i][0] = true
            maze[i][gridSize - 1] = true
        }

        // Add extra passages to create loops (multiple routes to the goal)
        var loopWalls: [(Int, Int)] = []
        for y in 1..<(gridSize - 1) {
            for x in 1..<(gridSize - 1) {
                guard maze[y][x] else { continue }
                if !maze[y][x - 1] && !maze[y][x + 1] {
                    loopWalls.append((x, y))
                } else if !maze[y - 1][x] && !maze[y + 1][x] {
                    loopWalls.append((x, y))
                }
            }
        }
        let removeCount = max(2, loopWalls.count / 6)
        for (wx, wy) in loopWalls.shuffled().prefix(removeCount) {
            maze[wy][wx] = false
        }
    }

    func drawMaze() {
        let startX = -CGFloat(gridSize) * tileSize / 2
        let startY = -CGFloat(gridSize) * tileSize / 2

        for y in 0..<gridSize {
            for x in 0..<gridSize {
                let tile = SKShapeNode(rectOf: CGSize(width: tileSize - 2, height: tileSize - 2), cornerRadius: 2)

                if maze[y][x] {
                    // Wall
                    tile.fillColor = SKColor.brown
                    tile.strokeColor = SKColor(red: 0.4, green: 0.2, blue: 0.0, alpha: 1.0)
                } else {
                    // Path
                    tile.fillColor = SKColor(red: 0.98, green: 0.95, blue: 0.90, alpha: 1.0)
                    tile.strokeColor = SKColor(red: 0.85, green: 0.80, blue: 0.75, alpha: 1.0)
                }

                tile.lineWidth = 1
                tile.position = CGPoint(
                    x: startX + CGFloat(x) * tileSize + tileSize / 2,
                    y: startY + CGFloat(y) * tileSize + tileSize / 2
                )

                mazeContainer.addChild(tile)
            }
        }
    }

    func createPlayer() {
        if playerNode != nil {
            playerNode.removeFromParent()
        }

        playerNode = SKLabelNode(text: "🐭")
        playerNode.fontSize = tileSize * 0.7
        playerNode.verticalAlignmentMode = .center
        playerNode.horizontalAlignmentMode = .center
        playerNode.zPosition = 10

        updatePlayerPosition(animated: false)
        mazeContainer.addChild(playerNode)
    }

    func createCheese() {
        if cheeseNode != nil {
            cheeseNode.removeFromParent()
        }

        cheeseNode = SKLabelNode(text: "🧀")
        cheeseNode.fontSize = tileSize * 0.6
        cheeseNode.verticalAlignmentMode = .center
        cheeseNode.horizontalAlignmentMode = .center
        cheeseNode.zPosition = 5

        let startX = -CGFloat(gridSize) * tileSize / 2
        let startY = -CGFloat(gridSize) * tileSize / 2
        cheeseNode.position = CGPoint(
            x: startX + CGFloat(cheeseGridX) * tileSize + tileSize / 2,
            y: startY + CGFloat(cheeseGridY) * tileSize + tileSize / 2
        )

        mazeContainer.addChild(cheeseNode)

        // Pulse animation
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        cheeseNode.run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])))
    }

    func updatePlayerPosition(animated: Bool) {
        let startX = -CGFloat(gridSize) * tileSize / 2
        let startY = -CGFloat(gridSize) * tileSize / 2
        let newPosition = CGPoint(
            x: startX + CGFloat(playerGridX) * tileSize + tileSize / 2,
            y: startY + CGFloat(playerGridY) * tileSize + tileSize / 2
        )

        if animated {
            let move = SKAction.move(to: newPosition, duration: 0.1)
            playerNode.run(move)
        } else {
            playerNode.position = newPosition
        }
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }

    func updateTimer() {
        guard isGameActive else { return }

        timeRemaining -= 0.1
        timerLabel.text = "\(Int(ceil(timeRemaining)))"

        // Color warning
        if timeRemaining <= 10 {
            timerLabel.fontColor = .systemRed
        } else {
            timerLabel.fontColor = .systemGreen
        }

        if timeRemaining <= 0 {
            handleTimeOut()
        }
    }

    func handleTimeOut() {
        isGameActive = false
        timer?.invalidate()

        run(SKAction.playSoundFileNamed("fail.mp3", waitForCompletion: false))

        // Show game over
        let gameOverLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = .systemRed
        gameOverLabel.text = "Time's Up!"
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)
        gameOverLabel.alpha = 0
        gameOverLabel.zPosition = 100
        addChild(gameOverLabel)

        let finalScoreLabel = SKLabelNode(fontNamed: "Arial")
        finalScoreLabel.fontSize = 28
        finalScoreLabel.fontColor = .systemBrown
        finalScoreLabel.text = "Final Score: \(totalScore)"
        finalScoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        finalScoreLabel.alpha = 0
        finalScoreLabel.zPosition = 100
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

    func checkWinCondition() {
        if playerGridX == cheeseGridX && playerGridY == cheeseGridY {
            handleWin()
        }
    }

    func handleWin() {
        isGameActive = false
        timer?.invalidate()

        run(SKAction.playSoundFileNamed("fanfare.mp3", waitForCompletion: false))

        // Calculate time bonus
        let timeBonus = Int(timeRemaining * 10)
        totalScore += timeBonus + (level * 50)

        // Cheese collection effect
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        cheeseNode.run(SKAction.sequence([scaleUp, SKAction.group([fadeOut]), remove]))

        // Advance to next level
        level += 1

        // Check if game complete (5 levels)
        if level > 5 {
            showVictory()
        } else {
            // Show level complete message
            let levelCompleteLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
            levelCompleteLabel.fontSize = 36
            levelCompleteLabel.fontColor = .systemGreen
            levelCompleteLabel.text = "Level Complete! +\(timeBonus + (level - 1) * 50)"
            levelCompleteLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
            levelCompleteLabel.alpha = 0
            levelCompleteLabel.zPosition = 100
            addChild(levelCompleteLabel)

            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            let wait = SKAction.wait(forDuration: 1.5)
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let remove = SKAction.removeFromParent()
            let nextLevel = SKAction.run { [weak self] in
                self?.startNewLevel()
            }

            levelCompleteLabel.run(SKAction.sequence([fadeIn, wait, fadeOut, remove, nextLevel]))
        }
    }

    func showVictory() {
        let victoryLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        victoryLabel.fontSize = 44
        victoryLabel.fontColor = .systemYellow
        victoryLabel.text = "All Levels Complete!"
        victoryLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)
        victoryLabel.alpha = 0
        victoryLabel.zPosition = 100
        addChild(victoryLabel)

        let finalScoreLabel = SKLabelNode(fontNamed: "Arial")
        finalScoreLabel.fontSize = 32
        finalScoreLabel.fontColor = .systemBrown
        finalScoreLabel.text = "Final Score: \(totalScore)"
        finalScoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        finalScoreLabel.alpha = 0
        finalScoreLabel.zPosition = 100
        addChild(finalScoreLabel)

        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        victoryLabel.run(fadeIn)
        finalScoreLabel.run(fadeIn)

        // Reset after delay
        let wait = SKAction.wait(forDuration: 3.0)
        let reset = SKAction.run { [weak self] in
            self?.resetGame()
        }
        run(SKAction.sequence([wait, reset]))
    }

    func updateScore() {
        scoreLabel.text = "Score: \(totalScore)"
    }

    func resetGame() {
        level = 1
        totalScore = 0

        // Remove any temporary labels
        for node in children {
            if node.zPosition == 100 {
                node.removeFromParent()
            }
        }

        updateScore()
        startNewLevel()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        // Check back button
        if tappedNodes.contains(where: { $0.name == "back_button" }) {
            timer?.invalidate()
            goBackToMenu()
            return
        }

        // Record touch start for swipe detection
        touchStartPosition = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isGameActive else { return }
        guard let touch = touches.first, let startPos = touchStartPosition else { return }

        let endPos = touch.location(in: self)
        let dx = endPos.x - startPos.x
        let dy = endPos.y - startPos.y

        // Determine swipe direction (reduced to 20 pixels for easier control)
        let minSwipeDistance: CGFloat = 20.0

        if abs(dx) > abs(dy) && abs(dx) > minSwipeDistance {
            // Horizontal swipe
            if dx > 0 {
                tryMove(dx: 1, dy: 0)  // Right
            } else {
                tryMove(dx: -1, dy: 0)  // Left
            }
        } else if abs(dy) > minSwipeDistance {
            // Vertical swipe
            if dy > 0 {
                tryMove(dx: 0, dy: 1)  // Up
            } else {
                tryMove(dx: 0, dy: -1)  // Down
            }
        } else if abs(dx) <= minSwipeDistance && abs(dy) <= minSwipeDistance {
            // Small movement - treat as tap, move in direction of player to tap location
            let playerScreenPos = playerNode.convert(playerNode.position, to: self)
            let tapInMaze = mazeContainer.convert(endPos, from: self)

            let tapDx = tapInMaze.x - playerNode.position.x
            let tapDy = tapInMaze.y - playerNode.position.y

            // Move in the dominant direction of the tap
            if abs(tapDx) > abs(tapDy) {
                tryMove(dx: tapDx > 0 ? 1 : -1, dy: 0)
            } else {
                tryMove(dx: 0, dy: tapDy > 0 ? 1 : -1)
            }
        }

        touchStartPosition = nil
    }

    func tryMove(dx: Int, dy: Int) {
        let newX = playerGridX + dx
        let newY = playerGridY + dy

        // Check bounds
        guard newX >= 0 && newX < gridSize && newY >= 0 && newY < gridSize else {
            return
        }

        // Check if not a wall
        guard !maze[newY][newX] else {
            // Optional: play collision sound
            return
        }

        // Move player
        playerGridX = newX
        playerGridY = newY
        updatePlayerPosition(animated: true)

        // Play movement sound
        run(SKAction.playSoundFileNamed("coin.caf", waitForCompletion: false))

        // Check win condition
        checkWinCondition()
    }

    func goBackToMenu() {
        let transition = SKTransition.push(with: .left, duration: 0.3)
        let menuScene = MenuScene(size: size)
        view?.presentScene(menuScene, transition: transition)
    }

    deinit {
        timer?.invalidate()
    }
}
