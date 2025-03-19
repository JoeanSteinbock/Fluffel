import SpriteKit

/// FluffelSpeakingDemo 为 Fluffel 的说话功能提供了一个简单的演示场景
class FluffelSpeakingDemo {
    var scene: FluffelScene?
    var fluffel: Fluffel?
    
    init(scene: FluffelScene, fluffel: Fluffel) {
        self.scene = scene
        self.fluffel = fluffel
    }
    
    /// 让 Fluffel 说一个随机的问候语
    func speakRandomGreeting() {
        guard let fluffel = fluffel else { return }
        let randomGreeting = FluffelDialogues.shared.getRandomGreeting()
        fluffel.speak(text: randomGreeting, duration: 3.0)
    }
    
    /// 让 Fluffel 讲一个随机的笑话
    func tellRandomJoke() {
        guard let fluffel = fluffel else { return }
        let randomJoke = FluffelDialogues.shared.getRandomJoke()
        fluffel.speak(text: randomJoke, duration: 5.0)
    }
    
    /// 让 Fluffel 分享一个随机的事实
    func shareRandomFact() {
        guard let fluffel = fluffel else { return }
        let randomFact = FluffelDialogues.shared.getRandomFact()
        fluffel.speak(text: randomFact, duration: 4.0)
    }
    
    /// 让 Fluffel 进行一段对话
    func performConversation() {
        guard let fluffel = fluffel else { return }
        
        // 获取对话数组
        let conversation = FluffelDialogues.shared.getConversationArray()
        
        // 用递归函数实现连续对话
        func speakNext(index: Int) {
            if index >= conversation.count { return }
            
            fluffel.speak(text: conversation[index], duration: 2.0) {
                // 短暂停顿后说下一句
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    speakNext(index: index + 1)
                }
            }
        }
        
        // 开始对话
        speakNext(index: 0)
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