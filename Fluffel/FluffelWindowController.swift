import Cocoa
import SpriteKit

class FluffelWindowController: NSWindowController {
    
    var fluffelScene: FluffelScene?
    
    // Fluffel 周围的填充空间
    private let fluffelPadding: CGFloat = 10.0
    
    // 改进的键盘状态跟踪
    private var activeKeys: Set<UInt16> = []
    private var moveTimer: Timer?
    
    // 储存原始窗口高度，用于说话结束后恢复
    private var originalWindowHeight: CGFloat = 0
    
    public var fluffel: Fluffel {
        return (window?.contentView as? SKView)?.scene?.childNode(withName: "fluffel") as! Fluffel
    }
    
    convenience init() {
        // 初始创建一个小窗口，刚好容纳 Fluffel
        let initialSize = CGSize(width: 70, height: 70) // 默认 Fluffel 尺寸 + 一些填充
        let contentRect = NSRect(x: 0, y: 0, width: initialSize.width, height: initialSize.height)
        
        // 使用自定义窗口类
        let window = TransparentWindow(
            contentRect: contentRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        // 初始化
        self.init(window: window)
        
        // 创建完全透明的 SpriteKit 视图
        let skView = SKView(frame: contentRect)
        skView.allowsTransparency = true
        
        // 创建并配置透明场景
        fluffelScene = FluffelScene(size: contentRect.size)
        fluffelScene?.backgroundColor = NSColor.clear
        skView.presentScene(fluffelScene)
        
        // 设置窗口内容视图
        window.contentView = skView
        
        // 显示窗口
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // 设置持续移动计时器
        setupMoveTimer()
        
        // 注册键盘事件监听 - 使用全局监听器可以捕获更多的按键
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(with: event)
            return event
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event in
            self?.handleKeyUp(with: event)
            return event
        }
        
        // 添加全局监听器以确保即使窗口失去焦点也能捕获按键
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(with: event)
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
            self?.handleKeyUp(with: event)
        }
        
