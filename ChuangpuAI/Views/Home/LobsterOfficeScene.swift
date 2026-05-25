import SpriteKit
import Foundation

/// 虚拟办公室 - 完整版：AI图片龙虾+区域+走路+行为AI
class LobsterOfficeScene: SKScene {
    
    private var lobsters: [LobsterCharacter] = []
    
    private let agents: [(String, String)] = [
        ("pm",       "主管"),
        ("file",     "文件员"),
        ("computer", "系统员"),
        ("app",      "应用员"),
        ("browser",  "浏览器员"),
        ("search",   "搜索员")
    ]
    
    // 区域坐标
    private var coffeePos: CGPoint = .zero
    private var gymPos: CGPoint = .zero
    private var toiletPos: CGPoint = .zero
    private var chatPos: CGPoint = .zero
    private var floorY: CGFloat = 0
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        let w = size.width, h = size.height
        floorY = h * 0.38
        coffeePos = CGPoint(x: w * 0.07, y: floorY)
        gymPos = CGPoint(x: w * 0.93, y: floorY)
        toiletPos = CGPoint(x: w * 0.04, y: floorY + 5)
        chatPos = CGPoint(x: w * 0.50, y: floorY - 5)
        
        buildOffice()
        buildLobsters()
        startBehaviorAI()
    }
    
    private func buildOffice() {
        let w = size.width, h = size.height
        backgroundColor = UIColor(hex: "0F0F1A")
        
        // 地板
        let floor = SKShapeNode(rectOf: CGSize(width:w, height:h*0.42))
        floor.fillColor = UIColor(hex:"1a1a35"); floor.strokeColor = .clear
        floor.position = CGPoint(x:w/2, y:h*0.21); addChild(floor)
        
        // 地板线
        let floorLine = SKShapeNode(rectOf: CGSize(width:w, height:1))
        floorLine.fillColor = UIColor(hex:"2a2a4a"); floorLine.strokeColor = .clear
        floorLine.position = CGPoint(x:w/2, y:floorY-18); addChild(floorLine)
        
        // 窗户
        let winW = w*0.45, winH = h*0.18
        let wf = SKShapeNode(rectOf:CGSize(width:winW+4,height:winH+4),cornerRadius:5)
        wf.fillColor = UIColor(hex:"2a2a4a"); wf.strokeColor = UIColor(hex:"3a3a5a"); wf.lineWidth = 2
        wf.position = CGPoint(x:w/2,y:h*0.75); addChild(wf)
        let wb = SKShapeNode(rectOf:CGSize(width:winW,height:winH),cornerRadius:3)
        wb.fillColor = UIColor(hex:"1e3a5f"); wb.strokeColor = .clear
        wb.position = CGPoint(x:w/2,y:h*0.75); addChild(wb)
        
        for _ in 0..<8 {
            let s = SKShapeNode(circleOfRadius:CGFloat.random(in:0.5...1.5))
            s.fillColor = .white; s.strokeColor = .clear; s.alpha = CGFloat.random(in:0.3...0.8)
            s.position = CGPoint(x:w/2+CGFloat.random(in:-winW/2+5...winW/2-5), y:h*0.75+CGFloat.random(in:-winH/2+5...winH/2-5))
            addChild(s)
            s.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to:0.2,duration:Double.random(in:1...2)),SKAction.fadeAlpha(to:0.8,duration:Double.random(in:1...2))])))
        }
        
        // 月亮
        let moon = SKShapeNode(circleOfRadius:5); moon.fillColor = UIColor(red:1,green:0.98,blue:0.8,alpha:0.5); moon.strokeColor = .clear
        moon.position = CGPoint(x:w/2-winW/4,y:h*0.82); addChild(moon)
        
        // 工位X位置
        let deskXs = [0.20, 0.35, 0.50, 0.65, 0.80, 0.92]
        for (idx, xr) in deskXs.enumerated() {
            let dx = w * xr, dy = floorY + 4
            
            // 桌子
            let desk = SKShapeNode(rectOf:CGSize(width:38,height:5),cornerRadius:2)
            desk.fillColor = UIColor(hex:"3a3a5a"); desk.strokeColor = UIColor(hex:"4a4a6a"); desk.lineWidth = 1
            desk.position = CGPoint(x:dx,y:dy); addChild(desk)
            
            // 显示器
            let mon = SKShapeNode(rectOf:CGSize(width:16,height:11),cornerRadius:2)
            mon.fillColor = UIColor(hex:"1a1a3a"); mon.strokeColor = UIColor(hex:"4a4a6a"); mon.lineWidth = 1
            mon.position = CGPoint(x:dx,y:dy+9); addChild(mon)
            let scr = SKShapeNode(rectOf:CGSize(width:12,height:7),cornerRadius:1)
            scr.fillColor = UIColor(red:0.49,green:0.23,blue:0.93,alpha:0.3); scr.strokeColor = .clear
            scr.position = CGPoint(x:dx,y:dy+9); addChild(scr)
            scr.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to:0.15,duration:2),SKAction.fadeAlpha(to:0.5,duration:2)])))
            
            // 椅子
            let chair = SKShapeNode(ellipseOf:CGSize(width:14,height:10))
            chair.fillColor = UIColor(hex:"2a2a4a"); chair.strokeColor = UIColor(hex:"3a3a5a"); chair.lineWidth = 1
            chair.position = CGPoint(x:dx,y:dy-7); addChild(chair)
        }
        
        // 咖啡机
        let cm = SKShapeNode(rectOf:CGSize(width:18,height:20),cornerRadius:3)
        cm.fillColor = UIColor(hex:"4a3a2a"); cm.strokeColor = UIColor(hex:"6a5a4a"); cm.lineWidth = 1
        cm.position = coffeePos; addChild(cm)
        let cmL = SKLabelNode(text:"☕"); cmL.fontSize = 10; cmL.position = CGPoint(x:coffeePos.x,y:coffeePos.y+2); addChild(cmL)
        
        // 健身角
        let gym = SKShapeNode(rectOf:CGSize(width:24,height:18),cornerRadius:4)
        gym.fillColor = UIColor(hex:"2a3a2a"); gym.strokeColor = UIColor(hex:"4a6a4a"); gym.lineWidth = 1
        gym.position = gymPos; addChild(gym)
        let gymL = SKLabelNode(text:"🏋️"); gymL.fontSize = 8; gymL.position = CGPoint(x:gymPos.x,y:gymPos.y); addChild(gymL)
        
        // 厕所
        let tl = SKShapeNode(rectOf:CGSize(width:14,height:24),cornerRadius:2)
        tl.fillColor = UIColor(hex:"3a4a5a"); tl.strokeColor = UIColor(hex:"5a6a7a"); tl.lineWidth = 1
        tl.position = toiletPos; addChild(tl)
        let tlL = SKLabelNode(text:"🚻"); tlL.fontSize = 7; tlL.position = CGPoint(x:toiletPos.x,y:toiletPos.y); addChild(tlL)
    }
    
    private func buildLobsters() {
        let w = size.width
        let xs: [CGFloat] = [0.20, 0.35, 0.50, 0.65, 0.80, 0.92]
        
        for (idx, ag) in agents.enumerated() {
            let lobster = LobsterCharacter(agentId: ag.0, name: ag.1)
            let home = CGPoint(x: w * xs[idx], y: floorY - 6)
            lobster.position = home
            lobster.homePosition = home
            lobster.sitAtDesk()
            addChild(lobster)
            lobsters.append(lobster)
        }
    }
    
    // MARK: - 行为AI
    
    private func startBehaviorAI() {
        // 空闲行为
        let idleCycle = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in:5...8)),
            SKAction.run { [weak self] in self?.triggerIdleBehavior() }
        ]))
        run(idleCycle, withKey:"idleCycle")
        
        // 工作触发
        let workCycle = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in:10...18)),
            SKAction.run { [weak self] in self?.triggerWork() }
        ]))
        run(workCycle, withKey:"workCycle")
    }
    
    private func triggerIdleBehavior() {
        let idle = lobsters.filter { $0.currentState == "idle" && !$0.isBusy }
        guard let lobster = idle.randomElement() else { return }
        lobster.isBusy = true
        
        let actions = ["coffee","gym","toilet","phone","sleep","chat"]
        let action = actions.randomElement()!
        
        switch action {
        case "coffee":
            lobster.walkTo(coffeePos) { [weak self, weak lobster] in
                guard let self = self, let lobster = lobster else { return }
                lobster.drinkCoffee()
                self.run(SKAction.wait(forDuration:Double.random(in:5...8))) { [weak self, weak lobster] in
                    guard let self = self, let lobster = lobster else { return }
                    if lobster.currentState == "coffee" { lobster.walkHome { lobster.isBusy = false } }
                }
            }
        case "gym":
            lobster.walkTo(gymPos) { [weak self, weak lobster] in
                guard let self = self, let lobster = lobster else { return }
                lobster.exercise()
                self.run(SKAction.wait(forDuration:Double.random(in:6...10))) { [weak self, weak lobster] in
                    guard let self = self, let lobster = lobster else { return }
                    if lobster.currentState == "exercise" { lobster.walkHome { lobster.isBusy = false } }
                }
            }
        case "toilet":
            lobster.goToToilet(toiletPos: CGPoint(x:toiletPos.x+6,y:toiletPos.y)) { [weak lobster] in lobster?.isBusy = false }
        case "phone":
            lobster.scrollPhone()
            run(SKAction.wait(forDuration:Double.random(in:5...8))) { [weak lobster] in
                guard let lobster = lobster else { return }
                if lobster.currentState == "phone" { lobster.sitAtDesk(); lobster.isBusy = false }
            }
        case "sleep":
            lobster.sleepAtDesk()
            run(SKAction.wait(forDuration:Double.random(in:8...14))) { [weak lobster] in
                guard let lobster = lobster else { return }
                if lobster.currentState == "sleeping" { lobster.sitAtDesk(); lobster.isBusy = false }
            }
        case "chat":
            let partners = lobsters.filter { $0.agentId ! = lobster.agentId && $0.currentState == "idle" && !$0.isBusy }
            if let partner = partners.randomElement() {
                partner.isBusy = true
                lobster.walkTo(CGPoint(x:chatPos.x-12,y:chatPos.y)) { [weak lobster] in
                    lobster?.chat(); lobster?.spriteNode.xScale = -1
                }
                partner.walkTo(CGPoint(x:chatPos.x+12,y:chatPos.y)) { [weak partner] in partner?.chat() }
                run(SKAction.wait(forDuration:Double.random(in:5...9))) { [weak self] in
                    guard let self = self else { return }
                    let chatters = self.lobsters.filter { $0.currentState == "chatting" }
                    for l in chatters { l.walkHome { l.isBusy = false } }
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
            self.run(SKAction.wait(forDuration:Double.random(in:8...14))) { [weak self, weak lobster] in
                guard let self = self, let lobster = lobster else { return }
                if lobster.currentState == "working" {
                    lobster.celebrate { lobster.sitAtDesk(); lobster.isBusy = false }
                }
            }
        }
        
        if lobster.position ! = lobster.homePosition { lobster.walkHome { doWork() } }
        else { doWork() }
    }
}
