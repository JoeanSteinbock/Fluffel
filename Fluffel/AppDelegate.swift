import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var fluffelWindowController: FluffelWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 关闭任何可能由 storyboard 创建的窗口
        for window in NSApplication.shared.windows {
            window.close()
        }
        
        // 创建我们的自定义窗口控制器
        fluffelWindowController = FluffelWindowController()
        
        // 隐藏 Dock 图标和菜单栏
        NSApp.setActivationPolicy(.accessory)
        
        // 添加退出快捷键 (Cmd+Q)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.keyCode == 12 { // Q 键
                NSApp.terminate(nil)
            }
            return event
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 清理代码
    }
    
    // 添加一个菜单项以退出应用
    @IBAction func quitApp(_ sender: Any) {
        NSApp.terminate(self)
    }
} 