        // 监听 Fluffel 的移动通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fluffelDidMove(_:)),
            name: .fluffelDidMove,
            object: nil
        )
        
        // 添加说话相关的通知监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fluffelWillSpeak(_:)),
            name: NSNotification.Name("fluffelWillSpeak"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fluffelDidStopSpeaking(_:)),
            name: NSNotification.Name("fluffelDidStopSpeaking"),
            object: nil
        )
    }
    
    deinit {
        // 确保计时器在控制器销毁时被停止
        moveTimer?.invalidate()
        moveTimer = nil
        
        // 移除通知监听
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func fluffelDidMove(_ notification: Notification) {
        updateWindowPositionAndSize()
    }
    
    private func updateWindowPositionAndSize() {
        guard let window = self.window,
              let fluffelScene = self.fluffelScene,
              let fluffelPosition = fluffelScene.getFluffelPosition(),
              let fluffelSize = fluffelScene.getFluffelSize() else {
            return
        }
        
        // 确保窗口和 Fluffel 一起移动，使 Fluffel 总是在窗口内
        let padding = fluffelPadding
        let windowSize = CGSize(
            width: fluffelSize.width + (padding * 2),
            height: fluffelSize.height + (padding * 2)
        )
        
        // 获取窗口和屏幕的当前坐标系
        let windowFrame = window.frame
        
        // 计算新窗口的原点，使 Fluffel 保持在窗口中心
        let sceneOriginInWindow = CGPoint(
            x: fluffelPosition.x - (windowSize.width / 2),
            y: fluffelPosition.y - (windowSize.height / 2)
        )
        
        // 将场景中的坐标转换为窗口坐标
        guard let contentView = window.contentView as? SKView else { return }
        
        // 计算新窗口的坐标
        let newWindowOrigin = CGPoint(
            x: windowFrame.origin.x + fluffelPosition.x - (windowSize.width / 2),
            y: windowFrame.origin.y + fluffelPosition.y - (windowSize.height / 2)
        )
        
        // 更新窗口的大小和位置
        let newWindowFrame = CGRect(
            x: newWindowOrigin.x,
            y: newWindowOrigin.y,
            width: windowSize.width,
            height: windowSize.height
        )
        
        // 设置新窗口大小和位置
        window.setFrame(newWindowFrame, display: true)
        
        // 重置 Fluffel 在场景中的位置为中心
        if let fluffel = fluffelScene.fluffel {
            fluffel.position = CGPoint(
                x: windowSize.width / 2,
                y: windowSize.height / 2
            )
            
            // 更新场景大小，使其与窗口保持同步
            fluffelScene.size = windowSize
        }
    }
    
    private func setupMoveTimer() {
        // 创建一个高频率的计时器来处理移动
        // 这样即使某些按键事件被错过，移动也能保持流畅
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.processActiveKeys()
        }
        moveTimer?.tolerance = 0.002 // 添加一些容差以优化性能
    }
    
    private func processActiveKeys() {
        // 处理所有当前按下的键
        for keyCode in activeKeys {
            if let direction = directionForKeyCode(keyCode) {
                fluffelScene?.moveFluffel(direction: direction)
            }
        }
    }
    
    func handleKeyDown(with event: NSEvent) {
        // 简单地将按下的键添加到活动键集合
        activeKeys.insert(event.keyCode)
    }
    
    func handleKeyUp(with event: NSEvent) {
        // 从活动键集合中移除释放的键
        activeKeys.remove(event.keyCode)
    }
    
    private func directionForKeyCode(_ keyCode: UInt16) -> Direction? {
        switch keyCode {
        case 123: // 左箭头
            return .left
        case 124: // 右箭头
            return .right
        case 125: // 下箭头
            return .down
        case 126: // 上箭头
            return .up
        default:
            return nil
        }
    }
    
    @objc private func fluffelWillSpeak(_ notification: Notification) {
        guard let window = self.window,
              let userInfo = notification.userInfo,
              let bubbleHeight = userInfo["bubbleHeight"] as? CGFloat else {
            return
        }
        
        // 保存当前窗口高度
        originalWindowHeight = window.frame.height
        
        // 计算新的窗口高度，确保有足够空间显示气泡
        let newWindowHeight = originalWindowHeight + bubbleHeight
        
        // 更新窗口高度，保持窗口的x坐标和宽度不变
        var newFrame = window.frame
        newFrame.origin.y -= bubbleHeight // 向下扩展窗口，这样Fluffel的位置保持不变
        newFrame.size.height = newWindowHeight
        
        // 使用动画平滑过渡到新的窗口大小
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window.animator().setFrame(newFrame, display: true)
        }, completionHandler: nil)
        
        // 更新场景大小
        if let fluffelScene = self.fluffelScene {
            fluffelScene.size = CGSize(width: newFrame.width, height: newFrame.height)
        }
    }
    
    @objc private func fluffelDidStopSpeaking(_ notification: Notification) {
        guard let window = self.window,
              originalWindowHeight > 0 else {
            return
        }
        
        // 恢复原始窗口高度
        var newFrame = window.frame
        let currentHeight = newFrame.height
        newFrame.origin.y += (currentHeight - originalWindowHeight) // 向上收缩窗口
        newFrame.size.height = originalWindowHeight
        
        // 使用动画平滑过渡回原始大小
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window.animator().setFrame(newFrame, display: true)
        }, completionHandler: nil)
        
        // 更新场景大小
        if let fluffelScene = self.fluffelScene {
            fluffelScene.size = CGSize(width: newFrame.width, height: newFrame.height)
        }
        
        // 重置原始高度
        originalWindowHeight = 0
    }
    
    func repositionWindow(to point: CGPoint, for spritePosition: CGPoint) {
        guard let window = window,
              let scene = fluffelScene,
              let view = window.contentView as? SKView else { return }
        
        // 计算正确的窗口位置以使 Fluffel 位于鼠标位置
        // 将精灵位置从场景坐标系转换为窗口坐标系
        let viewPosition = view.convert(spritePosition, from: scene)
        
        // 计算新的窗口位置
        let newWindowX = point.x - viewPosition.x
        let newWindowY = point.y - viewPosition.y
        
        // 设置窗口的新位置
        window.setFrameOrigin(NSPoint(x: newWindowX, y: newWindowY))
        
        print("窗口已重定位到: \(newWindowX), \(newWindowY)")
    }
} 