import Foundation
import SpriteKit
import AVFoundation

//setting up element textures
var greenPoints = SKTexture(imageNamed: "goGreen")
var randomVehicle = SKTexture(imageNamed: "tempVehicle")
var boostUp = SKTexture(imageNamed: "boostCharge")
var myCar = SKTexture(imageNamed: "myCar")

public func gamePlay() -> SKView {
    
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
    let arrayOfElements: [SKTexture] = [greenPoints,randomVehicle,boostUp]
    let idOfObstacles = ["plusPoints","minusPoints","charge"]
    let livesLabel = SKLabelNode(text: "LIVES: 💚💚💚")
    let scoreLabel = SKLabelNode(text: "SCORE: 00000")
    let gamePlayer = SKSpriteNode(texture: myCar)
    var lives = 3
    var points = 0
    var initialLives = 0
    var vehicleCrashSound = SKAction.playSoundFileNamed("Crash.m4a", waitForCompletion: false)
    var pointGainSound = SKAction.playSoundFileNamed("Pop.m4a", waitForCompletion: false)
    var boostSound = SKAction.playSoundFileNamed("Boost.m4a", waitForCompletion: false)
    var greenPointTexture: SKTexture?
    var randomVehicleTexture: SKTexture?
    var boostUpTexture: SKTexture?
    // game motion variables
    var newObstacleEach: TimeInterval = 0.5
    var gameSpeed: CGFloat = 5
    //State variables
    var timeOfLastObstacle: TimeInterval = 0.0
    var lastScene: TimeInterval = 0.0
    var isGameOver = false
    var obstacleCount = 0
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.contactDelegate = self
        lives = initialLives
        
        //background
        let bgImg = SKSpriteNode(texture: SKTexture(imageNamed: "Highway"))
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
        
        //creating gameplayer
        gamePlayer.name = "Rider"
        gamePlayer.position = CGPoint(x: self.size.width / 2, y: 90)
        gamePlayer.xScale = 0.8
        gamePlayer.yScale = 0.8
        gamePlayer.physicsBody = SKPhysicsBody(circleOfRadius: 50)
        gamePlayer.physicsBody!.affectedByGravity = false // Player doesn't fall
        gamePlayer.physicsBody!.isDynamic = false // and doesn't move when hit
        gamePlayer.physicsBody!.collisionBitMask = 0x0001 // 0b00000001
        gamePlayer.physicsBody!.categoryBitMask = 0x0000 // 0b00000000
        gamePlayer.physicsBody!.contactTestBitMask = 0x0001 // 0b00000001
        gamePlayer.physicsBody?.restitution = 0
        self.addChild(gamePlayer)
        
        //falling obstacles
        let obs = SKShapeNode(rectOf: CGSize(width: self.size.width, height: 100))
        obs.name = "obs"
        obs.position = CGPoint(x: self.size.width / 2, y: -100)
        obs.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.size.width, height: 100))
        obs.physicsBody!.affectedByGravity = false
        obs.physicsBody!.isDynamic = false
        obs.physicsBody!.collisionBitMask = 0x0001
        obs.physicsBody!.categoryBitMask = 0x0002
        obs.physicsBody!.contactTestBitMask = 0x0001
        obs.physicsBody!.restitution = 0
        self.addChild(obs)
        
        //gravity
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: gameSpeed * -1)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for tch in touches{
            //check for gameover
            if isGameOver {
                isGameOver = false
                lives = initialLives
                newObstacleEach = 0.5
                gameSpeed = 5
                self.physicsWorld.gravity.dy = -gameSpeed
                points = 0
                obstacleCount = 0
                //reset player
                gamePlayer.position = CGPoint(x: self.size.width / 2, y: 90)
                
                for node in self.children{
                    if node.name == "plusPoints" || node.name == "minusPoints" || node.name == "GameLabels" {
                        node.removeFromParent()
                    }
                }
                
                self.physicsWorld.speed = 1
            }
            //gameplayer movement
            else {
                // move vehicle to left
                if tch.location(in: self).x < self.size.width * 0.5 {
                    if (gamePlayer.position.x >= self.size.width / 2.1) {
                        gamePlayer.run(SKAction.moveBy(x: self.size.width / -3, y: 0, duration: 0.2))
                    }
                }
                // move vehicle to right
                else {
                    if (gamePlayer.position.x <= self.size.width / 1.9) {
                        gamePlayer.run(SKAction.moveBy(x: self.size.width / 3, y: 0, duration: 0.2))
                    }
                }
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if (contact.bodyB.node?.name == "plusPoints" || contact.bodyB.node?.name == "minusPoints" || contact.bodyB.node?.name == "charge") && contact.bodyA.node?.name == "Rider" {
            //print(gameSpeed)
            // boostup
            if contact.bodyB.node?.name == "charge" {
                gameSpeed += 4
                self.physicsWorld.gravity.dy = -gameSpeed
                points += 150
                self.run(boostSound)
                print(gameSpeed)
                
                if gameSpeed >= 15 {
                    newObstacleEach = 0.3
                    print(newObstacleEach)
                }
            }
            //plusPoints
            else if contact.bodyB.node?.name == "plusPoints" {
                points += 100
                self.run(pointGainSound)
            }
            //minus points
            else {
                lives -= 1
                points -= 50
                self.run(vehicleCrashSound)
            }
            
            contact.bodyB.node?.removeFromParent()
        }
        else if ((contact.bodyB.node?.name == "plusPoints" || contact.bodyB.node?.name == "minusPoints" || contact.bodyB.node?.name == "charge") && contact.bodyA.node?.name == "obs") {
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
            gameOverLabel.fontColor = .white
            gameOverLabel.fontSize = 75
            gameOverLabel.horizontalAlignmentMode = .center
            gameOverLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
            gameOverLabel.name = "GameLabels"
            self.addChild(gameOverLabel)
            
            //score label on scoreboard
            let pointsLabel = SKLabelNode(text: "YOUR SCORE")
            pointsLabel.fontName = "Avenir Next Condensed"
            pointsLabel.fontColor = .white
            pointsLabel.fontSize = 25
            pointsLabel.horizontalAlignmentMode = .center
            pointsLabel.position = CGPoint(x: self.size.width / 2, y: (self.size.height / 4) + 60)
            pointsLabel.name = "GameLabels"
            self.addChild(pointsLabel)
            
            //score label on gameover
            let scoreHeading = SKLabelNode(text: "\(points)")
            scoreHeading.fontName = "DIN Condensed"
            scoreHeading.fontColor = .white
            scoreHeading.fontSize = 55
            scoreHeading.horizontalAlignmentMode = .center
            scoreHeading.position = CGPoint(x: self.size.width / 2, y: (self.size.height / 2) - 150)
            scoreHeading.name = "GameLabels"
            self.addChild(scoreHeading)
            
            // retryLabel
            let retryLabel = SKLabelNode(text: "TAP TO RETRY")
            retryLabel.fontName = "Optima"
            retryLabel.fontColor = .white
            retryLabel.fontSize = 30
            retryLabel.horizontalAlignmentMode = .center
            retryLabel.position = CGPoint(x: self.size.width / 2, y: self.size.height / 8)
            retryLabel.name = "GameLabels"
            self.addChild(retryLabel)
            
            // GameOver sound
            self.run(SKAction.playSoundFileNamed("GameOver.m4a", waitForCompletion: true))
        }
        //update gamescene
        else {
            
            livesLabel.text = "LIVES: \(lifeLine[lives])"
            scoreLabel.text = "SCORE: \(points)"
            
            //update time since last obstacle
            timeOfLastObstacle += (currentTime - lastScene)
            
            //new obstacle time
            //print(newObstacleEach)
            if timeOfLastObstacle >= newObstacleEach {
                let randomTrack = arc4random_uniform(3)
                let randomObstacle = Int(arc4random_uniform(2))
                let vehicleTextures = [SKTexture(imageNamed: "vehicle01"),SKTexture(imageNamed: "vehicle02"),SKTexture(imageNamed: "vehicle03"),SKTexture(imageNamed: "vehicle04"),SKTexture(imageNamed: "vehicle05"),SKTexture(imageNamed: "vehicle06"),SKTexture(imageNamed: "vehicle07"),SKTexture(imageNamed: "vehicle08"),SKTexture(imageNamed: "vehicle09"),SKTexture(imageNamed: "vehicle10")]
                var obstacleTexture: SKTexture!
                var obstacleName: String
                
                //type of obstacle
                if obstacleCount == 30 {
                    obstacleCount = 0
                    obstacleTexture = arrayOfElements[2]
                    obstacleName = idOfObstacles[2]
                }
                else {
                    if randomObstacle == 1{
                        let carTexture = Int(arc4random_uniform(10))
                        obstacleTexture = vehicleTextures[carTexture]
                        obstacleName = idOfObstacles[randomObstacle]
                    }
                    else {
                        obstacleTexture = arrayOfElements[randomObstacle]
                        obstacleName = idOfObstacles[randomObstacle]
                    }
                }
                
                // lanes
                switch randomTrack {
                case 0:
                    self.addChild(createObstacle(obstacleTexture, position: CGPoint(x: self.size.width / 6, y: self.size.height + 100), name: obstacleName))
                case 1:
                    self.addChild(createObstacle(obstacleTexture, position: CGPoint(x: self.size.width / 2, y: self.size.height + 100), name: obstacleName))
                case 2:
                    self.addChild(createObstacle(obstacleTexture, position: CGPoint(x: self.size.width * 0.833, y: self.size.height + 100), name: obstacleName))
                default:
                    self.addChild(createObstacle(obstacleTexture, position: CGPoint(x: self.size.width / 2, y: self.size.height + 100), name: obstacleName))
                }
    
                timeOfLastObstacle = 0
            }
        }
        
        //update lastscene
        lastScene = currentTime
    }
    
    func createObstacle(_ texture: SKTexture?, position: CGPoint, name: String) -> SKSpriteNode {
        let obstacle = SKSpriteNode(texture: texture!)
        obstacle.name = name
        obstacle.xScale = 0.8
        obstacle.yScale = 0.8
        obstacle.position = position
        obstacle.physicsBody = SKPhysicsBody(circleOfRadius: obstacle.size.width / 2)
        obstacle.physicsBody = SKPhysicsBody(circleOfRadius: obstacle.size.width / 2)
        obstacle.physicsBody!.collisionBitMask = 0x0000 // 0b00000000
        obstacle.physicsBody!.categoryBitMask = 0x0003 // 0b00000011
        obstacle.physicsBody!.contactTestBitMask = 0x0003 // 0b00000011
        obstacle.physicsBody!.restitution = 0
        obstacleCount += 1
        //print("obstacle count: \(obstacleCount)")
        return obstacle
    }
    
}
