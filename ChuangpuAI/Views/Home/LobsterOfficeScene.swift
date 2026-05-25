import SpriteKit
import Foundation

/// 虚拟办公室 v3 - 真实AI背景图+龙虾走来走去
class LobsterOfficeScene: SKScene {
    private var lobsters: [LobsterCharacter] = []
    private let agents: [(String, String)] = [
        ("pm", "主管"), ("file", "文件员"), ("computer", "系统员"),
        ("app", "应用员"), ("browser", "浏览器员"), ("search", "搜索员")
    ]
    // 区域坐标（基于AI背景图的实际位置）
    private var coffeePos: CGPoint = .zero
    private var gymPos: CGPoint = .zero
    private var toiletPos: CGPoint = .zero
    private var chatPos: CGPoint = .zero
    // 后排Y（远）、前排Y（近）、走廊Y
    private var backY: CGFloat = 0
    private var frontY: CGFloat = 0
    private var midY: CGFloat = 0

    override func sceneDidLoad() {
        super.sceneDidLoad()
        let w = size.width, h = size.height
        
        // 布局：后排3工位在上，前排3工位在下
        backY = h * 0.52
        frontY = h * 0.30
        midY = h * 0.41
        
        // 区域位置（匹配背景图中的实际位置）
        coffeePos = CGPoint(x: w * 0.10, y: h * 0.42)
        gymPos = CGPoint(x: w * 0.90, y: h * 0.32)
        toiletPos = CGPoint(x: w * 0.10, y: h * 0.72)
        chatPos = CGPoint(x: w * 0.50, y: midY)
        
        buildScene()
        buildLobsters()
        startBehaviorAI()
    }

    private func buildScene() {
        let w = size.width, h = size.height
        
        // 加载AI生成的办公室背景图
        if let bgImage = UIImage(named: "office_bg") {
            let bgTexture = SKTexture(image: bgImage)
            let bgNode = SKSpriteNode(texture: bgTexture)
            bgNode.position = CGPoint(x: w/2, y: h/2)
            bgNode.zPosition = -10
            // 按场景大小缩放
            let scaleX = w / bgTexture.size().width
            let scaleY = h / bgTexture.size().height
            let scale = max(scaleX, scaleY)
            bgNode.xScale = scale
            bgNode.yScale = scale
            addChild(bgNode)
        } else if let path = Bundle.main.path(forResource: "office_bg", ofType: "jpg") {
            if let img = UIImage(contentsOfFile: path) {
                let bgTexture = SKTexture(image: img)
                let bgNode = SKSpriteNode(texture: bgTexture)
                bgNode.position = CGPoint(x: w/2, y: h/2)
                bgNode.zPosition = -10
                let scaleX = w / bgTexture.size().width
                let scaleY = h / bgTexture.size().height
                let scale = max(scaleX, scaleY)
                bgNode.xScale = scale
                bgNode.yScale = scale
                addChild(bgNode)
            }
        } else {
            // 兜底：纯色背景
            backgroundColor = UIColor(hex: "0D0D1A")
        }
    }

    private func buildLobsters() {
        let w = size.width
        // 后排3只（对应背景图上排3个工位）
        let backXs: [CGFloat] = [0.25, 0.50, 0.75]
        // 前排3只（对应背景图下排3个工位）
        let frontXs: [CGFloat] = [0.25, 0.50, 0.75]
        
        for (idx, ag) in agents.enumerated() {
            let lobster = LobsterCharacter(agentId: ag.0, name: ag.1)
            let home: CGPoint
            if idx < 3 {
                // 后排：Y更高（更远），缩放小
                home = CGPoint(x: w * backXs[idx], y: backY - 8)
                lobster.xScale = 0.75
                lobster.yScale = 0.75
                lobster.zPosition = 15
            } else {
                // 前排：Y更低（更近），正常大小
                home = CGPoint(x: w * frontXs[idx - 3], y: frontY - 8)
                lobster.zPosition = 25
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
            // 走到走廊，再走到咖啡机
            lobster.walkTo(CGPoint(x: lobster.position.x, y: midY)) { [weak self, weak lobster] in
                guard self != nil, let lobster = lobster else { return }
                lobster.walkTo(self!.coffeePos) { [weak self, weak lobster] in
                    guard self != nil, let lobster = lobster else { return }
                    lobster.drinkCoffee()
                    self?.run(SKAction.wait(forDuration: Double.random(in: 5...8))) { [weak self, weak lobster] in
                        guard self != nil, let lobster = lobster else { return }
                        if lobster.currentState == "coffee" { lobster.walkHome { lobster.isBusy = false } }
                    }
                }
            }
        case "gym":
            lobster.walkTo(CGPoint(x: lobster.position.x, y: midY)) { [weak self, weak lobster] in
                guard self != nil, let lobster = lobster else { return }
                lobster.walkTo(self!.gymPos) { [weak self, weak lobster] in
                    guard self != nil, let lobster = lobster else { return }
                    lobster.exercise()
                    self?.run(SKAction.wait(forDuration: Double.random(in: 6...10))) { [weak self, weak lobster] in
                        guard self != nil, let lobster = lobster else { return }
                        if lobster.currentState == "exercise" { lobster.walkHome { lobster.isBusy = false } }
                    }
                }
            }
        case "toilet":
            lobster.walkTo(CGPoint(x: size.width * 0.15, y: midY)) { [weak self, weak lobster] in
                guard self != nil, let lobster = lobster else { return }
                lobster.goToToilet(toiletPos: self!.toiletPos) { [weak lobster] in lobster?.isBusy = false }
            }
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
                lobster.walkTo(CGPoint(x: chatPos.x - 20, y: chatPos.y)) { [weak lobster] in
                    lobster?.chat()
                    lobster?.spriteNode.xScale = -1
                }
                partner.walkTo(CGPoint(x: chatPos.x + 20, y: chatPos.y)) { [weak partner] in
                    partner?.chat()
                }
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
                if lobster.currentState == "working" {
                    lobster.celebrate { lobster.sitAtDesk(); lobster.isBusy = false }
                }
            }
        }
        
        if lobster.position != lobster.homePosition { lobster.walkHome { doWork() } }
        else { doWork() }
    }
}
