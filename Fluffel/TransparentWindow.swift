import Cocoa

class TransparentWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: .borderless, backing: backingStoreType, defer: flag)
        
        // 绝对透明设置
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.level = .floating
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        
        // 添加 - 允许通过背景移动窗口
        self.isMovableByWindowBackground = true
    }
    
    // 添加 - 覆盖 mouseDown 方法以实现拖动
    override func mouseDown(with event: NSEvent) {
        self.performDrag(with: event)
    }
} 