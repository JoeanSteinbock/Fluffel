import SpriteKit

enum Direction {
    case left, right, up, down
}

// 添加一个通知名称，用于通知窗口 Fluffel 已移动
extension Notification.Name {
    static let fluffelDidMove = Notification.Name("fluffelDidMove")
}

class FluffelScene: SKScene {
    
    var fluffel: Fluffel?
    private var lastMoveTime: TimeInterval = 0
    private var moveDelay: TimeInterval = 0.01 // 控制移动流畅度
    
    // 边缘检测相关
    private var isEdgeDetectionEnabled = true
    private var edgeDetectionTolerance: CGFloat = 10.0
    private let edgeCheckInterval: TimeInterval = 0.1 // 每0.1秒检查一次边缘
    private var lastEdgeCheckTime: TimeInterval = 0
    
    // 坐标转换相关
    private var lastKnownGlobalPosition: CGPoint?
    
    private var isFollowingEdge = false
    private let edgeMoveSpeed: CGFloat = 2.0 // Speed of waddling along edge
    
    // 无聊状态相关
    private var lastActivityTime: TimeInterval = 0
    private let boredThreshold: TimeInterval = 10.0 // 10秒无活动后触发无聊状态
    private var isCheckingBoredom = false
    
    // 说话相关
    private var boredGreetings = [
"Bored? Let’s bounce around!",
"Eep, I’ll wiggle for you!",
"Ooh, wanna chase my tail?",
"Hop hop, let’s play now!",
"I’ll twirl ‘til you giggle!",
"Boop! Surprise fluff attack!",
"Let’s count my sparkles!",
"Puff puff, boredom’s gone!",
"Wiggle dance, just for you!",
"Eep, I’ll be your clown!",
"Bouncy Fluffel to the rescue!",
"Ooh, let’s make silly faces!",
"I’ll hop ‘til you laugh!",
"Teehee, watch me spin!",
"Bored? Pat my fluff!",
"Let’s play peekaboo, okay?",
"Wheee, I’m your fun pet!",
"Paws up, no more blah!",
"I’ll eep ‘til you smile!",
"Ooh, let’s chase pixels!",
"Fluffel’s got a silly trick!",
"Hop hop, boredom buster!",
"Twirl twirl, fun’s here!",
"Eep, I’ll tickle your screen!",
"Let’s bounce away the yawn!",
"Puffy fluff, instant fun!",
"Wiggle wiggle, wake up!",
"Ooh, I’ll boop your nose!",
"Bored? Watch my fluff dance!",
"Eep eep, giggle time!",
"I’ll spin ‘til you cheer!",
"Hop along with me!",
"Teehee, I’m your fluff fix!",
"Let’s play a tiny game!",
"Paws wave, boredom’s out!",
"Ooh, I’ll sparkle extra!",
"Fluffel’s here, no more dull!",
"Wiggle hop, fun starts!",
"Eep, let’s make mischief!",
"Bouncy me, happy you!",
"Twirl twirl, yawn no more!",
"Ooh, I’ll puff up big!",
"Let’s chase my fluffy tail!",
"Hop hop, fun explosion!",
"Eep, I’m your silly pal!",
"Wiggle fluff, boredom’s done!",
"Puffy pet, instant joy!",
"Ooh, watch me tumble!",
"Bored? Fluffel’s gotcha!",
"Teehee, let’s bounce forever!",
    ]
    
    // 添加一个防止重复触发说话功能的标志
    private var isSpeakingInProgress = false
    private var speakingDebounceTimer: Timer?
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        // 设置场景属性
        backgroundColor = .clear
        
        // 创建 Fluffel
        fluffel = Fluffel()
        if let fluffel = fluffel {
            // 确保 Fluffel 在场景中央
            fluffel.position = CGPoint(x: size.width / 2, y: size.height / 2)
            addChild(fluffel)
            
            // 使用正常比例
            fluffel.setScale(1.0)
            
            // 让 Fluffel 微笑，看起来更友好
            fluffel.smile()
            
            // 初次出现时说一句话
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.makeFluffelSpeak("你好！我是 Fluffel！")
            }
            
            print("Fluffel 已添加到场景，位置: \(fluffel.position)")
            
