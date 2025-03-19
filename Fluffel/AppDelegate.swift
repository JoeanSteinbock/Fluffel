import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var fluffelWindowController: FluffelWindowController?
    var speakingDemo: FluffelSpeakingDemo?
    
    // 添加一个标志，防止动作重复触发
    private var isActionInProgress = false
    // 添加计时器，用于防止快速连续触发
    private var actionDebounceTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 关闭任何可能由 storyboard 创建的窗口
        for window in NSApplication.shared.windows {
            window.close()
        }
        
        // 创建我们的自定义窗口控制器
        fluffelWindowController = FluffelWindowController()
        
        // 隐藏 Dock 图标和菜单栏
        NSApp.setActivationPolicy(.accessory)
        
        // 初始化说话演示
        if let scene = fluffelWindowController?.fluffelScene,
           let fluffel = scene.fluffel {
            speakingDemo = FluffelSpeakingDemo(scene: scene, fluffel: fluffel)
        }
        
        // 添加通知监听器，处理说话通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFluffelWillSpeak(_:)),
            name: NSNotification.Name.fluffelWillSpeak,
            object: nil
        )
        
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
            // Cmd+R 重置 Fluffel 到中心
            if event.modifierFlags.contains(.command) && event.keyCode == 15 { // R 键
                if let scene = self?.fluffelWindowController?.fluffelScene {
                    scene.resetFluffelToCenter()
                }
            }
            return event
        }
        
        // 测试 TTS 功能
        // testTTS()
    }
    
    // 测试 TTS 功能
    private func testTTS() {
        // 检查是否已设置 API 密钥
        if !FluffelTTSService.shared.hasApiKey() {
            // 如果没有设置 API 密钥，显示提示信息而不是自动打开设置窗口
            makeFluffelSpeak("请先通过右键菜单设置API密钥")
            return
        }
        
        let testText = "Hello, I'm Fluffel, your fluffy desktop pet!"
        FluffelTTSService.shared.speak(testText) {
            print("TTS 测试完成!")
        }
    }
    
    // 创建一个辅助方法让 Fluffel 显示提示信息
    private func makeFluffelSpeak(_ text: String) {
        if let fluffel = fluffelWindowController?.fluffel {
            fluffel.speak(text: text, duration: 3.0)
        }
    }
    
    // 处理Fluffel说话事件，确保线程安全
    @objc func handleFluffelWillSpeak(_ notification: Notification) {
        // 为避免强引用循环和内存问题，先捕获一个弱引用的副本
        let windowControllerRef = fluffelWindowController
        
        // 转发通知给FluffelWindowController处理，但只在主线程上执行
        DispatchQueue.main.async { [weak self] in
            // 检查AppDelegate和FluffelWindowController是否仍然有效
            guard self != nil, let windowController = windowControllerRef else { return }
            
            // 在主线程中安全处理说话请求
            windowController.handleFluffelSpeech(notification)
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 首先停止所有计时器
        actionDebounceTimer?.invalidate()
        actionDebounceTimer = nil
        
        // 清除所有通知监听器
        NotificationCenter.default.removeObserver(self)
        
        // 停止任何正在播放的音频
        FluffelTTSService.shared.stopCurrentAudio()
        
        // 清除对象引用
        speakingDemo = nil
        fluffelWindowController = nil
    }
    
    // 测试 TTS 功能的菜单动作
    @objc func testTTSFromMenu(_ sender: Any) {
        executeAction { [weak self] in
            self?.testTTS()
        }
    }
    
    // 辅助方法：防止动作重复触发，并在主线程中安全执行
    private func executeAction(_ action: @escaping () -> Void) {
        // 确保在主线程上执行
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.executeAction(action)
            }
            return
        }
        
        // 如果已经有动作在执行，忽略此次调用
        guard !isActionInProgress else {
            print("动作已在执行中，忽略重复调用")
            return
        }
        
        // 标记动作开始执行
        isActionInProgress = true
        
        // 取消现有计时器
        actionDebounceTimer?.invalidate()
        
        // 执行动作
        action()
        
        // 设置计时器，延迟清除标志，防止快速连续触发
        actionDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            // 确保在主线程中重置状态
            DispatchQueue.main.async {
                self?.isActionInProgress = false
            }
        }
    }
    
    // 菜单动作方法 - 所有方法现在都使用弱引用
    @objc func speakGreeting(_ sender: Any) {
        executeAction { [weak self] in
            guard let speakingDemo = self?.speakingDemo else { return }
            speakingDemo.speakRandomGreeting()
        }
    }
    
    @objc func tellJoke(_ sender: Any) {
        executeAction { [weak self] in
            guard let speakingDemo = self?.speakingDemo else { return }
            speakingDemo.tellRandomJoke()
        }
    }
    
    @objc func shareFact(_ sender: Any) {
        executeAction { [weak self] in
            guard let speakingDemo = self?.speakingDemo else { return }
            speakingDemo.shareRandomFact()
        }
    }
    
    @objc func startConversation(_ sender: Any) {
        executeAction { [weak self] in
            guard let speakingDemo = self?.speakingDemo else { return }
            speakingDemo.performConversation()
        }
    }
    
    // 新增重置 Fluffel 到中心的方法
    @objc func resetFluffelToCenter(_ sender: Any) {
        executeAction { [weak self] in
            guard let scene = self?.fluffelWindowController?.fluffelScene else { return }
            scene.resetFluffelToCenter()
        }
    }
    
    // 显示 API 密钥设置窗口
    @objc func showApiKeySettings(_ sender: Any) {
        executeAction { [weak self] in
            self?.showApiKeyWindow()
        }
    }
    
    // 创建并显示 API 密钥设置窗口
    private func showApiKeyWindow() {
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Google Cloud API Key Settings"
        
        // 创建内容视图
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 200))
        
        // 创建标签
        let label = NSTextField(labelWithString: "Google Cloud API Key:")
        label.frame = NSRect(x: 20, y: 120, width: 460, height: 20)
        contentView.addSubview(label)
        
        // 创建说明标签
        let infoLabel = NSTextField(wrappingLabelWithString: "请输入您的 Google Cloud API Key。您可以在 Google Cloud Console 的 API 和服务 > 凭据页面获取或创建密钥。")
        infoLabel.frame = NSRect(x: 20, y: 150, width: 460, height: 40)
        contentView.addSubview(infoLabel)
        
        // 创建输入框
        let textField = NSTextField(frame: NSRect(x: 20, y: 90, width: 460, height: 24))
        textField.placeholderString = "输入您的 Google Cloud API Key"
        // 从 UserDefaults 加载现有密钥
        textField.stringValue = UserDefaults.standard.string(forKey: "GoogleCloudAPIKey") ?? ""
        contentView.addSubview(textField)
        
        // 创建保存按钮
        let saveButton = NSButton(title: "保存", target: nil, action: #selector(saveApiKey(_:)))
        saveButton.frame = NSRect(x: 380, y: 20, width: 100, height: 32)
        saveButton.bezelStyle = .rounded
        
        // 存储文本字段引用，以便在操作方法中使用
        objc_setAssociatedObject(saveButton, "textField", textField, .OBJC_ASSOCIATION_RETAIN)
        saveButton.target = self
        contentView.addSubview(saveButton)
        
        // 创建测试按钮
        let testButton = NSButton(title: "测试", target: nil, action: #selector(testApiKey(_:)))
        testButton.frame = NSRect(x: 270, y: 20, width: 100, height: 32)
        testButton.bezelStyle = .rounded
        
        // 存储文本字段引用，以便在操作方法中使用
        objc_setAssociatedObject(testButton, "textField", textField, .OBJC_ASSOCIATION_RETAIN)
        testButton.target = self
        contentView.addSubview(testButton)
        
        // 创建状态标签
        let statusLabel = NSTextField(labelWithString: "")
        statusLabel.frame = NSRect(x: 20, y: 60, width: 460, height: 20)
        statusLabel.textColor = .systemGray
        contentView.addSubview(statusLabel)
        
        // 存储状态标签引用，以便在操作方法中使用
        objc_setAssociatedObject(saveButton, "statusLabel", statusLabel, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(testButton, "statusLabel", statusLabel, .OBJC_ASSOCIATION_RETAIN)
        
        // 设置内容视图
        window.contentView = contentView
        
        // 显示窗口
        window.makeKeyAndOrderFront(nil)
    }
    
    // 保存 API 密钥
    @objc func saveApiKey(_ sender: NSButton) {
        guard let textField = objc_getAssociatedObject(sender, "textField") as? NSTextField,
              let statusLabel = objc_getAssociatedObject(sender, "statusLabel") as? NSTextField else {
            return
        }
        
        let apiKey = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if apiKey.isEmpty {
            statusLabel.stringValue = "错误: API 密钥不能为空"
            statusLabel.textColor = .systemRed
            return
        }
        
        // 保存到 TTS 服务
        FluffelTTSService.shared.setApiKey(apiKey)
        
        statusLabel.stringValue = "API 密钥已保存！"
        statusLabel.textColor = .systemGreen
    }
    
    // 测试 API 密钥
    @objc func testApiKey(_ sender: NSButton) {
        guard let textField = objc_getAssociatedObject(sender, "textField") as? NSTextField,
              let statusLabel = objc_getAssociatedObject(sender, "statusLabel") as? NSTextField else {
            return
        }
        
        let apiKey = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if apiKey.isEmpty {
            statusLabel.stringValue = "错误: 请先输入 API 密钥"
            statusLabel.textColor = .systemRed
            return
        }
        
        // 临时设置 API 密钥进行测试
        FluffelTTSService.shared.setApiKey(apiKey)
        
        // 更新状态
        statusLabel.stringValue = "正在测试 API 密钥..."
        statusLabel.textColor = .systemBlue
        
        // 测试 TTS
        let testText = "Hello, I'm Fluffel!"
        FluffelTTSService.shared.speak(testText) {
            DispatchQueue.main.async {
                statusLabel.stringValue = "测试成功！API 密钥有效。"
                statusLabel.textColor = .systemGreen
            }
        }
    }
    
    // 添加一个菜单项以退出应用
    @IBAction func quitApp(_ sender: Any) {
        // 确保在退出前清理资源
        actionDebounceTimer?.invalidate()
        actionDebounceTimer = nil
        
        // 移除通知监听
        NotificationCenter.default.removeObserver(self)
        
        // 终止应用
        NSApp.terminate(self)
    }
} 