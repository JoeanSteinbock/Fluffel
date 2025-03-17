import Cocoa
import SpriteKit

class FluffelWindowController: NSWindowController {
    
    var fluffelScene: FluffelScene?
    private var keyIsDown = false
    private var currentDirection: Direction?
    private var moveTimer: Timer?
    
    convenience init() {
        // 减小窗口尺寸，使之更贴近 Fluffel 实际大小（50px 加一点边距）
        let contentRect = NSRect(x: 0, y: 0, width: 60, height: 60)
        
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
        
        // 绕过任何可能的 storyboard 干扰
        window.contentView = skView
        
        // 显示窗口
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // 注册键盘事件监听
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(with: event)
            return event
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event in
            self?.handleKeyUp(with: event)
            return event
        }
    }
    
    func handleKeyDown(with event: NSEvent) {
        let direction = directionForKeyCode(event.keyCode)
        
        if let direction = direction {
            // 如果是新的按键或者不同方向的按键
            if !keyIsDown || currentDirection != direction {
                // 停止旧的移动计时器
                moveTimer?.invalidate()
                
                // 设置当前状态
                keyIsDown = true
                currentDirection = direction
                
                // 立即移动一次
                fluffelScene?.moveFluffel(direction: direction)
                
                // 开始持续移动
                moveTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                    if let direction = self?.currentDirection {
                        self?.fluffelScene?.moveFluffel(direction: direction)
                    }
                }
            }
        }
    }
    
    func handleKeyUp(with event: NSEvent) {
        let direction = directionForKeyCode(event.keyCode)
        
        if let direction = direction, direction == currentDirection {
            keyIsDown = false
            currentDirection = nil
            moveTimer?.invalidate()
            moveTimer = nil
        }
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
} 