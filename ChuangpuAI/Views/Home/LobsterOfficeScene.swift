import SpriteKit
import Foundation

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
    private var floorY: CGFloat = 0

    override func sceneDidLoad() {
        super.sceneDidLoad()
        let w = size.width, h = size.height
        floorY = h * 0.35
        coffeePos = CGPoint(x: w * 0.08, y: floorY - 6)
        gymPos = CGPoint(x: w * 0.92, y: floorY - 6)
        toiletPos = CGPoint(x: w * 0.06, y: h * 0.62)
        chatPos = CGPoint(x: w * 0.50, y: floorY - 14)
        buildOffice()
        buildLobsters()
        startBehaviorAI()
    }

    private func buildOffice() {
        let w = size.width, h = size.height
        backgroundColor = UIColor(hex: "0D0D1A")

        // Wall
        let wall = SKShapeNode(rectOf: CGSize(width: w, height: h * 0.6))
        wall.fillColor = UIColor(hex: "12122A"); wall.strokeColor = .clear
        wall.position = CGPoint(x: w/2, y: h*0.7); addChild(wall)

        // Floor
        let floor = SKShapeNode(rectOf: CGSize(width: w, height: h*0.45))
        floor.fillColor = UIColor(hex: "1A1A38"); floor.strokeColor = .clear
        floor.position = CGPoint(x: w/2, y: h*0.22); addChild(floor)

        // Floor line
        let fl = SKShapeNode(rectOf: CGSize(width: w, height: 2))
        fl.fillColor = UIColor(hex: "3A3A6A"); fl.strokeColor = .clear
        fl.position = CGPoint(x: w/2, y: floorY - 25); addChild(fl)

        // Window
        let winW = w*0.4, winH = h*0.18
        let wf = SKShapeNode(rectOf: CGSize(width: winW+6, height: winH+6), cornerRadius: 6)
        wf.fillColor = UIColor(hex: "2A2A4A"); wf.strokeColor = UIColor(hex: "4A4A7A"); wf.lineWidth = 2
        wf.position = CGPoint(x: w/2, y: h*0.78); addChild(wf)
        let wb = SKShapeNode(rectOf: CGSize(width: winW, height: winH), cornerRadius: 4)
        wb.fillColor = UIColor(hex: "0A1A3A"); wb.strokeColor = .clear
        wb.position = CGPoint(x: w/2, y: h*0.78); addChild(wb)
        for _ in 0..<10 {
            let s = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.8...2.0))
            s.fillColor = .white; s.strokeColor = .clear; s.alpha = CGFloat.random(in: 0.4...0.9)
            s.position = CGPoint(x: w/2+CGFloat.random(in:-winW/2+8...winW/2-8), y: h*0.78+CGFloat.random(in:-winH/2+8...winH/2-8))
            addChild(s)
            s.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.2, duration: Double.random(in:1...2.5)), SKAction.fadeAlpha(to: 0.9, duration: Double.random(in:1...2.5))])))
        }
        let moon = SKShapeNode(circleOfRadius: 7)
        moon.fillColor = UIColor(red:1, green:0.95, blue:0.7, alpha:0.6); moon.strokeColor = .clear
        moon.position = CGPoint(x: w/2-winW/3, y: h*0.85); addChild(moon)

        // Desks
        let deskXs: [CGFloat] = [0.18, 0.33, 0.48, 0.63, 0.78, 0.90]
        for (_, xr) in deskXs.enumerated() {
            let dx = w * xr, dy = floorY
            let desk = SKShapeNode(rectOf: CGSize(width: 44, height: 6), cornerRadius: 2)
            desk.fillColor = UIColor(hex: "3A3A5A"); desk.strokeColor = UIColor(hex: "5A5A7A"); desk.lineWidth = 1
            desk.position = CGPoint(x: dx, y: dy); addChild(desk)
            let mon = SKShapeNode(rectOf: CGSize(width: 20, height: 15), cornerRadius: 2)
            mon.fillColor = UIColor(hex: "1A1A3A"); mon.strokeColor = UIColor(hex: "5A5A8A"); mon.lineWidth = 1
            mon.position = CGPoint(x: dx, y: dy+12); addChild(mon)
            let scr = SKShapeNode(rectOf: CGSize(width: 16, height: 11), cornerRadius: 1)
            scr.fillColor = UIColor(red:0.49, green:0.23, blue:0.93, alpha:0.4); scr.strokeColor = .clear
            scr.position = CGPoint(x: dx, y: dy+12); addChild(scr)
            scr.run(SKAction.repeatForever(SKAction.sequence([SKAction.fadeAlpha(to: 0.2, duration: 2), SKAction.fadeAlpha(to: 0.6, duration: 2)])))
            let chair = SKShapeNode(ellipseOf: CGSize(width: 18, height: 12))
            chair.fillColor = UIColor(hex: "2A2A4A"); chair.strokeColor = UIColor(hex: "3A3A5A"); chair.lineWidth = 1
            chair.position = CGPoint(x: dx, y: dy-10); addChild(chair)
        }

        // Coffee machine room
        let cmBg = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 6)
        cmBg.fillColor = UIColor(hex: "3A2A1A"); cmBg.strokeColor = UIColor(hex: "8A6A3A"); cmBg.lineWidth = 2
        cmBg.position = CGPoint(x: w*0.08, y: floorY+18); addChild(cmBg)
        let cmIcon = SKLabelNode(text: "☕")
        cmIcon.fontSize = 20; cmIcon.position = CGPoint(x: w*0.08, y: floorY+24); cmIcon.zPosition = 2; addChild(cmIcon)
        let cmLbl = SKLabelNode(text: "咖啡机")
        cmLbl.fontSize = 8; cmLbl.fontColor = UIColor(hex: "D4A574"); cmLbl.fontName = "PingFangSC-Medium"
        cmLbl.position = CGPoint(x: w*0.08, y: floorY+4); cmLbl.zPosition = 2; addChild(cmLbl)

        // Gym room
        let gymBg = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 6)
        gymBg.fillColor = UIColor(hex: "1A3A1A"); gymBg.strokeColor = UIColor(hex: "4A8A4A"); gymBg.lineWidth = 2
        gymBg.position = CGPoint(x: w*0.92, y: floorY+18); addChild(gymBg)
        let gymIcon = SKLabelNode(text: "🏋️")
        gymIcon.fontSize = 18; gymIcon.position = CGPoint(x: w*0.92, y: floorY+24); gymIcon.zPosition = 2; addChild(gymIcon)
        let gymLbl = SKLabelNode(text: "健身角")
        gymLbl.fontSize = 8; gymLbl.fontColor = UIColor(hex: "6ABF6A"); gymLbl.fontName = "PingFangSC-Medium"
        gymLbl.position = CGPoint(x: w*0.92, y: floorY+4); gymLbl.zPosition = 2; addChild(gymLbl)

        // Toilet room
        let tlBg = SKShapeNode(rectOf: CGSize(width: 44, height: 50), cornerRadius: 4)
        tlBg.fillColor = UIColor(hex: "2A3A5A"); tlBg.strokeColor = UIColor(hex: "5A8ACA"); tlBg.lineWidth = 2
        tlBg.position = CGPoint(x: w*0.06, y: h*0.62); addChild(tlBg)
        let tlIcon = SKLabelNode(text: "🚻")
        tlIcon.fontSize = 18; tlIcon.position = CGPoint(x: w*0.06, y: h*0.65); tlIcon.zPosition = 2; addChild(tlIcon)
        let tlLbl = SKLabelNode(text: "厕所")
        tlLbl.fontSize = 8; tlLbl.fontColor = UIColor(hex: "7AAADF"); tlLbl.fontName = "PingFangSC-Medium"
        tlLbl.position = CGPoint(x: w*0.06, y: h*0.57); tlLbl.zPosition = 2; addChild(tlLbl)
        // Door frame
        let doorL = SKShapeNode(rectOf: CGSize(width: 2, height: 30))
        doorL.fillColor = UIColor(hex: "5A8ACA"); doorL.strokeColor = .clear
        doorL.position = CGPoint(x: w*0.06-12, y: h*0.62); addChild(doorL)
        let doorR = SKShapeNode(rectOf: CGSize(width: 2, height: 30))
        doorR.fillColor = UIColor(hex: "5A8ACA"); doorR.strokeColor = .clear
        doorR.position = CGPoint(x: w*0.06+12, y: h*0.62); addChild(doorR)
        let doorT = SKShapeNode(rectOf: CGSize(width: 26, height: 2))
        doorT.fillColor = UIColor(hex: "5A8ACA"); doorT.strokeColor = .clear
        doorT.position = CGPoint(x: w*0.06, y: h*0.62+15); addChild(doorT)

        // Chat area
        let chatBg = SKShapeNode(ellipseOf: CGSize(width: 70, height: 34))
        chatBg.fillColor = UIColor(hex: "2A1A3A"); chatBg.strokeColor = UIColor(hex: "7A5AAA"); chatBg.lineWidth = 1
        chatBg.alpha = 0.6; chatBg.position = chatPos; chatBg.zPosition = 1; addChild(chatBg)
        let chatLbl = SKLabelNode(text: "💬")
        chatLbl.fontSize = 10; chatLbl.position = CGPoint(x: chatPos.x, y: chatPos.y+2)
        chatLbl.zPosition = 2; chatLbl.alpha = 0.5; addChild(chatLbl)
    }

    private func buildLobsters() {
        let w = size.width
        let xs: [CGFloat] = [0.18, 0.33, 0.48, 0.63, 0.78, 0.90]
        for (idx, ag) in agents.enumerated() {
            let lobster = LobsterCharacter(agentId: ag.0, name: ag.1)
            let home = CGPoint(x: w * xs[idx], y: floorY - 18)
            lobster.position = home
            lobster.homePosition = home
            lobster.zPosition = 20
            lobster.sitAtDesk()
            addChild(lobster)
            lobsters.append(lobster)
        }
    }

    private func startBehaviorAI() {
        let idleCycle = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in: 4...7)),
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
            lobster.goToToilet(toiletPos: CGPoint(x: size.width*0.06, y: size.height*0.58)) { [weak lobster] in lobster?.isBusy = false }
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
                lobster.walkTo(CGPoint(x: chatPos.x-18, y: chatPos.y)) { [weak lobster] in lobster?.chat(); lobster?.spriteNode.xScale = -1 }
                partner.walkTo(CGPoint(x: chatPos.x+18, y: chatPos.y)) { [weak partner] in partner?.chat() }
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
