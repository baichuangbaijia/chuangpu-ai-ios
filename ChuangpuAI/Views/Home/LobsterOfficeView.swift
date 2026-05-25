import SwiftUI
import SpriteKit

// MARK: - 虚拟办公室SwiftUI视图
struct LobsterOfficeView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.backgroundColor = UIColor(hex: "0F0F1A")
        view.ignoresSiblingOrder = true
        view.isMultipleTouchEnabled = false
        
        let scene = LobsterOfficeScene(size: CGSize(width: UIScreen.main.bounds.width, height: 220))
        scene.scaleMode = .aspectFill
        view.presentScene(scene)
        
        return view
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {}
}
