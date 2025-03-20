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

    // MARK: - 音乐播放相关

    /// 播放列表队列
    private var playlistQueue: [Track] = []
    private var currentTrackIndex: Int = 0
    
    /// 存储播放列表队列
    func storePlaylistQueue(_ tracks: [Track]) {
        // 保存播放列表
        playlistQueue = tracks
        currentTrackIndex = 0
        
        print("Playlist queue stored with \(tracks.count) tracks")
        
        // 添加音乐播放完成通知的观察者，用于播放下一首
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMusicFinished),
            name: .fluffelDidFinishPlayingMusic,
            object: nil
        )
    }
    
    /// 处理音乐播放完成通知
    @objc private func handleMusicFinished() {
        // 如果播放列表为空或者已经是最后一首，不继续播放
        if playlistQueue.isEmpty || currentTrackIndex >= playlistQueue.count - 1 {
            print("Reached end of playlist or playlist is empty")
            return
        }
        
        // 播放下一首
        currentTrackIndex += 1
        let nextTrack = playlistQueue[currentTrackIndex]
        print("Playing next track (\(currentTrackIndex+1)/\(playlistQueue.count)): \(nextTrack.title)")
        
        // 延迟一秒后播放下一首，避免立即切换
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.playTrack(nextTrack)
        }
    }
    
    /// 播放指定曲目
    func playTrack(_ track: Track) {
        print("Track requested to play: \(track.title)")
        
        guard let fluffel = fluffelWindowController?.fluffel else {
            print("Unable to find Fluffel instance")
            return
        }
        
        // 检查URL格式
        if let url = URL(string: track.url) {
            playAudioWithURL(url, trackTitle: track.title, fluffel: fluffel)
        } else {
            print("Invalid track URL: \(track.url)")
            fluffel.speak(text: "Sorry, this track has an invalid URL", duration: 3.0)
        }
    }
    
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
    
    /// 辅助方法：使用 URL 播放音频
    private func playAudioWithURL(_ url: URL, trackTitle: String, fluffel: Fluffel) {
        print("Attempting to play audio with URL: \(url)")
        
        // 检查 URL 是否包含音频文件扩展名
        let validAudioExtensions = ["mp3", "wav", "m4a", "aac", "mp4"]
        let hasValidExtension = validAudioExtensions.contains { url.pathExtension.lowercased() == $0 }
        
        if !hasValidExtension {
            print("⚠️ Warning: URL does not have a recognized audio file extension: \(url)")
            
            // 尝试从URL末尾推断格式
            let urlString = url.absoluteString
            if urlString.contains(".mp3") || urlString.contains("audio_") {
                print("URL appears to be an MP3 despite extension")
            } else {
                print("URL format cannot be determined reliably")
            }
        }
        
        // 添加下载超时和重试机制
        if url.scheme == "http" || url.scheme == "https" {
            // 为网络音频添加预下载逻辑
            executeNetworkAudioPlayback(url: url, trackTitle: trackTitle, fluffel: fluffel)
        } else {
            // 本地音频直接播放
            print("Attempting to play local audio file")
            playAudioDirectly(url: url, trackTitle: trackTitle, fluffel: fluffel)
        }
    }
    
    /// 执行网络音频播放
    private func executeNetworkAudioPlayback(url: URL, trackTitle: String, fluffel: Fluffel) {
        print("Downloading network audio from: \(url)")
        
        // 创建一个缓存关键字
        let cacheKey = url.lastPathComponent
        
        // 检查是否已有缓存
        if let cachedFile = checkAudioCache(for: cacheKey) {
            print("Found cached audio file: \(cachedFile.lastPathComponent)")
            playAudioDirectly(url: cachedFile, trackTitle: trackTitle, fluffel: fluffel)
            return
        }
        
        // 开始下载任务
        let downloadTask = URLSession.shared.downloadTask(with: url) { [weak self] (tempFileURL, response, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error downloading audio: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    fluffel.speak(text: "Sorry, I couldn't download the music", duration: 3.0)
                }
                return
            }
            
            guard let tempFileURL = tempFileURL else {
                print("Error: No temporary file URL provided")
                return
            }
            
            // 判断响应状态
            if let httpResponse = response as? HTTPURLResponse {
                print("Download completed with status code: \(httpResponse.statusCode)")
                
                if !(200...299).contains(httpResponse.statusCode) {
                    print("HTTP error: \(httpResponse.statusCode)")
                    return
                }
                
                // 检查内容类型
                if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
                    print("Content-Type: \(contentType)")
                    if !contentType.contains("audio/") && !contentType.contains("application/octet-stream") {
                        print("Warning: Content may not be audio, got type: \(contentType)")
                    }
                }
            }
            
            // 尝试保存到缓存
            if let cachedFile = self.saveToAudioCache(tempFile: tempFileURL, key: cacheKey) {
                // 在主线程播放音频
                DispatchQueue.main.async {
                    self.playAudioDirectly(url: cachedFile, trackTitle: trackTitle, fluffel: fluffel)
                }
            } else {
                // 如果缓存失败，直接从临时文件播放
                DispatchQueue.main.async {
                    self.playAudioDirectly(url: tempFileURL, trackTitle: trackTitle, fluffel: fluffel)
                }
            }
        }
        
        downloadTask.resume()
    }
    
    /// 直接播放音频文件
    private func playAudioDirectly(url: URL, trackTitle: String, fluffel: Fluffel) {
        print("Directly playing audio from: \(url)")
        
        // 尝试播放
        fluffel.playMusicFromURL(url) { success in
            if success {
                print("✅ Track playback completed successfully: \(trackTitle)")
            } else {
                print("❌ Failed to play track: \(trackTitle)")
                fluffel.speak(text: "Sorry, I couldn't play the music", duration: 3.0)
            }
        }
    }
    
    /// 检查音频缓存
    private func checkAudioCache(for key: String) -> URL? {
        let cacheDirectory = getCacheDirectory()
        let cachedFile = cacheDirectory.appendingPathComponent(key)
        
        // 检查文件是否存在
        if FileManager.default.fileExists(atPath: cachedFile.path) {
            return cachedFile
        }
        
        return nil
    }
    
    /// 保存到音频缓存
    private func saveToAudioCache(tempFile: URL, key: String) -> URL? {
        let cacheDirectory = getCacheDirectory()
        let cachedFile = cacheDirectory.appendingPathComponent(key)
        
        do {
            // 如果已存在，先删除
            if FileManager.default.fileExists(atPath: cachedFile.path) {
                try FileManager.default.removeItem(at: cachedFile)
            }
            
            // 复制临时文件到缓存目录
            try FileManager.default.copyItem(at: tempFile, to: cachedFile)
            print("Audio cached to: \(cachedFile.path)")
            return cachedFile
        } catch {
            print("Error caching audio file: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 获取缓存目录
    private func getCacheDirectory() -> URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectory = paths[0].appendingPathComponent("FluffelAudioCache", isDirectory: true)
        
        // 确保目录存在
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating cache directory: \(error.localizedDescription)")
            }
        }
        
        return cacheDirectory
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
    
    // 显示上下文菜单
    private func showContextMenu(at location: NSPoint, in view: NSView?) {
        guard let view = view else { return }
        
        // 创建菜单
        let menu = NSMenu(title: "Fluffel Menu")
        
        // 添加交互选项
        menu.addItem(withTitle: "Greeting", action: #selector(AppDelegate.speakGreeting(_:)), keyEquivalent: "g")
        menu.addItem(withTitle: "Joke", action: #selector(AppDelegate.tellJoke(_:)), keyEquivalent: "j")
        menu.addItem(withTitle: "Share facts", action: #selector(AppDelegate.shareFact(_:)), keyEquivalent: "f")
        menu.addItem(withTitle: "Conversation", action: #selector(AppDelegate.startConversation(_:)), keyEquivalent: "c")
        
        // 创建音乐子菜单
        let musicMenu = NSMenu(title: "Listen to music")
        let musicMenuItem = NSMenuItem(title: "Listen to music", action: nil, keyEquivalent: "m")
        musicMenuItem.submenu = musicMenu
        
        // 添加音乐类别
        for category in FluffelPixabayPlaylists.PlaylistCategory.allCases {
            let categoryItem = NSMenuItem(
                title: category.rawValue,
                action: #selector(AppDelegate.showPlaylistWindow(_:)),
                keyEquivalent: ""
            )
            categoryItem.representedObject = category
            categoryItem.target = NSApp.delegate
            musicMenu.addItem(categoryItem)
        }
        
        // 添加分隔线和其他音乐选项
        musicMenu.addItem(NSMenuItem.separator())
        
        // 添加随机播放选项
        let shuffleAllItem = NSMenuItem(
            title: "Shuffle All Music",
            action: #selector(AppDelegate.playRandomTrackFromAll(_:)),
            keyEquivalent: ""
        )
        shuffleAllItem.target = NSApp.delegate
        musicMenu.addItem(shuffleAllItem)
        
        // 添加停止音乐选项
        let stopItem = NSMenuItem(
            title: "Stop Music",
            action: #selector(AppDelegate.stopMusic(_:)),
            keyEquivalent: ""
        )
        stopItem.target = NSApp.delegate
        musicMenu.addItem(stopItem)
        
        menu.addItem(musicMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 添加声音选项子菜单
        let voiceMenu = NSMenu(title: "Voice Options")
        let voiceMenuItem = NSMenuItem(title: "Voice Options", action: nil, keyEquivalent: "")
        voiceMenuItem.submenu = voiceMenu
        
        // 添加声音选项
        voiceMenu.addItem(withTitle: "Squeaky", action: #selector(AppDelegate.setVoiceSqueaky(_:)), keyEquivalent: "1")
        voiceMenu.addItem(withTitle: "Deep", action: #selector(AppDelegate.setVoiceDeep(_:)), keyEquivalent: "2")
        voiceMenu.addItem(withTitle: "Chipmunk", action: #selector(AppDelegate.setVoiceChipmunk(_:)), keyEquivalent: "3")
        voiceMenu.addItem(withTitle: "Robot", action: #selector(AppDelegate.setVoiceRobot(_:)), keyEquivalent: "4")
        voiceMenu.addItem(withTitle: "Cute (Default)", action: #selector(AppDelegate.setVoiceCute(_:)), keyEquivalent: "5")
        
        menu.addItem(voiceMenuItem)
        
        // 添加操作选项
        menu.addItem(withTitle: "Reset to center", action: #selector(AppDelegate.resetFluffelToCenter(_:)), keyEquivalent: "r")
        menu.addItem(withTitle: "Test voice", action: #selector(AppDelegate.testTTSFromMenu(_:)), keyEquivalent: "t")
        
        menu.addItem(NSMenuItem.separator())
        
        // 添加API密钥设置选项
        menu.addItem(withTitle: "Set Google Cloud API key", action: #selector(AppDelegate.showApiKeySettings(_:)), keyEquivalent: "k")
        menu.addItem(withTitle: "Fix network permissions", action: #selector(AppDelegate.openNetworkSettings(_:)), keyEquivalent: "n")
        
        menu.addItem(NSMenuItem.separator())
        
        // 添加退出选项
        menu.addItem(withTitle: "Quit", action: #selector(AppDelegate.quitApp(_:)), keyEquivalent: "q")
        
        // 为菜单项设置目标
        for item in menu.items {
            if item.action != nil {
                item.target = NSApp.delegate
            }
        }
        
        // 显示菜单
        NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent!, for: view)
    }
}
