import SpriteKit

class Fluffel: SKNode {
    
    private let body: SKShapeNode
    private let leftEye: SKShapeNode
    private let rightEye: SKShapeNode
    
    public let size: CGSize = CGSize(width: 50, height: 50)
    
    override init() {
        // 创建 Fluffel 的圆形身体 (红色)
        body = SKShapeNode(circleOfRadius: 25)
        body.fillColor = .red
        body.strokeColor = .clear
        
        // 创建眼睛 (白色圆点)
        let eyeRadius: CGFloat = 5.0
        leftEye = SKShapeNode(circleOfRadius: eyeRadius)
        leftEye.fillColor = .white
        leftEye.strokeColor = .clear
        leftEye.position = CGPoint(x: -10, y: 5)
        
        rightEye = SKShapeNode(circleOfRadius: eyeRadius)
        rightEye.fillColor = .white
        rightEye.strokeColor = .clear
        rightEye.position = CGPoint(x: 10, y: 5)
        
        super.init()
        
        // 添加身体和眼睛到节点
        addChild(body)
        addChild(leftEye)
        addChild(rightEye)
        
        // 启动基本动画
        startBreathingAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 呼吸动画 - 让 Fluffel 看起来更有生命力
    func startBreathingAnimation() {
        // 身体轻微缩放动画
        let scaleUp = SKAction.scale(to: 1.05, duration: 0.5)
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.5)
        let breathe = SKAction.sequence([scaleUp, scaleDown])
        let breatheContinuously = SKAction.repeatForever(breathe)
        body.run(breatheContinuously)
        
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
} 