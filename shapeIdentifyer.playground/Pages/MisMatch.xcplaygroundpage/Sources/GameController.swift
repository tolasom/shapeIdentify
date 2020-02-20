import Foundation
import SpriteKit
import AVFoundation

//setting up shape textures
var randomShapes = SKTexture(imageNamed: "Circle")
var selectShape = Int(arc4random_uniform(6))
let shapeTextures = [SKTexture(imageNamed: "Circle"),SKTexture(imageNamed: "Triangle"),SKTexture(imageNamed: "Hexagon"),SKTexture(imageNamed: "Octagon"),SKTexture(imageNamed: "Pentagon"),SKTexture(imageNamed: "Square")]
let shapeSounds = ["Circle.m4a","Triangle.m4a","Hexagon.m4a","Octagon.m4a","Pentagon.m4a","Square.m4a"]
var presentShape = shapeTextures[selectShape]
var shapeMatches = shapeTextures[selectShape]
var shapeAudio = shapeSounds[selectShape]

public func GameController() -> SKView {
    
    
    let initialLives: Int = 3
    let gameView = SKView(frame: CGRect(x: 0, y: 0, width: 400, height: 640))
    let scene = gameScene(size: CGSize(width: 400, height: 640))
    
    scene.initialLives = initialLives
    gameView.presentScene(scene)
    
    return gameView
}

class gameScene: SKScene, SKPhysicsContactDelegate{
    
    // game variables declaration
    let lifeLine = ["💔💔💔","❤️💔💔","❤️❤️💔","❤️❤️❤️"]
    var arrayOfShapes: [SKTexture] = [shapeMatches,randomShapes]
    let idOfShapes = ["shapeToMatch","randomShape"]
    let livesLabel = SKLabelNode(text: "LIVES: 💚💚💚")
    let scoreLabel = SKLabelNode(text: "SCORE: 00000")
    let currentShape = SKSpriteNode(texture: presentShape)
    var lives = 3
    var points = 0
    var initialLives = 0
    var matchSound = SKAction.playSoundFileNamed(shapeAudio, waitForCompletion: false)
    var misSound = SKAction.playSoundFileNamed("NegativePop.m4a", waitForCompletion: false)
    var shapeToMatch: SKTexture?
    var randomShapeTexture: SKTexture?
    // game motion variables
    var newShapeEach: TimeInterval = 0.5
    var gameSpeed: CGFloat = 5
    //State variables
    var timeOfLastShape: TimeInterval = 0.0
    var lastScene: TimeInterval = 0.0
    var isGameOver = false
    var shapeCount = 0
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.contactDelegate = self
        lives = initialLives
        
        //background
        let bgImg = SKSpriteNode(texture: SKTexture(imageNamed: "Background.jpg"))
        bgImg.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        self.addChild(bgImg)
        
        //scoreboard background
        let scoreBoard = SKSpriteNode(color: UIColor.black, size: CGSize(width: self.size.width, height: self.size.height / 20))
        scoreBoard.position = CGPoint(x: self.size.width / 2, y: self.size.height - 15)
        self.addChild(scoreBoard)
        
