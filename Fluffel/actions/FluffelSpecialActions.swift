import SpriteKit

// Fluffel 的特殊状态动画扩展
extension Fluffel {
    
    // MARK: - 说话功能
    
    /// 让 Fluffel 说话，显示一个带有文本的气泡
    /// - Parameters:
    ///   - text: 要显示的文本
    ///   - duration: 气泡显示的时间 (默认 3 秒)
    ///   - fontSize: 文本大小 (默认 12)
    ///   - completion: 说话完成后的回调 (可选)
    func speak(text: String, duration: TimeInterval = 3.0, fontSize: CGFloat = 12, completion: (() -> Void)? = nil) {
        // 移除可能存在的旧气泡
        removeSpeechBubble()
        
        // 创建气泡节点
        let bubble = createSpeechBubble(withText: text, fontSize: fontSize)
        
        // 计算气泡的边界，用于扩大窗口
        let bubbleFrame = bubble.calculateAccumulatedFrame()
        
        // 发送通知，让窗口控制器知道需要更多空间用于气泡
        NotificationCenter.default.post(
            name: NSNotification.Name("fluffelWillSpeak"), 
            object: self,
            userInfo: ["bubbleHeight": bubbleFrame.height + 10]
        )
        
        // 添加气泡到Fluffel
        addChild(bubble)
        
        // 淡入动画
        bubble.alpha = 0
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        
        // 保持显示
        let wait = SKAction.wait(forDuration: duration)
        
        // 淡出动画
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        
        // 移除气泡
        let remove = SKAction.run { [weak self] in
            bubble.removeFromParent()
            
            // 发送通知，让窗口控制器知道气泡已被移除
            NotificationCenter.default.post(name: NSNotification.Name("fluffelDidStopSpeaking"), object: self)
            
            // 执行完成回调
            completion?()
        }
        
        // 添加一些小动画，让气泡看起来更活跃
        let bobUp = SKAction.moveBy(x: 0, y: 2, duration: 0.3)
        let bobDown = SKAction.moveBy(x: 0, y: -2, duration: 0.3)
        let bobSequence = SKAction.sequence([bobUp, bobDown])
        let bobRepeat = SKAction.repeat(bobSequence, count: Int(duration / 0.6) + 1)
        
        // 执行淡入、显示、淡出的序列
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
        bubble.run(sequence, withKey: "speechAction")
        bubble.run(bobRepeat, withKey: "bobAction")
        
        // 添加一些表情变化，使 Fluffel 看起来像在说话
        animateTalkingExpression(duration: duration)
    }
    
    /// 创建一个带有文本的气泡
    private func createSpeechBubble(withText text: String, fontSize: CGFloat) -> SKNode {
        // 创建容器节点
        let container = SKNode()
        container.name = "speechBubble"
        container.zPosition = 10
        
        // 计算文本大小
        let label = SKLabelNode(text: text)
        label.fontName = "Helvetica"
        label.fontSize = fontSize
        label.fontColor = NSColor.black
        
        // 测量文本大小，以便适当调整气泡大小
        let textWidth = text.size(withAttributes: [.font: NSFont.systemFont(ofSize: fontSize)]).width
        let bubbleWidth = max(textWidth + 20, 50)
        let bubbleHeight = fontSize + 16
        
        // 创建气泡背景
        let bubblePath = CGMutablePath()
        let bubbleRect = CGRect(x: -bubbleWidth/2, y: -bubbleHeight/2 - 2, width: bubbleWidth, height: bubbleHeight)
        bubblePath.addRoundedRect(in: bubbleRect, cornerWidth: 10, cornerHeight: 10)
        
        // 添加指向 Fluffel 的小尖角
        bubblePath.move(to: CGPoint(x: -5, y: -bubbleHeight/2))
        bubblePath.addLine(to: CGPoint(x: 0, y: -bubbleHeight/2 - 10))
        bubblePath.addLine(to: CGPoint(x: 5, y: -bubbleHeight/2))
        
        let bubble = SKShapeNode(path: bubblePath)
        bubble.fillColor = NSColor.white
        bubble.strokeColor = NSColor.gray
        bubble.lineWidth = 1.0
        
        // 定位气泡在 Fluffel 上方
        container.position = CGPoint(x: 0, y: 40)
        
        // 定位和添加文本
        label.position = CGPoint(x: 0, y: -2)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        // 组装气泡
        container.addChild(bubble)
        container.addChild(label)
        
        return container
    }
    
