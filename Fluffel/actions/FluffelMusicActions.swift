import SpriteKit
import AVFoundation

// Fluffel 的音乐相关动作扩展
extension Fluffel {
    
    // MARK: - 听音乐动画
    
    /// 开始听音乐动画
    func startListeningToMusicAnimation() {
        // 移除其他可能正在进行的动画
        removeAction(forKey: "walkingAction")
        removeAction(forKey: "fallingAction")
        removeAction(forKey: "sleepingAction")
        removeAction(forKey: "dancingAction")
        removeAction(forKey: "excitedAction")
        
        // 移除任何显示的对话气泡
        removeSpeechBubble()
        
        // 设置状态
        setState(.listeningToMusic)
        
        // 创建愉悦表情
        let happyFaceAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 稍微更大的眼睛，显示愉悦
            self.leftEye.setScale(1.1)
            self.rightEye.setScale(1.1)
            
            // 微笑表情，但不同于普通微笑
            let enjoyingMusicMouthPath = CGMutablePath()
            enjoyingMusicMouthPath.move(to: CGPoint(x: -7, y: -8))
            enjoyingMusicMouthPath.addQuadCurve(to: CGPoint(x: 7, y: -8), control: CGPoint(x: 0, y: -13))
            self.mouth.path = enjoyingMusicMouthPath
        }
        
        // 头部随节奏轻微摇摆的动画
        let headBobSequence = SKAction.sequence([
            SKAction.rotate(byAngle: 0.1, duration: 0.3),
            SKAction.rotate(byAngle: -0.2, duration: 0.6),
            SKAction.rotate(byAngle: 0.1, duration: 0.3)
        ])
        
        // 身体随音乐波动的动画
        let bodyBopSequence = SKAction.sequence([
            SKAction.scaleY(to: 1.05, duration: 0.3),
            SKAction.scaleY(to: 0.95, duration: 0.3),
            SKAction.scaleY(to: 1.0, duration: 0.3)
        ])
        
        // 耳朵随节奏抖动的动画
        let earsWiggleAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 左耳动画
            let leftEarWiggle = SKAction.sequence([
                SKAction.rotate(byAngle: 0.1, duration: 0.2),
                SKAction.rotate(byAngle: -0.1, duration: 0.2)
            ])
            self.leftEar.run(SKAction.repeatForever(leftEarWiggle))
            
