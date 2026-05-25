import SpriteKit
import Foundation

/// 虚拟办公室 v10 - 无墙房间，物品直接摆在APP背景上
class LobsterOfficeScene: SKScene {
    private var lobsters: [LobsterCharacter] = []
    private let agents: [(String, String)] = [
        ("pm", "主管"), ("file", "文件员"), ("computer", "系统员"),
        ("app", "应用员"), ("browser", "浏览器员"), ("search", "搜索员")
    ]
    private var coffeePos: CGPoint = .zero
    private var gymPos: CGPoint = .zero
    private var toiletPos: CGPoint = .zero
    private var chatPos: CGPoint = .zero

    override func sceneDidLoad() {
        super.sceneDidLoad()
        let w = size.width, h = size.height
        backgroundColor = UIColor(hex: "0D0D1A")
        
        // 各区域坐标
        coffeePos = CGPoint(x: w * 0.87, y: h * 0.55)
        gymPos = CGPoint(x: w * 0.87, y: h * 0.22)
        toiletPos = CGPoint(x: w * 0.10, y: h * 0.72)
        chatPos = CGPoint(x: w * 0.50, y: h * 0.42)
        
        placeItems()
        buildLobsters()
        startBehaviorAI()
    }
    
    private func loadSprite(_ name: String) -> SKTexture? {
        if let img = UIImage(named: name) {
            let t = SKTexture(image: img)
            t.filteringMode = .linear
            return t
        }
        if let p = Bundle.main.path(forResource: name, ofType: "png") {
            if let img = UIImage(contentsOfFile: p) {
                let t = SKTexture(image: img)
                t.filteringMode = .linear
                return t
            }
        }
        return nil
    }
    
    private func placeItem(named: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, z: CGFloat) {
        guard let tex = loadSprite(named) else { return }
        let node = SKSpriteNode(texture: tex)
        node.size = CGSize(width: w, height: h)
        node.position = CGPoint(x: x, y: y)
        node.zPosition = z
        node.blendMode = .replace
        addChild(node)
    }

    private func placeItems() {
        let w = size.width, h = size.height
        
        // 后排3个工位（远处，小一点）
        let backY: CGFloat = h * 0.65
        let backXs: [CGFloat] = [0.22, 0.46, 0.68]
        for xr in backXs {
            placeItem(named: "desk", x: w * xr, y: backY, w: 90, h: 54, z: 5)
        }
        
        // 前排3个工位（近处，大一点）
        let frontY: CGFloat = h * 0.30
        let frontXs: [CGFloat] = [0.25, 0.50, 0.72]
        for xr in frontXs {
            placeItem(named: "desk", x: w * xr, y: frontY, w: 110, h: 66, z: 5)
        }
        
        // 咖啡机（右侧中间）
        placeItem(named: "coffee", x: w * 0.87, y: h * 0.58, w: 65, h: 65, z: 5)
        
        // 跑步机（右侧下方）
        placeItem(named: "treadmill", x: w * 0.87, y: h * 0.22, w: 65, h: 65, z: 5)
        
        // 厕所（左侧上方）
        placeItem(named: "toilet", x: w * 0.10, y: h * 0.72, w: 55, h: 55, z: 5)
    }

    private func buildLobsters() {
        let w = size.width, h = size.height
        let backY: CGFloat = h * 0.58
        let backXs: [CGFloat] = [0.22, 0.46, 0.68]
        let frontY: CGFloat = h * 0.23
        let frontXs: [CGFloat] = [0.25, 0.50, 0.72]
        
        for (idx, ag) in agents.enumerated() {
            let lobster = LobsterCharacter(agentId: ag.0, name: ag.1)
            let home: CGPoint
            if idx < 3 {
                home = CGPoint(x: w * backXs[idx], y: backY)
                lobster.xScale = 0.5; lobster.yScale = 0.5; lobster.zPosition = 15
            } else {
                home = CGPoint(x: w * frontXs[idx - 3], y: frontY)
                lobster.xScale = 0.75; lobster.yScale = 0.75; lobster.zPosition = 25
            }
            lobster.position = home
            lobster.homePosition = home
            lobster.sitAtDesk()
            addChild(lobster)
            lobsters.append(lobster)
        }
    }

