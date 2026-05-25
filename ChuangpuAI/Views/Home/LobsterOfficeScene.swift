import SpriteKit
import Foundation

/// 虚拟办公室场景
class LobsterOfficeScene: SKScene {
    
    private var lobsters: [LobsterCharacter] = []
    
    private let agentConfigs: [(String, String, UIColor, CGFloat)] = [
        ("pm",       "主管",     UIColor(hex: "EF4444"), 0.50),
        ("file",     "文件员",   UIColor(hex: "3B82F6"), 0.20),
        ("computer", "系统员",   UIColor(hex: "10B981"), 0.35),
        ("app",      "应用员",   UIColor(hex: "F97316"), 0.65),
        ("browser",  "浏览器员", UIColor(hex: "8B5CF6"), 0.80),
        ("search",   "搜索员",   UIColor(hex: "06B6D4"), 0.92)
    ]
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        buildOffice()
        buildLobsters()
        startSimulation()
    }
    
    private func buildOffice() {
        backgroundColor = UIColor(hex: "0F0F1A")
        let w = size.width
        let h = size.height
        
        // 地板
        let floor = SKShapeNode(rectOf: CGSize(width: w, height: h * 0.35))
        floor.fillColor = UIColor(hex: "1a1a35")
        floor.strokeColor = .clear
        floor.position = CGPoint(x: w/2, y: h * 0.175)
        addChild(floor)
        
        // 窗户
        let winW = w * 0.5, winH = h * 0.22
        let winFrame = SKShapeNode(rectOf: CGSize(width: winW + 4, height: winH + 4), cornerRadius: 6)
        winFrame.fillColor = UIColor(hex: "2a2a4a")
        winFrame.strokeColor = UIColor(hex: "3a3a5a")
        winFrame.lineWidth = 2
        winFrame.position = CGPoint(x: w/2, y: h * 0.72)
        addChild(winFrame)
        
        let winBg = SKShapeNode(rectOf: CGSize(width: winW, height: winH), cornerRadius: 4)
        winBg.fillColor = UIColor(hex: "1e3a5f")
        winBg.strokeColor = .clear
        winBg.position = CGPoint(x: w/2, y: h * 0.72)
        addChild(winBg)
        
        // 星星
        for _ in 0..<12 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...1.5))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.3...0.8)
            star.position = CGPoint(
                x: w/2 + CGFloat.random(in: -winW/2+5...winW/2-5),
                y: h * 0.72 + CGFloat.random(in: -winH/2+5...winH/2-5)
            )
            addChild(star)
            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.2...0.4), duration: Double.random(in: 1...2)),
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.6...1.0), duration: Double.random(in: 1...2))
            ])
            star.run(SKAction.repeatForever(twinkle))
        }
        
        // 月亮
        let moon = SKShapeNode(circleOfRadius: 6)
        moon.fillColor = UIColor(red: 1, green: 0.98, blue: 0.8, alpha: 0.7)
        moon.strokeColor = .clear
        moon.position = CGPoint(x: w/2 - winW/4, y: h * 0.78)
        addChild(moon)
        
        // 办公桌
        for config in agentConfigs {
            let deskX = w * config.3
            let deskY = h * 0.28
            
            let desk = SKShapeNode(rectOf: CGSize(width: 50, height: 8), cornerRadius: 2)
            desk.fillColor = UIColor(hex: "3a3a5a")
            desk.strokeColor = UIColor(hex: "4a4a6a")
            desk.lineWidth = 1
            desk.position = CGPoint(x: deskX, y: deskY)
            addChild(desk)
            
            let monitor = SKShapeNode(rectOf: CGSize(width: 22, height: 16), cornerRadius: 2)
            monitor.fillColor = UIColor(hex: "1a1a3a")
            monitor.strokeColor = UIColor(hex: "4a4a6a")
            monitor.lineWidth = 1
            monitor.position = CGPoint(x: deskX, y: deskY + 12)
            addChild(monitor)
            
            let screen = SKShapeNode(rectOf: CGSize(width: 18, height: 12), cornerRadius: 1)
            screen.fillColor = UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 0.3)
            screen.strokeColor = .clear
            screen.position = CGPoint(x: deskX, y: deskY + 12)
            addChild(screen)
            
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.15, duration: 2),
                SKAction.fadeAlpha(to: 0.5, duration: 2)
            ])
            screen.run(SKAction.repeatForever(pulse))
            
            let chair = SKShapeNode(ellipseOf: CGSize(width: 18, height: 14))
            chair.fillColor = UIColor(hex: "2a2a4a")
            chair.strokeColor = UIColor(hex: "3a3a5a")
            chair.lineWidth = 1
            chair.position = CGPoint(x: deskX, y: deskY - 8)
            addChild(chair)
        }
    }
    
    private func buildLobsters() {
        let w = size.width
        let h = size.height
        
        for config in agentConfigs {
            let lobster = LobsterCharacter(
                agentId: config.0,
                name: config.1,
                color: config.2
            )
            lobster.position = CGPoint(x: w * config.3, y: h * 0.36)
            lobster.setScale(0.7)
            addChild(lobster)
            lobsters.append(lobster)
        }
    }
    
    private func startSimulation() {
        // 用SKAction定时触发工作
        let workCycle = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in: 8...15)),
            SKAction.run { [weak self] in self?.simulateWork() }
        ]))
        run(workCycle, withKey: "workCycle")
    }
    
    private func simulateWork() {
        let lobster = lobsters.randomElement()!
        if lobster.currentState == "idle" {
            lobster.setWorking()
        }
    }
}