            // 添加一个短暂的延迟，然后让 Fluffel 眨眼，显得更加活泼
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                fluffel.happyBlink()
                print("Fluffel 完成眨眼动画")
            }
        } else {
            print("错误: 无法创建 Fluffel")
        }
        
        // 初始化无聊检测
        lastActivityTime = CACurrentMediaTime()
        startBoredCheck()
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // Edge detection
        if isEdgeDetectionEnabled && currentTime - lastEdgeCheckTime > edgeCheckInterval {
            checkForWindowEdges(currentTime: currentTime)
            lastEdgeCheckTime = currentTime
        }

        // Edge following
        if fluffel?.state == .onEdge {
            followEdge(currentTime: currentTime)
        }
        
        // 检查无聊状态
        checkBoredom(currentTime: currentTime)
    }
    
    // 检查是否进入无聊状态
    private func checkBoredom(currentTime: TimeInterval) {
        guard let fluffel = fluffel else { return }
        
        // 调试输出，帮助诊断问题
        if currentTime - lastActivityTime > boredThreshold - 1.0 {
            print("无聊检测: 当前状态=\(fluffel.state), 是否在边缘=\(isFollowingEdge), 剩余时间=\(boredThreshold - (currentTime - lastActivityTime))")
        }
        
        // 只有在正常状态下才检查无聊
        guard fluffel.state != .falling && 
              fluffel.state != .onEdge && 
              !isFollowingEdge else {
            return  // 不重置计时器，只是跳过检查
        }
        
        // 如果超过无聊阈值时间没有活动，触发随机动画
        if currentTime - lastActivityTime > boredThreshold {
            print("触发无聊动画: 已经 \(currentTime - lastActivityTime) 秒无活动")
            startRandomBoredAnimation()
            lastActivityTime = currentTime // 重置计时器
        }
    }
    
    // 开始随机无聊动画
    private func startRandomBoredAnimation() {
        guard let fluffel = fluffel else { return }
        
        // 随机选择一个动画
        let randomAction = Int.random(in: 0...4)
        
        switch randomAction {
        case 0:
            // 睡觉动画
            fluffel.startSleepingAnimation()
            print("Fluffel 感到无聊，开始睡觉")
            
            // 5秒后停止睡觉
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                fluffel.stopSleepingAnimation()
                self?.lastActivityTime = CACurrentMediaTime()
            }
            
        case 1:
            // 跳舞动画
            fluffel.startDancingAnimation()
            print("Fluffel 感到无聊，开始跳舞")
            
            // 4秒后停止跳舞
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
                fluffel.stopDancingAnimation()
                self?.lastActivityTime = CACurrentMediaTime()
            }
            
        case 2:
            // 兴奋动画
            fluffel.startExcitedAnimation()
            print("Fluffel 感到无聊，变得兴奋")
            
            // 3秒后停止兴奋
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                fluffel.stopExcitedAnimation()
                self?.lastActivityTime = CACurrentMediaTime()
            }
            
        case 3:
            // 滚动动画
            fluffel.roll()
            print("Fluffel 感到无聊，开始滚动")
            
            // 2秒后停止滚动
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                fluffel.stopRolling()
                self?.lastActivityTime = CACurrentMediaTime()
            }
            
        case 4:
            // 眨眼动画
            fluffel.happyBlink()
            print("Fluffel 感到无聊，眨了眨眼")
            
            // 眨眼是瞬时的，不需要停止
            lastActivityTime = CACurrentMediaTime()
            
        default:
            break
        }
    }
    
    // 启动无聊检测
    private func startBoredCheck() {
        guard !isCheckingBoredom else { return }
        isCheckingBoredom = true
    }
    
    // Move Fluffel along the current edge
    private func followEdge(currentTime: TimeInterval) {
        guard let fluffel = fluffel, fluffel.state == .onEdge else {
            // 如果 Fluffel 不在边缘状态，重置标志
            isFollowingEdge = false
            return
        }
        
        // 设置标志表示正在沿边缘移动
        isFollowingEdge = true
        
        // 其余代码保持不变
        _ = edgeMoveSpeed

        switch fluffel.currentEdge {
        case .top, .bottom:
            // Move horizontally along top or bottom edge
            let direction = fluffel.xScale > 0 ? Direction.right : Direction.left
            moveFluffel(direction: direction)

            // Reverse direction if hitting scene bounds (simple bounce-back)
            if fluffel.position.x <= 10 || fluffel.position.x >= size.width - 10 {
                turnFluffelToFace(direction: direction == .right ? .left : .right)
            }

        case .left, .right:
            // Move vertically along left or right edge
            let direction = fluffel.position.y > size.height / 2 ? Direction.down : Direction.up
            moveFluffel(direction: direction)

            // Reverse direction at vertical bounds
            if fluffel.position.y <= 10 || fluffel.position.y >= size.height - 10 {
                fluffel.position.y = max(10, min(size.height - 10, fluffel.position.y))
            }
        case .none:
            // 如果没有边缘状态，不执行任何操作
            break
        }

        NotificationCenter.default.post(name: .fluffelDidMove, object: self)
    }
    
    // 检查 Fluffel 是否靠近窗口边缘
    private func checkForWindowEdges(currentTime: TimeInterval) {
        guard let fluffel = fluffel, 
              fluffel.state != .falling, // 如果正在下落，不检查边缘
              let window = self.view?.window else {
            return
        }

        // Get Fluffel's global position (existing code)
        let fluffelScenePosition = fluffel.position
        let fluffelViewPosition = self.view!.convert(fluffelScenePosition, from: self)
        var fluffelWindowPosition = fluffelViewPosition
        fluffelWindowPosition.y = window.frame.height - fluffelWindowPosition.y
        let fluffelGlobalPosition = CGPoint(
            x: window.frame.origin.x + fluffelWindowPosition.x,
            y: window.frame.origin.y + fluffelWindowPosition.y
        )
        lastKnownGlobalPosition = fluffelGlobalPosition

        // Check edge status
        let edgeResult = WindowUtility.isPointOnWindowEdge(fluffelGlobalPosition, tolerance: edgeDetectionTolerance)

        if edgeResult.isOnEdge, let edge = edgeResult.edge, let detectedWindow = edgeResult.window {
            if !fluffel.isOnEdge {
                // Moved to a new edge
                fluffel.setOnEdge(window: detectedWindow, edge: edge)
                isFollowingEdge = true // 确保设置标志
                print("Fluffel moved to edge: \(edge)")
            } else if fluffel.currentWindow?.id != detectedWindow.id {
                // Window changed, update it
                fluffel.setOnEdge(window: detectedWindow, edge: edge)
                isFollowingEdge = true // 确保设置标志
                print("Fluffel switched to new window edge: \(edge)")
            }
        } else if fluffel.isOnEdge {
            // No longer on an edge, initiate fall
            fluffel.leaveEdge()
            isFollowingEdge = false // 确保重置标志
            startFalling()
            print("Fluffel fell off edge")
        }
    }
    
    func moveFluffel(direction: Direction) {
        guard let fluffel = fluffel else { return }
        
        // 如果 Fluffel 在边缘上，先离开边缘
        if fluffel.isOnEdge {
            fluffel.leaveEdge()
            isFollowingEdge = false
        }
        
        let currentTime = CACurrentMediaTime()
        // 添加小延迟避免移动过快
        if currentTime - lastMoveTime < moveDelay {
            return
        }
        lastMoveTime = currentTime
        
        // 设置移动状态
        if fluffel.state == .idle {
            fluffel.setState(.moving)
        }
        
        // 增加移动距离，使移动更明显
        let moveDistance: CGFloat = 8.0
        
        // 临时保存当前位置，以便在越界时恢复
        let originalPosition = fluffel.position
        
        // 根据方向移动 Fluffel
        switch direction {
        case .left:
            fluffel.position.x -= moveDistance
            turnFluffelToFace(direction: .left)
        case .right:
            fluffel.position.x += moveDistance
            turnFluffelToFace(direction: .right)
        case .up:
            fluffel.position.y += moveDistance
        case .down:
            fluffel.position.y -= moveDistance
        }
        
        // 检查边界，确保Fluffel不会移出屏幕
        let fluffelSize = fluffel.size
        let padding: CGFloat = 10.0  // 边缘安全距离
        
        // 检查是否超出场景边界
        if fluffel.position.x < fluffelSize.width/2 + padding || 
           fluffel.position.x > size.width - fluffelSize.width/2 - padding ||
           fluffel.position.y < fluffelSize.height/2 + padding || 
           fluffel.position.y > size.height - fluffelSize.height/2 - padding {
            // 如果超出边界，恢复到原始位置
            fluffel.position = originalPosition
            print("Fluffel 到达屏幕边界，无法再移动")
        }
        
        // 重置无聊计时器，因为有移动发生
        lastActivityTime = CACurrentMediaTime()
        
        // 移动后发送通知，以便窗口控制器可以跟随 Fluffel 移动
        NotificationCenter.default.post(name: .fluffelDidMove, object: self)
    }
    
    // 启动下落动画
    func startFalling() {
        guard let fluffel = fluffel, fluffel.state != .falling else { return }
        
        // 确保重置边缘跟随状态
        isFollowingEdge = false
        
        fluffel.setState(.falling)
        
        // 重置无聊计时器，因为有下落发生
        lastActivityTime = CACurrentMediaTime()
    }
    
    // 获取 Fluffel 当前位置
    func getFluffelPosition() -> CGPoint? {
        return fluffel?.position
    }
    
    // 获取 Fluffel 的实际大小
    func getFluffelSize() -> CGSize? {
        return fluffel?.size
    }
    
    // 获取 Fluffel 全局坐标
    func getFluffelGlobalPosition() -> CGPoint? {
        return lastKnownGlobalPosition
    }
    
    // 让 Fluffel 朝向移动方向
    private func turnFluffelToFace(direction: Direction) {
        guard let fluffel = fluffel else { return }
        
        // 简单的左右翻转效果
        switch direction {
        case .left:
            fluffel.xScale = -1.0 // 镜像翻转
        case .right:
            fluffel.xScale = 1.0 // 正常方向
        default:
            break // 上下移动不改变朝向
        }
    }
    
    // 启用或禁用边缘检测
    func setEdgeDetectionEnabled(_ enabled: Bool) {
        isEdgeDetectionEnabled = enabled
    }
    
    // 设置边缘检测的容差
    func setEdgeDetectionTolerance(_ tolerance: CGFloat) {
        edgeDetectionTolerance = tolerance
    }
    
    // 在这里添加鼠标点击处理
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        // 如果已经在说话中，忽略此次点击
        if isSpeakingInProgress {
            print("Fluffel正在说话，忽略重复点击")
            return
        }
        
        // 将鼠标位置转换到场景坐标系
        let location = event.location(in: self)
        
        // 检测是否点击了 Fluffel
        if let fluffel = fluffel, fluffel.contains(location) {
            // 设置标志，防止重复触发
            isSpeakingInProgress = true
            
            // 取消可能存在的定时器
            speakingDebounceTimer?.invalidate()
            
            // 使用我们创建的说话演示
            if let appDelegate = NSApp.delegate as? AppDelegate {
                // 随机选择一个动作：问候、笑话或事实
                let action = Int.random(in: 0...2)
                switch action {
                case 0:
                    appDelegate.speakingDemo?.speakRandomGreeting()
                case 1:
                    appDelegate.speakingDemo?.tellRandomJoke()
                case 2:
                    appDelegate.speakingDemo?.shareRandomFact()
                default:
                    makeFluffelSpeak() // 使用原有的方法作为后备
                }
            } else {
                // 如果找不到 AppDelegate，仍然使用原有的方法
                makeFluffelSpeak()
            }
            
            // 设置定时器，延迟清除标志
            speakingDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                self?.isSpeakingInProgress = false
            }
        }
        
        // 更新最后活动时间
        lastActivityTime = CACurrentMediaTime()
    }
    
    // 让 Fluffel 说话
    func makeFluffelSpeak(_ text: String? = nil) {
        guard let fluffel = fluffel else { return }
        
        // 如果正在说话中，不要再触发新的说话
        if isSpeakingInProgress {
            return
        }
        
        // 设置标志，防止重复触发
        isSpeakingInProgress = true
        
        // 如果没有指定文本，随机选择一句问候语
        let speechText = text ?? boredGreetings.randomElement() ?? "你好！"
        
        // 根据文本长度调整显示时间
        let duration = min(max(TimeInterval(speechText.count) * 0.15, 2.0), 5.0)
        
        // 让 Fluffel 说话
        fluffel.speak(text: speechText, duration: duration) { [weak self] in
            // 说话结束后重置标志
            self?.isSpeakingInProgress = false
        }
        
        // 设置安全计时器，以防说话完成回调未被调用
        speakingDebounceTimer?.invalidate()
        speakingDebounceTimer = Timer.scheduledTimer(withTimeInterval: duration + 1.0, repeats: false) { [weak self] _ in
            self?.isSpeakingInProgress = false
        }
    }
    
    // 将 Fluffel 重置到第一屏中心
    func resetFluffelToCenter() {
        guard let fluffel = fluffel else { return }
        
        // 停止任何当前动画或状态
        if fluffel.state != .idle {
            fluffel.setState(.idle)
        }
        
        // 确保不在边缘上
        if fluffel.isOnEdge {
            fluffel.leaveEdge()
            isFollowingEdge = false
        }
        
        // 创建移动到中心的动画
        let centerPoint = CGPoint(x: size.width / 2, y: size.height / 2)
        let moveAction = SKAction.move(to: centerPoint, duration: 0.5)
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.3)
        let rotateAction = SKAction.rotate(toAngle: 0, duration: 0.3)
        
        // 组合动画
        let groupAction = SKAction.group([moveAction, scaleAction, rotateAction])
        
        // 添加一个小小的弹跳效果
        let bounceUp = SKAction.moveBy(x: 0, y: 10, duration: 0.1)
        let bounceDown = SKAction.moveBy(x: 0, y: -10, duration: 0.1)
        let bounceAction = SKAction.sequence([bounceUp, bounceDown])
        
        // 让 Fluffel 执行动画序列
        fluffel.run(SKAction.sequence([groupAction, bounceAction]))
        
        // 让 Fluffel 说话，表明它已经回到中心
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.makeFluffelSpeak("I'm back!")
        }
        
        // 重置朝向为右侧
        fluffel.xScale = abs(fluffel.xScale)
        
        // 更新最后活动时间
        lastActivityTime = CACurrentMediaTime()
        
        // 发送移动通知
        NotificationCenter.default.post(name: .fluffelDidMove, object: self)
        
        print("Fluffel 已重置到屏幕中心")
    }
} 
