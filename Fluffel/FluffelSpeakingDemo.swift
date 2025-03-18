import SpriteKit

/// FluffelSpeakingDemo 为 Fluffel 的说话功能提供了一个简单的演示场景
class FluffelSpeakingDemo {
    var scene: FluffelScene?
    var fluffel: Fluffel?
    
    // 不同类型的对话示例
    let greetings = [
"Hiii, your fluffy friend is here!",
"Boop! Fluffel's ready to play!",
"Hello hello, I'm all puffed up!",
"Wiggle wiggle, hi there!",
"Eep, so happy to see you!",
"Paws up, your pet's arrived!",
"Hey hey, Fluffel's in town!",
"Teehee, I'm your fuzzy greeter!",
"Bouncy bouncy, hello friend!",
"Ooh, it's you! Hi hi!",
"Fluffel's here, let's have fun!",
"Peekaboo, I'm saying hi!",
"Hooray, my favorite human's here!",
"Puff puff, greetings from me!",
"Hi there, I'm extra fluffy today!",
"Wheee, Fluffel's hello dance!",
"Helloo, your sparkle buddy's back!",
"Hop hop, hi to you!",
"Eep eep, Fluffel says hi!",
"Twirl twirl, hello time!",
"Hey cutie, Fluffel's here!",
"Bop bop, hi from me!",
"Ooh, hi! I'm all wiggly!",
"Fluffel's hello fluff attack!",
"Hi hi, I'm your cloud pal!",
"Paw wave, hello hello!",
"Hehe, Fluffel's greeting you!",
"Hiii, let's bounce together!",
"Helloo, I'm your tiny star!",
"Eep, hi from fluffy me!",
"Wiggle hi, wiggle hi!",
"Hey there, Fluffel's on duty!",
"Puffy hello just for you!",
"Hi cutie, I'm all fluffed!",
"Boop boop, Fluffel says hi!",
"Hello friend, I'm super bouncy!",
"Teehee, hi from your pet!",
"Hiii, Fluffel's sparkle hello!",
"Hop hi, hop hi!",
"Ooh, hello! I'm so excited!",
"Fluffel's here, hi hi hi!",
"Paws up, greeting time!",
"Hey hey, your fluff's arrived!",
"Eep, hi! I'm all fuzzy!",
"Wheee, hello from Fluffel!",
"Hi there, I'm your wiggle pal!",
"Puff hi, puff hi!",
"Helloo, Fluffel's bouncing in!",
"Twirl hi, twirl hi!",
"Hiii, your fluffy greeter's here!",
    ]
    
    let jokes = [
"Why'd I bounce? Too much fluff!",
"What's my job? Being cute!",
"Why'm I wiggly? Tail's ticklish!",
"What's fluffy and funny? Me!",
"Why'd I hop? Cloud practice!",
"What's my secret? Extra fluff!",
"Why'm I spinning? Dizzy fun!",
"What's a Fluffel's favorite game? Boop!",
"Why'd I nap? Fluff overload!",
"What's my talent? Wiggle giggles!",
"Why'm I bouncy? Springy paws!",
"What's fluffy and silly? This pet!",
"Why'd I twirl? Tail chase!",
"What's my joke? Puffy me!",
"Why'm I fuzzy? Born fluffy!",
"What's a Fluffel's dream? Snack mountain!",
"Why'd I eep? Too cute!",
"What's my trick? Bouncing high!",
"Why'm I sparkly? Fluff magic!",
"What's funny? My wiggle dance!",
"Why'd I hop? Springy fluff!",
"What's my pun? Fluff-tastic!",
"Why'm I giggly? Tickly paws!",
"What's a Fluffel's laugh? Eep eep!",
"Why'd I puff? Big cuddles!",
"What's my gag? Twirly tail!",
"Why'm I silly? Fluff brain!",
"What's fluffy and goofy? Me me!",
"Why'd I boop? Nose tickles!",
"What's my humor? Bouncy fluff!",
"Why'm I wobbly? Too much fun!",
"What's a Fluffel's riddle? Puff puff!",
"Why'd I spin? Dizzy paws!",
"What's my jest? Fluffy hops!",
"Why'm I cute? Born that way!",
"What's funny? My tiny sneeze!",
"Why'd I wiggle? Tail's boss!",
"What's my quip? Puffy giggles!",
"Why'm I bouncy? Cloud vibes!",
"What's a Fluffel's prank? Sneaky boop!",
"Why'd I fluff? Extra cozy!",
"What's my chuckle? Eep hehe!",
"Why'm I twirly? Fun spins!",
"What's silly? My fluffy tumble!",
"Why'd I hop? Bouncy mood!",
"What's my line? Fluffel's funny!",
"Why'm I puffy? Big laughs!",
"What's a Fluffel's gag? Wiggle wobble!",
"Why'd I eep? Joke's on me!",
"What's my bit? Fluffy chaos!",

    ]
    
