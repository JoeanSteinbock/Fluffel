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
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 清理代码
    }
    
    // 添加一个菜单项以退出应用
    @IBAction func quitApp(_ sender: Any) {
        NSApp.terminate(self)
    }
} 