import Cocoa
import AVFoundation

/// FluffelTTSService 负责处理音频播放功能
class FluffelTTSService: NSObject {
    // 单例实例
    static let shared = FluffelTTSService()
    
    // 用于播放音频的播放器
    private var audioPlayer: AVAudioPlayer?
    
    // 当前是否正在播放语音
    private var isPlaying = false
    
    // 请求队列，避免并发问题
    private let requestQueue = DispatchQueue(label: "com.fluffel.audio.requestQueue")
    
    // 卡通角色声音类型
    enum CartoonVoiceType: CustomStringConvertible, Equatable {
        case squeaky      // 尖细的声音
        case deep        // 低沉的声音
        case chipmunk    // 花栗鼠声音
        case robot       // 机器人声音
        case cute        // 可爱的声音（默认）
        case custom(pitch: Double, rate: Double, gain: Double)  // 自定义配置
        
        var description: String {
            switch self {
            case .squeaky: return "Squeaky"
            case .deep: return "Deep"
            case .chipmunk: return "Chipmunk"
            case .robot: return "Robot"
            case .cute: return "Cute"
            case let .custom(pitch, rate, gain):
                return "Custom(pitch: \(pitch), rate: \(rate), gain: \(gain))"
            }
        }
        
        // 实现 Equatable 协议
        static func == (lhs: CartoonVoiceType, rhs: CartoonVoiceType) -> Bool {
            switch (lhs, rhs) {
            case (.squeaky, .squeaky),
                 (.deep, .deep),
                 (.chipmunk, .chipmunk),
                 (.robot, .robot),
                 (.cute, .cute):
                return true
            case let (.custom(lhsPitch, lhsRate, lhsGain), .custom(rhsPitch, rhsRate, rhsGain)):
                return lhsPitch == rhsPitch && lhsRate == rhsRate && lhsGain == rhsGain
            default:
                return false
            }
        }
    }
    
    // 当前声音类型
    private var currentVoiceType: CartoonVoiceType = .cute
    
    // 私有初始化方法
    private override init() {
        super.init()
        loadVoiceSettings()
    }
    
    /// 保存当前声音设置到 UserDefaults
    private func saveVoiceSettings() {
        let voiceTypeInt: Int
        switch currentVoiceType {
        case .squeaky: voiceTypeInt = 0
        case .deep: voiceTypeInt = 1
        case .chipmunk: voiceTypeInt = 2
        case .robot: voiceTypeInt = 3
        case .cute: voiceTypeInt = 4
        case .custom: voiceTypeInt = 5
        }
        
        UserDefaults.standard.set(voiceTypeInt, forKey: "FluffelVoiceType")
        UserDefaults.standard.synchronize()
        print("Voice setting saved: \(voiceTypeInt)")
    }
    
    /// 从 UserDefaults 加载声音设置
    private func loadVoiceSettings() {
        if let voiceTypeInt = UserDefaults.standard.object(forKey: "FluffelVoiceType") as? Int {
            switch voiceTypeInt {
            case 0: currentVoiceType = .squeaky
            case 1: currentVoiceType = .deep
            case 2: currentVoiceType = .chipmunk
            case 3: currentVoiceType = .robot
            case 5: currentVoiceType = .custom(pitch: 0.0, rate: 1.0, gain: 0.0)
            default: currentVoiceType = .cute
            }
            print("Voice setting loaded: \(currentVoiceType)")
        } else {
            currentVoiceType = .cute
            print("No saved voice setting found, using default (cute)")
        }
    }
    
    /// 设置卡通角色声音类型
    func setCartoonVoice(_ voiceType: CartoonVoiceType) {
        // 如果类型没有变化，则不做任何事情
        if currentVoiceType == voiceType { return }
        
        // 先停止当前播放的音频
        stopCurrentAudio()
        
        // 设置新的语音类型
        currentVoiceType = voiceType
        print("Voice set to: \(voiceType)")
        
        // 保存设置
        saveVoiceSettings()
    }
    
    /// 播放音频数据
    func playAudio(_ audioData: Data, completion: @escaping () -> Void) {
        // 确保在主线程上执行UI操作
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            
            // 停止可能正在播放的音频
            self.stopCurrentAudio()
            
            do {
                // 创建并配置音频播放器
                self.audioPlayer = try AVAudioPlayer(data: audioData)
                guard let player = self.audioPlayer else {
                    print("Audio error: Cannot create audio player")
                    completion()
                    return
                }
                
                player.delegate = self
                player.prepareToPlay()
                
                // 保存完成回调
                self.currentCompletion = completion
                
                // 开始播放
                if player.play() {
                    self.isPlaying = true
                    print("Started playing audio, duration: \(player.duration) seconds")
                } else {
                    print("Audio error: Playback failed")
                    self.isPlaying = false
                    completion()
                }
            } catch {
                print("Audio error: Failed to create player - \(error)")
                completion()
            }
        }
    }
    
    /// 停止当前正在播放的音频
    func stopCurrentAudio() {
        if isPlaying, let player = audioPlayer {
            player.stop()
            isPlaying = false
            print("Stopped audio playback")
        }
        
        // 清理资源
        audioPlayer?.delegate = nil
        audioPlayer = nil
        currentCompletion = nil
    }
    
    // 保存当前的完成回调
    private var currentCompletion: (() -> Void)?
}

// MARK: - AVAudioPlayerDelegate
extension FluffelTTSService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        audioPlayer = nil
        
        // 调用完成回调
        if let completion = currentCompletion {
            DispatchQueue.main.async {
                completion()
            }
            currentCompletion = nil
        }
    }
} 