            // 右耳动画
            let rightEarWiggle = SKAction.sequence([
                SKAction.rotate(byAngle: -0.1, duration: 0.2),
                SKAction.rotate(byAngle: 0.1, duration: 0.2)
            ])
            self.rightEar.run(SKAction.repeatForever(rightEarWiggle))
        }
        
        // 组合动画动作
        let setupAction = SKAction.run { [weak self] in
            happyFaceAction.duration = 0
            self?.run(happyFaceAction)
            self?.run(earsWiggleAction)
        }
        
        let musicListeningSequence = SKAction.sequence([
            setupAction,
            SKAction.group([
                headBobSequence,
                bodyBopSequence
            ])
        ])
        
        // 循环执行动画
        run(SKAction.repeatForever(musicListeningSequence), withKey: "listeningToMusicAction")
        
        // 添加音符特效
        let createNotes = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            // 创建音符
            let noteSymbols = ["♪", "♫", "♬", "♩"]
            let noteColors: [NSColor] = [
                NSColor(calibratedRed: 0.4, green: 0.4, blue: 1.0, alpha: 0.8), // 蓝色
                NSColor(calibratedRed: 0.5, green: 0.8, blue: 1.0, alpha: 0.8), // 天蓝色
                NSColor(calibratedRed: 0.8, green: 0.4, blue: 1.0, alpha: 0.8), // 紫色
                NSColor(calibratedRed: 0.4, green: 0.8, blue: 0.6, alpha: 0.8)  // 蓝绿色
            ]
            
            // 随机选择音符和颜色
            let randomIndex = Int.random(in: 0..<noteSymbols.count)
            let noteNode = SKLabelNode(text: noteSymbols[randomIndex])
            noteNode.fontSize = 16
            noteNode.fontColor = noteColors[Int.random(in: 0..<noteColors.count)]
            
            // 从Fluffel的耳朵附近生成音符
            let side = Bool.random() ? 1.0 : -1.0 // 随机左右耳
            let randomX = side * CGFloat.random(in: 15...25)
            let randomY = CGFloat.random(in: 15...30)
            noteNode.position = CGPoint(x: randomX, y: randomY)
            noteNode.zPosition = 5
            noteNode.alpha = 0
            self.addChild(noteNode)
            
            // 音符淡入，向上漂移，然后淡出的动画
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            let moveUp = SKAction.moveBy(x: CGFloat.random(in: -10...10), y: 30, duration: 1.5)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -CGFloat.pi/4...CGFloat.pi/4), duration: 1.5)
            let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.5)
            let group = SKAction.sequence([
                fadeIn,
                SKAction.group([moveUp, rotate]),
                fadeOut
            ])
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([group, remove])
            
            noteNode.run(sequence)
        }
        
        // 定期创建音符，频率比跳舞时更低
        let noteSequence = SKAction.sequence([
            createNotes,
            SKAction.wait(forDuration: 0.8)
        ])
        
        run(SKAction.repeatForever(noteSequence), withKey: "musicListeningNotes")
        
        // 发送开始播放音乐的通知，供外部组件使用
        NotificationCenter.default.post(name: .fluffelWillPlayMusic, object: self)
    }
    
    /// 停止听音乐动画
    func stopListeningToMusicAnimation() {
        // 移除听音乐相关动画
        removeAction(forKey: "listeningToMusicAction")
        removeAction(forKey: "musicListeningNotes")
        
        // 停止耳朵抖动
        leftEar.removeAllActions()
        rightEar.removeAllActions()
        
        // 移除所有音符
        children.forEach { node in
            if let label = node as? SKLabelNode, ["♪", "♫", "♬", "♩"].contains(label.text ?? "") {
                label.removeFromParent()
            }
        }
        
        // 恢复正常外观
        leftEye.setScale(1.0)
        rightEye.setScale(1.0)
        xScale = 1.0
        yScale = 1.0
        zRotation = 0
        
        // 恢复正常表情
        smile()
        
        // 更新状态
        setState(.idle)
        
        // 发送停止音乐的通知，供外部组件使用
        NotificationCenter.default.post(name: .fluffelDidStopMusic, object: self)
    }
    
    // MARK: - 音乐播放器准备
    
    // 音乐播放器属性（准备将来实现）
    private static var musicPlayer: AVAudioPlayer?
    private static var musicTimer: Timer?
    
    /// 准备将来实现的音乐播放功能
    func playMusicFromURL(_ url: URL, completion: @escaping (Bool) -> Void) {
        // 开始听音乐动画
        startListeningToMusicAnimation()
        
        // 为将来的实现留下占位符
        print("将来会从URL播放音乐: \(url)")
        
        // 为将来播放Pixabay音乐做准备（占位代码）
        /*
        do {
            Fluffel.musicPlayer = try AVAudioPlayer(contentsOf: url)
            Fluffel.musicPlayer?.prepareToPlay()
            Fluffel.musicPlayer?.play()
            
            // 音乐播放结束时停止动画
            Fluffel.musicTimer = Timer.scheduledTimer(withTimeInterval: Fluffel.musicPlayer?.duration ?? 30, repeats: false) { [weak self] _ in
                self?.stopListeningToMusicAnimation()
                Fluffel.musicPlayer = nil
                Fluffel.musicTimer?.invalidate()
                Fluffel.musicTimer = nil
                completion(true)
            }
            
            return
        } catch {
            print("播放音乐失败: \(error)")
            stopListeningToMusicAnimation()
            completion(false)
        }
        */
        
        // 临时代码：10秒后自动停止动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.stopListeningToMusicAnimation()
            completion(true)
        }
    }
    
    /// 停止音乐播放（准备将来实现）
    func stopMusic() {
        Fluffel.musicPlayer?.stop()
        Fluffel.musicPlayer = nil
        Fluffel.musicTimer?.invalidate()
        Fluffel.musicTimer = nil
        
        stopListeningToMusicAnimation()
    }
} 