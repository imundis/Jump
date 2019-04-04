//
//  GameScene.swift
//  Jump
//
//  Created by guo on 2018/6/27.
//  Copyright © 2018年 guoshuai. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

enum GameStatus {
    case idle
    case running
    case over
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var cmManager: CMMotionManager? = CMMotionManager()  //重力感应控制器
    private var player: SKShapeNode?  //玩家
    private var stair: SKShapeNode?  //阶梯
    private var gameStauts: GameStatus = .idle //游戏状态
    //分数标签
    lazy var scoreLabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.fontSize = 16
        label.fontColor = .black
        label.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height-16)
        label.zPosition = 100
        return label
    }()
    //分数
    private var score: CGFloat? {
        didSet {
            self.scoreLabel.text = "Score:\(String(format: "%.2f", score!))"
        }
    }
    //开始标签
    lazy var startLabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = "Start"
        label.fontSize = 28
        label.fontColor = .black
        label.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
        return label
    }()
    //游戏结束标签
    lazy var gameOverLabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = "Game Over"
        label.fontSize = 28
        label.fontColor = .black
        return label
    }()
    
    let stair_width:CGFloat = 70
    let max_num:UInt32 = 3
    let impulse = CGVector(dx: 0, dy: 30)
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .white
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        
        self.player = SKShapeNode(circleOfRadius: 20)
        self.player?.strokeColor = .black
        self.player?.fillColor = .yellow
        self.player?.zPosition = 50
        self.player?.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        self.player?.physicsBody?.contactTestBitMask = (self.player?.physicsBody?.collisionBitMask)!
//        self.player?.physicsBody?.mass = 0.1
        
        self.stair = SKShapeNode(rectOf: CGSize(width: stair_width, height: 18), cornerRadius: 9)
        self.stair?.strokeColor = .black
        self.stair?.fillColor = .green
        
        if self.cmManager?.isAccelerometerAvailable == true {
            self.cmManager?.startAccelerometerUpdates()
        }
        
        self.shuffle()
    }
    
    func shuffle() {
        self.gameStauts = .idle
        self.removeAllChildren()
        self.addChild(self.startLabel)
    }
    
    func startGame() {
        self.gameStauts = .running
        self.startLabel.removeFromParent()
        
        self.createStairs(from: 0)
        
        self.player?.position = CGPoint(x: self.frame.size.width/2, y: 0)
        self.addChild(self.player!)
        self.player?.physicsBody?.applyImpulse(impulse)
        
        self.score = 0.0
        self.addChild(self.scoreLabel)
    }
    
    func gameOver() {
        self.gameStauts = .over
        self.isUserInteractionEnabled = false
        self.addChild(self.gameOverLabel)
        self.gameOverLabel.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height)
        self.gameOverLabel.zPosition = 150
        self.gameOverLabel.run(SKAction.move(by: CGVector(dx: 0, dy: -self.frame.size.height/2), duration: 0.5)) {
            self.isUserInteractionEnabled = true
        }
    }
    
    func playerUpdate() {
        let data: CMAccelerometerData? = self.cmManager?.accelerometerData
        var value = data?.acceleration.x
        if value == nil {
            value = 0
        }
        
        if fabs(value!) > 0.0 {
            let fvector = CGVector(dx: 100*CGFloat(value!), dy: 0)
            self.player?.physicsBody?.applyForce(fvector)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if self.gameStauts == .running {
            self.playerUpdate()
            
            if (self.player?.physicsBody?.velocity.dy)! > CGFloat.init(0) {
                for node in self.children where node.name == "stair" {
                    node.physicsBody = nil
                }
            } else {
                for node in self.children where node.name == "stair" {
                    node.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: -stair_width/2+9, y: 9), to: CGPoint(x: stair_width/2-9, y: 9))
                    node.physicsBody?.isDynamic = false
                }
            }
            
            if self.player!.position.x < CGFloat.init(0.0) {
                self.player!.position = CGPoint(x: self.frame.size.width-5, y: self.player!.position.y)
            } else if self.player!.position.x > self.frame.size.width {
                self.player!.position = CGPoint(x: 5, y: self.player!.position.y)
            }
            
            if self.player!.position.y > self.frame.size.height/2 {
                let distance = self.player!.position.y - self.frame.size.height/2
                var maxHeight: CGFloat = 0
                for node in self.children where node.name == "stair" {
                    node.position = CGPoint(x: node.position.x, y: node.position.y-distance)
                    if node.position.y < 0 {
                        node.removeFromParent()
                    }
                    if node.position.y > maxHeight {
                        maxHeight = node.position.y
                    }
                }
                self.createStairs(from: maxHeight+100)
                self.player?.position = CGPoint(x: (self.player?.position.x)!, y: self.frame.size.height/2)
                self.score! += distance
            } else if self.player!.position.y < CGFloat.init(0.0) {
                self.gameOver()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch self.gameStauts {
        case .idle:
            self.startGame()
            break
        case .over:
            self.shuffle()
            break
        case .running:
//            self.player?.physicsBody?.applyImpulse(impulse)
            break
        }
    }
    
    func createStairsByLine(_ y: CGFloat) {
        let rNum = (arc4random() % max_num) + 1
        var num = (arc4random() % rNum) + 1
        var lastX = self.frame.size.width - 25
        while (num > 0) {
            if let node = self.stair?.copy() as! SKShapeNode? {
                let size = UInt32.init(lastX) + UInt32.init(stair_width) / 2 - num * UInt32.init(stair_width)
                let pos = arc4random() % size
                node.position = CGPoint(x: lastX - CGFloat.init(pos), y: y)
                node.name = "stair"
                self.addChild(node)
                lastX = node.position.x - stair_width
            }
            num = num - 1
        }
    }
    
    func createStairs(from y: CGFloat) {
        var startLine = y
        while (startLine < self.frame.size.height) {
            createStairsByLine(startLine)
            startLine += CGFloat.init(100)
        }
    }
    
    func jumpAction() {
        self.player?.physicsBody?.applyImpulse(impulse)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        if self.gameStauts == .running {
            self.jumpAction()
        }
    }
    
}