    // MARK: - 行为AI
    private func startBehaviorAI() {
        let idleCycle = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in: 3...6)),
            SKAction.run { [weak self] in self?.triggerIdleBehavior() }
        ]))
        run(idleCycle, withKey: "idleCycle")
        let workCycle = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in: 10...16)),
            SKAction.run { [weak self] in self?.triggerWork() }
        ]))
        run(workCycle, withKey: "workCycle")
    }

    private func triggerIdleBehavior() {
        let idle = lobsters.filter { $0.currentState == "idle" && !$0.isBusy }
        guard let lobster = idle.randomElement() else { return }
        lobster.isBusy = true
        let actions = ["coffee", "gym", "toilet", "phone", "sleep", "chat"]
        let action = actions.randomElement()!
        switch action {
        case "coffee":
            lobster.walkTo(coffeePos) { [weak self, weak lobster] in
                guard self != nil, let lobster = lobster else { return }
                lobster.drinkCoffee()
                self?.run(SKAction.wait(forDuration: Double.random(in: 5...8))) { [weak self, weak lobster] in
                    guard self != nil, let lobster = lobster else { return }
                    if lobster.currentState == "coffee" { lobster.walkHome { lobster.isBusy = false } }
                }
            }
        case "gym":
            lobster.walkTo(gymPos) { [weak self, weak lobster] in
                guard self != nil, let lobster = lobster else { return }
                lobster.exercise()
                self?.run(SKAction.wait(forDuration: Double.random(in: 6...10))) { [weak self, weak lobster] in
                    guard self != nil, let lobster = lobster else { return }
                    if lobster.currentState == "exercise" { lobster.walkHome { lobster.isBusy = false } }
                }
            }
        case "toilet":
            lobster.goToToilet(toiletPos: toiletPos) { [weak lobster] in lobster?.isBusy = false }
        case "phone":
            lobster.scrollPhone()
            run(SKAction.wait(forDuration: Double.random(in: 5...8))) { [weak lobster] in
                guard let lobster = lobster else { return }
                if lobster.currentState == "phone" { lobster.sitAtDesk(); lobster.isBusy = false }
            }
        case "sleep":
            lobster.sleepAtDesk()
            run(SKAction.wait(forDuration: Double.random(in: 8...14))) { [weak lobster] in
                guard let lobster = lobster else { return }
                if lobster.currentState == "sleeping" { lobster.sitAtDesk(); lobster.isBusy = false }
            }
        case "chat":
            let partners = lobsters.filter { $0.agentId != lobster.agentId && $0.currentState == "idle" && !$0.isBusy }
            if let partner = partners.randomElement() {
                partner.isBusy = true
                lobster.walkTo(CGPoint(x: chatPos.x - 20, y: chatPos.y)) { [weak lobster] in lobster?.chat(); lobster?.spriteNode.xScale = -1 }
                partner.walkTo(CGPoint(x: chatPos.x + 20, y: chatPos.y)) { [weak partner] in partner?.chat() }
                run(SKAction.wait(forDuration: Double.random(in: 5...9))) { [weak self] in
                    guard let self = self else { return }
                    let ch = self.lobsters.filter { $0.currentState == "chatting" }
                    for l in ch { l.walkHome { l.isBusy = false } }
                }
            } else { lobster.isBusy = false }
        default: lobster.isBusy = false
        }
    }

    private func triggerWork() {
        let idle = lobsters.filter { $0.currentState == "idle" || $0.currentState == "sleeping" || $0.currentState == "phone" }
        guard let lobster = idle.randomElement() else { return }
        lobster.isBusy = true
        let doWork = { [weak self, weak lobster] in
            guard let self = self, let lobster = lobster else { return }
            lobster.position = lobster.homePosition
            lobster.setWorking()
            self.run(SKAction.wait(forDuration: Double.random(in: 8...14))) { [weak self, weak lobster] in
                guard let self = self, let lobster = lobster else { return }
                if lobster.currentState == "working" { lobster.celebrate { lobster.sitAtDesk(); lobster.isBusy = false } }
            }
        }
        if lobster.position != lobster.homePosition { lobster.walkHome { doWork() } }
        else { doWork() }
    }
}
