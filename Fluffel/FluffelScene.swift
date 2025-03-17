import SpriteKit

enum Direction {
    case left, right, up, down
}

class FluffelScene: SKScene {
    
    var fluffel: Fluffel?
    private var lastMoveTime: TimeInterval = 0
    private let moveDelay: TimeInterval = 0.01 // 控制移动流畅度
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        // 设置场景属性
        backgroundColor = .clear
        
        // 创建 Fluffel
        fluffel = Fluffel()
        if let fluffel = fluffel {
            // 确保 Fluffel 在场景中央
            fluffel.position = CGPoint(x: size.width / 2, y: size.height / 2)
            addChild(fluffel)
            
            // 关闭缩放动画会使窗口区域更准确
            fluffel.setScale(0.9)  // 稍微缩小一点，确保完全在小窗口内
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // 如果需要添加基于时间的更新逻辑，可以在这里实现
    }
    
    func moveFluffel(direction: Direction) {
        guard let fluffel = fluffel else { return }
        
        let currentTime = CACurrentMediaTime()
        // 添加小延迟避免移动过快
        if currentTime - lastMoveTime < moveDelay {
            return
        }
        lastMoveTime = currentTime
        
        let moveDistance: CGFloat = 5.0 // 较小的移动距离，使移动更平滑
        
        // 根据方向移动 Fluffel
        switch direction {
        case .left:
            fluffel.position.x -= moveDistance
            turnFluffelToFace(direction: .left)
        case .right:
            fluffel.position.x += moveDistance
            turnFluffelToFace(direction: .right)
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
    
    // 让 Fluffel 朝向移动方向
    private func turnFluffelToFace(direction: Direction) {
        guard let fluffel = fluffel else { return }
        
        // 简单的左右翻转效果
        switch direction {
        case .left:
            fluffel.xScale = -1.0 // 镜像翻转
        case .right:
            fluffel.xScale = 1.0 // 正常方向
        default:
            break // 上下移动不改变朝向
        }
    }
} 