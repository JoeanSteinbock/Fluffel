import SpriteKit

// Fluffel 的沿着边缘行走动作扩展
extension Fluffel {
    
    // 开始沿边缘行走的动画
    func startEdgeWalkingAnimation() {
        // 边缘行走功能已移除
        print("边缘行走功能已移除")
    }
    
    // 停止沿着边缘行走的动画
    func stopEdgeWalkingAnimation() {
        removeAction(forKey: "edgeWalkingAction")
        
        // 恢复正常角度和位置
        run(SKAction.rotate(toAngle: 0, duration: 0.2))
        run(SKAction.scale(to: 1.0, duration: 0.2))
    }
    
    // 调整位置和旋转以匹配边缘
    private func adjustPositionForEdge(edge: FluffelScene.SceneEdge, direction: MovementDirection) {
        // 重置旋转和缩放
        zRotation = 0
        setScale(1.0)
        
        // 根据边缘和方向调整旋转角度和缩放
        switch edge {
        case .top:
            zRotation = CGFloat.pi
            xScale = direction == .left ? 1 : -1
        case .right:
            zRotation = CGFloat.pi / 2
            xScale = direction == .up ? 1 : -1
        case .bottom:
            zRotation = 0
            xScale = direction == .right ? 1 : -1
        case .left:
            zRotation = -CGFloat.pi / 2
            xScale = direction == .down ? 1 : -1
        }
    }
} 