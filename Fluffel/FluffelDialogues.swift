import Foundation

/// 管理Fluffel所有对话内容的类
class FluffelDialogues {
    
    // 所有对话类别
    private var boredGreetings: [String] = []
    private var greetings: [String] = []
    private var jokes: [String] = []
    private var facts: [String] = []
    private var conversation: [String] = []
    
    // 单例模式
    static let shared = FluffelDialogues()
    
    private init() {
        loadDialogues()
    }
    
    /// 从JSON文件加载所有对话内容
    private func loadDialogues() {
        // 首先尝试从Resources目录加载
        if let url = Bundle.main.url(forResource: "FluffelDialogues", withExtension: "json", subdirectory: "Resources") {
            loadFromURL(url)
            return
        }
        
        // 如果不在Resources目录，则尝试直接从主目录加载
        if let url = Bundle.main.url(forResource: "FluffelDialogues", withExtension: "json") {
            loadFromURL(url)
            return
        }
        
        // 如果都找不到，使用后备对话
        print("错误: 无法找到FluffelDialogues.json文件")
        loadFallbackDialogues()
    }
    
    /// 从URL加载对话内容
    private func loadFromURL(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let dialogues = try decoder.decode(DialogueData.self, from: data)
            
            self.boredGreetings = dialogues.boredGreetings
            self.greetings = dialogues.greetings
            self.jokes = dialogues.jokes
            self.facts = dialogues.facts
            self.conversation = dialogues.conversation
            
            print("对话内容加载成功: \(boredGreetings.count)条无聊问候, \(greetings.count)条问候语, \(jokes.count)条笑话, \(facts.count)条知识点, \(conversation.count)条对话")
        } catch {
            print("错误: 加载对话内容失败 - \(error.localizedDescription)")
            loadFallbackDialogues()
        }
    }
    
    /// 加载硬编码的后备对话内容（以防JSON文件加载失败）
    private func loadFallbackDialogues() {
        print("使用后备对话内容")
        
        // 添加一些基本的后备对话
        boredGreetings = ["Bored? Let's play!", "Eep, I'm here to entertain you!"]
        greetings = ["Hi there!", "Hello friend!", "Fluffel says hi!"]
        jokes = ["Why am I so fluffy? It's a lifestyle choice!", "What's my favorite game? Chase the cursor!"]
        facts = ["I'm a desktop pet!", "I'm made of pure digital fluff!"]
        conversation = ["How are you today?", "What's new?", "Let's chat!"]
    }
    
    // MARK: - 公共方法
    
    /// 获取一条随机无聊问候语
    func getRandomBoredGreeting() -> String {
        return boredGreetings.randomElement() ?? "Eep, I'm bored!"
    }
    
    /// 获取一条随机问候语
    func getRandomGreeting() -> String {
        return greetings.randomElement() ?? "Hello there!"
    }
    
    /// 获取一条随机笑话
    func getRandomJoke() -> String {
        return jokes.randomElement() ?? "I'm too fluffy to remember my jokes!"
    }
    
    /// 获取一条随机知识点
    func getRandomFact() -> String {
        return facts.randomElement() ?? "I'm a digital pet!"
    }
    
    /// 获取一条随机对话句子
    func getRandomConversation() -> String {
        return conversation.randomElement() ?? "Let's chat!"
    }
    
    /// 获取完整的对话数组
    func getConversationArray() -> [String] {
        return conversation
    }
}

/// 用于解码JSON数据的结构
private struct DialogueData: Codable {
    let boredGreetings: [String]
    let greetings: [String]
    let jokes: [String]
    let facts: [String]
    let conversation: [String]
} 