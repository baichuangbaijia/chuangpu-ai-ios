import SwiftUI
import SpriteKit

struct LobsterOfficeView: UIViewRepresentable {
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.backgroundColor = .clear
        view.ignoresSiblingOrder = true
        view.isMultipleTouchEnabled = false
        let scene = LobsterOfficeScene(size: CGSize(width: UIScreen.main.bounds.width, height: 320))
        scene.scaleMode = .aspectFill
        scene.backgroundColor = UIColor(hex: "0D0D1A")
        view.presentScene(scene)
        return view
    }
    func updateUIView(_ uiView: SKView, context: Context) {}
}
