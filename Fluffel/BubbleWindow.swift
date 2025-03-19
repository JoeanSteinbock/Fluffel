import Cocoa
import SpriteKit

class BubbleWindow: NSWindow {
    // 气泡内容视图
    private var bubbleView: SKView!
    private var bubbleScene: SKScene!
    
    // 气泡节点
    private var bubbleNode: SKShapeNode?
    private var textNode: SKLabelNode?
    
    // 气泡显示计时器
    private var displayTimer: Timer?
    
    // 关联的 Fluffel 窗口
    weak var fluffelWindow: NSWindow?
    
    convenience init(text: String, fontSize: CGFloat = 12, duration: TimeInterval = 3.0) {
        // 先创建一个小窗口，之后再根据文本大小调整
        let initialSize = CGSize(width: 200, height: 100)
        let contentRect = NSRect(x: 0, y: 0, width: initialSize.width, height: initialSize.height)
        
        self.init(
            contentRect: contentRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .floating + 1  // 确保比 Fluffel 窗口高一级
        self.ignoresMouseEvents = true  // 点击穿透
        
        // 设置调试边框
        setupDebugBorder()
        
        // 创建并设置 SpriteKit 视图
        setupSpriteKitView(frame: contentRect)
        
        // 创建气泡和文本
        createBubble(withText: text, fontSize: fontSize)
        
        // 自动计时关闭
        scheduleDismissal(after: duration)
    }
    
    private func setupSpriteKitView(frame: NSRect) {
        // 创建 SpriteKit 视图
        bubbleView = SKView(frame: frame)
        bubbleView.allowsTransparency = true
        
        // 创建并配置场景
        bubbleScene = SKScene(size: frame.size)
        bubbleScene.backgroundColor = .clear
        
        // 显示场景
        bubbleView.presentScene(bubbleScene)
        
        // 设置窗口内容视图
        self.contentView = bubbleView
    }
    
    private func createBubble(withText text: String, fontSize: CGFloat) {
        // 测量文本大小
        let textAttributes = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: fontSize)]
        let maxBubbleWidth: CGFloat = 200
        
        // 计算合适的换行文本宽度
        var textWidth = text.size(withAttributes: textAttributes).width
        textWidth = min(textWidth, maxBubbleWidth - 20)
        
        // 创建约束宽度的文本
        let constrainedSize = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        let textBounds = text.boundingRect(with: constrainedSize,
                                          options: [.usesLineFragmentOrigin, .usesFontLeading],
                                          attributes: textAttributes, context: nil)
        
        // 基于实际文本高度计算气泡高度
        let bubbleWidth = textWidth + 20
        let bubbleHeight = textBounds.height + 20
        
        // 创建气泡路径
        let bubblePath = CGMutablePath()
        let bubbleRect = CGRect(x: -bubbleWidth/2, y: -bubbleHeight/2, width: bubbleWidth, height: bubbleHeight)
        bubblePath.addRoundedRect(in: bubbleRect, cornerWidth: 10, cornerHeight: 10)
        
        // 添加指向 Fluffel 的小尖角
        bubblePath.move(to: CGPoint(x: -5, y: -bubbleHeight/2))
        bubblePath.addLine(to: CGPoint(x: 0, y: -bubbleHeight/2 - 10))
        bubblePath.addLine(to: CGPoint(x: 5, y: -bubbleHeight/2))
        
        // 创建气泡形状节点
        bubbleNode = SKShapeNode(path: bubblePath)
        bubbleNode?.fillColor = .white
        bubbleNode?.strokeColor = .gray
        bubbleNode?.lineWidth = 1.0
        bubbleNode?.alpha = 0.9
        
