import SpriteKit

enum Direction {
    case left, right, up, down
}

// 添加一个通知名称，用于通知窗口 Fluffel 已移动
extension Notification.Name {
    static let fluffelDidMove = Notification.Name("fluffelDidMove")
}

class FluffelScene: SKScene {
    
    var fluffel: Fluffel?
    private var lastMoveTime: TimeInterval = 0
    private let moveDelay: TimeInterval = 0.01 // 控制移动流畅度
    
    // 边缘检测相关
    private var isEdgeDetectionEnabled = true
    private var edgeDetectionTolerance: CGFloat = 10.0
    private let edgeCheckInterval: TimeInterval = 0.1 // 每0.1秒检查一次边缘
    private var lastEdgeCheckTime: TimeInterval = 0
    
    // 坐标转换相关
    private var lastKnownGlobalPosition: CGPoint?
    
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
            
            // 使用正常比例
            fluffel.setScale(1.0)
            
            // 让 Fluffel 微笑，看起来更友好
            fluffel.smile()
            
            print("Fluffel 已添加到场景，位置: \(fluffel.position)")
            
            // 添加一个短暂的延迟，然后让 Fluffel 眨眼，显得更加活泼
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                fluffel.happyBlink()
                print("Fluffel 完成眨眼动画")
            }
        } else {
            print("错误: 无法创建 Fluffel")
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // 执行边缘检测，但不要每帧都检测，以避免性能问题
        if isEdgeDetectionEnabled && currentTime - lastEdgeCheckTime > edgeCheckInterval {
            checkForWindowEdges(currentTime: currentTime)
            lastEdgeCheckTime = currentTime
        }
    }
    
    // 检查 Fluffel 是否靠近窗口边缘
    private func checkForWindowEdges(currentTime: TimeInterval) {
        guard let fluffel = fluffel,
              let view = self.view,
              let window = view.window,
              let screen = window.screen else {
            return
        }
        
        // 获取 Fluffel 在全局坐标系中的位置
        let fluffelScenePosition = fluffel.position
        
        // 修正：从场景到视图的坐标转换 - 直接使用 SKView 的转换方法
        let fluffelViewPosition = view.convert(fluffelScenePosition, from: self)
        
        // 转换为屏幕坐标 - 使用 NSView 的转换方法，不需要 to 参数
        var fluffelWindowPosition = fluffelViewPosition
        
        // 调整 y 坐标（在 macOS 中，屏幕原点在左下角）
        fluffelWindowPosition.y = window.frame.height - fluffelWindowPosition.y
        
        // 转换为全局坐标
        let fluffelGlobalPosition = CGPoint(
            x: window.frame.origin.x + fluffelWindowPosition.x,
            y: window.frame.origin.y + fluffelWindowPosition.y
        )
        
        lastKnownGlobalPosition = fluffelGlobalPosition
        
        // 检查是否在窗口边缘上
        let edgeResult = WindowUtility.isPointOnWindowEdge(fluffelGlobalPosition, tolerance: edgeDetectionTolerance)
        
        if edgeResult.isOnEdge, let edge = edgeResult.edge, let detectedWindow = edgeResult.window {
            if !fluffel.isOnEdge {
                // 刚刚移动到边缘上
                fluffel.setOnEdge(window: detectedWindow, edge: edge)
                print("Fluffel 移动到窗口边缘: \(edge)")
            }
        } else if fluffel.isOnEdge {
            // 刚刚离开边缘
            fluffel.leaveEdge()
            print("Fluffel 离开窗口边缘")
        }
    }
    
    func moveFluffel(direction: Direction) {
        guard let fluffel = fluffel else { return }
        
        let currentTime = CACurrentMediaTime()
        // 添加小延迟避免移动过快
        if currentTime - lastMoveTime < moveDelay {
            return
        }
        lastMoveTime = currentTime
        
        // 设置移动状态
        if fluffel.state == .idle {
            fluffel.setState(.moving)
        }
        
        // 增加移动距离，使移动更明显
        let moveDistance: CGFloat = 8.0
        
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
        
        // 移除边界检查，允许 Fluffel 自由移动
        // 移动后发送通知，以便窗口控制器可以跟随 Fluffel 移动
        NotificationCenter.default.post(name: .fluffelDidMove, object: self)
    }
    
    // 启动下落动画
    func startFalling() {
        guard let fluffel = fluffel, fluffel.state != .falling else { return }
        
        fluffel.setState(.falling)
    }
    
    // 获取 Fluffel 当前位置
    func getFluffelPosition() -> CGPoint? {
        return fluffel?.position
    }
    
    // 获取 Fluffel 的实际大小
    func getFluffelSize() -> CGSize? {
        return fluffel?.size
    }
    
    // 获取 Fluffel 全局坐标
    func getFluffelGlobalPosition() -> CGPoint? {
        return lastKnownGlobalPosition
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
    
    // 启用或禁用边缘检测
    func setEdgeDetectionEnabled(_ enabled: Bool) {
        isEdgeDetectionEnabled = enabled
    }
    
    // 设置边缘检测的容差
    func setEdgeDetectionTolerance(_ tolerance: CGFloat) {
        edgeDetectionTolerance = tolerance
    }
} 