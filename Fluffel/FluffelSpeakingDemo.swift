import SpriteKit

/// FluffelSpeakingDemo 为 Fluffel 的说话功能提供了一个简单的演示场景
class FluffelSpeakingDemo {
    weak var scene: FluffelScene?
    weak var fluffel: Fluffel?
    
    // 添加对话控制变量
    private var isConversationActive = false
    private var conversationTimer: Timer?
    
    init(scene: FluffelScene, fluffel: Fluffel) {
        self.scene = scene
        self.fluffel = fluffel
    }
    
    deinit {
        // 确保清理任何潜在的定时器
        conversationTimer?.invalidate()
        conversationTimer = nil
    }
    
    /// 让 Fluffel 说一个随机的问候语
    func speakRandomGreeting() {
        // 如果Fluffel不存在，直接返回
        guard let fluffel = fluffel else { return }
        
        // 确保在主线程上执行
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.speakRandomGreeting()
            }
            return
        }
        
        let randomGreeting = FluffelDialogues.shared.getRandomGreeting()
        fluffel.speak(text: randomGreeting, duration: 3.0)
    }
    
    /// 让 Fluffel 讲一个随机的笑话
    func tellRandomJoke() {
        guard let fluffel = fluffel else { return }
        
        // 确保在主线程上执行
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.tellRandomJoke()
            }
            return
        }
        
        let randomJoke = FluffelDialogues.shared.getRandomJoke()
        fluffel.speak(text: randomJoke, duration: 5.0)
    }
    
    /// 让 Fluffel 分享一个随机的事实
    func shareRandomFact() {
        guard let fluffel = fluffel else { return }
        
        // 确保在主线程上执行
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.shareRandomFact()
            }
            return
        }
        
        let randomFact = FluffelDialogues.shared.getRandomFact()
        fluffel.speak(text: randomFact, duration: 4.0)
    }
    
    /// 让 Fluffel 进行一段对话
    func performConversation() {
        // 确保在主线程上执行
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.performConversation()
            }
            return
        }
        
        // 如果已经在进行对话，不要再开始新的对话
        guard !isConversationActive else {
            print("对话已在进行中")
            return
        }
        
        // 确保Fluffel还存在
        guard let fluffel = fluffel else {
            print("Fluffel不存在，无法进行对话")
            return
        }
        
        // 获取对话数组
        let conversation = FluffelDialogues.shared.getConversationArray()
        guard !conversation.isEmpty else {
            print("对话内容为空")
            return
        }
        
        // 标记对话开始
        isConversationActive = true
        
        // 使用迭代方法替代递归，避免可能的栈溢出和内存问题
        var currentIndex = 0
        
        // 取消之前可能存在的计时器
        conversationTimer?.invalidate()
        
        // 先声明一个变量用于储存闭包
        var speakItem: (() -> Void)? = nil
        
        // 然后定义闭包并赋值给刚声明的变量
        speakItem = { [weak self] in
            guard let self = self,
                  let fluffel = self.fluffel,
                  currentIndex < conversation.count else {
                // 对话结束或对象不存在
                self?.isConversationActive = false
                self?.conversationTimer?.invalidate()
                self?.conversationTimer = nil
                return
            }
            
            // 获取当前对话内容
            let text = conversation[currentIndex]
            
            // 根据文本长度计算合适的显示时间
            let duration = min(max(TimeInterval(text.count) * 0.1, 2.0), 4.0)
            
            // 让Fluffel说话
            fluffel.speak(text: text, duration: duration)
            
            // 移到下一个对话项
            currentIndex += 1
            
            // 如果还有更多对话，设置定时器继续
            if currentIndex < conversation.count {
                // 等待当前对话结束后再继续
                self.conversationTimer = Timer.scheduledTimer(withTimeInterval: duration + 0.5, repeats: false) { [weak self] _ in
                    // 确保在主线程上执行
                    DispatchQueue.main.async {
                        speakItem?()
                    }
                }
            } else {
                // 对话结束
                self.isConversationActive = false
                self.conversationTimer = nil
            }
        }
        
        // 开始对话
        speakItem?()
    }
    
    /// 设置菜单栏中的测试选项
    func setupMenuBarItems() {
        // 创建一个新的菜单项
        let fluffelMenu = NSMenu(title: "Fluffel")
        
        // 添加测试选项
        let greetingItem = NSMenuItem(title: "Greeting", action: #selector(AppDelegate.speakGreeting), keyEquivalent: "g")
        let jokeItem = NSMenuItem(title: "Joke", action: #selector(AppDelegate.tellJoke), keyEquivalent: "j")
        let factItem = NSMenuItem(title: "Fact", action: #selector(AppDelegate.shareFact), keyEquivalent: "f")
        let conversationItem = NSMenuItem(title: "Conversation", action: #selector(AppDelegate.startConversation), keyEquivalent: "c")
        
        fluffelMenu.addItem(greetingItem)
        fluffelMenu.addItem(jokeItem)
        fluffelMenu.addItem(factItem)
        fluffelMenu.addItem(conversationItem)
        
        // 添加到主菜单
        if let mainMenu = NSApp.mainMenu {
            let fluffelMenuItem = NSMenuItem(title: "Fluffel", action: nil, keyEquivalent: "")
            fluffelMenuItem.submenu = fluffelMenu
            mainMenu.insertItem(fluffelMenuItem, at: mainMenu.items.count - 1)
        }
    }
} 