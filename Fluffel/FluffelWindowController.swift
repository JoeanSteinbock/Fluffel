import Cocoa
import SpriteKit

class FluffelWindowController: NSWindowController {
    
    var fluffelScene: FluffelScene?
    
    convenience init() {
        // 创建一个完全透明的窗口，使用自定义 TransparentWindow 类
        let contentRect = NSRect(x: 0, y: 0, width: 200, height: 200)
        
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
        
        // 注册按键事件
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.keyDown(with: event)
            return event
        }
    }
    
    override func keyDown(with event: NSEvent) {
        // 处理方向键
        switch event.keyCode {
        case 123: // 左箭头
            fluffelScene?.moveFluffel(direction: .left)
        case 124: // 右箭头
            fluffelScene?.moveFluffel(direction: .right)
        case 125: // 下箭头
            fluffelScene?.moveFluffel(direction: .down)
        case 126: // 上箭头
            fluffelScene?.moveFluffel(direction: .up)
        default:
            break
        }
    }
} 