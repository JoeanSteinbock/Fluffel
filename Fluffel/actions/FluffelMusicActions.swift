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
        
        // 显示耳机 - 确保耳机可见
        self.headphones.isHidden = false
        
        // 确保耳机可见性并打印状态
        print("Setting headphones visible: isHidden=\(self.headphones.isHidden), alpha=\(self.headphones.alpha)")
        
        // 添加耳机淡入动画 - 更平滑的出现效果
        self.headphones.setScale(0.1) // 从小尺寸开始
        self.headphones.alpha = 0
        
        // 组合缩放和淡入效果
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.6)
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        
        // 添加弹性效果
        let scaleAction = SKAction.sequence([
            scaleUp,
            SKAction.scale(to: 1.1, duration: 0.1), // 稍微过度缩放
            SKAction.scale(to: 1.0, duration: 0.1)  // 回到正常大小
        ])
        
        // 同时执行缩放和淡入
        let groupAction = SKAction.group([scaleAction, fadeIn])
        
        self.headphones.run(groupAction) { [weak self] in
            // 确认动画完成后的状态
            if let self = self {
                // 强制确保耳机在动画完成后仍然可见
                DispatchQueue.main.async {
                    self.headphones.isHidden = false
                    print("Headphones fade-in complete: isHidden=\(self.headphones.isHidden), alpha=\(self.headphones.alpha)")
                }
            }
        }
        
        // 表现为享受音乐的样子
        blink()
        expressionDelight()
        
        // 创建轻微的摇头动作，表示享受音乐
        let rotateLeft = SKAction.rotate(byAngle: -0.05, duration: 0.5)
        let rotateRight = SKAction.rotate(byAngle: 0.05, duration: 0.5)
        let rotateSequence = SKAction.sequence([rotateLeft, rotateRight])
        let repeatRotate = SKAction.repeatForever(rotateSequence)
        
        // 运行摇头动作
        run(repeatRotate, withKey: "listeningToMusicAction")
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
        
        // 停止摇头动作
        removeAction(forKey: "listeningToMusicAction")
        
        // 重置旋转
        zRotation = 0
        
        // 恢复正常表情
        smile()
        
        // 淡出耳机动画 - 添加缩放效果使其更自然
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.4)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        
        // 组合缩放和淡出效果
        let groupAction = SKAction.group([scaleDown, fadeOut])
        
        let hideHeadphones = SKAction.run { [weak self] in
            self?.headphones.isHidden = true
            self?.headphones.alpha = 1 // 重置alpha值，以便下次显示
            self?.headphones.setScale(1.0) // 重置缩放，以便下次显示
        }
        
        let sequence = SKAction.sequence([groupAction, hideHeadphones])
        self.headphones.run(sequence)
        
        // 直接修改状态变量，避免递归调用
        state = .idle
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
        
        print("Starting music playback from URL: \(url)")
        print("Current headphones state before animation: isHidden=\(self.headphones.isHidden), alpha=\(self.headphones.alpha)")
        
        // 开始听音乐动画（这个方法已经确保会在主线程执行）
        startListeningToMusicAnimation()
        
        // 调用 FluffelScene 的音乐播放功能
        if let scene = self.parent?.scene as? FluffelScene {
            // 播放前清除现有的播放器
            Fluffel.musicPlayer = nil
            Fluffel.completionHandler = completion // 再次确保回调被设置
            
            print("Calling scene.startPlayingMusic with URL: \(url)")
            scene.startPlayingMusic(from: url)
            
            // 延长检查时间到5秒，给音频有更多时间下载和加载
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                // 打印当前状态
                print("Checking musicPlayer after 5 seconds: \(Fluffel.musicPlayer != nil ? "Exists" : "Nil")")
                
                // 检查5秒后是否有播放器实例
                if Fluffel.musicPlayer == nil {
                    print("⚠️ Warning: musicPlayer is still nil after 5 seconds")
                    // 如果5秒后还没有播放器实例，认为播放失败
                    // 确保在主线程上停止动画
                    DispatchQueue.main.async {
                        print("Stopping music animation due to missing player")
                        self?.stopListeningToMusicAnimation()
                        Fluffel.completionHandler?(false)
                        Fluffel.completionHandler = nil
                    }
                } else {
                    print("Setting delegate for musicPlayer")
                    // 设置代理接收播放结束事件
                    if Fluffel.musicPlayer?.delegate == nil {
                        Fluffel.musicPlayer?.delegate = self
                        print("Delegate set to self")
                    } else {
                        print("Delegate already set to: \(String(describing: Fluffel.musicPlayer?.delegate))")
                        
                        // 强制重设代理以确保接收回调
                        Fluffel.musicPlayer?.delegate = self
                        print("Delegate forcibly reset to self")
                    }
                    
                    // 打印播放状态
                    if let player = Fluffel.musicPlayer {
                        print("Current playback: playing=\(player.isPlaying), currentTime=\(player.currentTime), duration=\(player.duration)")
                        
                        // 如果播放器存在但没有播放，尝试重新开始播放
                        if !player.isPlaying {
                            print("Player exists but not playing, attempting to restart playback")
                            player.currentTime = 0
                            let playResult = player.play()
                            print("Restart playback result: \(playResult ? "Success" : "Failed")")
                        }
                    }
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