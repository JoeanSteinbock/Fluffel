import Cocoa
import SpriteKit  // 用于类型识别

class TransparentWindow: NSWindow {
    // 是否显示调试边框
    private var showDebugBorder: Bool = false
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        // 设置窗口特性
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating // 使窗口始终保持在最前面
        ignoresMouseEvents = false
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary] // 允许在所有工作区显示
        
        // 允许窗口在全屏模式下工作
        collectionBehavior.insert(.fullScreenAuxiliary)
        
        // 设置窗口可以接收键盘事件，使其可以成为主窗口
        acceptsMouseMovedEvents = true
        
        // 读取调试边框设置
        checkDebugSettings()
        
        // 应用边框设置
        applyBorderSettings()
    }
    
    // 检查是否应该显示调试边框
    private func checkDebugSettings() {
        // 从用户默认设置中读取，如果不存在则默认为false
        if let showBorder = UserDefaults.standard.object(forKey: "FluffelShowDebugBorder") as? Bool {
            showDebugBorder = showBorder
        } else {
            // 临时设置为true，方便调试
            showDebugBorder = true
        }
    }
    
    // 应用边框设置
    private func applyBorderSettings() {
        if showDebugBorder {
            // 添加边框，便于调试
            contentView?.wantsLayer = true
            contentView?.layer?.borderWidth = 1.0
            contentView?.layer?.borderColor = NSColor.red.cgColor
        } else {
            // 不显示边框
            contentView?.layer?.borderWidth = 0.0
        }
    }
    
    // 切换边框显示状态
    func toggleDebugBorder() {
        showDebugBorder = !showDebugBorder
        applyBorderSettings()
        UserDefaults.standard.set(showDebugBorder, forKey: "FluffelShowDebugBorder")
    }
    
    // 覆盖此方法以允许通过点击背景来移动窗口，并增加安全性
    override func mouseDown(with event: NSEvent) {
        // 直接处理鼠标点击，而不是在异步闭包中
        if event.clickCount == 1 {
            performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }
    
    // 覆盖canBecomeKey以允许窗口接收键盘事件
    override var canBecomeKey: Bool {
        return true
    }
    
    // 覆盖canBecomeMain以允许窗口成为主窗口
    override var canBecomeMain: Bool {
        return true
    }
    
    // 辅助方法，用于安全地调用super.sendEvent
    private func superSendEvent(_ event: NSEvent) {
        super.sendEvent(event)
    }
    
    // 改进点击穿透逻辑，处理更大窗口下的事件
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown || 
           event.type == .rightMouseDown || 
           event.type == .otherMouseDown {
            // 获取点击位置
            let location = event.locationInWindow
            
            // 添加强健的空值检查和类型检查
            guard let contentView = self.contentView else {
                // 如果没有内容视图，就不处理事件（穿透）
                return
            }
            
            // 确保视图是 SKView
            guard let skView = contentView as? SKView else {
                // 如果不是 SKView，执行默认行为
                superSendEvent(event)
                return
            }
            
            // 确保场景存在并且是正确类型
            guard let scene = skView.scene as? FluffelScene else {
                // 如果场景不存在或类型不对，执行默认行为
                superSendEvent(event)
                return
            }
            
            // 确保 Fluffel 存在
            guard let fluffel = scene.fluffel else {
                // 如果 Fluffel 不存在，执行默认行为
                superSendEvent(event)
                return
            }
            
            // 安全地计算场景点位置
            let scenePoint = skView.convert(location, to: scene)
            
            // 使用更安全的方式获取 Fluffel 节点的边界
            let fluffelNode = fluffel.calculateAccumulatedFrame()
            
            // 扩大可点击区域 - 只有 Fluffel 周围一小部分区域可点击，其余区域点击穿透
            let paddedFrame = fluffelNode.insetBy(dx: -15, dy: -15)
            
            if paddedFrame.contains(scenePoint) {
                // 使用 DispatchQueue.main.async 来避免在事件处理期间的可能的不一致状态
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // 点击在 Fluffel 上，处理事件
                    superSendEvent(event)
                    
                    // 如果是鼠标按下，启动拖动，但确保在主线程中执行
                    if event.type == .leftMouseDown {
                        self.performDrag(with: event)
                    }
                }
                return
            } else {
                // 点击在 Fluffel 区域外，穿透点击
                return
            }
        } else if event.type == .leftMouseDragged ||
                  event.type == .rightMouseDragged ||
                  event.type == .otherMouseDragged {
            // 拖动事件始终在主线程安全处理
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                superSendEvent(event)
            }
        } else {
            // 其他类型的事件正常处理
            superSendEvent(event)
        }
    }
    
    // 添加此方法以覆盖窗口位置限制，确保可以拖到任何位置
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect  // 允许窗口移动到任何位置，不受限制
    }
} 