    /// 移除当前的对话气泡
    func removeSpeechBubble() {
        // 查找并移除名为 "speechBubble" 的子节点
        var didRemoveBubble = false
        self.children.forEach { node in
            if node.name == "speechBubble" {
                node.removeFromParent()
                didRemoveBubble = true
            }
        }
        
        // 如果确实移除了气泡，发送通知让窗口控制器知道气泡已被移除
        if didRemoveBubble {
            NotificationCenter.default.post(name: NSNotification.Name("fluffelDidStopSpeaking"), object: self)
        }
        
        // 停止说话动画
        removeAction(forKey: "talkingAction")
        
        // 恢复正常表情
        resetFacialExpression()
    }
    
    /// 当 Fluffel 说话时的表情动画
    private func animateTalkingExpression(duration: TimeInterval) {
        // 保存当前的嘴巴路径以便之后恢复
        let currentMouthPath = mouth.path
        
        // 创建说话动画序列
        let openMouth = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 张开嘴巴的路径
            let openMouthPath = CGMutablePath()
            openMouthPath.addEllipse(in: CGRect(x: -5, y: -10, width: 10, height: 5))
            self.mouth.path = openMouthPath
        }
        
        let closeMouth = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 闭上嘴巴的路径 - 只是一条短线
            let closeMouthPath = CGMutablePath()
            closeMouthPath.move(to: CGPoint(x: -5, y: -8))
            closeMouthPath.addLine(to: CGPoint(x: 5, y: -8))
            self.mouth.path = closeMouthPath
        }
        
        // 创建一个说话动画序列
        let talkSequence = SKAction.sequence([
            openMouth,
            SKAction.wait(forDuration: 0.1),
            closeMouth,
            SKAction.wait(forDuration: 0.1)
        ])
        
        // 根据持续时间计算需要重复的次数
        let repeatCount = Int(duration / 0.2)
        
        // 重复说话动画
        let repeatTalk = SKAction.repeat(talkSequence, count: repeatCount)
        
        // 结束后恢复原始表情
        let restoreMouth = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.mouth.path = currentMouthPath
        }
        
        // 执行完整序列
        let fullSequence = SKAction.sequence([repeatTalk, restoreMouth])
        run(fullSequence, withKey: "talkingAction")
        
        // 偶尔眨眨眼睛，看起来更自然
        let randomBlink = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.happyBlink()
        }
        
        let waitForBlink = SKAction.wait(forDuration: 1.0)
        let blinkSequence = SKAction.sequence([waitForBlink, randomBlink])
        let blinkRepeat = SKAction.repeat(blinkSequence, count: Int(duration / 1.0))
        
        run(blinkRepeat, withKey: "blinkWhileTalking")
    }
    
    /// 重置面部表情到正常状态
    private func resetFacialExpression() {
        removeAction(forKey: "blinkWhileTalking")
        
        // 恢复正常表情
        smile()
    }
    
    // MARK: - 睡眠动画
    
    // 睡眠动画 - 模拟 Fluffel 睡觉
    func startSleepingAnimation() {
        // 移除可能正在进行的其他动画
        removeAction(forKey: "walkingAction")
        removeAction(forKey: "fallingAction")
        removeAction(forKey: "dancingAction")
        removeAction(forKey: "excitedAction")
        // 移除说话相关的动画
        removeSpeechBubble()
        
        // 创建睡眠表情
        let sleepyEyesAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 闭上眼睛
            self.leftEye.setScale(0.1)
            self.rightEye.setScale(0.1)
            
            // 睡觉时的嘴巴表情 - 轻微张开
            let sleepyMouthPath = CGMutablePath()
            sleepyMouthPath.move(to: CGPoint(x: -5, y: -8))
            sleepyMouthPath.addQuadCurve(to: CGPoint(x: 5, y: -8), control: CGPoint(x: 0, y: -6))
            self.mouth.path = sleepyMouthPath
        }
        
        // 创建"Z"字符动画表示睡眠
        let createZs = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 创建三个Z字符，大小不同
            for i in 0..<3 {
                let zSize = CGFloat(10 + i * 2) // 逐渐增大的Z
                let zNode = SKLabelNode(text: "Z")
                zNode.fontSize = zSize
                zNode.fontColor = NSColor(calibratedRed: 0.6, green: 0.6, blue: 1.0, alpha: 0.8)
                zNode.position = CGPoint(x: 20 + CGFloat(i * 5), y: 15 + CGFloat(i * 5))
                zNode.zPosition = 5
                self.addChild(zNode)
                
                // Z字符上升并淡出的动画
                let moveUp = SKAction.moveBy(x: 15, y: 20, duration: 2.0)
                let fadeOut = SKAction.fadeOut(withDuration: 2.0)
                let group = SKAction.group([moveUp, fadeOut])
                let remove = SKAction.removeFromParent()
                let sequence = SKAction.sequence([group, remove])
                
                zNode.run(sequence)
            }
        }
        
        // 轻微的呼吸动作
        let breatheIn = SKAction.scale(to: 1.05, duration: 1.0)
        let breatheOut = SKAction.scale(to: 0.95, duration: 1.0)
        let breatheCycle = SKAction.sequence([breatheIn, breatheOut])
        let breatheAction = SKAction.repeatForever(breatheCycle)
        
        // 组合所有动作
        let sleepSequence = SKAction.sequence([
            sleepyEyesAction,
            SKAction.wait(forDuration: 1.0),
            createZs,
            SKAction.wait(forDuration: 3.0)
        ])
        
        let sleepCycle = SKAction.repeatForever(sleepSequence)
        
        // 运行动画
        run(breatheAction, withKey: "breathingSleep")
        run(sleepCycle, withKey: "sleepingAction")
    }
    
    // 停止睡眠动画
    func stopSleepingAnimation() {
        // 移除睡眠相关动画
        removeAction(forKey: "sleepingAction")
        removeAction(forKey: "breathingSleep")
        
        // 移除所有Z字符
        self.children.forEach { node in
            if let label = node as? SKLabelNode, label.text == "Z" {
                label.removeFromParent()
            }
        }
        
        // 恢复正常表情
        leftEye.setScale(1.0)
        rightEye.setScale(1.0)
        smile()
    }
    
    // 开始跳舞动画
    func startDancingAnimation() {
        // 移除可能正在进行的其他动画
        removeAction(forKey: "walkingAction")
        removeAction(forKey: "fallingAction")
        removeAction(forKey: "sleepingAction")
        removeAction(forKey: "excitedAction")
        
        // 创建开心表情
        let happyFaceAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 大眼睛
            self.leftEye.setScale(1.2)
            self.rightEye.setScale(1.2)
            
            // 大笑的嘴巴
            let bigSmilePath = CGMutablePath()
            bigSmilePath.move(to: CGPoint(x: -8, y: -8))
            bigSmilePath.addQuadCurve(to: CGPoint(x: 8, y: -8), control: CGPoint(x: 0, y: -16))
            self.mouth.path = bigSmilePath
        }
        
        // 创建跳舞动作序列
        let jump1 = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 10, duration: 0.2),
            SKAction.moveBy(x: 0, y: -10, duration: 0.2)
        ])
        
        let spin = SKAction.sequence([
            SKAction.rotate(byAngle: CGFloat.pi, duration: 0.4),
            SKAction.rotate(byAngle: CGFloat.pi, duration: 0.4)
        ])
        
        let sideStep = SKAction.sequence([
            SKAction.moveBy(x: 10, y: 0, duration: 0.2),
            SKAction.moveBy(x: -20, y: 0, duration: 0.4),
            SKAction.moveBy(x: 10, y: 0, duration: 0.2)
        ])
        
        // 身体变形动画
        let bodyStretch = SKAction.sequence([
            SKAction.scaleX(to: 0.8, y: 1.2, duration: 0.2),
            SKAction.scaleX(to: 1.2, y: 0.8, duration: 0.2),
            SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.2)
        ])
        
        // 组合舞蹈动作
        let danceSequence = SKAction.sequence([
            happyFaceAction,
            jump1,
            bodyStretch,
            sideStep,
            spin,
            SKAction.wait(forDuration: 0.5)
        ])
        
        let danceCycle = SKAction.repeatForever(danceSequence)
        
        // 运行动画
        run(danceCycle, withKey: "dancingAction")
        
        // 添加音符效果
        let createNotes = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 创建音符
            let noteSymbols = ["♪", "♫", "♬", "♩"]
            let noteColors: [NSColor] = [
                NSColor(calibratedRed: 1.0, green: 0.5, blue: 0.5, alpha: 0.8),
                NSColor(calibratedRed: 0.5, green: 1.0, blue: 0.5, alpha: 0.8),
                NSColor(calibratedRed: 0.5, green: 0.5, blue: 1.0, alpha: 0.8),
                NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.5, alpha: 0.8)
            ]
            
            // 随机选择音符和颜色
            let randomIndex = Int.random(in: 0..<noteSymbols.count)
            let noteNode = SKLabelNode(text: noteSymbols[randomIndex])
            noteNode.fontSize = 20
            noteNode.fontColor = noteColors[Int.random(in: 0..<noteColors.count)]
            
            // 随机位置
            let randomOffset = CGFloat.random(in: -20...20)
            noteNode.position = CGPoint(x: randomOffset, y: 20)
            noteNode.zPosition = 5
            self.addChild(noteNode)
            
            // 音符上升并旋转淡出的动画
            let moveUp = SKAction.moveBy(x: CGFloat.random(in: -30...30), y: 40, duration: 1.5)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -CGFloat.pi...CGFloat.pi), duration: 1.5)
            let fadeOut = SKAction.fadeOut(withDuration: 1.5)
            let group = SKAction.group([moveUp, rotate, fadeOut])
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([group, remove])
            
            noteNode.run(sequence)
        }
        
        // 定期创建音符
        let noteSequence = SKAction.sequence([
            createNotes,
            SKAction.wait(forDuration: 0.5)
        ])
        
        run(SKAction.repeatForever(noteSequence), withKey: "musicNotes")
    }
    
    // 停止跳舞动画
    func stopDancingAnimation() {
        // 移除跳舞相关动画
        removeAction(forKey: "dancingAction")
        removeAction(forKey: "musicNotes")
        
        // 移除所有音符
        self.children.forEach { node in
            if let label = node as? SKLabelNode, ["♪", "♫", "♬", "♩"].contains(label.text ?? "") {
                label.removeFromParent()
            }
        }
        
        // 恢复正常表情和姿态
        leftEye.setScale(1.0)
        rightEye.setScale(1.0)
        self.xScale = 1.0
        self.yScale = 1.0
        self.zRotation = 0
        smile()
    }
    
    // 开始兴奋动画
    func startExcitedAnimation() {
        // 移除可能正在进行的其他动画
        removeAction(forKey: "walkingAction")
        removeAction(forKey: "fallingAction")
        removeAction(forKey: "sleepingAction")
        removeAction(forKey: "dancingAction")
        
        // 创建兴奋表情
        let excitedFaceAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 大眼睛，瞳孔放大
            self.leftEye.setScale(1.3)
            self.rightEye.setScale(1.3)
            
            // 惊喜的嘴巴 - 大大的笑容
            let excitedMouthPath = CGMutablePath()
            excitedMouthPath.move(to: CGPoint(x: -10, y: -8))
            excitedMouthPath.addQuadCurve(to: CGPoint(x: 10, y: -8), control: CGPoint(x: 0, y: -18))
            self.mouth.path = excitedMouthPath
            self.mouth.fillColor = NSColor(calibratedRed: 0.9, green: 0.5, blue: 0.5, alpha: 0.3)
        }
        
        // 创建兴奋动作 - 快速跳跃和旋转
        let quickJump = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 15, duration: 0.1),
            SKAction.moveBy(x: 0, y: -15, duration: 0.1)
        ])
        
        // 身体快速变形
        let quickPulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        
        // 耳朵快速摆动
        let quickEarWiggle = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            let leftWiggle = SKAction.sequence([
                SKAction.rotate(byAngle: 0.2, duration: 0.1),
                SKAction.rotate(byAngle: -0.4, duration: 0.2),
                SKAction.rotate(byAngle: 0.2, duration: 0.1)
            ])
            
            let rightWiggle = SKAction.sequence([
                SKAction.rotate(byAngle: -0.2, duration: 0.1),
                SKAction.rotate(byAngle: 0.4, duration: 0.2),
                SKAction.rotate(byAngle: -0.2, duration: 0.1)
            ])
            
            self.leftEar.run(SKAction.repeat(leftWiggle, count: 3))
            self.rightEar.run(SKAction.repeat(rightWiggle, count: 3))
        }
        
        // 创建星星效果
        let createStars = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 创建3-5个星星
            let starCount = Int.random(in: 3...5)
            for _ in 0..<starCount {
                let starNode = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
                
                // 创建星形路径
                let starPath = CGMutablePath()
                let centerX: CGFloat = 0
                let centerY: CGFloat = 0
                let radius: CGFloat = 5
                
                for i in 0..<10 {
                    let angle = CGFloat(i) * .pi / 5
                    let r = i % 2 == 0 ? radius : radius / 2
                    let x = centerX + r * cos(angle)
                    let y = centerY + r * sin(angle)
                    
                    if i == 0 {
                        starPath.move(to: CGPoint(x: x, y: y))
                    } else {
                        starPath.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                starPath.closeSubpath()
                
                starNode.path = starPath
                starNode.fillColor = NSColor(calibratedRed: 1.0, green: 0.9, blue: 0.4, alpha: 0.8)
                starNode.strokeColor = NSColor(calibratedRed: 1.0, green: 0.8, blue: 0.0, alpha: 0.8)
                
                // 随机位置
                let randomAngle = CGFloat.random(in: 0...(2 * .pi))
                let randomDistance = CGFloat.random(in: 30...50)
                let x = cos(randomAngle) * randomDistance
                let y = sin(randomAngle) * randomDistance
                starNode.position = CGPoint(x: x, y: y)
                starNode.zPosition = 5
                self.addChild(starNode)
                
                // 星星闪烁并消失的动画
                let scaleUp = SKAction.scale(to: 1.5, duration: 0.3)
                let scaleDown = SKAction.scale(to: 0.5, duration: 0.3)
                let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                let sequence = SKAction.sequence([scaleUp, scaleDown, fadeOut, SKAction.removeFromParent()])
                
                starNode.run(sequence)
            }
        }
        
        // 组合兴奋动作
        let excitedSequence = SKAction.sequence([
            excitedFaceAction,
            quickPulse,
            quickJump,
            quickEarWiggle,
            createStars,
            SKAction.wait(forDuration: 0.5)
        ])
        
        let excitedCycle = SKAction.repeatForever(excitedSequence)
        
        // 运行动画
        run(excitedCycle, withKey: "excitedAction")
    }
    
    // 停止兴奋动画
    func stopExcitedAnimation() {
        // 移除兴奋相关动画
        removeAction(forKey: "excitedAction")
        
        // 移除所有星星
        self.children.forEach { node in
            if let shapeNode = node as? SKShapeNode,
                node != body && node != leftEye && node != rightEye &&
                node != mouth && node != leftCheek && node != rightCheek &&
                node != leftEar && node != rightEar && node != glowEffect {
                node.removeFromParent()
            }
        }
        
        // 恢复正常表情和姿态
        leftEye.setScale(1.0)
        rightEye.setScale(1.0)
        mouth.fillColor = .clear
        self.xScale = 1.0
        self.yScale = 1.0
        smile()
    }
} 