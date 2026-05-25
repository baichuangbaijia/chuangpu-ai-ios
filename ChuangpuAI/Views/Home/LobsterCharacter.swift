import SpriteKit

// MARK: - 龙虾角色骨骼动画
// 每只龙虾由多个部件组成，各部件可独立动画
class LobsterCharacter: SKNode {
    
    let agentId: String
    let agentName: String
    let baseColor: UIColor
    let darkColor: UIColor
    
    // 骨骼节点
    private let bodyNode = SKNode()       // 身体（根）
    private let headNode = SKNode()       // 头
    private let leftClawNode = SKNode()   // 左钳
    private let rightClawNode = SKNode()  // 右钳
    private let tailNode = SKNode()       // 尾巴
    private let leftLegNode = SKNode()    // 左腿
    private let rightLegNode = SKNode()   // 右腿
    
    // 部件精灵
    private var bodySprite: SKShapeNode!
    private var headSprite: SKShapeNode!
    private var leftEyeWhite: SKShapeNode!
    private var rightEyeWhite: SKShapeNode!
    private var leftPupil: SKShapeNode!
    private var rightPupil: SKShapeNode!
    private var leftClawSprite: SKShapeNode!
    private var rightClawSprite: SKShapeNode!
    private var tailSprite: SKShapeNode!
    private var leftLegSprite: SKShapeNode!
    private var rightLegSprite: SKShapeNode!
    private var leftAntenna: SKShapeNode!
    private var rightAntenna: SKShapeNode!
    private var badgeNode: SKShapeNode!
    private var mouthNode: SKShapeNode!
    
    // UI
    private var nameLabel: SKLabelNode!
    private var bubbleLabel: SKLabelNode!
    private var bubbleBg: SKShapeNode!
    private var statusLight: SKShapeNode!
    private var zzzLabel: SKLabelNode!
    
    // 状态
    private var currentState: AgentState = .idle
    private var currentIdleAction: IdleAction = .stand
    private var stateTimer: Timer?
    private var blinkTimer: Timer?
    private var isEyesClosed = false
    
    enum AgentState {
        case idle, working, celebrating, panicking
    }
    
    enum IdleAction: CaseIterable {
        case stand, sleep, coffee, exercise, chat, think, phone, dance, stretch, yawn
    }
    
    init(agentId: String, name: String, color: UIColor) {
        self.agentId = agentId
        self.agentName = name
        self.baseColor = color
        self.darkColor = color.darker(by: 40) ?? color
        
        super.init()
        
        buildCharacter()
        buildUI()
        startBlinking()
        setIdle()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    // MARK: - 构建角色
    
    private func buildCharacter() {
        addChild(bodyNode)
        
        // 身体
        bodySprite = SKShapeNode(ellipseOf: CGSize(width: 28, height: 36))
        bodySprite.fillColor = baseColor
        bodySprite.strokeColor = darkColor
        bodySprite.lineWidth = 1.5
        bodySprite.glowWidth = 2
        bodyNode.addChild(bodySprite)
        
        // 工服
        let uniformBg = SKShapeNode(rectOf: CGSize(width: 24, height: 18), cornerRadius: 3)
        uniformBg.fillColor = UIColor(hex: "3B82F6").withAlphaComponent(0.45)
        uniformBg.strokeColor = .clear
        uniformBg.position = CGPoint(x: 0, y: -2)
        bodySprite.addChild(uniformBg)
        
        // 工牌
        badgeNode = SKShapeNode(rectOf: CGSize(width: 6, height: 4), cornerRadius: 1)
        badgeNode.fillColor = baseColor.withAlphaComponent(0.7)
        badgeNode.strokeColor = .clear
        badgeNode.position = CGPoint(x: 0, y: 2)
        uniformBg.addChild(badgeNode)
        
        // 身体纹理线
        for i in 0..<3 {
            let line = SKShapeNode()
            let yOff = CGFloat(i) * 8 - 6
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -10, y: yOff))
            path.addQuadCurve(to: CGPoint(x: 10, y: yOff), control: CGPoint(x: 0, y: yOff - 2))
            line.path = path
            line.strokeColor = darkColor.withAlphaComponent(0.4)
            line.lineWidth = 0.8
            bodySprite.addChild(line)
        }
        
