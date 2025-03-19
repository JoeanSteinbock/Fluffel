import SpriteKit
import Cocoa

// Fluffel 的呼吸和发光动画扩展
extension Fluffel {
    
    // 呼吸动画 - 让 Fluffel 看起来更有生命力
    func startBreathingAnimation() {
        // 将呼吸动画应用到整个 Fluffel，而不仅仅是身体
        // 这样身体和耳朵会一起缩放，看起来更加协调
        let scaleUp = SKAction.scale(to: 1.05, duration: 0.5)
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.5)
        let breathe = SKAction.sequence([scaleUp, scaleDown])
        let breatheContinuously = SKAction.repeatForever(breathe)
        
        // 应用到整个 Fluffel（自己），而不仅仅是身体
        self.run(breatheContinuously)
        
        // 因为整体已经有缩放动画，身体不需要单独的缩放
        // 确保眨眼动画仍然独立工作
        
        // 耳朵稍微摇动的动画 - 保留这个效果
        let leftEarWiggle = SKAction.sequence([
            SKAction.rotate(byAngle: 0.05, duration: 0.3),
            SKAction.rotate(byAngle: -0.05, duration: 0.3)
        ])
        leftEar.run(SKAction.repeatForever(leftEarWiggle))
        
        let rightEarWiggle = SKAction.sequence([
            SKAction.rotate(byAngle: -0.05, duration: 0.3),
            SKAction.rotate(byAngle: 0.05, duration: 0.3)
        ])
        rightEar.run(SKAction.repeatForever(rightEarWiggle))
        
        // 眼睛眨眼动画 - 每隔几秒眨一次眼
        let wait = SKAction.wait(forDuration: 3.0)
        let blink = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 眨眼动画序列
            let close = SKAction.scaleY(to: 0.1, duration: 0.1)
            let open = SKAction.scaleY(to: 1.0, duration: 0.1)
            let blinkAction = SKAction.sequence([close, open])
            
            self.leftEye.run(blinkAction)
            self.rightEye.run(blinkAction)
        }
        
        let blinkSequence = SKAction.sequence([wait, blink])
        let blinkRepeat = SKAction.repeatForever(blinkSequence)
        self.run(blinkRepeat)
    }
    
    // 发光效果动画
    func startGlowAnimation() {
        // 创建一个缓慢的脉动动画，让发光效果更加自然
        let fadeOut = SKAction.fadeAlpha(to: 0.1, duration: 1.5)
        let fadeIn = SKAction.fadeAlpha(to: 0.3, duration: 1.5)
        let pulse = SKAction.sequence([fadeOut, fadeIn])
        let pulseContinuously = SKAction.repeatForever(pulse)
        
        // 同时添加一个微小的缩放动画，使发光效果看起来更加活跃
        let scaleUp = SKAction.scale(to: 1.1, duration: 1.5)
        let scaleDown = SKAction.scale(to: 0.95, duration: 1.5)
        let scalePulse = SKAction.sequence([scaleUp, scaleDown])
        let scalePulseContinuously = SKAction.repeatForever(scalePulse)
        
        // 运行动画
        glowEffect.run(pulseContinuously)
        glowEffect.run(scalePulseContinuously)
    }
} 