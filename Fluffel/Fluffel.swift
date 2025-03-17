import SpriteKit

class Fluffel: SKNode {
    
    private let body: SKShapeNode
    private let leftEye: SKShapeNode
    private let rightEye: SKShapeNode
    private let mouth: SKShapeNode
    private let leftCheek: SKShapeNode
    private let rightCheek: SKShapeNode
    private let leftEar: SKShapeNode
    private let rightEar: SKShapeNode
    private let glowEffect: SKShapeNode // 添加发光效果节点
    
    public let size: CGSize = CGSize(width: 50, height: 50)
    
    override init() {
        // 首先创建发光效果，这样它会位于所有部件的下方
        glowEffect = SKShapeNode(circleOfRadius: 28) // 略大于身体
        glowEffect.fillColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.2) // 非常淡的白色
        glowEffect.strokeColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.1)
        glowEffect.lineWidth = 3.0
        glowEffect.blendMode = .add // 使用叠加混合模式使发光效果更明显
        glowEffect.zPosition = -1 // 确保在 Fluffel 下方
        
        // 创建 Fluffel 的圆形身体 (使用更明亮、更可爱的粉色)
        body = SKShapeNode(circleOfRadius: 25)
        body.fillColor = NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.85, alpha: 1.0) // 更明亮的粉色
        body.strokeColor = NSColor(calibratedRed: 0.95, green: 0.7, blue: 0.75, alpha: 1.0) // 柔和的边缘
        body.lineWidth = 1.0
        
        // 创建眼睛 (更大、更友好的眼睛)
        let eyeRadius: CGFloat = 6.0 // 稍微大一点的眼睛
        leftEye = SKShapeNode(circleOfRadius: eyeRadius)
        leftEye.fillColor = .white
        leftEye.strokeColor = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        leftEye.lineWidth = 0.5
        leftEye.position = CGPoint(x: -10, y: 7) // 稍微上移
        
        // 创建瞳孔 (更大、更可爱的瞳孔)
        let leftPupil = SKShapeNode(circleOfRadius: eyeRadius * 0.65)
        leftPupil.fillColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.3, alpha: 1.0) // 不那么黑的瞳孔
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: 0.5, y: 0) // 居中一点
        leftEye.addChild(leftPupil)
        
        // 添加更大的高光点，增加可爱感
        let leftHighlight = SKShapeNode(circleOfRadius: eyeRadius * 0.3)
        leftHighlight.fillColor = .white
        leftHighlight.strokeColor = .clear
        leftHighlight.position = CGPoint(x: 1.5, y: 1.5)
        leftPupil.addChild(leftHighlight)
        
        // 添加第二个小高光点
        let leftSmallHighlight = SKShapeNode(circleOfRadius: eyeRadius * 0.15)
        leftSmallHighlight.fillColor = .white
        leftSmallHighlight.strokeColor = .clear
        leftSmallHighlight.position = CGPoint(x: -1.0, y: -1.0)
        leftPupil.addChild(leftSmallHighlight)
        
        rightEye = SKShapeNode(circleOfRadius: eyeRadius)
        rightEye.fillColor = .white
        rightEye.strokeColor = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        rightEye.lineWidth = 0.5
        rightEye.position = CGPoint(x: 10, y: 7) // 稍微上移
        
        // 创建瞳孔
        let rightPupil = SKShapeNode(circleOfRadius: eyeRadius * 0.65)
        rightPupil.fillColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.3, alpha: 1.0) // 不那么黑的瞳孔
        rightPupil.strokeColor = .clear
        rightPupil.position = CGPoint(x: -0.5, y: 0) // 居中一点
        rightEye.addChild(rightPupil)
        
        // 添加更大的高光点
        let rightHighlight = SKShapeNode(circleOfRadius: eyeRadius * 0.3)
        rightHighlight.fillColor = .white
        rightHighlight.strokeColor = .clear
        rightHighlight.position = CGPoint(x: -1.5, y: 1.5)
        rightPupil.addChild(rightHighlight)
        
        // 添加第二个小高光点
        let rightSmallHighlight = SKShapeNode(circleOfRadius: eyeRadius * 0.15)
        rightSmallHighlight.fillColor = .white
        rightSmallHighlight.strokeColor = .clear
        rightSmallHighlight.position = CGPoint(x: 1.0, y: -1.0)
        rightPupil.addChild(rightSmallHighlight)
        
        // 创建嘴巴 (简单直线，后续可以改变形状表达情感)
        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -7, y: -8))
        mouthPath.addLine(to: CGPoint(x: 7, y: -8))
        
        mouth = SKShapeNode(path: mouthPath)
        mouth.strokeColor = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        mouth.lineWidth = 1.5
        
        // 创建粉红色的脸颊，增添可爱度
        leftCheek = SKShapeNode(circleOfRadius: 5.0) // 稍微大一点的脸颊
        leftCheek.fillColor = NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.7, alpha: 0.3) // 更淡的粉色
        leftCheek.strokeColor = .clear
        leftCheek.position = CGPoint(x: -15, y: -3)
        
        rightCheek = SKShapeNode(circleOfRadius: 5.0)
        rightCheek.fillColor = NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.7, alpha: 0.3)
        rightCheek.strokeColor = .clear
        rightCheek.position = CGPoint(x: 15, y: -3)
        
        // 添加可爱的小耳朵
        leftEar = SKShapeNode(circleOfRadius: 8)
        leftEar.fillColor = NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.8, alpha: 1.0) // 略微明亮一点的颜色
        leftEar.strokeColor = .clear
        leftEar.position = CGPoint(x: -18, y: 18)
        
        rightEar = SKShapeNode(circleOfRadius: 8)
        rightEar.fillColor = NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.8, alpha: 1.0)
        rightEar.strokeColor = .clear
        rightEar.position = CGPoint(x: 18, y: 18)
        
        super.init()
        
        // 添加所有部件到节点，确保发光效果在最底层
        addChild(glowEffect)
        addChild(leftEar)
        addChild(rightEar)
        addChild(body)
        addChild(leftEye)
        addChild(rightEye)
        addChild(mouth)
        addChild(leftCheek)
        addChild(rightCheek)
        
        // 启动基本动画
        startBreathingAnimation()
        
        // 启动发光效果动画
        startGlowAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
    
    // 修正微笑方法，使用向上的曲线而不是向下的曲线
    func smile() {
        // 创建一个真正的微笑曲线 (向上弯曲)
        let smilePath = CGMutablePath()
        smilePath.move(to: CGPoint(x: -7, y: -8))
        // 修正控制点，在 SpriteKit 中，较大的 y 值表示向下，所以使用 -14 使曲线向上弯曲
        smilePath.addQuadCurve(to: CGPoint(x: 7, y: -8), control: CGPoint(x: 0, y: -14))
        
        mouth.path = smilePath
    }
    
    // 添加一个眨眼的开心表情
    func happyBlink() {
        // 眨眼动画序列
        let close = SKAction.scaleY(to: 0.3, duration: 0.1)
        let open = SKAction.scaleY(to: 1.0, duration: 0.1)
        let blinkAction = SKAction.sequence([close, open])
        
        leftEye.run(blinkAction)
        rightEye.run(blinkAction)
    }
} 