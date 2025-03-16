import SpriteKit

enum Direction {
    case left, right, up, down
}

class FluffelScene: SKScene {
    
    var fluffel: Fluffel?
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        // 设置场景属性
        backgroundColor = .clear
        
        // 创建 Fluffel
        fluffel = Fluffel()
        if let fluffel = fluffel {
            fluffel.position = CGPoint(x: size.width / 2, y: size.height / 2)
            addChild(fluffel)
        }
    }
    
    func moveFluffel(direction: Direction) {
        guard let fluffel = fluffel else { return }
        
        let moveDistance: CGFloat = 10.0
        
        // 根据方向移动 Fluffel
        switch direction {
        case .left:
            fluffel.position.x -= moveDistance
        case .right:
            fluffel.position.x += moveDistance
        case .up:
            fluffel.position.y += moveDistance
        case .down:
            fluffel.position.y -= moveDistance
        }
        
        // 确保 Fluffel 不会移出窗口
        let minX = fluffel.size.width / 2
        let maxX = size.width - fluffel.size.width / 2
        let minY = fluffel.size.height / 2
        let maxY = size.height - fluffel.size.height / 2
        
        fluffel.position.x = max(minX, min(maxX, fluffel.position.x))
        fluffel.position.y = max(minY, min(maxY, fluffel.position.y))
    }
} 