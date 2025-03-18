import SpriteKit

// Fluffel 的基本动画扩展
extension Fluffel {
    
    // 创建行走动画
    func createWalkingAnimation() -> SKAction {
        // 创建身体摆动动画，模拟行走
        let bodySwing = SKAction.sequence([
            SKAction.scaleX(to: 1.05, y: 0.95, duration: 0.15),
            SKAction.scaleX(to: 0.95, y: 1.05, duration: 0.15)
        ])
        
        return bodySwing
    }
    
    // 开始行走动画
    func startWalkingAnimation(direction: MovementDirection) {
        if state == .walking { return }
        
        // 停止其他动画
        // 直接清理边缘行走相关动作
        removeAction(forKey: "edgeWalkingAction")
        body.removeAction(forKey: "bodyWobble")
        leftEar.removeAction(forKey: "leftEarWobble")
        rightEar.removeAction(forKey: "rightEarWobble")
        
        removeAction(forKey: "fallingAction")
        
        // 移除任何显示的对话气泡
        removeSpeechBubble()
        
        state = .walking
        smile()
        
        // 设置朝向
        xScale = (direction == .right) ? 1.0 : -1.0
        
        // 创建并运行行走动画
        let walkAction = createWalkingAnimation()
        run(SKAction.repeatForever(walkAction), withKey: "walkingAction")
    }
    
    // 停止行走动画
    func stopWalkingAnimation() {
        if state != .walking { return }
        
        removeAction(forKey: "walkingAction")
        run(SKAction.scale(to: 1.0, duration: 0.1))
        setState(.idle)
    }
    
    // 改变朝向
    func changeDirection(to direction: MovementDirection) {
        switch direction {
        case .left:
            xScale = -1.0
        case .right:
            xScale = 1.0
        default:
            break // 上下方向不改变x轴缩放
        }
    }
} 