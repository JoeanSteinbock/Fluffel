import SpriteKit

// Fluffel 的活动状态
enum FluffelState {
    case idle           // 闲置状态
    case moving         // 正常移动
    case onEdge         // 在窗口边缘上
    case falling        // 下落中
    case climbing       // 攀爬中
    case sleeping       // 睡眠状态
    case dancing        // 跳舞状态
    case excited        // 兴奋状态
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
            stopEdgeWalkingAnimation()
            break
        case .falling:
            // 从下落状态退出时的操作
            break
        case .climbing:
            // 从攀爬状态退出时的操作
            break
        case .sleeping:
            // 从睡眠状态退出时的操作
            stopSleepingAnimation()
            break
        case .dancing:
            // 从跳舞状态退出时的操作
            stopDancingAnimation()
            break
        case .excited:
            // 从兴奋状态退出时的操作
            stopExcitedAnimation()
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
        case .sleeping:
            // 进入睡眠状态时的操作
            startSleepingAnimation()
            break
        case .dancing:
            // 进入跳舞状态时的操作
            startDancingAnimation()
            break
        case .excited:
            // 进入兴奋状态时的操作
            startExcitedAnimation()
            break
        }
    }
    
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
            stopEdgeWalkingAnimation()
            setState(.moving)
            print("Fluffel 离开了边缘")
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
        
        // 停止其他动画
        stopEdgeWalkingAnimation()
        removeAction(forKey: "walkingAction")
        
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
    
    // 停止边缘行走动画
    func stopEdgeWalkingAnimation() {
        removeAction(forKey: "edgeWalkingAction")
        body.removeAction(forKey: "bodyWobble")
        leftEar.removeAction(forKey: "leftEarWobble")
        rightEar.removeAction(forKey: "rightEarWobble")
    }
    
    // 睡眠动画 - 模拟 Fluffel 睡觉
    func startSleepingAnimation() {
        // 移除可能正在进行的其他动画
        removeAction(forKey: "walkingAction")
        removeAction(forKey: "fallingAction")
        removeAction(forKey: "dancingAction")
        removeAction(forKey: "excitedAction")
        
        // 创建睡眠表情
        let sleepyEyesAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 闭上眼睛
            self.leftEye.setScale(0.1)
            self.rightEye.setScale(0.1)
            
            // 睡觉时的嘴巴表情 - 轻微张开
            let sleepyMouthPath = CGMutablePath()
            sleepyMouthPath.move(to: CGPoint(x: -5, y: -8))
            sleepyMouthPath.addQuadCurve(to: CGPoint(x: 5, y: -8), control: CGPoint(x: 0, y: -6))
            self.mouth.path = sleepyMouthPath
        }
        
        // 创建"Z"字符动画表示睡眠
        let createZs = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 创建三个Z字符，大小不同
            for i in 0..<3 {
                let zSize = CGFloat(10 + i * 2) // 逐渐增大的Z
                let zNode = SKLabelNode(text: "Z")
                zNode.fontSize = zSize
                zNode.fontColor = NSColor(calibratedRed: 0.6, green: 0.6, blue: 1.0, alpha: 0.8)
                zNode.position = CGPoint(x: 20 + CGFloat(i * 5), y: 15 + CGFloat(i * 5))
                zNode.zPosition = 5
                self.addChild(zNode)
                
                // Z字符上升并淡出的动画
                let moveUp = SKAction.moveBy(x: 15, y: 20, duration: 2.0)
                let fadeOut = SKAction.fadeOut(withDuration: 2.0)
                let group = SKAction.group([moveUp, fadeOut])
                let remove = SKAction.removeFromParent()
                let sequence = SKAction.sequence([group, remove])
                
                zNode.run(sequence)
            }
        }
        
        // 轻微的呼吸动作
        let breatheIn = SKAction.scale(to: 1.05, duration: 1.0)
        let breatheOut = SKAction.scale(to: 0.95, duration: 1.0)
        let breatheCycle = SKAction.sequence([breatheIn, breatheOut])
        let breatheAction = SKAction.repeatForever(breatheCycle)
        
        // 组合所有动作
        let sleepSequence = SKAction.sequence([
            sleepyEyesAction,
            SKAction.wait(forDuration: 1.0),
            createZs,
            SKAction.wait(forDuration: 3.0)
        ])
        
        let sleepCycle = SKAction.repeatForever(sleepSequence)
        
        // 运行动画
        run(breatheAction, withKey: "breathingSleep")
        run(sleepCycle, withKey: "sleepingAction")
    }
    
    // 停止睡眠动画
    func stopSleepingAnimation() {
        // 移除睡眠相关动画
        removeAction(forKey: "sleepingAction")
        removeAction(forKey: "breathingSleep")
        
        // 移除所有Z字符
        self.children.forEach { node in
            if let label = node as? SKLabelNode, label.text == "Z" {
                label.removeFromParent()
            }
        }
        
        // 恢复正常表情
        leftEye.setScale(1.0)
        rightEye.setScale(1.0)
        smile()
    }
    
    // 开始跳舞动画
    func startDancingAnimation() {
        // 移除可能正在进行的其他动画
        removeAction(forKey: "walkingAction")
        removeAction(forKey: "fallingAction")
        removeAction(forKey: "sleepingAction")
        removeAction(forKey: "excitedAction")
        
        // 创建开心表情
        let happyFaceAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 大眼睛
            self.leftEye.setScale(1.2)
            self.rightEye.setScale(1.2)
            
            // 大笑的嘴巴
            let bigSmilePath = CGMutablePath()
            bigSmilePath.move(to: CGPoint(x: -8, y: -8))
            bigSmilePath.addQuadCurve(to: CGPoint(x: 8, y: -8), control: CGPoint(x: 0, y: -16))
            self.mouth.path = bigSmilePath
        }
        
        // 创建跳舞动作序列
        let jump1 = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 10, duration: 0.2),
            SKAction.moveBy(x: 0, y: -10, duration: 0.2)
        ])
        
        let spin = SKAction.sequence([
            SKAction.rotate(byAngle: CGFloat.pi, duration: 0.4),
            SKAction.rotate(byAngle: CGFloat.pi, duration: 0.4)
        ])
        
        let sideStep = SKAction.sequence([
            SKAction.moveBy(x: 10, y: 0, duration: 0.2),
            SKAction.moveBy(x: -20, y: 0, duration: 0.4),
            SKAction.moveBy(x: 10, y: 0, duration: 0.2)
        ])
        
        // 身体变形动画
        let bodyStretch = SKAction.sequence([
            SKAction.scaleX(to: 0.8, y: 1.2, duration: 0.2),
            SKAction.scaleX(to: 1.2, y: 0.8, duration: 0.2),
            SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.2)
        ])
        
        // 组合舞蹈动作
        let danceSequence = SKAction.sequence([
            happyFaceAction,
            jump1,
            bodyStretch,
            sideStep,
            spin,
            SKAction.wait(forDuration: 0.5)
        ])
        
        let danceCycle = SKAction.repeatForever(danceSequence)
        
        // 运行动画
        run(danceCycle, withKey: "dancingAction")
        
        // 添加音符效果
        let createNotes = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 创建音符
            let noteSymbols = ["♪", "♫", "♬", "♩"]
            let noteColors: [NSColor] = [
                NSColor(calibratedRed: 1.0, green: 0.5, blue: 0.5, alpha: 0.8),
                NSColor(calibratedRed: 0.5, green: 1.0, blue: 0.5, alpha: 0.8),
                NSColor(calibratedRed: 0.5, green: 0.5, blue: 1.0, alpha: 0.8),
                NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.5, alpha: 0.8)
            ]
            
            // 随机选择音符和颜色
            let randomIndex = Int.random(in: 0..<noteSymbols.count)
            let noteNode = SKLabelNode(text: noteSymbols[randomIndex])
            noteNode.fontSize = 20
            noteNode.fontColor = noteColors[Int.random(in: 0..<noteColors.count)]
            
            // 随机位置
            let randomOffset = CGFloat.random(in: -20...20)
            noteNode.position = CGPoint(x: randomOffset, y: 20)
            noteNode.zPosition = 5
            self.addChild(noteNode)
            
            // 音符上升并旋转淡出的动画
            let moveUp = SKAction.moveBy(x: CGFloat.random(in: -30...30), y: 40, duration: 1.5)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -CGFloat.pi...CGFloat.pi), duration: 1.5)
            let fadeOut = SKAction.fadeOut(withDuration: 1.5)
            let group = SKAction.group([moveUp, rotate, fadeOut])
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([group, remove])
            
            noteNode.run(sequence)
        }
        
        // 定期创建音符
        let noteSequence = SKAction.sequence([
            createNotes,
            SKAction.wait(forDuration: 0.5)
        ])
        
        run(SKAction.repeatForever(noteSequence), withKey: "musicNotes")
    }
    
    // 停止跳舞动画
    func stopDancingAnimation() {
        // 移除跳舞相关动画
        removeAction(forKey: "dancingAction")
        removeAction(forKey: "musicNotes")
        
        // 移除所有音符
        self.children.forEach { node in
            if let label = node as? SKLabelNode, ["♪", "♫", "♬", "♩"].contains(label.text ?? "") {
                label.removeFromParent()
            }
        }
        
        // 恢复正常表情和姿态
        leftEye.setScale(1.0)
        rightEye.setScale(1.0)
        self.xScale = 1.0
        self.yScale = 1.0
        self.zRotation = 0
        smile()
    }
    
    // 开始兴奋动画
    func startExcitedAnimation() {
        // 移除可能正在进行的其他动画
        removeAction(forKey: "walkingAction")
        removeAction(forKey: "fallingAction")
        removeAction(forKey: "sleepingAction")
        removeAction(forKey: "dancingAction")
        
        // 创建兴奋表情
        let excitedFaceAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 大眼睛，瞳孔放大
            self.leftEye.setScale(1.3)
            self.rightEye.setScale(1.3)
            
            // 惊喜的嘴巴 - 大大的笑容
            let excitedMouthPath = CGMutablePath()
            excitedMouthPath.move(to: CGPoint(x: -10, y: -8))
            excitedMouthPath.addQuadCurve(to: CGPoint(x: 10, y: -8), control: CGPoint(x: 0, y: -18))
            self.mouth.path = excitedMouthPath
            self.mouth.fillColor = NSColor(calibratedRed: 0.9, green: 0.5, blue: 0.5, alpha: 0.3)
        }
        
        // 创建兴奋动作 - 快速跳跃和旋转
        let quickJump = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 15, duration: 0.1),
            SKAction.moveBy(x: 0, y: -15, duration: 0.1)
        ])
        
        // 身体快速变形
        let quickPulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        
        // 耳朵快速摆动
        let quickEarWiggle = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            let leftWiggle = SKAction.sequence([
                SKAction.rotate(byAngle: 0.2, duration: 0.1),
                SKAction.rotate(byAngle: -0.4, duration: 0.2),
                SKAction.rotate(byAngle: 0.2, duration: 0.1)
            ])
            
            let rightWiggle = SKAction.sequence([
                SKAction.rotate(byAngle: -0.2, duration: 0.1),
                SKAction.rotate(byAngle: 0.4, duration: 0.2),
                SKAction.rotate(byAngle: -0.2, duration: 0.1)
            ])
            
            self.leftEar.run(SKAction.repeat(leftWiggle, count: 3))
            self.rightEar.run(SKAction.repeat(rightWiggle, count: 3))
        }
        
        // 创建星星效果
        let createStars = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 创建3-5个星星
            let starCount = Int.random(in: 3...5)
            for _ in 0..<starCount {
                let starNode = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
                
                // 创建星形路径
                let starPath = CGMutablePath()
                let centerX: CGFloat = 0
                let centerY: CGFloat = 0
                let radius: CGFloat = 5
                
                for i in 0..<10 {
                    let angle = CGFloat(i) * .pi / 5
                    let r = i % 2 == 0 ? radius : radius / 2
                    let x = centerX + r * cos(angle)
                    let y = centerY + r * sin(angle)
                    
                    if i == 0 {
                        starPath.move(to: CGPoint(x: x, y: y))
                    } else {
                        starPath.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                starPath.closeSubpath()
                
                starNode.path = starPath
                starNode.fillColor = NSColor(calibratedRed: 1.0, green: 0.9, blue: 0.4, alpha: 0.8)
                starNode.strokeColor = NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.0, alpha: 0.8)
                
                // 随机位置
                let randomAngle = CGFloat.random(in: 0...(2 * .pi))
                let randomDistance = CGFloat.random(in: 30...50)
                let x = cos(randomAngle) * randomDistance
                let y = sin(randomAngle) * randomDistance
                starNode.position = CGPoint(x: x, y: y)
                starNode.zPosition = 5
                self.addChild(starNode)
                
                // 星星闪烁并消失的动画
                let scaleUp = SKAction.scale(to: 1.5, duration: 0.3)
                let scaleDown = SKAction.scale(to: 0.5, duration: 0.3)
                let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                let sequence = SKAction.sequence([scaleUp, scaleDown, fadeOut, SKAction.removeFromParent()])
                
                starNode.run(sequence)
            }
        }
        
        // 组合兴奋动作
        let excitedSequence = SKAction.sequence([
            excitedFaceAction,
            quickPulse,
            quickJump,
            quickEarWiggle,
            createStars,
            SKAction.wait(forDuration: 0.5)
        ])
        
        let excitedCycle = SKAction.repeatForever(excitedSequence)
        
        // 运行动画
        run(excitedCycle, withKey: "excitedAction")
    }
    
    // 停止兴奋动画
    func stopExcitedAnimation() {
        // 移除兴奋相关动画
        removeAction(forKey: "excitedAction")
        
        // 移除所有星星
        self.children.forEach { node in
            if let shapeNode = node as? SKShapeNode,
                node != body && node != leftEye && node != rightEye &&
                node != mouth && node != leftCheek && node != rightCheek &&
                node != leftEar && node != rightEar && node != glowEffect {
                node.removeFromParent()
            }
        }
        
        // 恢复正常表情和姿态
        leftEye.setScale(1.0)
        rightEye.setScale(1.0)
        mouth.fillColor = .clear
        self.xScale = 1.0
        self.yScale = 1.0
        smile()
    }
}
