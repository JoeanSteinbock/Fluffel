import Cocoa
import SpriteKit

// Fluffel 的活动状态
enum FluffelState {
    case idle           // 闲置状态
    case moving         // 正常移动
    case walking        // 行走状态
    case falling        // 下落中
    case sleeping       // 睡眠状态
    case dancing        // 跳舞状态
    case excited        // 兴奋状态
    case listeningToMusic // 听音乐状态
}

class Fluffel: SKNode {
    
    // MARK: - 属性
    
    // 视觉组件
    internal let body: SKShapeNode
    internal let leftEye: SKShapeNode
    internal let rightEye: SKShapeNode
    internal let mouth: SKShapeNode
    internal let leftCheek: SKShapeNode
    internal let rightCheek: SKShapeNode
    internal let leftEar: SKShapeNode
    internal let rightEar: SKShapeNode
    internal let glowEffect: SKShapeNode // 添加发光效果节点
    
    // 耳机组件 - 只在听音乐时显示
    internal let headphones: SKNode
    internal let leftHeadphone: SKShapeNode
    internal let rightHeadphone: SKShapeNode
    internal let headband: SKShapeNode
    
    // Fluffel 状态相关变量
    var state: FluffelState = .idle
    
    public let size: CGSize = CGSize(width: 50, height: 50)
    
    // MARK: - 初始化
    
