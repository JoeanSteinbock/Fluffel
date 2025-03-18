import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var fluffelWindowController: FluffelWindowController?
    var speakingDemo: FluffelSpeakingDemo?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 关闭任何可能由 storyboard 创建的窗口
        for window in NSApplication.shared.windows {
            window.close()
        }
        
        // 创建我们的自定义窗口控制器
        fluffelWindowController = FluffelWindowController()
        
        // 隐藏 Dock 图标和菜单栏
        NSApp.setActivationPolicy(.accessory)
        
        // 设置菜单栏
        setupMenu()
        
        // 初始化说话演示
        if let scene = fluffelWindowController?.fluffelScene,
           let fluffel = scene.fluffel {
            speakingDemo = FluffelSpeakingDemo(scene: scene, fluffel: fluffel)
        }
        
        // 添加快捷键监听
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Cmd+Q 退出
            if event.modifierFlags.contains(.command) && event.keyCode == 12 { // Q 键
                NSApp.terminate(nil)
            }
            // Cmd+S 保存图标
            if event.modifierFlags.contains(.command) && event.keyCode == 1 { // S 键
                if let fluffel = self?.fluffelWindowController?.fluffelScene?.fluffel {
                    fluffel.saveAppearanceAsIcon()
                }
            }
            return event
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 清理代码
    }
    
    // 设置应用菜单
    private func setupMenu() {
        let mainMenu = NSMenu(title: "MainMenu")
        
        // 应用菜单
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        
        appMenu.addItem(withTitle: "关于 Fluffel", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "退出", action: #selector(quitApp(_:)), keyEquivalent: "q")
        
        // Fluffel 菜单
        let fluffelMenuItem = NSMenuItem(title: "Fluffel", action: nil, keyEquivalent: "")
        mainMenu.addItem(fluffelMenuItem)
        
        let fluffelMenu = NSMenu(title: "Fluffel")
        fluffelMenuItem.submenu = fluffelMenu
        
        fluffelMenu.addItem(withTitle: "问候", action: #selector(speakGreeting), keyEquivalent: "g")
        fluffelMenu.addItem(withTitle: "讲笑话", action: #selector(tellJoke), keyEquivalent: "j")
        fluffelMenu.addItem(withTitle: "分享事实", action: #selector(shareFact), keyEquivalent: "f")
        fluffelMenu.addItem(withTitle: "进行对话", action: #selector(startConversation), keyEquivalent: "c")
        
        NSApp.mainMenu = mainMenu
    }
    
    // 菜单动作方法
    @objc func speakGreeting(_ sender: Any) {
        speakingDemo?.speakRandomGreeting()
    }
    
    @objc func tellJoke(_ sender: Any) {
        speakingDemo?.tellRandomJoke()
    }
    
    @objc func shareFact(_ sender: Any) {
        speakingDemo?.shareRandomFact()
    }
    
    @objc func startConversation(_ sender: Any) {
        speakingDemo?.performConversation()
    }
    
    // 添加一个菜单项以退出应用
    @IBAction func quitApp(_ sender: Any) {
        NSApp.terminate(self)
    }
} 