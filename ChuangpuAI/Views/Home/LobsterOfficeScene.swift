import SpriteKit
import Foundation

/// 虚拟办公室 v9 - 完整办公室背景图+龙虾限定在房间内
class LobsterOfficeScene: SKScene {
    private var lobsters: [LobsterCharacter] = []
    private let agents: [(String, String)] = [
        ("pm", "主管"), ("file", "文件员"), ("computer", "系统员"),
        ("app", "应用员"), ("browser", "浏览器员"), ("search", "搜索员")
    ]
    // 房间内部安全边界（比例），龙虾不能走出这个范围
    private let safeLeft: CGFloat = 0.10
    private let safeRight: CGFloat = 0.90
    private let safeTop: CGFloat = 0.85
    private let safeBottom: CGFloat = 0.12
    
    private var coffeePos: CGPoint = .zero
    private var gymPos: CGPoint = .zero
    private var toiletPos: CGPoint = .zero
    private var chatPos: CGPoint = .zero

    override func sceneDidLoad() {
        super.sceneDidLoad()
        let w = size.width, h = size.height
        backgroundColor = UIColor(hex: "0D0D1A")
        
        // 放置完整办公室背景图
        placeOfficeBackground()
        
        // 各区域坐标——全部在房间内部
        coffeePos = safePoint(CGPoint(x: w * 0.80, y: h * 0.52))
        gymPos = safePoint(CGPoint(x: w * 0.80, y: h * 0.22))
        toiletPos = safePoint(CGPoint(x: w * 0.16, y: h * 0.72))
        chatPos = safePoint(CGPoint(x: w * 0.50, y: h * 0.42))
        
        buildLobsters()
        startBehaviorAI()
    }
    
    /// 把坐标限定在房间安全区内
    private func safePoint(_ p: CGPoint) -> CGPoint {
        CGPoint(
            x: max(size.width * safeLeft, min(size.width * safeRight, p.x)),
            y: max(size.height * safeBottom, min(size.height * safeTop, p.y))
        )
    }
    
    private func placeOfficeBackground() {
        if let tex = loadSprite("office_bg") {
            let bg = SKSpriteNode(texture: tex)
            bg.size = CGSize(width: size.width, height: size.height)
            bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
            bg.zPosition = 0
            addChild(bg)
        } else {
            print("[Office] office_bg not found")
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
        // 后排3个工位（远处偏上，小）
        let backY: CGFloat = h * 0.66
        let backXs: [CGFloat] = [0.30, 0.50, 0.70]
        // 前排3个工位（近处偏下，大）
        let frontY: CGFloat = h * 0.32
        let frontXs: [CGFloat] = [0.32, 0.50, 0.68]
        
        for (idx, ag) in agents.enumerated() {
            let lobster = LobsterCharacter(agentId: ag.0, name: ag.1)
            var home: CGPoint
            if idx < 3 {
                home = safePoint(CGPoint(x: w * backXs[idx], y: backY))
                lobster.xScale = 0.5; lobster.yScale = 0.5; lobster.zPosition = 15
            } else {
                home = safePoint(CGPoint(x: w * frontXs[idx - 3], y: frontY))
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
            lobster.walkTo(safePoint(coffeePos)) { [weak self, weak lobster] in
                guard self != nil, let lobster = lobster else { return }
                lobster.drinkCoffee()
                self?.run(SKAction.wait(forDuration: Double.random(in: 5...8))) { [weak self, weak lobster] in
                    guard self != nil, let lobster = lobster else { return }
                    if lobster.currentState == "coffee" { lobster.walkHome { lobster.isBusy = false } }
                }
            }
        case "gym":
            lobster.walkTo(safePoint(gymPos)) { [weak self, weak lobster] in
                guard self != nil, let lobster = lobster else { return }
                lobster.exercise()
                self?.run(SKAction.wait(forDuration: Double.random(in: 6...10))) { [weak self, weak lobster] in
                    guard self != nil, let lobster = lobster else { return }
                    if lobster.currentState == "exercise" { lobster.walkHome { lobster.isBusy = false } }
                }
            }
        case "toilet":
            lobster.goToToilet(toiletPos: safePoint(toiletPos)) { [weak lobster] in lobster?.isBusy = false }
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
                lobster.walkTo(safePoint(CGPoint(x: chatPos.x - 20, y: chatPos.y))) { [weak lobster] in lobster?.chat(); lobster?.spriteNode.xScale = -1 }
                partner.walkTo(safePoint(CGPoint(x: chatPos.x + 20, y: chatPos.y))) { [weak partner] in partner?.chat() }
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
