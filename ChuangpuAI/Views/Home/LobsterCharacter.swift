import SpriteKit
import Foundation

/// 龙虾角色 - 骨骼动画版
class LobsterCharacter: SKNode {
    let agentId: String
    let agentName: String
    let baseColor: UIColor
    
    // 骨骼部件
    private let bodyNode = SKNode()
    private let headNode = SKNode()
    private let leftClawNode = SKNode()
    private let rightClawNode = SKNode()
    
    // 状态
    var currentState: String = "idle"
    private var idleActionIndex: Int = 0
    
    private let idleActions = ["stand","sleep","coffee","exercise","chat","think","phone","dance","stretch"]
    private let idleBubbles = ["😌 待命","💤 打盹","☕ 咖啡","🏋️ 健身","💬 聊天","🤔 思考","📱 刷手机","💃 蹦迪","🙆 伸懒腰"]
    
    private var nameLabel: SKLabelNode!
    private var bubbleLabel: SKLabelNode!
    private var statusDot: SKShapeNode!
    private var zzzNode: SKLabelNode!
    
    init(agentId: String, name: String, color: UIColor) {
        self.agentId = agentId
        self.agentName = name
        self.baseColor = color
        super.init()
        buildBody()
        startIdleLoop()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func buildBody() {
        // 身体
        let body = SKShapeNode(ellipseOf: CGSize(width: 28, height: 36))
        body.fillColor = baseColor
        body.strokeColor = baseColor.darker()
        body.lineWidth = 1.5
        bodyNode.addChild(body)
        
        // 工服
        let uniform = SKShapeNode(rectOf: CGSize(width: 22, height: 14), cornerRadius: 3)
        uniform.fillColor = UIColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 0.4)
        uniform.strokeColor = .clear
        uniform.position = CGPoint(x: 0, y: -2)
        body.addChild(uniform)
        
        // 头
        headNode.position = CGPoint(x: 0, y: 22)
        bodyNode.addChild(headNode)
        
        let head = SKShapeNode(ellipseOf: CGSize(width: 26, height: 22))
        head.fillColor = baseColor
        head.strokeColor = baseColor.darker()
        head.lineWidth = 1.5
        headNode.addChild(head)
        
        // 眼睛
        let lEye = SKShapeNode(ellipseOf: CGSize(width: 7, height: 7))
        lEye.fillColor = .white; lEye.strokeColor = .clear
        lEye.position = CGPoint(x: -5, y: 2)
        head.addChild(lEye)
        
        let rEye = SKShapeNode(ellipseOf: CGSize(width: 7, height: 7))
        rEye.fillColor = .white; rEye.strokeColor = .clear
        rEye.position = CGPoint(x: 5, y: 2)
        head.addChild(rEye)
        
        let lPupil = SKShapeNode(circleOfRadius: 2)
        lPupil.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1)
        lPupil.strokeColor = .clear
        lPupil.position = CGPoint(x: 0.5, y: -0.5)
        lEye.addChild(lPupil)
        
