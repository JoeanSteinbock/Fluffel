import Cocoa
import AVFoundation
// Import our playlist manager
import Foundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var fluffelWindowController: FluffelWindowController?
    var speakingDemo: FluffelSpeakingDemo?
    
    // 添加一个标志，防止动作重复触发
    private var isActionInProgress = false
    // 添加计时器，用于防止快速连续触发
    private var actionDebounceTimer: Timer?
    
    // 存储 API 设置窗口的强引用
    private var apiKeyWindow: NSWindow?
    private var apiKeyTextField: NSTextField?
    private var apiKeyStatusLabel: NSTextField?
    
    // 标记是否已显示网络错误对话框，避免重复显示
    private var isShowingNetworkErrorAlert = false
    
    // 存储播放列表窗口的引用
    private var playlistWindows: [FluffelPixabayPlaylists.PlaylistCategory: FluffelPlaylistWindow] = [:]

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
        
        // 添加TTS网络错误监听器
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTTSNetworkError(_:)),
            name: NSNotification.Name("FluffelTTSNetworkError"),
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
            makeFluffelSpeak("Please set the API key first through the right-click menu")
            return
        }
        
        let testText = "Hello, I'm Fluffel, your fluffy desktop pet!"
        FluffelTTSService.shared.speak(testText) {
            print("TTS test completed!")
        }
    }
    
    // 创建一个辅助方法让 Fluffel 显示提示信息
    private func makeFluffelSpeak(_ text: String) {
        if let fluffel = fluffelWindowController?.fluffel {
            fluffel.speak(text: text, duration: 3.0)
        } else {
            // 如果fluffel为nil，只记录日志
            print("无法显示消息：\(text)，fluffel对象为nil")
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
    
    // 处理TTS网络错误通知
    @objc func handleTTSNetworkError(_ notification: Notification) {
        let message = notification.userInfo?["message"] as? String ?? "Network access denied, please check application permissions settings"
        
        DispatchQueue.main.async { [weak self] in
            // 避免显示多个错误对话框
            guard let self = self, !self.isShowingNetworkErrorAlert else { return }
            
            self.isShowingNetworkErrorAlert = true
            
            // 显示一个弹出对话框，提醒用户网络访问问题
            let alert = NSAlert()
            alert.messageText = "Network access error"
            alert.informativeText = message + "\n\nPlease ensure that in the system preferences > security & privacy > network, Fluffel is allowed to access the network."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            
            // 可选: 添加一个打开系统设置的按钮
            let settingsButton = alert.addButton(withTitle: "Open network settings")
            settingsButton.keyEquivalent = "s"
            
            let response = alert.runModal()
            
            // 重置标志
            self.isShowingNetworkErrorAlert = false
            
            if response == NSApplication.ModalResponse.alertSecondButtonReturn {
                // 用户点击了"打开网络设置"
                self.openNetworkPreferences()
            }
            
            // 同时也让Fluffel显示一条消息
            self.makeFluffelSpeak("Unable to connect to the network, please check the application permission settings")
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
        
        // 保存窗口的强引用
        apiKeyWindow = window
        
        // 创建内容视图
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 200))
        
        // 创建标签
        let label = NSTextField(labelWithString: "Google Cloud API Key:")
        label.frame = NSRect(x: 20, y: 120, width: 460, height: 20)
        contentView.addSubview(label)
        
        // 创建说明标签
        let infoLabel = NSTextField(wrappingLabelWithString: "Enter your Google Cloud API Key. You can get or create a key in the API & Services > Credentials page of the Google Cloud Console.")
        infoLabel.frame = NSRect(x: 20, y: 150, width: 460, height: 40)
        contentView.addSubview(infoLabel)
        
        // 创建输入框
        let textField = NSTextField(frame: NSRect(x: 20, y: 90, width: 460, height: 24))
        textField.placeholderString = "Enter your Google Cloud API Key"
        // 从 UserDefaults 加载现有密钥
        textField.stringValue = UserDefaults.standard.string(forKey: "GoogleCloudAPIKey") ?? ""
        contentView.addSubview(textField)
        apiKeyTextField = textField
        
        // 创建状态标签
        let statusLabel = NSTextField(labelWithString: "")
        statusLabel.frame = NSRect(x: 20, y: 60, width: 460, height: 20)
        statusLabel.textColor = .systemGray
        contentView.addSubview(statusLabel)
        apiKeyStatusLabel = statusLabel
        
        // 创建保存按钮
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveApiKey(_:)))
        saveButton.frame = NSRect(x: 380, y: 20, width: 100, height: 32)
        saveButton.bezelStyle = .rounded
        contentView.addSubview(saveButton)
        
        // 创建测试按钮
        let testButton = NSButton(title: "Test", target: self, action: #selector(testApiKey(_:)))
        testButton.frame = NSRect(x: 270, y: 20, width: 100, height: 32)
        testButton.bezelStyle = .rounded
        contentView.addSubview(testButton)
        
        // 设置内容视图
        window.contentView = contentView
        
        // 显示窗口
        window.makeKeyAndOrderFront(nil)
    }
    
    // 保存 API 密钥
    @objc func saveApiKey(_ sender: NSButton) {
        print("保存 API 密钥按钮被点击")
        
        // 使用属性而不是关联对象
        guard let textField = apiKeyTextField,
              let statusLabel = apiKeyStatusLabel else {
            print("错误: 无法获取文本字段或状态标签")
            return
        }
        
        let apiKey = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        print("获取到的 API 密钥: \(apiKey)")
        
        if apiKey.isEmpty {
            statusLabel.stringValue = "Error: API key cannot be empty"
            statusLabel.textColor = .systemRed
            return
        }
        
        // 保存到 TTS 服务
        FluffelTTSService.shared.setApiKey(apiKey)
        
        // 更新状态标签
        statusLabel.stringValue = "API key saved successfully"
        statusLabel.textColor = .systemGreen
        
        // 强制更新 UI
        statusLabel.needsDisplay = true
        
        print("API 密钥已成功保存到 UserDefaults")
        
        // 获取窗口
        if let window = apiKeyWindow {
            // 视觉反馈 - 按钮变绿
            let originalColor = NSColor.controlColor
            if #available(macOS 10.14, *) {
                sender.contentTintColor = .systemGreen
            }
            
            // 短暂延迟后关闭窗口
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                // 还原按钮颜色
                if #available(macOS 10.14, *) {
                    sender.contentTintColor = originalColor
                }
                
                // 关闭窗口
                window.close()
                
                // 清除引用
                self?.apiKeyWindow = nil
                self?.apiKeyTextField = nil
                self?.apiKeyStatusLabel = nil
                
                // 显示成功消息
                if let fluffel = self?.fluffelWindowController?.fluffel {
                    fluffel.speak(text: "API key saved successfully", duration: 3.0)
                } else {
                    // 如果fluffel为nil，只记录日志
                    print("无法显示API密钥保存成功消息，fluffel对象为nil")
                }
            }
        } else {
            print("警告: 窗口引用丢失")
        }
    }
    
    // 测试 API 密钥
    @objc func testApiKey(_ sender: NSButton) {
        print("测试 API 密钥按钮被点击")
        
        // 使用属性而不是关联对象
        guard let textField = apiKeyTextField,
              let statusLabel = apiKeyStatusLabel else {
            print("错误: 无法获取文本字段或状态标签")
            return
        }
        
        let apiKey = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        print("获取到的 API 密钥: \(apiKey)")
        
        if apiKey.isEmpty {
            statusLabel.stringValue = "Error: Please enter an API key"
            statusLabel.textColor = .systemRed
            return
        }
        
        // 更新状态
        statusLabel.stringValue = "Testing API key..."
        statusLabel.textColor = .systemBlue
        statusLabel.needsDisplay = true
        
        // 禁用按钮，防止重复点击
        sender.isEnabled = false
        
        // 临时设置 API 密钥进行测试
        FluffelTTSService.shared.setApiKey(apiKey)
        
        // 测试 TTS
        let testText = "Hello, I'm Fluffel!"
        FluffelTTSService.shared.speak(testText) { [weak self, weak sender] in
            DispatchQueue.main.async {
                // 重新启用按钮
                sender?.isEnabled = true
                
                // 检查状态标签是否仍然有效
                if let statusLabel = self?.apiKeyStatusLabel {
                    statusLabel.stringValue = "Test successful! API key is valid."
                    statusLabel.textColor = .systemGreen
                }
                
                // 视觉反馈
                if #available(macOS 10.14, *) {
                    sender?.contentTintColor = .systemGreen
                    
                    // 1秒后恢复颜色
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        sender?.contentTintColor = nil
                    }
                }
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
    
    // 新增方法：打开网络设置
    @objc func openNetworkSettings(_ sender: Any) {
        executeAction { [weak self] in
            self?.openNetworkPreferences()
        }
    }
    
    // 打开网络偏好设置
    private func openNetworkPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        } else {
            // 备用方法，打开一般的系统偏好设置
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:")!)
        }
    }
    
    // 新增设置卡通角色声音的方法
    @objc func setVoiceSqueaky(_ sender: Any) {
        executeAction { [weak self] in
            self?.setFluffelVoice(.squeaky)
        }
    }
    
    @objc func setVoiceDeep(_ sender: Any) {
        executeAction { [weak self] in
            self?.setFluffelVoice(.deep)
        }
    }
    
    @objc func setVoiceChipmunk(_ sender: Any) {
        executeAction { [weak self] in
            self?.setFluffelVoice(.chipmunk)
        }
    }
    
    @objc func setVoiceRobot(_ sender: Any) {
        executeAction { [weak self] in
            self?.setFluffelVoice(.robot)
        }
    }
    
    @objc func setVoiceCute(_ sender: Any) {
        executeAction { [weak self] in
            self?.setFluffelVoice(.cute)
        }
    }
    
    // 音乐相关方法
    @objc func startListeningToMusic(_ sender: Any) {
        // 如果不是菜单项，直接播放默认音乐
        playDefaultMusic()
    }
    
    /// 显示播放列表窗口
    @objc internal func showPlaylistWindow(_ sender: NSMenuItem) {
        guard let category = sender.representedObject as? FluffelPixabayPlaylists.PlaylistCategory else {
            return
        }
        
        // 如果窗口已存在，显示并前置
        if let window = playlistWindows[category] {
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        // 创建新窗口
        let window = FluffelPlaylistWindow(category: category, delegate: self)
        playlistWindows[category] = window
        window.makeKeyAndOrderFront(nil)
    }
    
    /// 播放整个播放列表
    func playPlaylist(_ playlist: Playlist) {
        guard let firstTrack = playlist.tracks.first else { return }
        playTrack(firstTrack)
    }
    
    /// 播放单个曲目
    func playTrack(_ track: Track) {
        executeAction { [weak self] in
            guard let fluffel = self?.fluffelWindowController?.fluffel else { return }
            
            fluffel.playMusicFromURL(track.url) { success in
                if success {
                    print("Track playback completed successfully: \(track.title)")
                } else {
                    print("Failed to play track: \(track.title)")
                    fluffel.speak(text: "Sorry, I couldn't play the music", duration: 3.0)
                }
            }
        }
    }
    
    /// 播放随机曲目（从所有播放列表）
    @objc func playRandomTrackFromAll(_ sender: NSMenuItem) {
        guard let track = FluffelPixabayPlaylists.shared.getRandomTrack() else {
            return
        }
        
        playTrack(track)
    }
    
    /// 播放默认音乐
    private func playDefaultMusic() {
        executeAction { [weak self] in
            guard let fluffel = self?.fluffelWindowController?.fluffel else { 
                print("无法播放音乐，fluffel对象为nil")
                return 
            }
            
            print("开始播放默认音乐...")
            
            // 获取示例URL - 使用更可靠的 Pixabay 音频 URL
            let sampleURL = URL(string: "https://cdn.pixabay.com/audio/2023/07/30/audio_e0908e8569.mp3")!
            
            // 添加错误处理和备选方案
            fluffel.playMusicFromURL(sampleURL) { [weak self] success in
                if success {
                    print("Music playback completed successfully")
                } else {
                    print("Online music playback failed, trying local file")
                    
                    // 尝试使用本地文件作为备选
                    if let bundleURL = Bundle.main.url(forResource: "sample_music", withExtension: "mp3") {
                        fluffel.playMusicFromURL(bundleURL) { success in
                            if success {
                                print("Local music playback completed successfully")
                            } else {
                                print("Local music playback also failed")
                                // 通知用户
                                if let fluffel = self?.fluffelWindowController?.fluffel {
                                    fluffel.speak(text: "Sorry, I couldn't play the music", duration: 3.0)
                                }
                            }
                        }
                    } else {
                        print("No local music file found")
                        // 通知用户
                        if let fluffel = self?.fluffelWindowController?.fluffel {
                            fluffel.speak(text: "Sorry, I couldn't play the music", duration: 3.0)
                        }
                    }
                }
            }
        }
    }
    
    @objc func stopMusic(_ sender: Any) {
        executeAction { [weak self] in
            guard let fluffel = self?.fluffelWindowController?.fluffel else { return }
            
            // 安全地停止音乐
            DispatchQueue.main.async {
                print("AppDelegate: Stopping music")
                fluffel.stopMusic()
            }
        }
    }
    
    // 设置Fluffel声音类型并播放示例
    private func setFluffelVoice(_ voiceType: FluffelTTSService.CartoonVoiceType) {
        // 设置声音类型
        FluffelTTSService.shared.setCartoonVoice(voiceType)
        
        // 播放示例
        let demoText = "Hello! This is my new voice!"
        FluffelTTSService.shared.speak(demoText) {
            print("Voice changed successfully!")
        }
        
        // 让Fluffel显示消息泡泡
        if let fluffel = fluffelWindowController?.fluffel {
            fluffel.speak(text: "Voice updated!", duration: 2.0)
        }
    }
}
