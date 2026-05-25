import SpriteKit
import Foundation

/// 虚拟办公室 v6 - 霓虹线稿风格，APP背景融合
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
    // Colors
    private let neonPurple = UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 1)
    private let neonCyan = UIColor(red: 0.0, green: 0.9, blue: 0.9, alpha: 1)
    private let neonBlue = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1)
    private let deskColor = UIColor(hex: "2A2A4A")
    private let deskBorder = UIColor(hex: "5A5A8A")
    private let screenGlow = UIColor(red: 0.49, green: 0.23, blue: 0.93, alpha: 0.5)

    override func sceneDidLoad() {
        super.sceneDidLoad()
        let w = size.width, h = size.height
        backgroundColor = UIColor(hex: "0D0D1A")
        
        coffeePos = CGPoint(x: w * 0.09, y: h * 0.32)
        gymPos = CGPoint(x: w * 0.91, y: h * 0.28)
        toiletPos = CGPoint(x: w * 0.09, y: h * 0.68)
        chatPos = CGPoint(x: w * 0.50, y: h * 0.42)
        
        drawOffice()
        buildLobsters()
        startBehaviorAI()
    }
    
    // MARK: - 霓虹线稿办公室
    
    private func drawOffice() {
        let w = size.width, h = size.height
        
        // === 窗户（顶部中间）===
        let winW: CGFloat = w * 0.38, winH: CGFloat = 45
        let winY = h * 0.84
        let winFrame = SKShapeNode(rectOf: CGSize(width: winW, height: winH), cornerRadius: 4)
        winFrame.fillColor = UIColor(hex: "081530"); winFrame.strokeColor = neonPurple; winFrame.lineWidth = 2
        winFrame.position = CGPoint(x: w/2, y: winY); addChild(winFrame)
        // Moon
        let moon = SKShapeNode(circleOfRadius: 5)
        moon.fillColor = UIColor(red: 1, green: 0.95, blue: 0.7, alpha: 0.7); moon.strokeColor = .clear
        moon.position = CGPoint(x: w/2 - winW/4, y: winY + 8); addChild(moon)
        // Stars
        for _ in 0..<6 {
            let s = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.8...1.5))
            s.fillColor = .white; s.strokeColor = .clear; s.alpha = 0.7
            s.position = CGPoint(x: w/2 + CGFloat.random(in: -winW/2+10...winW/2-10), y: winY + CGFloat.random(in: -10...10))
            addChild(s)
        }
        // City skyline in window
        for i in 0..<5 {
            let bw = CGFloat.random(in: 8...16), bh = CGFloat.random(in: 10...22)
            let bldg = SKShapeNode(rectOf: CGSize(width: bw, height: bh))
            bldg.fillColor = UIColor(hex: "0A0A20"); bldg.strokeColor = neonPurple.withAlphaComponent(0.3); bldg.lineWidth = 1
            bldg.position = CGPoint(x: w/2 - winW/2 + 20 + CGFloat(i) * (winW-40)/5, y: winY - 10)
            addChild(bldg)
        }
        
        // === 后排3个工位 ===
        let backY: CGFloat = h * 0.60
        let backXs: [CGFloat] = [0.25, 0.50, 0.75]
        for xr in backXs { drawDesk(x: w * xr, y: backY, scale: 0.85) }
        
        // === 前排3个工位 ===
        let frontY: CGFloat = h * 0.34
        let frontXs: [CGFloat] = [0.28, 0.50, 0.72]
        for xr in frontXs { drawDesk(x: w * xr, y: frontY, scale: 1.0) }
        
        // === 咖啡机（左下）===
        drawCoffeeMachine(x: w * 0.09, y: h * 0.32)
        
        // === 厕所（左上）===
        drawToilet(x: w * 0.09, y: h * 0.68)
        
        // === 健身角（右下）===
        drawGym(x: w * 0.91, y: h * 0.28)
    }
    
    private func drawDesk(x: CGFloat, y: CGFloat, scale: CGFloat) {
        let s = scale
        // 桌面
        let desk = SKShapeNode(rectOf: CGSize(width: 52*s, height: 6*s), cornerRadius: 2)
        desk.fillColor = deskColor; desk.strokeColor = deskBorder; desk.lineWidth = 1
        desk.position = CGPoint(x: x, y: y); desk.zPosition = 3; addChild(desk)
        // 桌腿
        for lx in [x - 22*s, x + 22*s] {
            let leg = SKShapeNode(rectOf: CGSize(width: 3*s, height: 12*s))
            leg.fillColor = deskColor; leg.strokeColor = .clear
            leg.position = CGPoint(x: lx, y: y - 9*s); leg.zPosition = 3; addChild(leg)
        }
        // 显示器
        let mon = SKShapeNode(rectOf: CGSize(width: 22*s, height: 16*s), cornerRadius: 2)
        mon.fillColor = UIColor(hex: "0A0A1A"); mon.strokeColor = deskBorder; mon.lineWidth = 1
        mon.position = CGPoint(x: x, y: y + 14*s); mon.zPosition = 4; addChild(mon)
        // 屏幕（发光）
        let scr = SKShapeNode(rectOf: CGSize(width: 18*s, height: 12*s), cornerRadius: 1)
        scr.fillColor = screenGlow; scr.strokeColor = .clear
        scr.position = CGPoint(x: x, y: y + 14*s); scr.zPosition = 5; addChild(scr)
        scr.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.25, duration: 2), SKAction.fadeAlpha(to: 0.6, duration: 2)])))
        // 显示器支架
        let stand = SKShapeNode(rectOf: CGSize(width: 4*s, height: 6*s))
        stand.fillColor = deskColor; stand.strokeColor = .clear
        stand.position = CGPoint(x: x, y: y + 4*s); stand.zPosition = 4; addChild(stand)
        // 键盘
        let kb = SKShapeNode(rectOf: CGSize(width: 18*s, height: 4*s), cornerRadius: 1)
        kb.fillColor = UIColor(hex: "1A1A3A"); kb.strokeColor = deskBorder; kb.lineWidth = 0.5
        kb.position = CGPoint(x: x, y: y - 2*s); kb.zPosition = 4; addChild(kb)
        // 椅子
        let seat = SKShapeNode(ellipseOf: CGSize(width: 20*s, height: 14*s))
        seat.fillColor = UIColor(hex: "1A1A3A"); seat.strokeColor = UIColor(hex: "3A3A6A"); seat.lineWidth = 1
        seat.position = CGPoint(x: x, y: y - 16*s); seat.zPosition = 3; addChild(seat)
        let back = SKShapeNode(rectOf: CGSize(width: 16*s, height: 6*s), cornerRadius: 3)
        back.fillColor = UIColor(hex: "1A1A3A"); back.strokeColor = UIColor(hex: "3A3A6A"); back.lineWidth = 1
        back.position = CGPoint(x: x, y: y - 22*s); back.zPosition = 3; addChild(back)
    }
    
    private func drawCoffeeMachine(x: CGFloat, y: CGFloat) {
        // 咖啡机主体
        let body = SKShapeNode(rectOf: CGSize(width: 26, height: 36), cornerRadius: 4)
        body.fillColor = UIColor(hex: "1A1A3A"); body.strokeColor = neonCyan; body.lineWidth = 1.5
        body.position = CGPoint(x: x, y: y + 8); body.zPosition = 5; addChild(body)
        // 出水口
        let nozzle = SKShapeNode(rectOf: CGSize(width: 10, height: 6), cornerRadius: 2)
        nozzle.fillColor = UIColor(hex: "2A2A4A"); nozzle.strokeColor = neonCyan.withAlphaComponent(0.6); nozzle.lineWidth = 1
        nozzle.position = CGPoint(x: x, y: y + 20); nozzle.zPosition = 6; addChild(nozzle)
        // 指示灯
        let light = SKShapeNode(circleOfRadius: 2)
        light.fillColor = neonCyan; light.strokeColor = .clear
        light.position = CGPoint(x: x, y: y + 26); light.zPosition = 6; addChild(light)
        light.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.3, duration: 1), SKAction.fadeAlpha(to: 1, duration: 1)])))
        // 杯子
        let cup = SKShapeNode(rectOf: CGSize(width: 8, height: 10), cornerRadius: 2)
        cup.fillColor = UIColor(hex: "2A2A4A"); cup.strokeColor = UIColor(hex: "8A7A5A"); cup.lineWidth = 1
        cup.position = CGPoint(x: x, y: y - 6); cup.zPosition = 5; addChild(cup)
        // 蒸汽
        let steam = SKLabelNode(text: "~")
        steam.fontSize = 10; steam.fontColor = UIColor.white.withAlphaComponent(0.3)
        steam.position = CGPoint(x: x, y: y - 12); steam.zPosition = 6; addChild(steam)
        steam.run(SKAction.repeatForever(SKAction.sequence([SKAction.moveBy(x: 0, y: 6, duration: 1.5), SKAction.moveBy(x: 0, y: -6, duration: 0)])))
        // 标签
        let lbl = SKLabelNode(text: "咖啡机")
        lbl.fontSize = 9; lbl.fontColor = neonCyan; lbl.fontName = "PingFangSC-Medium"
        lbl.position = CGPoint(x: x, y: y - 20); lbl.zPosition = 6; addChild(lbl)
    }
    
    private func drawToilet(x: CGFloat, y: CGFloat) {
        // 隔间三面墙
        let wallC = UIColor(hex: "3A5A8A")
        // 顶墙
        let tw = SKShapeNode(rectOf: CGSize(width: 50, height: 3))
        tw.fillColor = wallC; tw.strokeColor = .clear
        tw.position = CGPoint(x: x, y: y + 26); tw.zPosition = 5; addChild(tw)
        // 右墙
        let rw = SKShapeNode(rectOf: CGSize(width: 3, height: 52))
        rw.fillColor = wallC; rw.strokeColor = .clear
        rw.position = CGPoint(x: x + 24, y: y); rw.zPosition = 5; addChild(rw)
        // 左墙（短，留门口）
        let lw = SKShapeNode(rectOf: CGSize(width: 3, height: 22))
        lw.fillColor = wallC; lw.strokeColor = .clear
        lw.position = CGPoint(x: x - 24, y: y + 15); lw.zPosition = 5; addChild(lw)
        // 门（微开）
        let door = SKShapeNode(rectOf: CGSize(width: 22, height: 3))
        door.fillColor = UIColor(hex: "4A7ACA"); door.strokeColor = .clear
        door.position = CGPoint(x: x - 14, y: y - 24); door.zRotation = 0.3; door.zPosition = 5; addChild(door)
        // 门把手
        let handle = SKShapeNode(circleOfRadius: 2)
        handle.fillColor = UIColor(hex: "FFD700"); handle.strokeColor = .clear
        handle.position = CGPoint(x: x - 22, y: y - 24); handle.zPosition = 6; addChild(handle)
        // 马桶
        let toilet = SKShapeNode(ellipseOf: CGSize(width: 18, height: 22))
        toilet.fillColor = UIColor(hex: "2A3A5A"); toilet.strokeColor = UIColor(hex: "6A9ADA"); toilet.lineWidth = 1.5
        toilet.position = CGPoint(x: x, y: y + 4); toilet.zPosition = 6; addChild(toilet)
        // 水箱
        let tank = SKShapeNode(rectOf: CGSize(width: 16, height: 10), cornerRadius: 2)
        tank.fillColor = UIColor(hex: "2A3A5A"); tank.strokeColor = UIColor(hex: "6A9ADA"); tank.lineWidth = 1
        tank.position = CGPoint(x: x, y: y + 18); tank.zPosition = 6; addChild(tank)
        // 冲水按钮
        let btn = SKShapeNode(circleOfRadius: 2)
        btn.fillColor = neonCyan; btn.strokeColor = .clear
        btn.position = CGPoint(x: x, y: y + 22); btn.zPosition = 7; addChild(btn)
        // 标签
        let lbl = SKLabelNode(text: "卫生间")
        lbl.fontSize = 9; lbl.fontColor = UIColor(hex: "6A9ADA"); lbl.fontName = "PingFangSC-Medium"
        lbl.position = CGPoint(x: x, y: y - 20); lbl.zPosition = 6; addChild(lbl)
    }
    
    private func drawGym(x: CGFloat, y: CGFloat) {
        // 地垫
        let mat = SKShapeNode(rectOf: CGSize(width: 50, height: 24), cornerRadius: 4)
        mat.fillColor = UIColor(hex: "1A1A3A"); mat.strokeColor = UIColor(hex: "5A4A8A"); mat.lineWidth = 1
        mat.position = CGPoint(x: x, y: y); mat.zPosition = 3; addChild(mat)
        // 跑步机
        let tm = SKShapeNode(rectOf: CGSize(width: 30, height: 16), cornerRadius: 3)
        tm.fillColor = UIColor(hex: "1A1A2A"); tm.strokeColor = neonPurple; tm.lineWidth = 1.5
        tm.position = CGPoint(x: x, y: y + 4); tm.zPosition = 5; addChild(tm)
        // 跑步机屏幕
        let tmscr = SKShapeNode(rectOf: CGSize(width: 10, height: 6), cornerRadius: 1)
        tmscr.fillColor = neonBlue.withAlphaComponent(0.4); tmscr.strokeColor = .clear
        tmscr.position = CGPoint(x: x, y: y + 12); tmscr.zPosition = 6; addChild(tmscr)
        // 哑铃
        for dy in [y - 6, y + 16] {
            let bar = SKShapeNode(rectOf: CGSize(width: 22, height: 3))
            bar.fillColor = UIColor(hex: "5A5A6A"); bar.strokeColor = .clear
            bar.position = CGPoint(x: x, y: dy); bar.zPosition = 5; addChild(bar)
            for dx in [x - 10, x + 10] {
                let weight = SKShapeNode(ellipseOf: CGSize(width: 8, height: 6))
                weight.fillColor = UIColor(hex: "3A3A4A"); weight.strokeColor = neonPurple.withAlphaComponent(0.5); weight.lineWidth = 1
                weight.position = CGPoint(x: dx, y: dy); weight.zPosition = 5; addChild(weight)
            }
        }
        // 标签
        let lbl = SKLabelNode(text: "健身角")
        lbl.fontSize = 9; lbl.fontColor = neonPurple; lbl.fontName = "PingFangSC-Medium"
        lbl.position = CGPoint(x: x, y: y - 18); lbl.zPosition = 6; addChild(lbl)
    }

    private func buildLobsters() {
        let w = size.width, h = size.height
        let backY: CGFloat = h * 0.52
        let backXs: [CGFloat] = [0.25, 0.50, 0.75]
        let frontY: CGFloat = h * 0.26
        let frontXs: [CGFloat] = [0.28, 0.50, 0.72]
        
        for (idx, ag) in agents.enumerated() {
            let lobster = LobsterCharacter(agentId: ag.0, name: ag.1)
            let home: CGPoint
            if idx < 3 {
                home = CGPoint(x: w * backXs[idx], y: backY)
                lobster.xScale = 0.7; lobster.yScale = 0.7; lobster.zPosition = 15
            } else {
                home = CGPoint(x: w * frontXs[idx - 3], y: frontY)
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
