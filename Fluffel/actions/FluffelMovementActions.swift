import SpriteKit
import Cocoa

// Fluffel 的移动动作扩展
extension Fluffel {
    
    // 开始下落动画
    func startFallingAnimation() {
        if state == .falling { return }
        
        // 停止其他动画
        // 直接清理边缘行走相关动作
        removeAction(forKey: "edgeWalkingAction")
        body.removeAction(forKey: "bodyWobble")
        leftEar.removeAction(forKey: "leftEarWobble")
        rightEar.removeAction(forKey: "rightEarWobble")
        
        removeAction(forKey: "walkingAction")
        
        // 移除任何显示的对话气泡
        removeSpeechBubble()
        
        state = .falling
        surprisedFace()
        
        let rotate = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 0.7)
        let fall = SKAction.moveBy(x: 0, y: -300, duration: 0.7)
        let bodySquish = SKAction.sequence([
            SKAction.scaleX(to: 1.1, y: 0.9, duration: 0.1),
            SKAction.scaleX(to: 0.9, y: 1.1, duration: 0.1),
            SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.1)
        ])
        
        let fallingGroup = SKAction.group([rotate, fall, SKAction.repeatForever(bodySquish)])
        
        let bounce1 = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 40, duration: 0.2),
            SKAction.moveBy(x: 0, y: -40, duration: 0.15)
        ])
        let bounce2 = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 20, duration: 0.15),
            SKAction.moveBy(x: 0, y: -20, duration: 0.1)
        ])
        let bounce3 = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 10, duration: 0.1),
            SKAction.moveBy(x: 0, y: -10, duration: 0.05)
        ])
        
        let landSquish = SKAction.sequence([
            SKAction.scaleX(to: 1.3, y: 0.7, duration: 0.1),
            SKAction.scaleX(to: 0.9, y: 1.2, duration: 0.1),
            SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.1)
        ])
        
        let resetAction = SKAction.run { [weak self] in
            self?.setState(.idle)
            self?.smile()
            // Reset position to bottom of scene if needed
            if let scene = self?.scene as? FluffelScene {
                self?.position.y = scene.size.height / 2 // Center vertically for now
            }
        }
        
        let fallSequence = SKAction.sequence([
            fallingGroup,
            landSquish,
            bounce1, bounce2, bounce3,
            resetAction
        ])
        
        run(fallSequence, withKey: "fallingAction")
    }
    
    // 滚动动画 - 用于 Fluffel 在边缘滚动时
    func roll() {
        // 停止其他可能正在进行的动画
        removeAction(forKey: "walkingAction")
        removeAction(forKey: "fallingAction")
        
        // 移除任何显示的对话气泡
        removeSpeechBubble()
        
        // 设置表情为开心
        smile()
        
        // 创建完整旋转动画
        let rotateAction = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 0.8)
        let rollSequence = SKAction.sequence([
            // 稍微压缩身体，模拟准备滚动
            SKAction.scaleX(to: 1.1, y: 0.9, duration: 0.1),
            // 执行滚动动画
            SKAction.group([
                SKAction.repeatForever(rotateAction),
                // 身体在滚动时轻微变形
                SKAction.sequence([
                    SKAction.scaleX(to: 1.05, y: 0.95, duration: 0.2),
                    SKAction.scaleX(to: 0.95, y: 1.05, duration: 0.2),
                    SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.2)
                ])
            ])
        ])
        
        // 执行动画
        run(rollSequence, withKey: "rollingAction")
    }
    
    // 停止滚动动画
    func stopRolling() {
        // 移除滚动动画
        removeAction(forKey: "rollingAction")
        
        // 重置旋转和缩放
        run(SKAction.rotate(toAngle: 0, duration: 0.2))
        run(SKAction.scale(to: 1.0, duration: 0.2))
        
        // 恢复正常表情
        smile()
    }
} 