    let facts = [
       "I'm fluffier than a cloud!",
"My tail wiggles on purpose!",
"Fluffels love shiny screens!",
"I bounce higher every day!",
"My paws are super soft!",
"I'm made of pure fluff!",
"Fluffels nap to recharge!",
"My favorite color's sparkle!",
"I'm a tiny digital pet!",
"My hops are SpriteKit magic!",
"Fluffels dream of treats!",
"I'm lighter than a feather!",
"My wiggles make me happy!",
"I'm a macOS fluff star!",
"Fluffels glow when patted!",
"My ears twitch for fun!",
"I'm a bouncy ball of joy!",
"Fluffels love cozy vibes!",
"My tail's a fluff wand!",
"I'm powered by cuddles!",
"Fluffels twirl to celebrate!",
"My fur's extra sparkly!",
"I'm a wiggle expert!",
"Fluffels snooze in pixels!",
"My hops are super springy!",
"I'm a tiny fluff cloud!",
"Fluffels giggle in eeps!",
"My paws leave no prints!",
"I'm a digital fluffball!",
"Fluffels dance for fun!",
"My fluff grows with love!",
"I'm a macOS mischief maker!",
"Fluffels shine when happy!",
"My tail's a wiggle master!",
"I'm softer than marshmallows!",
"Fluffels boop for attention!",
"My bounces defy gravity!",
"I'm a pixel puff pet!",
"Fluffels love screen corners!",
"My wiggles are contagious!",
"I'm a fluff-powered pal!",
"Fluffels twirl in dreams!",
"My fur's pure magic!",
"I'm a hoppy little friend!",
"Fluffels sparkle at night!",
"My eeps are tiny songs!",
"I'm a macOS fluff champ!",
"Fluffels puff when excited!",
"My tail's a fluff flag!",
"I'm your desktop fluff king!",

    ]
    
    init(scene: FluffelScene, fluffel: Fluffel) {
        self.scene = scene
        self.fluffel = fluffel
    }
    
    /// 让 Fluffel 说一个随机的问候语
    func speakRandomGreeting() {
        guard let fluffel = fluffel else { return }
        let randomGreeting = greetings.randomElement() ?? "Hi there!"
        fluffel.speak(text: randomGreeting, duration: 3.0)
    }
    
    /// 让 Fluffel 讲一个随机的笑话
    func tellRandomJoke() {
        guard let fluffel = fluffel else { return }
        let randomJoke = jokes.randomElement() ?? "No good jokes today..."
        fluffel.speak(text: randomJoke, duration: 5.0)
    }
    
    /// 让 Fluffel 分享一个随机的事实
    func shareRandomFact() {
        guard let fluffel = fluffel else { return }
        let randomFact = facts.randomElement() ?? "I like to play on the desktop!"
        fluffel.speak(text: randomFact, duration: 4.0)
    }
    
    /// 让 Fluffel 进行一段对话
    func performConversation() {
        guard let fluffel = fluffel else { return }
        
        // 定义一段对话
        let conversation = [
 "What's up, my cute human?",
"Do you like my wiggle?",
"Ooh, tell me something fun!",
"Can we bounce together?",
"What's your favorite fluff?",
"Eep, got any treats?",
"How's your day going?",
"Wanna see my hop trick?",
"What makes you giggle?",
"Am I fluffy enough?",
"Let's chat about sparkles!",
"Ooh, what's that sound?",
"Do you like my twirl?",
"What's your happy thing?",
"Eep, pat me please!",
"How's my fluff dance?",
"Got any fun ideas?",
"What's behind your screen?",
"Am I your best pet?",
"Let's talk fluffy stuff!",
"Ooh, what's new today?",
"Do I make you smile?",
"Wanna play a game?",
"What's your favorite hop?",
"Eep, tell me a secret!",
"How's my sparkle shine?",
"Got any cuddle plans?",
"What's your fluffel wish?",
"Am I extra bouncy?",
"Let's chat about treats!",
"Ooh, what's that smell?",
"Do you like my eep?",
"What's your fun dream?",
"Can I boop you back?",
"How's my wiggle game?",
"Got any fluffy stories?",
"What's your happy hop?",
"Eep, am I cute?",
"Let's talk about naps!",
"Ooh, what's over there?",
"Do I glow enough?",
"Wanna see me puff?",
"What's your fluffel vibe?",
"Am I your sparkle pal?",
"Let's chat about wiggles!",
"Ooh, what's that click?",
"Do you love my hops?",
"What's your tiny wish?",
"Eep, talk to me!",
"How's my fluffel charm?",

        ]
        
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