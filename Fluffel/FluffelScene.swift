import SpriteKit

// 删除不再使用的Direction枚举，使用FluffelTypes.swift中的MovementDirection代替
// enum Direction {
//     case left, right, up, down
// }

// 添加一个通知名称，用于通知窗口 Fluffel 已移动
extension Notification.Name {
    static let fluffelDebugInfo = Notification.Name("fluffelDebugInfo") // 添加调试信息通知
}

class FluffelScene: SKScene {
    
    var fluffel: Fluffel?
    private var lastMoveTime: TimeInterval = 0
    private var moveDelay: TimeInterval = 0.01 // 控制移动流畅度
    
    // 无聊状态相关
    private var lastActivityTime: TimeInterval = 0
    private let boredThreshold: TimeInterval = 10.0 // 10秒无活动后触发无聊状态
    private var isCheckingBoredom = false
    
    // 添加一个防止重复触发说话功能的标志
    private var isSpeakingInProgress = false
    private var speakingDebounceTimer: Timer?
    
    // 调试状态
    private var isDebugMode = false
    
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
            
            // 添加一个短暂的延迟，然后让 Fluffel 眨眼，显得更加活泼
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                fluffel.happyBlink()
                print("Fluffel 完成眨眼动画")
            }
            
            print("Fluffel 已添加到场景，位置: \(fluffel.position)")
            
            // 为初次问候设置更长的延迟，确保窗口和Fluffel已完全准备好
            // 这样可以避免在初始化动画过程中出现问题
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // 发送一个窗口调整通知，确保Fluffel窗口有足够空间
                NotificationCenter.default.post(name: .fluffelDidMove, object: self)
                
                // 再等待一小段时间，确保窗口调整完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.makeFluffelSpeak("你好！我是 Fluffel！")
                }
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
        
        // 检查无聊状态
        checkBoredom(currentTime: currentTime)
    }
    
    // 检查是否进入无聊状态
    private func checkBoredom(currentTime: TimeInterval) {
        guard let fluffel = fluffel else { return }
        
        // 只有在正常状态下才检查无聊
        guard fluffel.state != .falling else {
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
    
    // 启动下落动画
    func startFalling() {
        guard let fluffel = fluffel, fluffel.state != .falling else { return }
        
        fluffel.setState(.falling)
        
        // 重置无聊计时器，因为有下落发生
        lastActivityTime = CACurrentMediaTime()
    }
    
    func moveFluffel(direction: MovementDirection) {
        guard let fluffel = fluffel else { return }
        
        // 如果 Fluffel 在边缘上，先离开边缘
        if fluffel.isOnEdge {
            fluffel.leaveEdge()
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
        
        // 简单的边界检查，确保Fluffel不会移出场景
        let fluffelSize = fluffel.size
        let padding: CGFloat = 10.0  // 边缘安全距离
        
        if fluffel.position.x < fluffelSize.width/2 + padding || 
           fluffel.position.x > size.width - fluffelSize.width/2 - padding ||
           fluffel.position.y < fluffelSize.height/2 + padding || 
           fluffel.position.y > size.height - fluffelSize.height/2 - padding {
            // 如果超出边界，恢复到原始位置
            fluffel.position = originalPosition
            print("Fluffel 到达场景边界")
        }
        
        // 重置无聊计时器，因为有移动发生
        lastActivityTime = CACurrentMediaTime()
        
        // 移动后发送通知，以便窗口控制器可以跟随 Fluffel 移动
        NotificationCenter.default.post(name: .fluffelDidMove, object: self)
    }
    
    // 获取 Fluffel 当前位置
    func getFluffelPosition() -> CGPoint? {
        return fluffel?.position
    }
    
    // 获取 Fluffel 的实际大小
    func getFluffelSize() -> CGSize? {
        return fluffel?.size
    }
    
    // 让 Fluffel 朝向移动方向
    private func turnFluffelToFace(direction: MovementDirection) {
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
    
    // 在这里添加鼠标点击处理
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        
        // 更健壮的 Fluffel 存在性检查
        guard let fluffel = fluffel else { return }
        
        // 确保点击在 Fluffel 上
        if fluffel.contains(location) {
            // 在主线程中安全地处理点击操作
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // 使用场景的isSpeakingInProgress标志而不是局部标志
                // 如果正在说话中，不要再触发新的说话
                if self.isSpeakingInProgress {
                    return
                }
                
                // 设置标志，防止重复触发
                self.isSpeakingInProgress = true
                
                // 取消可能存在的定时器
                self.speakingDebounceTimer?.invalidate()
                
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
                        self.makeFluffelSpeak() // 使用原有的方法作为后备
                    }
                } else {
                    // 如果找不到 AppDelegate，仍然使用原有的方法
                    self.makeFluffelSpeak()
                }
                
                // 设置定时器，延迟清除标志
                self.speakingDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                    self?.isSpeakingInProgress = false
                }
            }
        }
        
        // 更新最后活动时间
        lastActivityTime = CACurrentMediaTime()
    }
    
    // 让 Fluffel 说话
    func makeFluffelSpeak(_ text: String? = nil) {
        // 在主线程中安全地执行说话逻辑
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let fluffel = self.fluffel else { return }
            
            // 如果正在说话中，不要再触发新的说话
            if self.isSpeakingInProgress {
                return
            }
            
            // 设置标志，防止重复触发
            self.isSpeakingInProgress = true
            
            // 如果没有指定文本，随机选择一句问候语
            let speechText = text ?? FluffelDialogues.shared.getRandomBoredGreeting()
            
            // 根据文本长度调整显示时间
            let duration = min(max(TimeInterval(speechText.count) * 0.15, 2.0), 5.0)
            
            // 让 Fluffel 说话
            fluffel.speak(text: speechText, duration: duration) { [weak self] in
                // 说话结束后重置标志
                DispatchQueue.main.async {
                    self?.isSpeakingInProgress = false
                }
            }
            
            // 设置安全计时器，以防说话完成回调未被调用
            self.speakingDebounceTimer?.invalidate()
            self.speakingDebounceTimer = Timer.scheduledTimer(withTimeInterval: duration + 1.0, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isSpeakingInProgress = false
                }
            }
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
    
    // 设置调试模式
    func setDebugMode(_ enabled: Bool) {
        isDebugMode = enabled
    }
} 
