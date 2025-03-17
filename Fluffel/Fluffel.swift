import SpriteKit

// Fluffel 的活动状态
enum FluffelState {
    case idle           // 闲置状态
    case moving         // 正常移动
    case onEdge         // 在窗口边缘上
    case falling        // 下落中
    case climbing       // 攀爬中
}

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
    
    // 当前状态相关变量
    private(set) var state: FluffelState = .idle
    private(set) var isOnEdge: Bool = false
    private(set) var currentEdge: ScreenWindow.EdgeType?
    private(set) var currentWindow: ScreenWindow?
    
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
        
        print("Fluffel 初始化开始")
        
        // 添加所有部件到节点，确保发光效果在最底层
        addChild(glowEffect)
        addChild(body)
        addChild(leftEar)
        addChild(rightEar)
        addChild(leftEye)
        addChild(rightEye)
        addChild(mouth)
        addChild(leftCheek)
        addChild(rightCheek)
        
        // 启动基本动画
        startBreathingAnimation()
        
        // 启动发光效果动画
        startGlowAnimation()
        
        print("Fluffel 初始化完成")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 设置 Fluffel 的状态
    func setState(_ newState: FluffelState) {
        // 如果状态没有变化，不做任何处理
        if state == newState { return }
        
        // 退出当前状态
        switch state {
        case .idle:
            // 从闲置状态退出时的操作
            break
        case .moving:
            // 从移动状态退出时的操作
            break
        case .onEdge:
            // 从边缘状态退出时的操作
            isOnEdge = false
            currentEdge = nil
            currentWindow = nil
            break
        case .falling:
            // 从下落状态退出时的操作
            break
        case .climbing:
            // 从攀爬状态退出时的操作
            break
        }
        
        // 进入新状态
        state = newState
        
        switch newState {
        case .idle:
            // 进入闲置状态时的操作
            smile()
            break
        case .moving:
            // 进入移动状态时的操作
            break
        case .onEdge:
            // 进入边缘状态时的操作
            isOnEdge = true
            break
        case .falling:
            // 进入下落状态时的操作
            startFallingAnimation()
            break
        case .climbing:
            // 进入攀爬状态时的操作
            break
        }
    }
    
    // 设置在边缘上的状态
    func setOnEdge(window: ScreenWindow, edge: ScreenWindow.EdgeType) {
        currentWindow = window
        currentEdge = edge
        setState(.onEdge)
    }
    
    // 当 Fluffel 离开边缘时
    func leaveEdge() {
        if state == .onEdge {
            setState(.moving)
        }
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
    
    // 开始下落动画
    func startFallingAnimation() {
        if state == .falling { return }
        
        // 设置下落状态
        setState(.falling)
        
        // 表情变化
        surprisedFace()
        
        // 下落动画序列
        let rotate = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 0.7)  // 旋转一圈
        let fall = SKAction.moveBy(x: 0, y: -300, duration: 0.7)  // 下落
        let group = SKAction.group([rotate, fall])  // 同时旋转和下落
        
        // 落地后的弹跳效果
        let bounce1 = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 30, duration: 0.2),
            SKAction.moveBy(x: 0, y: -30, duration: 0.15)
        ])
        let bounce2 = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 15, duration: 0.15),
            SKAction.moveBy(x: 0, y: -15, duration: 0.1)
        ])
        
        // 完成后恢复闲置状态
        let resetAction = SKAction.run { [weak self] in
            self?.setState(.idle)
            self?.smile()  // 恢复微笑
        }
        
        // 完整的下落序列
        let fallSequence = SKAction.sequence([group, bounce1, bounce2, resetAction])
        
        // 执行动画
        run(fallSequence, withKey: "fallingAction")
    }
    
    // 惊讶表情 - 用于下落时
    func surprisedFace() {
        // 眼睛变大
        leftEye.setScale(1.3)
        rightEye.setScale(1.3)
        
        // 嘴巴变成O形
        let oMouthPath = CGMutablePath()
        oMouthPath.addEllipse(in: CGRect(x: -5, y: -10, width: 10, height: 8))
        mouth.path = oMouthPath
        mouth.fillColor = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
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
    
    // 担忧表情
    func worried() {
        let worriedPath = CGMutablePath()
        worriedPath.move(to: CGPoint(x: -7, y: -8))
        // 担忧的表情，嘴巴向下弯曲
        worriedPath.addQuadCurve(to: CGPoint(x: 7, y: -8), control: CGPoint(x: 0, y: -4))
        
        mouth.path = worriedPath
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

    // 滚动动画 - 用于 Fluffel 在边缘滚动时
    func roll() {
        // 停止其他可能正在进行的动画
        removeAction(forKey: "walkingAction")
        removeAction(forKey: "fallingAction")
        
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