    override init() {
        // 首先创建发光效果，这样它会位于所有部件的下方
        glowEffect = SKShapeNode(circleOfRadius: 28) // 略大于身体
        glowEffect.fillColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.2) // 非常淡的白色
        glowEffect.strokeColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.1)
        glowEffect.lineWidth = 3.0
        glowEffect.blendMode = .add // 使用叠加混合模式使发光效果更明显
        glowEffect.zPosition = -1 // 确保在 Fluffel 下方
        
        // 创建 Fluffel 的圆形身体 (使用 Morty 的肤色)
        body = SKShapeNode(circleOfRadius: 25)
        body.fillColor = NSColor(calibratedRed: 0.98, green: 0.85, blue: 0.65, alpha: 1.0) // Morty 的肤色
        body.strokeColor = NSColor(calibratedRed: 0.95, green: 0.8, blue: 0.6, alpha: 1.0) // 柔和的边缘
        body.lineWidth = 1.0
        
        // 创建 Morty 风格的大眼睛
        let eyeRadius: CGFloat = 8.0 // 更大的眼睛
        leftEye = SKShapeNode(circleOfRadius: eyeRadius)
        leftEye.fillColor = .white
        leftEye.strokeColor = NSColor.black
        leftEye.lineWidth = 1.0
        leftEye.position = CGPoint(x: -10, y: 7) // 稍微上移
        
        // 创建 Morty 风格的简单黑色瞳孔
        let leftPupil = SKShapeNode(circleOfRadius: eyeRadius * 0.3)
        leftPupil.fillColor = NSColor.black
        leftPupil.strokeColor = .clear
        leftPupil.position = CGPoint(x: 0, y: 0) // 居中
        leftEye.addChild(leftPupil)
        
        rightEye = SKShapeNode(circleOfRadius: eyeRadius)
        rightEye.fillColor = .white
        rightEye.strokeColor = NSColor.black
        rightEye.lineWidth = 1.0
        rightEye.position = CGPoint(x: 10, y: 7) // 稍微上移
        
        // 创建 Morty 风格的简单黑色瞳孔
        let rightPupil = SKShapeNode(circleOfRadius: eyeRadius * 0.3)
        rightPupil.fillColor = NSColor.black
        rightPupil.strokeColor = .clear
        rightPupil.position = CGPoint(x: 0, y: 0) // 居中
        rightEye.addChild(rightPupil)
        
        // 创建嘴巴 (简单直线，后续可以改变形状表达情感)
        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -7, y: -8))
        mouthPath.addLine(to: CGPoint(x: 7, y: -8))
        
        mouth = SKShapeNode(path: mouthPath)
        mouth.strokeColor = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        mouth.lineWidth = 1.5
        
        // 创建 Morty 风格的脸颊，更加淡化
        leftCheek = SKShapeNode(circleOfRadius: 5.0)
        leftCheek.fillColor = NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.6, alpha: 0.2) // 更淡的橙色
        leftCheek.strokeColor = .clear
        leftCheek.position = CGPoint(x: -15, y: -3)
        
        rightCheek = SKShapeNode(circleOfRadius: 5.0)
        rightCheek.fillColor = NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.6, alpha: 0.2) // 更淡的橙色
        rightCheek.strokeColor = .clear
        rightCheek.position = CGPoint(x: 15, y: -3)
        
        // 添加 Morty 风格的耳朵
        leftEar = SKShapeNode(circleOfRadius: 8)
        leftEar.fillColor = NSColor(calibratedRed: 0.98, green: 0.85, blue: 0.65, alpha: 1.0) // 与肤色相同
        leftEar.strokeColor = .clear
        leftEar.position = CGPoint(x: -18, y: 18)
        
        rightEar = SKShapeNode(circleOfRadius: 8)
        rightEar.fillColor = NSColor(calibratedRed: 0.98, green: 0.85, blue: 0.65, alpha: 1.0) // 与肤色相同
        rightEar.strokeColor = .clear
        rightEar.position = CGPoint(x: 18, y: 18)
        
        // 创建耳机组件
        // 耳机父节点
        headphones = SKNode()
        
        // 创建更现代化的耳机设计
        // 左耳机 - 使用椭圆形状更符合真实耳机
        let leftHeadphonePath = CGMutablePath()
        leftHeadphonePath.addEllipse(in: CGRect(x: -10, y: -10, width: 20, height: 25))
        leftHeadphone = SKShapeNode(path: leftHeadphonePath)
        leftHeadphone.fillColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) // 更深的黑色
        leftHeadphone.strokeColor = NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        leftHeadphone.lineWidth = 1.5
        leftHeadphone.position = CGPoint(x: -23, y: 15) // 位于左耳附近
        
        // 右耳机 - 使用椭圆形状更符合真实耳机
        let rightHeadphonePath = CGMutablePath()
        rightHeadphonePath.addEllipse(in: CGRect(x: -10, y: -10, width: 20, height: 25))
        rightHeadphone = SKShapeNode(path: rightHeadphonePath)
        rightHeadphone.fillColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        rightHeadphone.strokeColor = NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        rightHeadphone.lineWidth = 1.5
        rightHeadphone.position = CGPoint(x: 23, y: 15) // 位于右耳附近
        
        // 添加耳垫 - 增加舒适感
        let leftEarpad = SKShapeNode(ellipseOf: CGSize(width: 16, height: 20))
        leftEarpad.fillColor = NSColor(calibratedRed: 0.3, green: 0.3, blue: 0.3, alpha: 1.0) // 稍微浅一点的颜色
        leftEarpad.strokeColor = .clear
        leftEarpad.position = CGPoint(x: 0, y: 0)
        leftHeadphone.addChild(leftEarpad)
        
        let rightEarpad = SKShapeNode(ellipseOf: CGSize(width: 16, height: 20))
        rightEarpad.fillColor = NSColor(calibratedRed: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        rightEarpad.strokeColor = .clear
        rightEarpad.position = CGPoint(x: 0, y: 0)
        rightHeadphone.addChild(rightEarpad)
        
        // 头带连接左右耳机 - 更平滑的曲线
        let headbandPath = CGMutablePath()
        headbandPath.move(to: CGPoint(x: -20, y: 21))
        headbandPath.addCurve(
            to: CGPoint(x: 20, y: 21), 
            control1: CGPoint(x: -10, y: 35), // 更高的控制点
            control2: CGPoint(x: 10, y: 35)   // 更高的控制点
        )
        
        headband = SKShapeNode(path: headbandPath)
        headband.strokeColor = NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        headband.lineWidth = 3.0 // 更粗的线条
        
        // 添加头带填充 - 使头带看起来更立体
        let headbandFillPath = CGMutablePath()
        headbandFillPath.move(to: CGPoint(x: -20, y: 21))
        headbandFillPath.addCurve(
            to: CGPoint(x: 20, y: 21),
            control1: CGPoint(x: -10, y: 35),
            control2: CGPoint(x: 10, y: 35)
        )
        headbandFillPath.addCurve(
            to: CGPoint(x: -20, y: 21),
            control1: CGPoint(x: 10, y: 33),
            control2: CGPoint(x: -10, y: 33)
        )
        
        let headbandFill = SKShapeNode(path: headbandFillPath)
        headbandFill.fillColor = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.2, alpha: 0.7)
        headbandFill.strokeColor = .clear
        headband.addChild(headbandFill)
        
        // 添加金属高光到耳机，使其更有立体感
        let leftHeadphoneHighlight = SKShapeNode(ellipseOf: CGSize(width: 10, height: 12))
        leftHeadphoneHighlight.fillColor = NSColor(calibratedRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.4) // 金属质感
        leftHeadphoneHighlight.strokeColor = .clear
        leftHeadphoneHighlight.position = CGPoint(x: -2, y: 2)
        leftHeadphone.addChild(leftHeadphoneHighlight)
        
        let rightHeadphoneHighlight = SKShapeNode(ellipseOf: CGSize(width: 10, height: 12))
        rightHeadphoneHighlight.fillColor = NSColor(calibratedRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.4) // 金属质感
        rightHeadphoneHighlight.strokeColor = .clear
        rightHeadphoneHighlight.position = CGPoint(x: 2, y: 2)
        rightHeadphone.addChild(rightHeadphoneHighlight)
        
        // 添加品牌标志 - 小圆点
        let leftLogo = SKShapeNode(circleOfRadius: 2)
        leftLogo.fillColor = NSColor(calibratedRed: 0.8, green: 0.1, blue: 0.1, alpha: 1.0) // 红色标志
        leftLogo.strokeColor = .clear
        leftLogo.position = CGPoint(x: 7, y: 0)
        leftHeadphone.addChild(leftLogo)
        
        let rightLogo = SKShapeNode(circleOfRadius: 2)
        rightLogo.fillColor = NSColor(calibratedRed: 0.8, green: 0.1, blue: 0.1, alpha: 1.0) // 红色标志
        rightLogo.strokeColor = .clear
        rightLogo.position = CGPoint(x: -7, y: 0)
        rightHeadphone.addChild(rightLogo)
        
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
        
        // 添加耳机组件
        headphones.addChild(leftHeadphone)
        headphones.addChild(rightHeadphone)
        headphones.addChild(headband)
        addChild(headphones)
        
        // 启动基本动画
        startBreathingAnimation()
        
        // 启动发光效果动画
        startGlowAnimation()
        
        // 隐藏耳机组件
        headphones.isHidden = true
        
        print("Fluffel 初始化完成")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 状态管理
    
    // 设置 Fluffel 的状态
    func setState(_ newState: FluffelState) {
        // 确保状态更改在主线程上执行
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.setState(newState)
            }
            return
        }
        
        // 在改变状态前清理当前状态
        if state != newState {
            // 移除任何显示的对话气泡
            removeSpeechBubble()
            
            // 根据当前状态执行清理
            switch state {
            case .walking:
                removeAction(forKey: "walkingAction")
            case .falling:
                removeAction(forKey: "fallingAction")
            case .dancing:
                removeAction(forKey: "dancingAction")
                removeAction(forKey: "musicNotes")
            case .listeningToMusic:
                removeAction(forKey: "listeningToMusicAction")
                removeAction(forKey: "musicListeningNotes")
                leftEar.removeAllActions()
                rightEar.removeAllActions()
                
                // 注释掉这一行，避免循环调用
                // 这里不应该调用FluffelScene.stopMusic()，因为可能会导致无限递归
                // (self.parent?.scene as? FluffelScene)?.stopMusic()
                
                // 直接停止音频播放器，无需通过场景
                if Fluffel.musicPlayer != nil {
                    Fluffel.musicPlayer?.stop()
                    Fluffel.musicPlayer = nil
                    Fluffel.musicTimer?.invalidate()
                    Fluffel.musicTimer = nil
                    print("Music player stopped directly in setState")
                }
            default:
                break
            }
        }
        
        state = newState
        
        // 根据新状态执行初始化
        switch state {
        case .idle:
            smile()
        case .listeningToMusic:
            // 当切换到听音乐状态时，确保所有其他动画被停止
            removeAction(forKey: "walkingAction")
            removeAction(forKey: "fallingAction")
            removeAction(forKey: "dancingAction")
            removeAction(forKey: "musicNotes")
            removeAction(forKey: "excitedAction")
        default:
            break
        }
    }
}