        //scoreboard elements
        livesLabel.fontName = "Marker Felt"
        livesLabel.fontColor = .white
        livesLabel.fontSize = 20
        livesLabel.horizontalAlignmentMode = .right
        livesLabel.position = CGPoint(x: self.size.width - 10, y: self.size.height - 25)
        self.addChild(livesLabel)
        scoreLabel.fontName = "Marker Felt"
        scoreLabel.fontColor = .white
        scoreLabel.fontSize = 20
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 10, y: self.size.height - 25)
        self.addChild(scoreLabel)
        
        //creating currentShape
        currentShape.name = "Rider"
        currentShape.position = CGPoint(x: self.size.width / 2, y: 70)
        currentShape.xScale = 0.9
        currentShape.yScale = 0.9
        currentShape.physicsBody = SKPhysicsBody(circleOfRadius: 50)
        currentShape.physicsBody!.affectedByGravity = false // Player doesn't fall
        currentShape.physicsBody!.isDynamic = false // and doesn't move when hit
        currentShape.physicsBody!.collisionBitMask = 0x0001 // 0b00000001
        currentShape.physicsBody!.categoryBitMask = 0x0000 // 0b00000000
        currentShape.physicsBody!.contactTestBitMask = 0x0001 // 0b00000001
        currentShape.physicsBody?.restitution = 0
        self.addChild(currentShape)
        
        //falling shapes
        let shape = SKShapeNode(rectOf: CGSize(width: self.size.width, height: 100))
        shape.name = "shape"
        shape.position = CGPoint(x: self.size.width / 2, y: -100)
        shape.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.size.width, height: 100))
        shape.physicsBody!.affectedByGravity = false
        shape.physicsBody!.isDynamic = false
        shape.physicsBody!.collisionBitMask = 0x0001
        shape.physicsBody!.categoryBitMask = 0x0002
        shape.physicsBody!.contactTestBitMask = 0x0001
        shape.physicsBody!.restitution = 0
        self.addChild(shape)
        
        //gravity
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: gameSpeed * -1)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for tch in touches{
            //check for gameover
            if isGameOver {
                isGameOver = false
                lives = initialLives
                newShapeEach = 0.5
                gameSpeed = 5
                self.physicsWorld.gravity.dy = -gameSpeed
                points = 0
                shapeCount = 0
                //reset player
                selectShape = Int(arc4random_uniform(6))
                arrayOfShapes[0] = shapeTextures[selectShape]
                currentShape.texture = shapeTextures[selectShape]
                currentShape.position = CGPoint(x: self.size.width / 2, y: 70)
                //sounds
                shapeAudio = shapeSounds[selectShape]
                matchSound = SKAction.playSoundFileNamed(shapeAudio, waitForCompletion: false)
                
                for node in self.children{
                    if node.name == "shapeToMatch" || node.name == "randomShape" || node.name == "GameLabels" {
                        node.removeFromParent()
                    }
                }
                
                self.physicsWorld.speed = 1
            }
            //currentShape position movement
            else {
                // move current shape to left side
                if tch.location(in: self).x < self.size.width * 0.5 {
                    if (currentShape.position.x >= self.size.width / 2.1) {
                        currentShape.run(SKAction.moveBy(x: self.size.width / -3, y: 0, duration: 0.2))
                    }
                }
                // move current shape to right side
                else {
                    if (currentShape.position.x <= self.size.width / 1.9) {
                        currentShape.run(SKAction.moveBy(x: self.size.width / 3, y: 0, duration: 0.2))
                    }
                }
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if (contact.bodyB.node?.name == "shapeToMatch" || contact.bodyB.node?.name == "randomShape") && contact.bodyA.node?.name == "Rider" {
            //print(gameSpeed)
            //shape matched correctly
            if contact.bodyB.node?.name == "shapeToMatch" {
                points += 100
                self.run(matchSound)
            }
            //incorrect match
            else {
                lives -= 1
                points -= 50
                self.run(misSound)
            }
            
            contact.bodyB.node?.removeFromParent()
        }
        //remove shape
        else if ((contact.bodyB.node?.name == "shapeToMatch" || contact.bodyB.node?.name == "randomShape") && contact.bodyA.node?.name == "shape") {
            contact.bodyB.node?.removeFromParent()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        //check for gameover
        if (lives <= 0 && !isGameOver){
            isGameOver = true
            self.physicsWorld.speed = 0.0
            
            //GameOver label
            let gameOverLabel = SKLabelNode(text: "GAME OVER")
            gameOverLabel.fontName = "Marker Felt"
            gameOverLabel.fontColor = .red
            gameOverLabel.fontSize = 75
            gameOverLabel.horizontalAlignmentMode = .center
            gameOverLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
            gameOverLabel.name = "GameLabels"
            self.addChild(gameOverLabel)
            
            //score label on scoreboard
            let pointsLabel = SKLabelNode(text: "YOUR SCORE")
            pointsLabel.fontName = "Avenir Next Condensed"
            pointsLabel.fontColor = .gray
            pointsLabel.fontSize = 25
            pointsLabel.horizontalAlignmentMode = .center
            pointsLabel.position = CGPoint(x: self.size.width / 2, y: (self.size.height / 4) + 60)
            pointsLabel.name = "GameLabels"
            self.addChild(pointsLabel)
            
            //score label on gameover
            let scoreHeading = SKLabelNode(text: "\(points)")
            scoreHeading.fontName = "Papyrus"
            scoreHeading.fontColor = .black
            scoreHeading.fontSize = 55
            scoreHeading.horizontalAlignmentMode = .center
            scoreHeading.position = CGPoint(x: self.size.width / 2, y: (self.size.height / 2) - 150)
            scoreHeading.name = "GameLabels"
            self.addChild(scoreHeading)
            
            // retryLabel
            let retryLabel = SKLabelNode(text: "TAP TO RETRY")
            retryLabel.fontName = "Optima"
            retryLabel.fontColor = .black
            retryLabel.fontSize = 30
            retryLabel.horizontalAlignmentMode = .center
            retryLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 8)
            retryLabel.name = "GameLabels"
            self.addChild(retryLabel)
            
            // GameOver sound
            self.run(SKAction.playSoundFileNamed("GameOver.m4a", waitForCompletion: true))
        }
        //if game is not over then update gamescene
        else {
            livesLabel.text = "LIVES: \(lifeLine[lives])"
            scoreLabel.text = "SCORE: \(points)"
            
            //update time since last shape generated
            timeOfLastShape += (currentTime - lastScene)
            
            //new shape time
            //print(newShapeEach)
            if timeOfLastShape >= newShapeEach {
                let randomTrack = arc4random_uniform(3)
                let shapeType = Int(arc4random_uniform(2))
                var shapeTypeTexture: SKTexture!
                var shapeName: String
                
                //increase game speed
                if shapeCount == 30 {
                    shapeCount = 0
                    gameSpeed += 4
                    self.physicsWorld.gravity.dy = -gameSpeed
                    //print(gameSpeed)
                }
                
                //type of shape
                if shapeType == 1{
                    var carTexture = Int(arc4random_uniform(6))
                    if carTexture == selectShape{
                        while carTexture == selectShape{
                                carTexture = Int(arc4random_uniform(6))
                        }
                    }
                    shapeTypeTexture = shapeTextures[carTexture]
                    shapeName = idOfShapes[shapeType]
                }
                else {
                    shapeTypeTexture = arrayOfShapes[shapeType]
                    shapeName = idOfShapes[shapeType]
                }
                
                // display shape on selected tracks
                switch randomTrack {
                case 0:
                    self.addChild(createNewShape(shapeTypeTexture, position: CGPoint(x: self.size.width / 6, y: self.size.height + 100), name: shapeName))
                case 1:
                    self.addChild(createNewShape(shapeTypeTexture, position: CGPoint(x: self.size.width / 2, y: self.size.height + 100), name: shapeName))
                case 2:
                    self.addChild(createNewShape(shapeTypeTexture, position: CGPoint(x: self.size.width * 0.833, y: self.size.height + 100), name: shapeName))
                default:
                    self.addChild(createNewShape(shapeTypeTexture, position: CGPoint(x: self.size.width / 2, y: self.size.height + 100), name: shapeName))
                }
    
                timeOfLastShape = 0
            }
        }
        
        //update lastscene
        lastScene = currentTime
    }
    
    func createNewShape(_ texture: SKTexture?, position: CGPoint, name: String) -> SKSpriteNode {
        let newShape = SKSpriteNode(texture: texture!)
        newShape.name = name
        newShape.xScale = 0.9
        newShape.yScale = 0.9
        newShape.position = position
        newShape.physicsBody = SKPhysicsBody(circleOfRadius: newShape.size.width / 2)
        newShape.physicsBody = SKPhysicsBody(circleOfRadius: newShape.size.width / 2)
        newShape.physicsBody!.collisionBitMask = 0x0000 // 0b00000000
        newShape.physicsBody!.categoryBitMask = 0x0003 // 0b00000011
        newShape.physicsBody!.contactTestBitMask = 0x0003 // 0b00000011
        newShape.physicsBody!.restitution = 0
        shapeCount += 1
        //print("Shape count: \(shapeCount)")
        return newShape
    }
    
}
