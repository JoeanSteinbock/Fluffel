import SpriteKit

// Fluffel 的边缘行为扩展
extension Fluffel {
    
    // 设置在边缘上的状态
    func setOnEdge(window: ScreenWindow, edge: ScreenWindow.EdgeType) {
        currentWindow = window
        currentEdge = edge
        setState(.onEdge)
        
        // 当到达边缘时，根据边缘类型调整 Fluffel 的姿态
        switch edge {
        case .top, .bottom:
            // 顶部或底部边缘时保持正常方向
            self.xScale = abs(self.xScale) // 确保正向
            self.zRotation = 0 // 重置旋转
        case .left:
            // 左边缘时，Fluffel 面向右侧
            self.xScale = abs(self.xScale) // 确保正向
            self.zRotation = 0 // 重置旋转
        case .right:
            // 右边缘时，Fluffel 面向左侧
            self.xScale = -abs(self.xScale) // 确保负向（镜像）
            self.zRotation = 0 // 重置旋转
        }
        
        // 在边缘上开始边缘行走动画
        startEdgeWalkingAnimation(edge: edge)
        
        print("Fluffel 现在在 \(edge.description) 边缘行走")
    }
    
    // 当 Fluffel 离开边缘时
    func leaveEdge() {
        if state == .onEdge {
            // 停止边缘行走动画
            removeAction(forKey: "edgeWalkingAction")
            body.removeAction(forKey: "bodyWobble")
            leftEar.removeAction(forKey: "leftEarWobble")
            rightEar.removeAction(forKey: "rightEarWobble")
            
            setState(.moving)
            print("Fluffel 离开了边缘")
        }
    }
    
    // 添加边缘行走动画
    func startEdgeWalkingAnimation(edge: ScreenWindow.EdgeType) {
        // 移除任何现有的行走动画
        removeAction(forKey: "edgeWalkingAction")
        
        // 根据边缘类型创建不同的行走动画
        switch edge {
        case .top, .bottom:
            // 顶部/底部边缘上行走 - 轻微上下摆动
            let walkCycle = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 2, duration: 0.15),
                SKAction.moveBy(x: 0, y: -2, duration: 0.15)
            ])
            let walkAction = SKAction.repeatForever(walkCycle)
            run(walkAction, withKey: "edgeWalkingAction")
            
            // 身体摆动
            let bodyWobble = SKAction.sequence([
                SKAction.scaleX(to: 1.05, y: 0.95, duration: 0.15),
                SKAction.scaleX(to: 0.95, y: 1.05, duration: 0.15)
            ])
            body.run(SKAction.repeatForever(bodyWobble), withKey: "bodyWobble")
            
        case .left, .right:
            // 左/右边缘上行走 - 轻微左右摆动
            let walkCycle = SKAction.sequence([
                SKAction.moveBy(x: 2, y: 0, duration: 0.15),
                SKAction.moveBy(x: -2, y: 0, duration: 0.15)
            ])
            let walkAction = SKAction.repeatForever(walkCycle)
            run(walkAction, withKey: "edgeWalkingAction")
            
            // 身体摆动
            let bodyWobble = SKAction.sequence([
                SKAction.scaleY(to: 1.05, duration: 0.15),
                SKAction.scaleY(to: 0.95, duration: 0.15)
            ])
            body.run(SKAction.repeatForever(bodyWobble), withKey: "bodyWobble")
        }
        
        // 耳朵摆动增强
        let leftEarWobble = SKAction.sequence([
            SKAction.rotate(byAngle: 0.1, duration: 0.15),
            SKAction.rotate(byAngle: -0.1, duration: 0.15)
        ])
        leftEar.run(SKAction.repeatForever(leftEarWobble), withKey: "leftEarWobble")
        
        let rightEarWobble = SKAction.sequence([
            SKAction.rotate(byAngle: -0.1, duration: 0.15),
            SKAction.rotate(byAngle: 0.1, duration: 0.15)
        ])
        rightEar.run(SKAction.repeatForever(rightEarWobble), withKey: "rightEarWobble")
    }
} 