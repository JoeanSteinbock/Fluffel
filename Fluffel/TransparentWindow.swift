import Cocoa
import SpriteKit  // 用于类型识别

class TransparentWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: .borderless, backing: backingStoreType, defer: flag)
        
        // 基本透明设置
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        
        // 窗口位置和行为设置
        self.level = .floating
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        
        // 重要：确保窗口可以移动到任何位置，包括屏幕顶部和菜单栏
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // 允许鼠标事件，我们将在 sendEvent 中过滤
        self.ignoresMouseEvents = false
    }
    
    // 改进点击穿透逻辑，处理更大窗口下的事件
    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown || 
           event.type == .rightMouseDown || 
           event.type == .otherMouseDown {
            // 获取点击位置
            let location = event.locationInWindow
            
            // 检查是否点击在 Fluffel 上
            if let contentView = self.contentView,
               let skView = contentView as? SKView,
               let scene = skView.scene as? FluffelScene,
               let fluffel = scene.fluffel {
                
                // 将窗口坐标转换为场景坐标
                let scenePoint = skView.convert(location, to: scene)
                
                // 检查点击是否在 Fluffel 节点内
                let fluffelNode = fluffel.calculateAccumulatedFrame()
                
                // 扩大可点击区域 - 只有 Fluffel 周围一小部分区域可点击，其余区域点击穿透
                let paddedFrame = fluffelNode.insetBy(dx: -15, dy: -15)
                
                if paddedFrame.contains(scenePoint) {
                    // 点击在 Fluffel 上，处理事件
                    super.sendEvent(event)
                    
                    // 如果是鼠标按下，启动拖动
                    if event.type == .leftMouseDown {
                        self.performDrag(with: event)
                    }
                    return
                }
            }
            // 否则点击穿透，不处理事件
        } else {
            // 其他类型的事件正常处理
            super.sendEvent(event)
        }
    }
    
    // 添加此方法以覆盖窗口位置限制，确保可以拖到任何位置
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect  // 允许窗口移动到任何位置，不受限制
    }
} 