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
    private var originalWindowWidth: CGFloat = 0
    private var isSpeakingInProgress: Bool = false
    
    // 当前活跃的气泡窗口
    private var activeBubbleWindow: BubbleWindow?
    
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
        
        // 启用窗口调试边框（如果支持）
        if let transparentWindow = window as? TransparentWindow {
            // 确保调试边框始终启用，方便开发阶段观察
            UserDefaults.standard.set(true, forKey: "FluffelShowDebugBorder")
            transparentWindow.toggleDebugBorder()
        }
        
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
        window.makeKeyAndOrderFront(Optional.none)
        
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
        
        // 添加气泡窗口相关的通知监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFluffelSpeech(_:)),
            name: NSNotification.Name("fluffelWillSpeak"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBubbleDismissed(_:)),
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
        // 防止在说话状态中调整窗口大小，这会导致气泡错位
        if isSpeakingInProgress {
            return
        }
        
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
    
    private func directionForKeyCode(_ keyCode: UInt16) -> MovementDirection? {
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
    
    // 删除所有旧的对话气泡处理方法，已由新的机制替代
    
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
        
        // 防止计算出的位置无效
        guard !newWindowX.isNaN && !newWindowY.isNaN && 
              newWindowX.isFinite && newWindowY.isFinite else {
            print("警告：计算的窗口位置无效：\(newWindowX), \(newWindowY)")
            return
        }
        
        // 在主线程中安全地设置窗口的新位置
        DispatchQueue.main.async { [weak self] in
            guard let self = self, window.isVisible else { return }
            
            // 设置窗口的新位置
            window.setFrameOrigin(NSPoint(x: newWindowX, y: newWindowY))
            
            // 确保气泡窗口跟随移动（如果存在）
            if let bubbleWindow = self.activeBubbleWindow, bubbleWindow.isVisible {
                bubbleWindow.positionAboveFluffelWindow()
            }
            
            print("窗口已重定位到: \(newWindowX), \(newWindowY)")
        }
    }
    
    // MARK: - 初始化
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.title = "Fluffel"
        
        // 模拟窗口边框（调试用）
        if let transparentWindow = window as? TransparentWindow {
            // 总是显示调试边框（开发阶段）
            UserDefaults.standard.set(true, forKey: "ShowDebugBorder")
            transparentWindow.toggleDebugBorder()
        }
        
        // 设置 Fluffel 视图 - 暂不实现详细内容
        // setupFluffelView()
        
        // 设置键盘事件监听
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
        
        // 注册通知监听器
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(fluffelMoved(_:)), 
            name: NSNotification.Name("FluffelMoved"), 
            object: nil
        )
        
        // 添加气泡窗口相关通知监听器
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFluffelSpeech(_:)),
            name: NSNotification.Name("fluffelWillSpeak"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBubbleDismissed(_:)),
            name: NSNotification.Name("fluffelBubbleDismissed"),
            object: nil
        )
    }
    
    // MARK: - 气泡窗口处理
    
    // 处理 Fluffel 说话请求
    @objc func handleFluffelSpeech(_ notification: Notification) {
        // 如果有活跃的气泡窗口，先关闭它
        activeBubbleWindow?.dismiss()
        activeBubbleWindow = Optional.none
        
        // 获取说话文本和其他参数
        guard let userInfo = notification.userInfo,
              let text = userInfo["text"] as? String else {
            return
        }
        
        let fontSize = userInfo["fontSize"] as? CGFloat ?? 12
        let duration = userInfo["duration"] as? TimeInterval ?? 3.0
        
        // 创建新的气泡窗口
        let bubbleWindow = BubbleWindow(text: text, fontSize: fontSize, duration: duration)
        
        // 设置关联的 Fluffel 窗口
        bubbleWindow.fluffelWindow = self.window
        
        // 将气泡窗口定位到 Fluffel 窗口上方
        bubbleWindow.positionAboveFluffelWindow()
        
        // 显示气泡窗口
        bubbleWindow.makeKeyAndOrderFront(Optional.none)
        
        // 保存引用
        activeBubbleWindow = bubbleWindow
        
        // 添加观察者，当 Fluffel 窗口移动时，气泡窗口也跟着移动
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateBubblePosition(_:)),
            name: NSWindow.didMoveNotification,
            object: self.window
        )
    }
    
    // 更新气泡位置以跟随 Fluffel 窗口
    @objc func updateBubblePosition(_ notification: Notification) {
        // 添加强引用检查，确保气泡窗口仍然有效
        if let bubbleWindow = activeBubbleWindow, bubbleWindow.isVisible {
            bubbleWindow.positionAboveFluffelWindow()
        } else {
            // 如果气泡窗口已经无效或不可见，清除引用
            activeBubbleWindow = Optional.none
            
            // 移除窗口移动观察者
            NotificationCenter.default.removeObserver(
                self,
                name: NSWindow.didMoveNotification,
                object: self.window
            )
        }
    }
    
    // 处理气泡消失通知
    @objc func handleBubbleDismissed(_ notification: Notification) {
        // 清除活跃的气泡窗口引用
        activeBubbleWindow = Optional.none
        
        // 移除窗口移动观察者
        NotificationCenter.default.removeObserver(
            self,
            name: NSWindow.didMoveNotification,
            object: self.window
        )
    }
    
    // 处理 Fluffel 移动通知
    @objc func fluffelMoved(_ notification: Notification) {
        // 当 Fluffel 移动时，如果有活跃的气泡窗口，更新其位置
        if let bubbleWindow = activeBubbleWindow, bubbleWindow.isVisible {
            bubbleWindow.positionAboveFluffelWindow()
        } else {
            // 气泡窗口无效，清除引用
            activeBubbleWindow = Optional.none
        }
    }
    
    // 处理键盘事件
    private func handleKeyEvent(_ event: NSEvent) {
        // 键盘事件处理逻辑
        print("收到键盘事件: \(event.keyCode)")
        
        // 可以在这里添加键盘控制逻辑
    }
    
    // 设置 Fluffel 视图
    private func setupFluffelView() {
        // Fluffel 视图设置逻辑
        print("设置 Fluffel 视图")
        
        // 可以在这里添加视图设置逻辑
    }
} 