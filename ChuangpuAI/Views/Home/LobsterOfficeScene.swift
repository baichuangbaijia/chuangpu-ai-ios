import SpriteKit
import Foundation

/// 虚拟办公室 v8 - 一整张办公室全景图做背景，龙虾在上面走
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
        
        // 放置一整张办公室全景背景图
        placeOfficeBackground()
        
        // 区域坐标（基于场景图中物品的大致位置）
        // 咖啡机在右上区域
        coffeePos = CGPoint(x: w * 0.85, y: h * 0.55)
        // 跑步机在右下区域
        gymPos = CGPoint(x: w * 0.85, y: h * 0.25)
        // 厕所在左上区域
        toiletPos = CGPoint(x: w * 0.12, y: h * 0.70)
        // 聊天区在中间
        chatPos = CGPoint(x: w * 0.50, y: h * 0.45)
        
        buildLobsters()
        startBehaviorAI()
    }
    
    private func placeOfficeBackground() {
        // 加载一整张办公室全景图
        if let tex = loadSprite("office_bg") {
            let bg = SKSpriteNode(texture: tex)
            bg.size = CGSize(width: size.width, height: size.height)
            bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
            bg.zPosition = 0
            addChild(bg)
        } else {
            // 兜底：如果没有图片就用纯色背景
            print("[Office] office_bg not found, using solid background")
        }
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

    private func buildLobsters() {
        let w = size.width, h = size.height
        // 后排3个工位（远处，小一点）
        let backY: CGFloat = h * 0.58
        let backXs: [CGFloat] = [0.25, 0.50, 0.75]
        // 前排3个工位（近处，大一点）
        let frontY: CGFloat = h * 0.30
        let frontXs: [CGFloat] = [0.28, 0.50, 0.72]
        
        for (idx, ag) in agents.enumerated() {
            let lobster = LobsterCharacter(agentId: ag.0, name: ag.1)
            let home: CGPoint
            if idx < 3 {
                home = CGPoint(x: w * backXs[idx], y: backY)
                lobster.xScale = 0.6; lobster.yScale = 0.6; lobster.zPosition = 15
            } else {
                home = CGPoint(x: w * frontXs[idx - 3], y: frontY)
                lobster.xScale = 0.85; lobster.yScale = 0.85; lobster.zPosition = 25
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