        // 头
        headNode.position = CGPoint(x: 0, y: 22)
        bodyNode.addChild(headNode)
        
        headSprite = SKShapeNode(ellipseOf: CGSize(width: 26, height: 22))
        headSprite.fillColor = baseColor
        headSprite.strokeColor = darkColor
        headSprite.lineWidth = 1.5
        headNode.addChild(headSprite)
        
        // 眼睛
        leftEyeWhite = SKShapeNode(ellipseOf: CGSize(width: 8, height: 8))
        leftEyeWhite.fillColor = .white
        leftEyeWhite.strokeColor = .clear
        leftEyeWhite.position = CGPoint(x: -5, y: 2)
        headSprite.addChild(leftEyeWhite)
        
        rightEyeWhite = SKShapeNode(ellipseOf: CGSize(width: 8, height: 8))
        rightEyeWhite.fillColor = .white
        rightEyeWhite.strokeColor = .clear
        rightEyeWhite.position = CGPoint(x: 5, y: 2)
        headSprite.addChild(rightEyeWhite)
        
        leftPupil = SKShapeNode(ellipseOf: CGSize(width: 4, height: 4))
        leftPupil.fillColor = UIColor(hex: "1a1a2e")
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: 0.5, y: 0)
        leftEyeWhite.addChild(leftPupil)
        
        // 瞳孔高光
        let lHighlight = SKShapeNode(ellipseOf: CGSize(width: 1.5, height: 1.5))
        lHighlight.fillColor = .white
        lHighlight.strokeColor = .clear
        lHighlight.position = CGPoint(x: 1, y: 1)
        leftPupil.addChild(lHighlight)
        
        rightPupil = SKShapeNode(ellipseOf: CGSize(width: 4, height: 4))
        rightPupil.fillColor = UIColor(hex: "1a1a2e")
        rightPupil.strokeColor = .clear
        rightPupil.position = CGPoint(x: 0.5, y: 0)
        rightEyeWhite.addChild(rightPupil)
        
        let rHighlight = SKShapeNode(ellipseOf: CGSize(width: 1.5, height: 1.5))
        rHighlight.fillColor = .white
        rHighlight.strokeColor = .clear
        rHighlight.position = CGPoint(x: 1, y: 1)
        rightPupil.addChild(rHighlight)
        
        // 嘴巴
        mouthNode = SKShapeNode(ellipseOf: CGSize(width: 5, height: 3))
        mouthNode.fillColor = darkColor
        mouthNode.strokeColor = .clear
        mouthNode.position = CGPoint(x: 0, y: -5)
        headSprite.addChild(mouthNode)
        
        // 触角
        let leftAntPath = CGMutablePath()
        leftAntPath.move(to: CGPoint(x: -6, y: 8))
        leftAntPath.addQuadCurve(to: CGPoint(x: -12, y: 20), control: CGPoint(x: -10, y: 14))
        leftAntenna = SKShapeNode(path: leftAntPath)
        leftAntenna.strokeColor = darkColor
        leftAntenna.lineWidth = 2
        leftAntenna.lineCap = .round
        headSprite.addChild(leftAntenna)
        
        let rightAntPath = CGMutablePath()
        rightAntPath.move(to: CGPoint(x: 6, y: 8))
        rightAntPath.addQuadCurve(to: CGPoint(x: 12, y: 20), control: CGPoint(x: 10, y: 14))
        rightAntenna = SKShapeNode(path: rightAntPath)
        rightAntenna.strokeColor = darkColor
        rightAntenna.lineWidth = 2
        rightAntenna.lineCap = .round
        headSprite.addChild(rightAntenna)
        
        // 触角尖
        let lTip = SKShapeNode(circleOfRadius: 2.5)
        lTip.fillColor = baseColor
        lTip.strokeColor = .clear
        lTip.position = CGPoint(x: -12, y: 20)
        headSprite.addChild(lTip)
        
        let rTip = SKShapeNode(circleOfRadius: 2.5)
        rTip.fillColor = baseColor
        rTip.strokeColor = .clear
        rTip.position = CGPoint(x: 12, y: 20)
        headSprite.addChild(rTip)
        
        // 左钳
        leftClawNode.position = CGPoint(x: -16, y: 6)
        leftClawNode.zRotation = 0.2
        bodyNode.addChild(leftClawNode)
        
        leftClawSprite = SKShapeNode()
        let lcPath = CGMutablePath()
        lcPath.move(to: CGPoint(x: 0, y: 0))
        lcPath.addQuadCurve(to: CGPoint(x: -8, y: -10), control: CGPoint(x: -6, y: -6))
        lcPath.addQuadCurve(to: CGPoint(x: -4, y: -14), control: CGPoint(x: -8, y: -12))
        lcPath.addQuadCurve(to: CGPoint(x: -2, y: -8), control: CGPoint(x: -2, y: -10))
        lcPath.closeSubpath()
        leftClawSprite.path = lcPath
        leftClawSprite.fillColor = baseColor
        leftClawSprite.strokeColor = darkColor
        leftClawSprite.lineWidth = 1
        leftClawNode.addChild(leftClawSprite)
        
        // 右钳
        rightClawNode.position = CGPoint(x: 16, y: 6)
        rightClawNode.zRotation = -0.2
        bodyNode.addChild(rightClawNode)
        
        rightClawSprite = SKShapeNode()
        let rcPath = CGMutablePath()
        rcPath.move(to: CGPoint(x: 0, y: 0))
        rcPath.addQuadCurve(to: CGPoint(x: 8, y: -10), control: CGPoint(x: 6, y: -6))
        rcPath.addQuadCurve(to: CGPoint(x: 4, y: -14), control: CGPoint(x: 8, y: -12))
        rcPath.addQuadCurve(to: CGPoint(x: 2, y: -8), control: CGPoint(x: 2, y: -10))
        rcPath.closeSubpath()
        rightClawSprite.path = rcPath
        rightClawSprite.fillColor = baseColor
        rightClawSprite.strokeColor = darkColor
        rightClawSprite.lineWidth = 1
        rightClawNode.addChild(rightClawSprite)
        
        // 尾巴
        tailNode.position = CGPoint(x: 0, y: -18)
        bodyNode.addChild(tailNode)
        
        tailSprite = SKShapeNode()
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -8, y: 0))
        tailPath.addQuadCurve(to: CGPoint(x: 0, y: 12), control: CGPoint(x: -4, y: 8))
        tailPath.addQuadCurve(to: CGPoint(x: 8, y: 0), control: CGPoint(x: 4, y: 8))
        tailSprite.path = tailPath
        tailSprite.fillColor = baseColor
        tailSprite.strokeColor = darkColor
        tailSprite.lineWidth = 1
        tailNode.addChild(tailSprite)
        
        // 腿
        leftLegSprite = SKShapeNode()
        let llPath = CGMutablePath()
        llPath.move(to: CGPoint(x: -6, y: -12))
        llPath.addLine(to: CGPoint(x: -14, y: -24))
        leftLegSprite.path = llPath
        leftLegSprite.strokeColor = baseColor
        leftLegSprite.lineWidth = 3
        leftLegSprite.lineCap = .round
        bodyNode.addChild(leftLegSprite)
        
        rightLegSprite = SKShapeNode()
        let rlPath = CGMutablePath()
        rlPath.move(to: CGPoint(x: 6, y: -12))
        rlPath.addLine(to: CGPoint(x: 14, y: -24))
        rightLegSprite.path = rlPath
        rightLegSprite.strokeColor = baseColor
        rightLegSprite.lineWidth = 3
        rightLegSprite.lineCap = .round
        bodyNode.addChild(rightLegSprite)
    }
    
    private func buildUI() {
        // 名字标签
        nameLabel = SKLabelNode(text: agentName)
        nameLabel.fontSize = 9
        nameLabel.fontColor = baseColor
        nameLabel.fontName = "PingFangSC-Medium"
        nameLabel.position = CGPoint(x: 0, y: -38)
        let nameBg = SKShapeNode(rectOf: CGSize(width: nameLabel.frame.width + 10, height: 14), cornerRadius: 7)
        nameBg.fillColor = UIColor(hex: "1a1a35")
        nameBg.strokeColor = baseColor.withAlphaComponent(0.25)
        nameBg.lineWidth = 1
        nameBg.position = nameLabel.position
        addChild(nameBg)
        nameLabel.position.y = nameLabel.position.y - 3
        addChild(nameLabel)
        
        // 状态灯
        statusLight = SKShapeNode(circleOfRadius: 3)
        statusLight.fillColor = UIColor(hex: "4a4a6a")
        statusLight.strokeColor = .clear
        statusLight.position = CGPoint(x: 18, y: 30)
        addChild(statusLight)
        
        // 气泡
        bubbleBg = SKShapeNode(rectOf: CGSize(width: 60, height: 20), cornerRadius: 10)
        bubbleBg.fillColor = UIColor(hex: "252540")
        bubbleBg.strokeColor = UIColor(hex: "4a4a6a")
        bubbleBg.lineWidth = 1
        bubbleBg.position = CGPoint(x: 0, y: 42)
        bubbleBg.isHidden = true
        addChild(bubbleBg)
        
        bubbleLabel = SKLabelNode(text: "")
        bubbleLabel.fontSize = 9
        bubbleLabel.fontColor = UIColor(hex: "a0a0c0")
        bubbleLabel.fontName = "PingFangSC-Medium"
        bubbleLabel.position = CGPoint(x: 0, y: 39)
        bubbleLabel.isHidden = true
        addChild(bubbleLabel)
        
        // ZZZ
        zzzLabel = SKLabelNode(text: "💤")
        zzzLabel.fontSize = 10
        zzzLabel.position = CGPoint(x: 14, y: 34)
        zzzLabel.isHidden = true
        addChild(zzzLabel)
    }
    
    // MARK: - 眨眼
    
    private func startBlinking() {
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 3 + Double.random(in: 1...4), repeats: true) { [weak self] _ in
            self?.blink()
        }
    }
    
    private func blink() {
        guard !isEyesClosed else { return }
        isEyesClosed = true
        
        let close = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.leftEyeWhite.yScale = 0.2
                self?.rightEyeWhite.yScale = 0.2
                self?.leftPupil.isHidden = true
                self?.rightPupil.isHidden = true
            },
            SKAction.wait(forDuration: 0.15),
            SKAction.run { [weak self] in
                self?.leftEyeWhite.yScale = 1
                self?.rightEyeWhite.yScale = 1
                self?.leftPupil.isHidden = false
                self?.rightPupil.isHidden = false
                self?.isEyesClosed = false
            }
        ])
        run(close)
    }
    
    // MARK: - 状态切换
    
    func setIdle() {
        currentState = .idle
        statusLight.fillColor = UIColor(hex: "4a4a6a")
        removeAllActions()
        bodyNode.removeAllActions()
        headNode.removeAllActions()
        leftClawNode.removeAllActions()
        rightClawNode.removeAllActions()
        tailNode.removeAllActions()
        
        // 随机选一个空闲动作
        let action = IdleAction.allCases.randomElement()!
        currentIdleAction = action
        performIdleAction(action)
        
        // 定时切换下一个空闲动作
        scheduleNextIdle()
    }
    
    private func scheduleNextIdle() {
        stateTimer?.invalidate()
        let delay = 5.0 + Double.random(in: 0...7)
        stateTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self, self.currentState == .idle else { return }
            self.setIdle()
        }
    }
    
    func setWorking() {
        currentState = .working
        stateTimer?.invalidate()
        removeAllActions()
        bodyNode.removeAllActions()
        headNode.removeAllActions()
        leftClawNode.removeAllActions()
        rightClawNode.removeAllActions()
        
        statusLight.fillColor = UIColor(hex: "10B981")
        let pulse = SKAction.sequence([
            SKAction.run { [weak self] in self?.statusLight.alpha = 1 },
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in self?.statusLight.alpha = 0.4 },
            SKAction.wait(forDuration: 0.5)
        ])
        statusLight.run(SKAction.repeatForever(pulse))
        
        showBubble("⌨️ 工作中")
        zzzLabel.isHidden = true
        
        // 认真表情
        setMouth(.serious)
        openEyes()
        lookAtScreen()
        
        // 身体前倾
        bodyNode.run(SKAction.sequence([
            SKAction.moveTo(y: -2, duration: 0.3),
            SKAction.moveTo(y: 0, duration: 0.3)
        ]))
        
        // 钳子快速敲键盘
        let typeL = SKAction.sequence([
            SKAction.rotate(toAngle: 0.4, duration: 0.08),
            SKAction.rotate(toAngle: 0.1, duration: 0.08)
        ])
        let typeR = SKAction.sequence([
            SKAction.rotate(toAngle: -0.4, duration: 0.08),
            SKAction.rotate(toAngle: -0.1, duration: 0.08)
        ])
        leftClawNode.run(SKAction.repeatForever(typeL))
        rightClawNode.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 0.04), SKAction.repeatForever(typeR)])))
        
        // 身体微动
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: -1, duration: 0.3),
            SKAction.moveBy(x: 0, y: 1, duration: 0.3)
        ])
        bodyNode.run(SKAction.repeatForever(bob))
    }
    
    func setCelebrating() {
        currentState = .celebrating
        stateTimer?.invalidate()
        removeAllActions()
        bodyNode.removeAllActions()
        headNode.removeAllActions()
        leftClawNode.removeAllActions()
        rightClawNode.removeAllActions()
        
        statusLight.fillColor = UIColor(hex: "10B981")
        showBubble("🎉 完成!")
        zzzLabel.isHidden = true
        
        setMouth(.happy)
        openEyes()
        lookForward()
        
        // 举起钳子庆祝
        leftClawNode.run(SKAction.rotate(toAngle: -0.8, duration: 0.2))
        rightClawNode.run(SKAction.rotate(toAngle: 0.8, duration: 0.2))
        
        // 上下跳跃
        let jump = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 6, duration: 0.2),
            SKAction.moveBy(x: 0, y: -6, duration: 0.2)
        ])
        bodyNode.run(SKAction.repeat(jump, count: 3)) { [weak self] in
            self?.setIdle()
        }
    }
    
    func setPanicking() {
        currentState = .panicking
        stateTimer?.invalidate()
        
        showBubble("😨 出错!")
        zzzLabel.isHidden = true
        
        setMouth(.shocked)
        openEyesWide()
        
        // 抖动
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -2, y: 0, duration: 0.05),
            SKAction.moveBy(x: 4, y: 0, duration: 0.05),
            SKAction.moveBy(x: -4, y: 0, duration: 0.05),
            SKAction.moveBy(x: 2, y: 0, duration: 0.05)
        ])
        bodyNode.run(SKAction.repeat(shake, count: 4)) { [weak self] in
            self?.setIdle()
        }
    }
    
    // MARK: - 空闲动作
    
    private func performIdleAction(_ action: IdleAction) {
        switch action {
        case .stand:
            showBubble("😌 待命中")
            zzzLabel.isHidden = true
            openEyes()
            lookForward()
            setMouth(.neutral)
            let breathe = SKAction.sequence([
                SKAction.scaleY(to: 1.02, duration: 1.5),
                SKAction.scaleY(to: 1.0, duration: 1.5)
            ])
            bodyNode.run(SKAction.repeatForever(breathe))
            leftClawNode.run(SKAction.rotate(toAngle: 0.2, duration: 0.5))
            rightClawNode.run(SKAction.rotate(toAngle: -0.2, duration: 0.5))
            
        case .sleep:
            showBubble("💤 打盹中")
            zzzLabel.isHidden = false
            // 动画ZZZ上升
            let zzzUp = SKAction.sequence([
                SKAction.moveBy(x: 3, y: 8, duration: 1.5),
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.moveBy(x: -3, y: -8, duration: 0),
                SKAction.fadeIn(withDuration: 0.3)
            ])
            zzzLabel.run(SKAction.repeatForever(zzzUp))
            
            closeEyes()
            setMouth(.sleepy)
            // 头慢慢歪
            let headTilt = SKAction.sequence([
                SKAction.rotate(toAngle: -0.15, duration: 1.5),
                SKAction.rotate(toAngle: 0.15, duration: 1.5)
            ])
            headNode.run(SKAction.repeatForever(headTilt))
            // 身体微微晃
            let bodySway = SKAction.sequence([
                SKAction.rotate(toAngle: -0.03, duration: 2),
                SKAction.rotate(toAngle: 0.03, duration: 2)
            ])
            bodyNode.run(SKAction.repeatForever(bodySway))
            leftClawNode.run(SKAction.rotate(toAngle: 0.5, duration: 0.5))
            rightClawNode.run(SKAction.rotate(toAngle: -0.5, duration: 0.5))
            
        case .coffee:
            showBubble("☕ 喝咖啡")
            zzzLabel.isHidden = true
            openEyes()
            lookForward()
            setMouth(.happy)
            // 右钳举起做喝咖啡动作
            rightClawNode.run(SKAction.sequence([
                SKAction.rotate(toAngle: -1.2, duration: 0.5),
                SKAction.rotate(toAngle: -1.0, duration: 0.8),
                SKAction.rotate(toAngle: -1.2, duration: 0.5)
            ]))
            leftClawNode.run(SKAction.rotate(toAngle: 0.2, duration: 0.5))
            // 身体微仰
            bodyNode.run(SKAction.sequence([
                SKAction.rotate(toAngle: -0.05, duration: 1.0),
                SKAction.rotate(toAngle: 0, duration: 1.0)
            ]))
            
        case .exercise:
            showBubble("🏋️ 健身中")
            zzzLabel.isHidden = true
            setMouth(.serious)
            openEyes()
            lookForward()
            // 双钳举哑铃
            let lift = SKAction.sequence([
                SKAction.rotate(toAngle: -0.6, duration: 0.4),
                SKAction.rotate(toAngle: -1.0, duration: 0.4),
                SKAction.rotate(toAngle: -0.6, duration: 0.4)
            ])
            leftClawNode.run(SKAction.repeatForever(SKAction.sequence([SKAction.rotate(toAngle: 0.6, duration: 0.4), SKAction.rotate(toAngle: 1.0, duration: 0.4), SKAction.rotate(toAngle: 0.6, duration: 0.4)])))
            rightClawNode.run(SKAction.repeatForever(lift))
            // 身体上下
            let bodyBounce = SKAction.sequence([
                SKAction.moveBy(x: 0, y: -3, duration: 0.4),
                SKAction.moveBy(x: 0, y: 3, duration: 0.4)
            ])
            bodyNode.run(SKAction.repeatForever(bodyBounce))
            
        case .chat:
            showBubble("💬 聊天中")
            zzzLabel.isHidden = true
            openEyes()
            lookForward()
            setMouth(.talking)
            // 钳子挥动
            let waveL = SKAction.sequence([
                SKAction.rotate(toAngle: 0.6, duration: 0.3),
                SKAction.rotate(toAngle: 0, duration: 0.3)
            ])
            let waveR = SKAction.sequence([
                SKAction.rotate(toAngle: -0.6, duration: 0.3),
                SKAction.rotate(toAngle: 0, duration: 0.3)
            ])
            leftClawNode.run(SKAction.repeatForever(waveL))
            rightClawNode.run(SKAction.repeatForever(SKAction.sequence([SKAction.wait(forDuration: 0.3), SKAction.repeatForever(waveR)])))
            // 身体微微左右
            let sway = SKAction.sequence([
                SKAction.rotate(toAngle: -0.04, duration: 0.5),
                SKAction.rotate(toAngle: 0.04, duration: 0.5)
            ])
            bodyNode.run(SKAction.repeatForever(sway))
            
        case .think:
            showBubble("🤔 思考中")
            zzzLabel.isHidden = true
            halfCloseEyes()
            lookUp()
            setMouth(.neutral)
            // 左钳摸下巴
            leftClawNode.run(SKAction.rotate(toAngle: 0.8, duration: 0.5))
            rightClawNode.run(SKAction.rotate(toAngle: -0.2, duration: 0.5))
            // 头微歪
            headNode.run(SKAction.sequence([
                SKAction.rotate(toAngle: 0.1, duration: 1.5),
                SKAction.rotate(toAngle: -0.1, duration: 1.5)
            ]))
            
        case .phone:
            showBubble("📱 刷手机")
            zzzLabel.isHidden = true
            lookDown()
            halfCloseEyes()
            setMouth(.neutral)
            // 双钳在前面捧手机
            leftClawNode.run(SKAction.rotate(toAngle: 0.4, duration: 0.5))
            rightClawNode.run(SKAction.rotate(toAngle: -0.4, duration: 0.5))
            // 偶尔滑动
            let scrollDelay = SKAction.sequence([
                SKAction.wait(forDuration: 2),
                SKAction.rotate(byAngle: 0.1, duration: 0.2),
                SKAction.rotate(byAngle: -0.1, duration: 0.2)
            ])
            leftClawNode.run(SKAction.repeatForever(scrollDelay))
            // 头低着微动
            let nod = SKAction.sequence([
                SKAction.rotate(toAngle: 0.15, duration: 1.5),
                SKAction.rotate(toAngle: 0.1, duration: 1.5)
            ])
            headNode.run(SKAction.repeatForever(nod))
            
        case .dance:
            showBubble("💃 蹦迪中")
            zzzLabel.isHidden = true
            openEyes()
            lookForward()
            setMouth(.happy)
            // 身体扭动
            let danceBody = SKAction.sequence([
                SKAction.rotate(toAngle: -0.1, duration: 0.25),
                SKAction.rotate(toAngle: 0.1, duration: 0.25)
            ])
            bodyNode.run(SKAction.repeatForever(danceBody))
            // 钳子交替挥
            leftClawNode.run(SKAction.repeatForever(SKAction.sequence([SKAction.rotate(toAngle: 1.0, duration: 0.25), SKAction.rotate(toAngle: 0, duration: 0.25)])))
            rightClawNode.run(SKAction.repeatForever(SKAction.sequence([SKAction.rotate(toAngle: -1.0, duration: 0.25), SKAction.rotate(toAngle: 0, duration: 0.25)])))
            // 上下跳
            let jump = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 4, duration: 0.25),
                SKAction.moveBy(x: 0, y: -4, duration: 0.25)
            ])
            bodyNode.run(SKAction.repeatForever(jump))
            
        case .stretch:
            showBubble("🙆 伸懒腰")
            zzzLabel.isHidden = true
            openEyes()
            lookUp()
            setMouth(.happy)
            // 双钳上举
            leftClawNode.run(SKAction.sequence([SKAction.rotate(toAngle: -1.5, duration: 0.8), SKAction.rotate(toAngle: 0.2, duration: 0.8)]))
            rightClawNode.run(SKAction.sequence([SKAction.rotate(toAngle: 1.5, duration: 0.8), SKAction.rotate(toAngle: -0.2, duration: 0.8)]))
            // 身体伸展
            bodyNode.run(SKAction.sequence([
                SKAction.scaleY(to: 1.08, duration: 0.8),
                SKAction.scaleY(to: 1.0, duration: 0.8)
            ]))
            
        case .yawn:
            showBubble("😮 打哈欠")
            zzzLabel.isHidden = true
            closeEyes()
            setMouth(.yawn)
            // 张大嘴的动画
            let yawnMouth = SKAction.sequence([
                SKAction.run { [weak self] in self?.mouthNode.yScale = 2.0 },
                SKAction.wait(forDuration: 1.5),
                SKAction.run { [weak self] in self?.mouthNode.yScale = 1.0; self?.openEyes() }
            ])
            mouthNode.run(yawnMouth)
            leftClawNode.run(SKAction.rotate(toAngle: 0.3, duration: 0.5))
            rightClawNode.run(SKAction.rotate(toAngle: -0.3, duration: 0.5))
        }
    }
    
    // MARK: - 表情控制
    
    private enum MouthState { case neutral, happy, serious, sleepy, talking, shocked, yawn }
    
    private func setMouth(_ state: MouthState) {
        switch state {
        case .neutral:
            mouthNode.xScale = 1; mouthNode.yScale = 1
            mouthNode.fillColor = darkColor
        case .happy:
            mouthNode.xScale = 1.3; mouthNode.yScale = 0.8
            mouthNode.fillColor = darkColor
        case .serious:
            mouthNode.xScale = 0.8; mouthNode.yScale = 0.5
            mouthNode.fillColor = darkColor
        case .sleepy:
            mouthNode.xScale = 0.6; mouthNode.yScale = 0.6
            mouthNode.fillColor = darkColor.withAlphaComponent(0.5)
        case .talking:
            let talkAnim = SKAction.repeatForever(SKAction.sequence([
                SKAction.run { [weak self] in self?.mouthNode.yScale = 1.5 },
                SKAction.wait(forDuration: 0.12),
                SKAction.run { [weak self] in self?.mouthNode.yScale = 0.5 },
                SKAction.wait(forDuration: 0.12)
            ]))
            mouthNode.run(talkAnim)
        case .shocked:
            mouthNode.xScale = 0.8; mouthNode.yScale = 2.0
            mouthNode.fillColor = darkColor
        case .yawn:
            mouthNode.xScale = 1.2; mouthNode.yScale = 1.8
            mouthNode.fillColor = darkColor
        }
    }
    
    private func openEyes() {
        leftEyeWhite.yScale = 1; rightEyeWhite.yScale = 1
        leftPupil.isHidden = false; rightPupil.isHidden = false
    }
    
    private func closeEyes() {
        leftEyeWhite.yScale = 0.15; rightEyeWhite.yScale = 0.15
        leftPupil.isHidden = true; rightPupil.isHidden = true
    }
    
    private func halfCloseEyes() {
        leftEyeWhite.yScale = 0.5; rightEyeWhite.yScale = 0.5
        leftPupil.isHidden = false; rightPupil.isHidden = false
    }
    
    private func openEyesWide() {
        leftEyeWhite.yScale = 1.3; rightEyeWhite.yScale = 1.3
        leftPupil.yScale = 1.2; rightPupil.yScale = 1.2
    }
    
    private func lookAtScreen() {
        leftPupil.position = CGPoint(x: 0, y: -1)
        rightPupil.position = CGPoint(x: 0, y: -1)
    }
    
    private func lookForward() {
        leftPupil.position = CGPoint(x: 0.5, y: 0)
        rightPupil.position = CGPoint(x: 0.5, y: 0)
    }
    
    private func lookUp() {
        leftPupil.position = CGPoint(x: 0, y: 1.5)
        rightPupil.position = CGPoint(x: 0, y: 1.5)
    }
    
    private func lookDown() {
        leftPupil.position = CGPoint(x: 0, y: -1.5)
        rightPupil.position = CGPoint(x: 0, y: -1.5)
    }
    
    // MARK: - 气泡
    
    private func showBubble(_ text: String) {
        bubbleLabel.text = text
        bubbleLabel.isHidden = false
        bubbleBg.isHidden = false
        // 调整气泡大小
        let w = max(60, CGFloat(text.count) * 10 + 16)
        let newBg = SKShapeNode(rectOf: CGSize(width: w, height: 20), cornerRadius: 10)
        newBg.fillColor = UIColor(hex: "252540")
        newBg.strokeColor = UIColor(hex: "4a4a6a")
        newBg.lineWidth = 1
        newBg.position = bubbleBg.position
        bubbleBg.removeFromParent()
        bubbleBg = newBg
        addChild(bubbleBg)
    }
    
    // MARK: - 清理
    deinit {
        stateTimer?.invalidate()
        blinkTimer?.invalidate()
    }
}

// MARK: - UIColor扩展
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: CGFloat(a)/255)
    }
    
    func darker(by percentage: CGFloat = 30) -> UIColor? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: max(r - percentage/100, 0), green: max(g - percentage/100, 0), blue: max(b - percentage/100, 0), alpha: a)
    }
}
