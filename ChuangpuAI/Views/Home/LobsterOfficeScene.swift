import SpriteKit

// MARK: - 虚拟办公室场景
// 6只龙虾在办公室里，有活干活没活摸鱼
class LobsterOfficeScene: SKScene {
    
    private var lobsters: [LobsterCharacter] = []
    private var desks: [SKNode] = []
    private var workTimer: Timer?
    
    // 6个Agent配置
    private let agentConfigs: [(id: String, name: String, color: UIColor, xRatio: CGFloat)] = [
        ("pm",       "主管",     UIColor(hex: "EF4444"), 0.50),  // 红色，中间
        ("file",     "文件员",   UIColor(hex: "3B82F6"), 0.20),  // 蓝色，左
        ("computer", "系统员",   UIColor(hex: "10B981"), 0.35),  // 绿色
        ("app",      "应用员",   UIColor(hex: "F97316"), 0.65),  // 橙色
        ("browser",  "浏览器员", UIColor(hex: "8B5CF6"), 0.80),  // 紫色
        ("search",   "搜索员",   UIColor(hex: "06B6D4"), 0.92)   // 青色
    ]
    
    override func didMove(to view: SKView) {
        super.didMove(to view)
        buildOffice()
        buildLobsters()
        startSimulation()
    }
    
    // MARK: - 搭建办公室
    
