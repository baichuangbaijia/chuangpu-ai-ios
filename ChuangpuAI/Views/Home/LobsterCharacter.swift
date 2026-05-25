import SpriteKit
import Foundation

/// 龙虾角色 - AI图片纹理版，可走动+多区域+行为AI
class LobsterCharacter: SKNode {
    let agentId: String
    let agentName: String
    let colorKey: String
    
    // 纹理
    private var textures: [String: SKTexture] = [:]
    private let spriteNode = SKSpriteNode()
    
    // 名字和状态
    private var nameLabel: SKLabelNode!
    private var statusDot: SKShapeNode!
    
    var currentState: String = "idle"
    var homePosition: CGPoint = .zero
    var isBusy: Bool = false
    
    // 颜色映射
    private static let colorMap: [String: String] = [
        "pm": "red", "file": "blue", "computer": "green",
        "app": "orange", "browser": "purple", "search": "cyan"
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
                textures[state]?.filteringMode = .nearest
            }
        }
    }
    
    private func buildUI() {
        spriteNode.size = CGSize(width: 60, height: 60)
        spriteNode.anchorPoint = CGPoint(x: 0.5, y: 0.3)
        spriteNode.zPosition = 10
        addChild(spriteNode)
        
        nameLabel = SKLabelNode(text: agentName)
        nameLabel.fontSize = 8
        nameLabel.fontColor = UIColor(hex: colorKey == "red" ? "EF4444" : colorKey == "blue" ? "3B82F6" : colorKey == "green" ? "10B981" : colorKey == "orange" ? "F97316" : colorKey == "purple" ? "8B5CF6" : "06B6D4")
        nameLabel.fontName = "PingFangSC-Medium"
        nameLabel.position = CGPoint(x: 0, y: -15)
        nameLabel.zPosition = 11
        addChild(nameLabel)
        
        statusDot = SKShapeNode(circleOfRadius: 3)
        statusDot.fillColor = .gray
        statusDot.strokeColor = .clear
        statusDot.position = CGPoint(x: 22, y: 30)
        statusDot.zPosition = 11
        addChild(statusDot)
    }
    
    private func showState(_ state: String) {
        if let tex = textures[state] {
            spriteNode.texture = tex
        }
    }
    
    // MARK: - 走路到目标
    func walkTo(_ target: CGPoint, speed: CGFloat = 50, completion: @escaping () -> Void) {
        clearAnimations()
        currentState = "walking"
        showState("walk")
        
        let dx = target.x - position.x
        spriteNode.xScale = dx > 0 ? 1 : -1
        
        // 走路晃动效果
        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: 0.08, duration: 0.2),
            SKAction.rotate(byAngle: -0.08, duration: 0.2)
        ])
        spriteNode.run(SKAction.repeatForever(wobble), withKey: "walkWobble")
        
        let dist = sqrt(dx*dx + (target.y-position.y)*(target.y-position.y))
        let dur = Double(dist) / Double(speed)
        
        run(SKAction.move(to: target, duration: dur), withKey: "walkMove") { [weak self] in
            self?.clearAnimations()
            self?.spriteNode.xScale = 1
            completion()
        }
    }
    
    func walkHome(completion: @escaping () -> Void = {}) {
        walkTo(homePosition) { [weak self] in
            self?.sitAtDesk()
            completion()
        }
    }
    
    // MARK: - 各状态
    
    func sitAtDesk() {
        clearAnimations()
        currentState = "idle"
        showState("idle")
        statusDot.fillColor = .gray
        // 微微呼吸
        let breathe = SKAction.sequence([SKAction.scaleX(to:1.03,duration:1.5), SKAction.scaleX(to:1.0,duration:1.5)])
        spriteNode.run(SKAction.repeatForever(breathe), withKey: "breathe")
    }
    
    func sleepAtDesk() {
        clearAnimations()
        currentState = "sleeping"
        showState("sleep")
        statusDot.fillColor = .gray
        let sway = SKAction.sequence([SKAction.rotate(byAngle:0.05,duration:2), SKAction.rotate(byAngle:-0.05,duration:2)])
        spriteNode.run(SKAction.repeatForever(sway), withKey: "sleepSway")
    }
    
    func drinkCoffee() {
        clearAnimations()
        currentState = "coffee"
        showState("coffee")
        statusDot.fillColor = .gray
        let sip = SKAction.sequence([SKAction.rotate(byAngle:0.1,duration:0.8), SKAction.rotate(byAngle:-0.1,duration:0.8)])
        spriteNode.run(SKAction.repeatForever(sip), withKey: "sip")
    }
    
    func exercise() {
        clearAnimations()
        currentState = "exercise"
        showState("exercise")
        statusDot.fillColor = .gray
        let bounce = SKAction.sequence([SKAction.moveBy(x:0,y:3,duration:0.3), SKAction.moveBy(x:0,y:-3,duration:0.3)])
        spriteNode.run(SKAction.repeatForever(bounce), withKey: "bounce")
    }
    
    func chat() {
        clearAnimations()
        currentState = "chatting"
        showState("chat")
        statusDot.fillColor = .gray
        let wave = SKAction.sequence([SKAction.rotate(byAngle:0.08,duration:0.5), SKAction.rotate(byAngle:-0.08,duration:0.5)])
        spriteNode.run(SKAction.repeatForever(wave), withKey: "chatWave")
    }
    
    func setWorking() {
        clearAnimations()
        currentState = "working"
        showState("typing")
        statusDot.fillColor = UIColor(red:0.06,green:0.73,blue:0.51,alpha:1)
        let bob = SKAction.sequence([SKAction.moveBy(x:0,y:-1,duration:0.15), SKAction.moveBy(x:0,y:1,duration:0.15)])
        spriteNode.run(SKAction.repeatForever(bob), withKey: "workBob")
    }
    
    func celebrate(completion: @escaping () -> Void = {}) {
        clearAnimations()
        currentState = "celebrating"
        showState("celebrate")
        let jump = SKAction.sequence([SKAction.moveBy(x:0,y:6,duration:0.15), SKAction.moveBy(x:0,y:-6,duration:0.15)])
        spriteNode.run(SKAction.repeat(jump, count: 3), withKey: "jump") { completion() }
    }
    
    func goToToilet(toiletPos: CGPoint, returnCompletion: @escaping () -> Void) {
        clearAnimations()
        currentState = "toilet"
        showState("walk")
        walkTo(toiletPos) { [weak self] in
            guard let self = self else { return }
            let fade = SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.wait(forDuration: Double.random(in: 4...7)),
                SKAction.fadeIn(withDuration: 0.4)
            ])
            self.run(fade, withKey: "toiletWait") { [weak self] in
                guard let self = self else { return }
                self.showState("walk")
                self.walkHome(completion: returnCompletion)
            }
        }
    }
    
    func scrollPhone() {
        clearAnimations()
        currentState = "phone"
        showState("idle")
        statusDot.fillColor = .gray
        let nod = SKAction.sequence([SKAction.rotate(byAngle:0.05,duration:1), SKAction.rotate(byAngle:-0.05,duration:1)])
        spriteNode.run(SKAction.repeatForever(nod), withKey: "phoneNod")
    }
    
    // MARK: - 清理
    private func clearAnimations() {
        removeAction(forKey: "walkMove")
        removeAction(forKey: "toiletWait")
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
