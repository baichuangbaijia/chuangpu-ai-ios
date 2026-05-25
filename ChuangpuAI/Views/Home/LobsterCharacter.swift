import SpriteKit
import Foundation

/// 龙虾角色 v3 - AI图片纹理+代码兜底+纵深行走
class LobsterCharacter: SKNode {
    let agentId: String
    let agentName: String
    let colorKey: String
    private var textures: [String: SKTexture] = [:]
    private var hasImages: Bool = false
    let spriteNode = SKSpriteNode()
    private var nameLabel: SKLabelNode!
    private var stateIcon: SKLabelNode!
    var currentState: String = "idle"
    var homePosition: CGPoint = .zero
    var isBusy: Bool = false
    private var baseScale: CGFloat = 1.0
    
    private static let colorMap: [String: String] = [
        "pm": "red", "file": "blue", "computer": "green",
        "app": "orange", "browser": "purple", "search": "cyan"
    ]
    private static let hexMap: [String: String] = [
        "red": "EF4444", "blue": "3B82F6", "green": "10B981",
        "orange": "F97316", "purple": "8B5CF6", "cyan": "06B6D4"
    ]
    
    init(agentId: String, name: String) {
        self.agentId = agentId
        self.agentName = name
        self.colorKey = LobsterCharacter.colorMap[agentId] ?? "red"
        super.init()
        loadTextures()
        buildUI()
        showState("idle")
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func loadTextures() {
        let states = ["idle", "walk", "typing", "sleep", "coffee", "exercise", "chat", "celebrate"]
        for state in states {
            let name = "\(colorKey)_\(state)"
            if let img = UIImage(named: name) {
                textures[state] = SKTexture(image: img)
                hasImages = true
            } else if let p = Bundle.main.path(forResource: name, ofType: "png") {
                if let img = UIImage(contentsOfFile: p) {
                    textures[state] = SKTexture(image: img)
                    hasImages = true
                }
            }
        }
        if hasImages { for (_, t) in textures { t.filteringMode = .linear } }
    }
    
    private func buildUI() {
        spriteNode.size = hasImages ? CGSize(width: 52, height: 52) : CGSize(width: 1, height: 1)
        spriteNode.anchorPoint = CGPoint(x: 0.5, y: 0.3)
        spriteNode.zPosition = 10
        spriteNode.isHidden = !hasImages
        addChild(spriteNode)
        
        stateIcon = SKLabelNode(text: "")
        stateIcon.fontSize = 12
        stateIcon.zPosition = 12
        stateIcon.position = CGPoint(x: 0, y: 24)
        addChild(stateIcon)
        
        nameLabel = SKLabelNode(text: agentName)
        nameLabel.fontSize = 8
        nameLabel.fontName = "PingFangSC-Medium"
        let hex = LobsterCharacter.hexMap[colorKey] ?? "FFFFFF"
        nameLabel.fontColor = UIColor(hex: hex)
        nameLabel.position = CGPoint(x: 0, y: -16)
        nameLabel.zPosition = 11
        addChild(nameLabel)
        
        if !hasImages { drawFallback() }
    }
    
    private func drawFallback() {
        let hex = LobsterCharacter.hexMap[colorKey] ?? "EF4444"
        let col = UIColor(hex: hex)
        let body = SKShapeNode(ellipseOf: CGSize(width: 28, height: 22))
        body.fillColor = col; body.strokeColor = col.withAlphaComponent(0.5); body.lineWidth = 1
        body.position = CGPoint(x: 0, y: 0); body.zPosition = 10; addChild(body)
        let head = SKShapeNode(circleOfRadius: 8)
        head.fillColor = col; head.strokeColor = .clear
        head.position = CGPoint(x: 0, y: 13); head.zPosition = 10; addChild(head)
        let e1 = SKShapeNode(circleOfRadius: 2.5)
        e1.fillColor = .white; e1.strokeColor = .clear
        e1.position = CGPoint(x: -3, y: 15); e1.zPosition = 11; addChild(e1)
        let e2 = SKShapeNode(circleOfRadius: 2.5)
        e2.fillColor = .white; e2.strokeColor = .clear
        e2.position = CGPoint(x: 3, y: 15); e2.zPosition = 11; addChild(e2)
        let c1 = SKShapeNode(ellipseOf: CGSize(width: 9, height: 5))
        c1.fillColor = col.withAlphaComponent(0.8); c1.strokeColor = .clear
        c1.position = CGPoint(x: -16, y: 2); c1.zPosition = 9; addChild(c1)
        let c2 = SKShapeNode(ellipseOf: CGSize(width: 9, height: 5))
        c2.fillColor = col.withAlphaComponent(0.8); c2.strokeColor = .clear
        c2.position = CGPoint(x: 16, y: 2); c2.zPosition = 9; addChild(c2)
    }
    
    private let stateIcons: [String: String] = [
        "idle": "", "walking": "🚶", "working": "💻", "sleeping": "💤",
        "coffee": "☕", "exercise": "🏋️", "chatting": "💬", "celebrating": "🎉",
        "phone": "📱", "toilet": "🚻"
    ]
    
    private func showState(_ state: String) {
        if let tex = textures[state] { spriteNode.texture = tex; spriteNode.isHidden = false }
        stateIcon.text = stateIcons[currentState] ?? ""
    }
    
    /// 走到目标点（支持X+Y纵深移动，走的时候缩放模拟远近）
    func walkTo(_ target: CGPoint, speed: CGFloat = 60, completion: @escaping () -> Void) {
        clearAnimations()
        currentState = "walking"
        showState("walk")
        
        let dx = target.x - position.x
        spriteNode.xScale = dx > 0 ? 1 : -1
        
        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: 0.08, duration: 0.18),
            SKAction.rotate(byAngle: -0.08, duration: 0.18)
        ])
        spriteNode.run(SKAction.repeatForever(wobble), withKey: "walkWobble")
        
        let dist = sqrt(dx*dx + (target.y - position.y) * (target.y - position.y))
        let dur = Double(dist) / Double(speed)
        
        // 计算目标缩放（Y越高=越远=越小）
        let sceneH: CGFloat = 320
        let targetScale = 0.65 + 0.45 * (target.y / sceneH)
        
        // 同时移动+缩放
        let moveAction = SKAction.move(to: target, duration: max(dur, 0.3))
        let scaleXTarget = targetScale * (dx > 0 ? 1.0 : -1.0)
        let scaleAction = SKAction.group([
            SKAction.scaleX(to: abs(scaleXTarget), duration: max(dur, 0.3)),
            SKAction.scaleY(to: targetScale, duration: max(dur, 0.3))
        ])
        
        run(moveAction) { [weak self] in
            self?.clearAnimations()
            self?.spriteNode.xScale = 1
            completion()
        }
        run(scaleAction, withKey: "walkScale")
    }
    
    func walkHome(completion: @escaping () -> Void = {}) {
        walkTo(homePosition) { [weak self] in
            self?.sitAtDesk()
            completion()
        }
    }
    
    func sitAtDesk() {
        clearAnimations()
        currentState = "idle"
        showState("idle")
        // 恢复工位缩放
        let homeScale = 0.65 + 0.45 * (homePosition.y / 320)
        xScale = homeScale
        yScale = homeScale
        let b = SKAction.sequence([SKAction.scaleX(to: homeScale * 1.04, duration: 1.2), SKAction.scaleX(to: homeScale, duration: 1.2)])
        run(SKAction.repeatForever(b), withKey: "breathe")
    }
    
    func sleepAtDesk() {
        clearAnimations(); currentState = "sleeping"; showState("sleep")
        let s = SKAction.sequence([SKAction.rotate(byAngle: 0.05, duration: 1.8), SKAction.rotate(byAngle: -0.05, duration: 1.8)])
        spriteNode.run(SKAction.repeatForever(s), withKey: "sleepSway")
    }
    
    func drinkCoffee() {
        clearAnimations(); currentState = "coffee"; showState("coffee")
        let s = SKAction.sequence([SKAction.rotate(byAngle: 0.1, duration: 0.7), SKAction.rotate(byAngle: -0.1, duration: 0.7)])
        spriteNode.run(SKAction.repeatForever(s), withKey: "sip")
    }
    
    func exercise() {
        clearAnimations(); currentState = "exercise"; showState("exercise")
        let b = SKAction.sequence([SKAction.moveBy(x: 0, y: 4, duration: 0.25), SKAction.moveBy(x: 0, y: -4, duration: 0.25)])
        spriteNode.run(SKAction.repeatForever(b), withKey: "bounce")
    }
    
    func chat() {
        clearAnimations(); currentState = "chatting"; showState("chat")
        let w = SKAction.sequence([SKAction.rotate(byAngle: 0.08, duration: 0.4), SKAction.rotate(byAngle: -0.08, duration: 0.4)])
        spriteNode.run(SKAction.repeatForever(w), withKey: "chatWave")
    }
    
    func setWorking() {
        clearAnimations(); currentState = "working"; showState("typing")
        let b = SKAction.sequence([SKAction.moveBy(x: 0, y: -1.5, duration: 0.12), SKAction.moveBy(x: 0, y: 1.5, duration: 0.12)])
        spriteNode.run(SKAction.repeatForever(b), withKey: "workBob")
    }
    
    func celebrate(completion: @escaping () -> Void = {}) {
        clearAnimations(); currentState = "celebrating"; showState("celebrate")
        let j = SKAction.sequence([SKAction.moveBy(x: 0, y: 6, duration: 0.12), SKAction.moveBy(x: 0, y: -6, duration: 0.12)])
        spriteNode.run(SKAction.repeat(j, count: 3)) { completion() }
    }
    
    func goToToilet(toiletPos: CGPoint, returnCompletion: @escaping () -> Void) {
        clearAnimations(); currentState = "toilet"; showState("walk")
        walkTo(toiletPos) { [weak self] in
            guard let self = self else { return }
            let fade = SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.wait(forDuration: Double.random(in: 4...7)),
                SKAction.fadeIn(withDuration: 0.4)
            ])
            self.run(fade) { [weak self] in
                guard let self = self else { return }
                self.showState("walk")
                self.walkHome(completion: returnCompletion)
            }
        }
    }
    
    func scrollPhone() {
        clearAnimations(); currentState = "phone"; showState("idle")
        let n = SKAction.sequence([SKAction.rotate(byAngle: 0.05, duration: 0.8), SKAction.rotate(byAngle: -0.05, duration: 0.8)])
        spriteNode.run(SKAction.repeatForever(n), withKey: "phoneNod")
    }
    
    private func clearAnimations() {
        removeAction(forKey: "walkMove")
        removeAction(forKey: "walkScale")
        removeAction(forKey: "toiletWait")
        removeAction(forKey: "breathe")
        spriteNode.removeAllActions()
        spriteNode.zRotation = 0
        spriteNode.xScale = 1
        alpha = 1
    }
}

extension UIColor {
    convenience init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var i: UInt64 = 0; Scanner(string: h).scanHexInt64(&i)
        let r: UInt64, g: UInt64, b: UInt64
        switch h.count { case 6: (r,g,b) = (i>>16,i>>8&0xFF,i&0xFF); case 8: (r,g,b) = (i>>16&0xFF,i>>8&0xFF,i&0xFF); default: (r,g,b) = (0,0,0) }
        self.init(red:CGFloat(r)/255, green:CGFloat(g)/255, blue:CGFloat(b)/255, alpha:1)
    }
}