    private func buildOffice() {
        backgroundColor = UIColor(hex: "0F0F1A")
        
        let w = size.width
        let h = size.height
        
        // 墙壁
        let wall = SKShapeNode(rectOf: CGSize(width: w, height: h * 0.65))
        wall.fillColor = UIColor(hex: "12122a")
        wall.strokeColor = .clear
        wall.position = CGPoint(x: w/2, y: h * 0.675)
        addChild(wall)
        
        // 地板
        let floor = SKShapeNode(rectOf: CGSize(width: w, height: h * 0.35))
        floor.fillColor = UIColor(hex: "1a1a35")
        floor.strokeColor = .clear
        floor.position = CGPoint(x: w/2, y: h * 0.175)
        addChild(floor)
        
        // 窗户
        let windowW = w * 0.5
        let windowH = h * 0.22
        let windowFrame = SKShapeNode(rectOf: CGSize(width: windowW + 4, height: windowH + 4), cornerRadius: 6)
        windowFrame.fillColor = UIColor(hex: "2a2a4a")
        windowFrame.strokeColor = UIColor(hex: "3a3a5a")
        windowFrame.lineWidth = 2
        windowFrame.position = CGPoint(x: w/2, y: h * 0.72)
        addChild(windowFrame)
        
        let windowBg = SKShapeNode(rectOf: CGSize(width: windowW, height: windowH), cornerRadius: 4)
        windowBg.fillColor = UIColor(hex: "1e3a5f")
        windowBg.strokeColor = .clear
        windowBg.position = CGPoint(x: w/2, y: h * 0.72)
        addChild(windowBg)
        
        // 窗户里的星星
        for _ in 0..<15 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...2))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.3...0.8)
            star.position = CGPoint(
                x: w/2 + CGFloat.random(in: -windowW/2+5...windowW/2-5),
                y: h * 0.72 + CGFloat.random(in: -windowH/2+5...windowH/2-5)
            )
            addChild(star)
            // 闪烁
            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.2...0.5), duration: Double.random(in: 1...2)),
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.6...1.0), duration: Double.random(in: 1...2))
            ])
            star.run(SKAction.repeatForever(twinkle))
        }
        
        // 窗户分隔线
        let vLine = SKShapeNode(rectOf: CGSize(width: 1, height: windowH))
        vLine.fillColor = UIColor(hex: "2a2a4a")
        vLine.strokeColor = .clear
        vLine.position = CGPoint(x: w/2, y: h * 0.72)
        addChild(vLine)
        
        let hLine = SKShapeNode(rectOf: CGSize(width: windowW, height: 1))
        hLine.fillColor = UIColor(hex: "2a2a4a")
        hLine.strokeColor = .clear
        hLine.position = CGPoint(x: w/2, y: h * 0.72)
        addChild(hLine)
        
        // 月亮
        let moon = SKShapeNode(circleOfRadius: 8)
        moon.fillColor = UIColor(hex: "FFFACD")
        moon.strokeColor = .clear
        moon.alpha = 0.7
        moon.position = CGPoint(x: w/2 - windowW/4, y: h * 0.78)
        addChild(moon)
        
        // 办公桌
        for config in agentConfigs {
            let deskX = w * config.xRatio
            let deskY = h * 0.28
            
            // 桌面
            let desk = SKShapeNode(rectOf: CGSize(width: 50, height: 8), cornerRadius: 2)
            desk.fillColor = UIColor(hex: "3a3a5a")
            desk.strokeColor = UIColor(hex: "4a4a6a")
            desk.lineWidth = 1
            desk.position = CGPoint(x: deskX, y: deskY)
            addChild(desk)
            desks.append(desk)
            
            // 显示器
            let monitor = SKShapeNode(rectOf: CGSize(width: 22, height: 16), cornerRadius: 2)
            monitor.fillColor = UIColor(hex: "1a1a3a")
            monitor.strokeColor = UIColor(hex: "4a4a6a")
            monitor.lineWidth = 1
            monitor.position = CGPoint(x: deskX, y: deskY + 12)
            addChild(monitor)
            
            // 屏幕发光
            let screen = SKShapeNode(rectOf: CGSize(width: 18, height: 12), cornerRadius: 1)
            screen.fillColor = UIColor(hex: "7C3AED").withAlphaComponent(0.3)
            screen.strokeColor = .clear
            screen.position = CGPoint(x: deskX, y: deskY + 12)
            addChild(screen)
            
            let screenPulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.15, duration: 2),
                SKAction.fadeAlpha(to: 0.5, duration: 2)
            ])
            screen.run(SKAction.repeatForever(screenPulse))
            
            // 椅子
            let chair = SKShapeNode(ellipseOf: CGSize(width: 18, height: 14))
            chair.fillColor = UIColor(hex: "2a2a4a")
            chair.strokeColor = UIColor(hex: "3a3a5a")
            chair.lineWidth = 1
            chair.position = CGPoint(x: deskX, y: deskY - 8)
            addChild(chair)
        }
    }
    
    // MARK: - 创建龙虾
    
    private func buildLobsters() {
        let w = size.width
        let h = size.height
        
        for config in agentConfigs {
            let lobster = LobsterCharacter(
                agentId: config.id,
                name: config.name,
                color: config.color
            )
            lobster.position = CGPoint(x: w * config.xRatio, y: h * 0.36)
            lobster.setScale(0.7)
            addChild(lobster)
            lobsters.append(lobster)
        }
    }
    
    // MARK: - 模拟工作
    
    private func startSimulation() {
        // 8-15秒随机让一只虾开始工作
        scheduleWork()
        // 15-25秒随机两只虾聊天
        scheduleChat()
    }
    
    private func scheduleWork() {
        let delay = 8.0 + Double.random(in: 0...7)
        workTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.simulateWork()
            self?.scheduleWork()
        }
    }
    
    private func simulateWork() {
        let lobster = lobsters.randomElement()!
        lobster.setWorking()
        
        // 5-10秒后完成
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 5...10)) { [weak self] in
            guard let self = self else { return }
            if lobster.currentState == .working {
                lobster.setCelebrating()
            }
        }
    }
    
    private func scheduleChat() {
        let delay = 15.0 + Double.random(in: 0...10)
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.simulateChat()
            self?.scheduleChat()
        }
    }
    
    private func simulateChat() {
        guard lobsters.count >= 2 else { return }
        let i1 = Int.random(in: 0..<lobsters.count)
        var i2 = Int.random(in: 0..<lobsters.count)
        while i2 == i1 { i2 = Int.random(in: 0..<lobsters.count) }
        
        let l1 = lobsters[i1], l2 = lobsters[i2]
        // 只在空闲时聊天
        if l1.currentState == .idle && l2.currentState == .idle {
            l1.setIdle()
            l2.setIdle()
        }
    }
    
    // MARK: - 外部接口（供SwiftUI调用）
    
    func agentStartWorking(_ agentId: String) {
        if let l = lobsters.first(where: { $0.agentId == agentId }) {
            l.setWorking()
        }
    }
    
    func agentComplete(_ agentId: String) {
        if let l = lobsters.first(where: { $0.agentId == agentId }) {
            l.setCelebrating()
        }
    }
    
    func agentError(_ agentId: String) {
        if let l = lobsters.first(where: { $0.agentId == agentId }) {
            l.setPanicking()
        }
    }
}
