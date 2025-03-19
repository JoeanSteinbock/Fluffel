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
        self.headphones.isHidden = false
        
        // 添加耳机淡入动画
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        self.headphones.alpha = 0
        self.headphones.run(fadeIn)
        
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
        
        // 淡出耳机动画
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let hideHeadphones = SKAction.run { [weak self] in
            self?.headphones.isHidden = true
            self?.headphones.alpha = 1 // 重置alpha值，以便下次显示
        }
        let sequence = SKAction.sequence([fadeOut, hideHeadphones])
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