        let rPupil = SKShapeNode(circleOfRadius: 2)
        rPupil.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1)
        rPupil.strokeColor = .clear
        rPupil.position = CGPoint(x: 0.5, y: -0.5)
        rEye.addChild(rPupil)
        
        // 触角
        let lAnt = SKShapeNode()
        let lPath = CGMutablePath()
        lPath.move(to: CGPoint(x: -6, y: 8))
        lPath.addLine(to: CGPoint(x: -12, y: 18))
        lAnt.path = lPath
        lAnt.strokeColor = baseColor.darker()
        lAnt.lineWidth = 2
        head.addChild(lAnt)
        
        let rAnt = SKShapeNode()
        let rPath = CGMutablePath()
        rPath.move(to: CGPoint(x: 6, y: 8))
        rPath.addLine(to: CGPoint(x: 12, y: 18))
        rAnt.path = rPath
        rAnt.strokeColor = baseColor.darker()
        rAnt.lineWidth = 2
        head.addChild(rAnt)
        
        // 嘴
        let mouth = SKShapeNode(ellipseOf: CGSize(width: 5, height: 3))
        mouth.fillColor = baseColor.darker()
        mouth.strokeColor = .clear
        mouth.position = CGPoint(x: 0, y: -5)
        head.addChild(mouth)
        
        // 钳子
        leftClawNode.position = CGPoint(x: -16, y: 6)
        leftClawNode.zRotation = 0.2
        bodyNode.addChild(leftClawNode)
        
        let lClaw = SKShapeNode(ellipseOf: CGSize(width: 12, height: 8))
        lClaw.fillColor = baseColor
        lClaw.strokeColor = baseColor.darker()
        lClaw.lineWidth = 1
        leftClawNode.addChild(lClaw)
        
        rightClawNode.position = CGPoint(x: 16, y: 6)
        rightClawNode.zRotation = -0.2
        bodyNode.addChild(rightClawNode)
        
        let rClaw = SKShapeNode(ellipseOf: CGSize(width: 12, height: 8))
        rClaw.fillColor = baseColor
        rClaw.strokeColor = baseColor.darker()
        rClaw.lineWidth = 1
        rightClawNode.addChild(rClaw)
        
        // 尾巴
        let tail = SKShapeNode()
        let tPath = CGMutablePath()
        tPath.move(to: CGPoint(x: -8, y: -18))
        tPath.addQuadCurve(to: CGPoint(x: 0, y: -28), control: CGPoint(x: -4, y: -24))
        tPath.addQuadCurve(to: CGPoint(x: 8, y: -18), control: CGPoint(x: 4, y: -24))
        tail.path = tPath
        tail.fillColor = baseColor
        tail.strokeColor = baseColor.darker()
        tail.lineWidth = 1
        bodyNode.addChild(tail)
        
        // 腿
        let ll = SKShapeNode()
        let llp = CGMutablePath()
        llp.move(to: CGPoint(x: -8, y: -12)); llp.addLine(to: CGPoint(x: -14, y: -22))
        ll.path = llp; ll.strokeColor = baseColor; ll.lineWidth = 2.5
        bodyNode.addChild(ll)
        
        let rl = SKShapeNode()
        let rlp = CGMutablePath()
        rlp.move(to: CGPoint(x: 8, y: -12)); rlp.addLine(to: CGPoint(x: 14, y: -22))
        rl.path = rlp; rl.strokeColor = baseColor; rl.lineWidth = 2.5
        bodyNode.addChild(rl)
        
        addChild(bodyNode)
        
        // 名字
        nameLabel = SKLabelNode(text: agentName)
        nameLabel.fontSize = 9
        nameLabel.fontColor = baseColor
        nameLabel.fontName = "PingFangSC-Medium"
        nameLabel.position = CGPoint(x: 0, y: -38)
        addChild(nameLabel)
        
        // 状态灯
        statusDot = SKShapeNode(circleOfRadius: 3)
        statusDot.fillColor = .gray
        statusDot.strokeColor = .clear
        statusDot.position = CGPoint(x: 18, y: 30)
        addChild(statusDot)
        
        // 气泡
        bubbleLabel = SKLabelNode(text: "")
        bubbleLabel.fontSize = 9
        bubbleLabel.fontColor = UIColor(red: 0.63, green: 0.63, blue: 0.75, alpha: 1)
        bubbleLabel.fontName = "PingFangSC-Medium"
        bubbleLabel.position = CGPoint(x: 0, y: 40)
        bubbleLabel.isHidden = true
        addChild(bubbleLabel)
        
        // ZZZ
        zzzNode = SKLabelNode(text: "💤")
        zzzNode.fontSize = 10
        zzzNode.position = CGPoint(x: 14, y: 32)
        zzzNode.isHidden = true
        addChild(zzzNode)
    }
    
    // MARK: - 空闲循环（用SKAction代替Timer）
    
    private func startIdleLoop() {
        currentState = "idle"
        switchToRandomIdle()
    }
    
    private func switchToRandomIdle() {
        guard currentState == "idle" else { return }
        
        // 停掉所有动作
        bodyNode.removeAllActions()
        headNode.removeAllActions()
        leftClawNode.removeAllActions()
        rightClawNode.removeAllActions()
        
        // 随机选一个
        idleActionIndex = Int.random(in: 0..<idleActions.count)
        let action = idleActions[idleActionIndex]
        let bubble = idleBubbles[idleActionIndex]
        
        bubbleLabel.text = bubble
        bubbleLabel.isHidden = false
        zzzNode.isHidden = true
        statusDot.fillColor = .gray
        
        // 重置骨骼姿态
        bodyNode.zRotation = 0
        headNode.zRotation = 0
        leftClawNode.zRotation = 0.2
        rightClawNode.zRotation = -0.2
        
        switch action {
        case "stand":
            let breathe = SKAction.sequence([
                SKAction.scaleY(to: 1.03, duration: 1.5),
                SKAction.scaleY(to: 1.0, duration: 1.5)
            ])
            bodyNode.run(SKAction.repeatForever(breathe))
            
        case "sleep":
            zzzNode.isHidden = false
            let headTilt = SKAction.sequence([
                SKAction.rotate(toAngle: -0.15, duration: 1.5),
                SKAction.rotate(toAngle: 0.15, duration: 1.5)
            ])
            headNode.run(SKAction.repeatForever(headTilt))
            leftClawNode.run(SKAction.rotate(toAngle: 0.5, duration: 0.5))
            rightClawNode.run(SKAction.rotate(toAngle: -0.5, duration: 0.5))
            let bodySway = SKAction.sequence([
                SKAction.rotate(toAngle: -0.03, duration: 2),
                SKAction.rotate(toAngle: 0.03, duration: 2)
            ])
            bodyNode.run(SKAction.repeatForever(bodySway))
            
        case "coffee":
            rightClawNode.run(SKAction.rotate(toAngle: -1.2, duration: 0.5))
            bodyNode.run(SKAction.sequence([
                SKAction.rotate(toAngle: -0.05, duration: 1),
                SKAction.rotate(toAngle: 0, duration: 1)
            ]))
            
        case "exercise":
            let lift = SKAction.sequence([
                SKAction.rotate(toAngle: 0.8, duration: 0.4),
                SKAction.rotate(toAngle: 0.2, duration: 0.4)
            ])
            leftClawNode.run(SKAction.repeatForever(lift))
            let liftR = SKAction.sequence([
                SKAction.rotate(toAngle: -0.8, duration: 0.4),
                SKAction.rotate(toAngle: -0.2, duration: 0.4)
            ])
            rightClawNode.run(SKAction.repeatForever(liftR))
            let bounce = SKAction.sequence([
                SKAction.moveBy(x: 0, y: -3, duration: 0.4),
                SKAction.moveBy(x: 0, y: 3, duration: 0.4)
            ])
            bodyNode.run(SKAction.repeatForever(bounce))
            
        case "chat":
            let wave = SKAction.sequence([
                SKAction.rotate(toAngle: 0.6, duration: 0.3),
                SKAction.rotate(toAngle: 0, duration: 0.3)
            ])
            leftClawNode.run(SKAction.repeatForever(wave))
            let waveR = SKAction.sequence([
                SKAction.rotate(toAngle: -0.6, duration: 0.3),
                SKAction.rotate(toAngle: 0, duration: 0.3)
            ])
            rightClawNode.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 0.3), SKAction.repeatForever(waveR)])))
            let sway = SKAction.sequence([
                SKAction.rotate(toAngle: -0.04, duration: 0.5),
                SKAction.rotate(toAngle: 0.04, duration: 0.5)
            ])
            bodyNode.run(SKAction.repeatForever(sway))
            
        case "think":
            leftClawNode.run(SKAction.rotate(toAngle: 0.8, duration: 0.5))
            headNode.run(SKAction.sequence([
                SKAction.rotate(toAngle: 0.1, duration: 1.5),
                SKAction.rotate(toAngle: -0.1, duration: 1.5)
            ]))
            
        case "phone":
            leftClawNode.run(SKAction.rotate(toAngle: 0.4, duration: 0.5))
            rightClawNode.run(SKAction.rotate(toAngle: -0.4, duration: 0.5))
            headNode.run(SKAction.rotate(toAngle: 0.15, duration: 0.5))
            
        case "dance":
            let bodyRock = SKAction.sequence([
                SKAction.rotate(toAngle: -0.1, duration: 0.25),
                SKAction.rotate(toAngle: 0.1, duration: 0.25)
            ])
            bodyNode.run(SKAction.repeatForever(bodyRock))
            leftClawNode.run(SKAction.repeatForever(SKAction.sequence([SKAction.rotate(toAngle: 1.0, duration: 0.25), SKAction.rotate(toAngle: 0, duration: 0.25)])))
            rightClawNode.run(SKAction.repeatForever(SKAction.sequence([SKAction.rotate(toAngle: -1.0, duration: 0.25), SKAction.rotate(toAngle: 0, duration: 0.25)])))
            let jump = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 4, duration: 0.25),
                SKAction.moveBy(x: 0, y: -4, duration: 0.25)
            ])
            bodyNode.run(SKAction.repeatForever(jump))
            
        case "stretch":
            leftClawNode.run(SKAction.rotate(toAngle: -1.5, duration: 0.8))
            rightClawNode.run(SKAction.rotate(toAngle: 1.5, duration: 0.8))
            bodyNode.run(SKAction.sequence([
                SKAction.scaleY(to: 1.08, duration: 0.8),
                SKAction.scaleY(to: 1.0, duration: 0.8)
            ]))
            
        default:
            break
        }
        
        // 5-10秒后切换下一个空闲状态
        let delay = Double.random(in: 5...10)
        let nextAction = SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.run { [weak self] in self?.switchToRandomIdle() }
        ])
        run(nextAction, withKey: "idleLoop")
    }
    
    // MARK: - 外部状态设置
    
    func setWorking() {
        currentState = "working"
        removeAction(forKey: "idleLoop")
        bodyNode.removeAllActions()
        headNode.removeAllActions()
        leftClawNode.removeAllActions()
        rightClawNode.removeAllActions()
        
        bodyNode.zRotation = 0
        headNode.zRotation = 0
        bubbleLabel.text = "⌨️ 工作中"
        bubbleLabel.isHidden = false
        zzzNode.isHidden = true
        statusDot.fillColor = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1)
        
        // 钳子快速敲键盘
        let typeL = SKAction.sequence([
            SKAction.rotate(toAngle: 0.4, duration: 0.08),
            SKAction.rotate(toAngle: 0.1, duration: 0.08)
        ])
        leftClawNode.run(SKAction.repeatForever(typeL))
        
        let typeR = SKAction.sequence([
            SKAction.rotate(toAngle: -0.4, duration: 0.08),
            SKAction.rotate(toAngle: -0.1, duration: 0.08)
        ])
        rightClawNode.run(SKAction.repeatForever(typeR))
        
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: -1, duration: 0.3),
            SKAction.moveBy(x: 0, y: 1, duration: 0.3)
        ])
        bodyNode.run(SKAction.repeatForever(bob))
        
        // 8秒后庆祝然后回到空闲
        let finishAction = SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in: 6...12)),
            SKAction.run { [weak self] in self?.setCelebrating() }
        ])
        run(finishAction, withKey: "workFinish")
    }
    
    func setCelebrating() {
        currentState = "celebrating"
        removeAction(forKey: "workFinish")
        bodyNode.removeAllActions()
        headNode.removeAllActions()
        leftClawNode.removeAllActions()
        rightClawNode.removeAllActions()
        
        bubbleLabel.text = "🎉 完成!"
        leftClawNode.run(SKAction.rotate(toAngle: -0.8, duration: 0.2))
        rightClawNode.run(SKAction.rotate(toAngle: 0.8, duration: 0.2))
        
        let jump = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 6, duration: 0.2),
            SKAction.moveBy(x: 0, y: -6, duration: 0.2)
        ])
        bodyNode.run(SKAction.repeat(jump, count: 3)) { [weak self] in
            self?.currentState = "idle"
            self?.switchToRandomIdle()
        }
    }
}

// UIColor扩展
extension UIColor {
    func darker() -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: max(r - 0.15, 0), green: max(g - 0.15, 0), blue: max(b - 0.15, 0), alpha: a)
    }
    
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r: UInt64, g: UInt64, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
    }
}
