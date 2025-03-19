import SpriteKit
import AVFoundation

// Fluffel 的音乐相关动作扩展
extension Fluffel: AVAudioPlayerDelegate {
    
    // MARK: - 听音乐动画
    
    /// 开始听音乐动画
    func startListeningToMusicAnimation() {
        // 确保在主线程执行UI操作
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.startListeningToMusicAnimation()
            }
            return
        }
        
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
        
        // 显示耳机
        headphones.isHidden = false
        
        // 添加耳机出现动画
        headphones.alpha = 0
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        headphones.run(fadeIn)
        
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
        // 确保在主线程执行UI操作
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.stopListeningToMusicAnimation()
            }
            return
        }
        
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
        
        // 隐藏耳机
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let hideHeadphones = SKAction.run { [weak self] in
            self?.headphones.isHidden = true
            self?.headphones.alpha = 1 // 重置alpha值，以便下次显示
        }
        let sequence = SKAction.sequence([fadeOut, hideHeadphones])
        headphones.run(sequence)
        
        // 避免使用setState触发潜在的循环调用
        // 直接修改状态变量
        state = .idle
        
        // 发送停止音乐的通知，供外部组件使用
        NotificationCenter.default.post(name: .fluffelDidStopMusic, object: self)
    }
    
    // MARK: - 音乐播放器
    
    // 音乐播放器属性
    internal static var musicPlayer: AVAudioPlayer?
    internal static var musicTimer: Timer?
    private static var completionHandler: ((Bool) -> Void)?
    
    /// 播放音乐
    func playMusicFromURL(_ url: URL, completion: @escaping (Bool) -> Void) {
        // 保存完成回调
        Fluffel.completionHandler = completion
        
        // 开始听音乐动画（这个方法已经确保会在主线程执行）
        startListeningToMusicAnimation()
        
        // 调用 FluffelScene 的音乐播放功能
        if let scene = self.parent?.scene as? FluffelScene {
            scene.startPlayingMusic(from: url)
            
            // 标记当前为正在播放状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                // 检查1秒后是否有播放器实例
                if Fluffel.musicPlayer == nil {
                    // 如果1秒后还没有播放器实例，认为播放失败
                    // 确保在主线程上停止动画
                    DispatchQueue.main.async {
                        self?.stopListeningToMusicAnimation()
                        Fluffel.completionHandler?(false)
                        Fluffel.completionHandler = nil
                    }
                } else {
                    // 设置代理接收播放结束事件
                    Fluffel.musicPlayer?.delegate = self
                }
            }
        } else {
            print("Error: Cannot find FluffelScene to play music")
            // 确保在主线程上停止动画
            DispatchQueue.main.async { [weak self] in
                self?.stopListeningToMusicAnimation()
                Fluffel.completionHandler?(false)
                Fluffel.completionHandler = nil
            }
        }
    }
    
    /// 停止音乐播放
    func stopMusic() {
        // 确保在主线程执行UI操作
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.stopMusic()
            }
            return
        }
        
        // 停止所有定时器
        Fluffel.musicTimer?.invalidate()
        Fluffel.musicTimer = nil
        
        // 直接停止音频播放，而不是通过场景
        Fluffel.musicPlayer?.stop()
        Fluffel.musicPlayer = nil
        
        // 取消回调
        Fluffel.completionHandler = nil
        
        // 停止动画
        stopListeningToMusicAnimation()
        
        print("Music playback stopped by Fluffel")
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    /// 音频播放结束时调用
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // 确保在主线程处理回调
        DispatchQueue.main.async { [weak self] in
            // 停止动画
            self?.stopListeningToMusicAnimation()
            
            // 调用完成回调
            Fluffel.completionHandler?(flag)
            Fluffel.completionHandler = nil
        }
    }
    
    /// 音频播放出错时调用
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        // 确保在主线程处理回调
        DispatchQueue.main.async { [weak self] in
            print("Audio playback error: \(error?.localizedDescription ?? "unknown error")")
            
            // 停止动画
            self?.stopListeningToMusicAnimation()
            
            // 调用完成回调
            Fluffel.completionHandler?(false)
            Fluffel.completionHandler = nil
        }
    }
}