        // 创建文本节点
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: fontSize),
                NSAttributedString.Key.foregroundColor: NSColor.black,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
        )
        
        textNode = SKLabelNode(text: "")
        textNode?.numberOfLines = 0
        textNode?.preferredMaxLayoutWidth = textWidth
        textNode?.verticalAlignmentMode = .center
        textNode?.horizontalAlignmentMode = .center
        textNode?.attributedText = attributedText
        
        // 添加节点到场景
        if let bubbleNode = bubbleNode, let textNode = textNode {
            bubbleScene.addChild(bubbleNode)
            bubbleScene.addChild(textNode)
            
            // 淡入动画
            bubbleNode.alpha = 0
            textNode.alpha = 0
            
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            bubbleNode.run(fadeIn)
            textNode.run(fadeIn)
            
            // 添加轻微的上下移动动画，使气泡看起来更活跃
            let moveUp = SKAction.moveBy(x: 0, y: 2, duration: 0.5)
            let moveDown = SKAction.moveBy(x: 0, y: -2, duration: 0.5)
            let sequence = SKAction.sequence([moveUp, moveDown])
            let repeatAction = SKAction.repeatForever(sequence)
            bubbleNode.run(repeatAction)
            textNode.run(repeatAction)
        }
        
        // 根据气泡大小调整窗口尺寸
        let windowSize = CGSize(width: max(bubbleWidth + 20, 100), height: bubbleHeight + 20)
        self.setContentSize(windowSize)
        
        // 更新场景大小
        bubbleScene.size = windowSize
        
        // 将节点居中显示
        bubbleNode?.position = CGPoint(x: windowSize.width / 2, y: windowSize.height / 2)
        textNode?.position = CGPoint(x: windowSize.width / 2, y: windowSize.height / 2)
    }
    
    // 设置窗口位置到 Fluffel 窗口上方
    func positionAboveFluffelWindow() {
        guard let fluffelWindow = self.fluffelWindow, fluffelWindow.isVisible else { return }
        
        // 确保 Fluffel 窗口有效
        guard fluffelWindow.screen != nil else { return }
        
        // 获取 Fluffel 窗口的位置和大小
        let fluffelFrame = fluffelWindow.frame
        
        // 计算气泡窗口的位置 - 水平居中于 Fluffel 窗口，垂直位于上方
        let bubbleX = fluffelFrame.origin.x + (fluffelFrame.width - self.frame.width) / 2
        let bubbleY = fluffelFrame.origin.y + fluffelFrame.height + 10 // 在 Fluffel 上方 10 像素
        
        // 确保计算的位置在有效范围内
        guard !bubbleX.isNaN && !bubbleY.isNaN && bubbleX.isFinite && bubbleY.isFinite else {
            print("警告: 计算的气泡位置无效: x=\(bubbleX), y=\(bubbleY)")
            return
        }
        
        // 安全地设置气泡窗口位置
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isVisible else { return }
            self.setFrameOrigin(NSPoint(x: bubbleX, y: bubbleY))
        }
    }
    
    // 设置自动关闭计时器
    private func scheduleDismissal(after duration: TimeInterval) {
        displayTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }
    
    // 关闭气泡窗口
    func dismiss() {
        // 取消计时器
        displayTimer?.invalidate()
        displayTimer = nil
        
        // 执行淡出动画，然后关闭窗口
        if let bubbleNode = bubbleNode, let textNode = textNode {
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let closeWindow = SKAction.run { [weak self] in
                self?.close()
                
                // 发送通知，表示气泡已消失
                NotificationCenter.default.post(
                    name: NSNotification.Name("fluffelBubbleDismissed"),
                    object: nil
                )
            }
            
            let sequence = SKAction.sequence([fadeOut, closeWindow])
            bubbleNode.run(sequence)
            textNode.run(fadeOut)
        } else {
            self.close()
        }
    }
    
    // 添加调试边框
    private func setupDebugBorder() {
        // 检查是否应该显示调试边框
        if let showBorder = UserDefaults.standard.object(forKey: "FluffelShowDebugBorder") as? Bool, showBorder {
            contentView?.wantsLayer = true
            contentView?.layer?.borderWidth = 2.0
            contentView?.layer?.borderColor = NSColor.blue.cgColor // 使用蓝色边框区分气泡窗口
        }
    }
} 