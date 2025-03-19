import Cocoa
import AVFoundation

/// FluffelTTSService 负责处理文本转语音功能
class FluffelTTSService: NSObject {
    
    // 单例实例
    static let shared = FluffelTTSService()
    
    // 用于播放音频的播放器
    private var audioPlayer: AVAudioPlayer?
    
    // 当前是否正在播放语音
    private var isPlaying = false
    
    // 请求队列，避免并发问题
    private let requestQueue = DispatchQueue(label: "com.fluffel.tts.requestQueue")
    
    // API 密钥
    private var apiKey: String?
    
    // 卡通角色声音类型
    enum CartoonVoiceType: CustomStringConvertible {
        case squeaky      // 尖细的声音
        case deep         // 低沉的声音
        case chipmunk     // 花栗鼠声音
        case robot        // 机器人声音
        case cute         // 可爱的声音（默认）
        case custom(pitch: Double, rate: Double, gain: Double)  // 自定义配置
        
        var description: String {
            switch self {
            case .squeaky:
                return "Squeaky"
            case .deep:
                return "Deep"
            case .chipmunk:
                return "Chipmunk"
            case .robot:
                return "Robot"
            case .cute:
                return "Cute"
            case let .custom(pitch, rate, gain):
                return "Custom(pitch: \(pitch), rate: \(rate), gain: \(gain))"
            }
        }
    }
    
    // 当前声音类型
    private var currentVoiceType: CartoonVoiceType = .cute
    
    // 语音配置
    private struct VoiceConfig {
        static let languageCode = "en-US"
        static let voiceName = "en-US-Standard-D" // 基础声音
        static let audioEncoding = "LINEAR16"
        
        // 默认参数（可爱声音）
        static let defaultPitch = 4.0
        static let defaultRate = 1.1
        static let defaultGain = 2.0
    }
    
    // 私有初始化方法
    private override init() {
        super.init()
        // 尝试从 UserDefaults 加载 API 密钥
        apiKey = UserDefaults.standard.string(forKey: "GoogleCloudAPIKey")
        
        // 尝试从 UserDefaults 加载声音设置
        loadVoiceSettings()
    }
    
    /// 设置 Google Cloud API 密钥
    /// - Parameter key: API 密钥
    func setApiKey(_ key: String) {
        print("设置 API 密钥: \(key)")
        apiKey = key
        
        // 保存到 UserDefaults
        UserDefaults.standard.set(key, forKey: "GoogleCloudAPIKey")
        
        // 立即同步 UserDefaults
        UserDefaults.standard.synchronize()
        
        // 验证保存是否成功
        let savedKey = UserDefaults.standard.string(forKey: "GoogleCloudAPIKey") ?? ""
        print("从 UserDefaults 读取到的 API 密钥: \(savedKey)")
        
        // 确认实例变量设置成功
        print("当前实例的 API 密钥: \(apiKey ?? "nil")")
    }
    
    /// 检查是否已设置 API 密钥
    /// - Returns: 布尔值，表示是否已设置 API 密钥
    func hasApiKey() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    /// 保存当前声音设置到 UserDefaults
    private func saveVoiceSettings() {
        var voiceTypeInt: Int
        
        switch currentVoiceType {
        case .squeaky:
            voiceTypeInt = 0
        case .deep:
            voiceTypeInt = 1
        case .chipmunk:
            voiceTypeInt = 2
        case .robot:
            voiceTypeInt = 3
        case .cute:
            voiceTypeInt = 4
        case .custom:
            voiceTypeInt = 5
        }
        
        UserDefaults.standard.set(voiceTypeInt, forKey: "FluffelVoiceType")
        UserDefaults.standard.synchronize()
        
        print("Voice setting saved: \(voiceTypeInt)")
    }
    
    /// 从 UserDefaults 加载声音设置
    private func loadVoiceSettings() {
        if let voiceTypeInt = UserDefaults.standard.object(forKey: "FluffelVoiceType") as? Int {
            switch voiceTypeInt {
            case 0:
                currentVoiceType = .squeaky
            case 1:
                currentVoiceType = .deep
            case 2:
                currentVoiceType = .chipmunk
            case 3:
                currentVoiceType = .robot
            case 5:
                currentVoiceType = .custom(pitch: 0.0, rate: 1.0, gain: 0.0)
            default:
                currentVoiceType = .cute
            }
            
            print("Voice setting loaded: \(currentVoiceType)")
        } else {
            currentVoiceType = .cute
            print("No saved voice setting found, using default (cute)")
        }
    }
    
    /// 设置卡通角色声音类型
    /// - Parameter voiceType: 卡通角色声音类型
    func setCartoonVoice(_ voiceType: CartoonVoiceType) {
        currentVoiceType = voiceType
        print("Voice set to: \(voiceType)")
        
        // 保存设置
        saveVoiceSettings()
    }
    
    /// 获取当前声音类型的配置
    private func getCurrentVoiceConfig() -> (pitch: Double, rate: Double, gain: Double) {
        switch currentVoiceType {
        case .squeaky:
            return (pitch: 10.0, rate: 1.3, gain: 2.0)
        case .deep:
            return (pitch: -5.0, rate: 0.8, gain: 3.0)
        case .chipmunk:
            return (pitch: 12.0, rate: 1.5, gain: 1.0)
        case .robot:
            return (pitch: 0.0, rate: 0.9, gain: 4.0)
        case .cute:
            return (pitch: VoiceConfig.defaultPitch, rate: VoiceConfig.defaultRate, gain: VoiceConfig.defaultGain)
        case .custom(let pitch, let rate, let gain):
            return (pitch: pitch, rate: rate, gain: gain)
        }
    }
    
    /// 将文本转换为语音并播放
    /// - Parameters:
    ///   - text: 要转换为语音的文本
    ///   - completion: 播放完成后的回调
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        // 确保在后台线程处理网络请求
        requestQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 检查是否有 API 密钥
            guard let apiKey = self.apiKey, !apiKey.isEmpty else {
                print("TTS error: API key not set")
                DispatchQueue.main.async { completion?() }
                return
            }
            
            // 获取当前声音配置
            let voiceConfig = self.getCurrentVoiceConfig()
            
            // 构建请求体
            let requestBody: [String: Any] = [
                "input": [
                    "text": text
                ],
                "voice": [
                    "languageCode": VoiceConfig.languageCode,
                    "name": VoiceConfig.voiceName
                ],
                "audioConfig": [
                    "audioEncoding": VoiceConfig.audioEncoding,
                    "pitch": voiceConfig.pitch,
                    "speakingRate": voiceConfig.rate,
                    "volumeGainDb": voiceConfig.gain
                ]
            ]
            
            // 发送 API 请求
            self.sendTTSRequest(requestBody: requestBody, apiKey: apiKey) { audioData in
                guard let audioData = audioData else {
                    print("TTS 错误: 未能获取音频数据")
                    DispatchQueue.main.async { completion?() }
                    return
                }
                
                // 播放音频
                self.playAudio(audioData) {
                    DispatchQueue.main.async { completion?() }
                }
            }
        }
    }
    
    /// 发送 Text-to-Speech API 请求
    private func sendTTSRequest(requestBody: [String: Any], apiKey: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: "https://texttospeech.googleapis.com/v1/text:synthesize?key=\(apiKey)") else {
            print("TTS API 错误: 无效的URL")
            completion(nil)
            return
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("TTS API 错误: 无法序列化请求数据")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                let nsError = error as NSError
                if nsError.domain == NSPOSIXErrorDomain && nsError.code == 1 {
                    // 网络权限错误
                    print("TTS API 错误: 网络访问权限被拒绝。请检查应用权限设置。")
                    NotificationCenter.default.post(
                        name: NSNotification.Name("FluffelTTSNetworkError"),
                        object: nil,
                        userInfo: ["message": "网络访问被拒绝，请确保应用有网络权限"]
                    )
                } else {
                    print("TTS API 错误: \(error)")
                }
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("TTS API 错误: 没有数据返回")
                completion(nil)
                return
            }
            
            // 解析 API 响应
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let audioContent = json["audioContent"] as? String,
                   let audioData = Data(base64Encoded: audioContent) {
                    completion(audioData)
                } else {
                    print("TTS API 错误: 解析响应失败")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("响应内容: \(responseString)")
                    }
                    completion(nil)
                }
            } catch {
                print("TTS API 错误: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    /// 播放音频数据
    private func playAudio(_ audioData: Data, completion: @escaping () -> Void) {
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
                self.audioPlayer?.delegate = self
                self.audioPlayer?.prepareToPlay()
                
                // 保存完成回调
                self.currentCompletion = completion
                
                // 开始播放
                if self.audioPlayer?.play() == true {
                    self.isPlaying = true
                } else {
                    print("TTS 错误: 播放失败")
                    self.isPlaying = false
                    completion()
                }
            } catch {
                print("TTS 错误: 创建播放器失败 - \(error)")
                completion()
            }
        }
    }
    
    /// 停止当前正在播放的音频
    func stopCurrentAudio() {
        if isPlaying, let player = audioPlayer {
            player.stop()
            isPlaying = false
        }
        audioPlayer = nil
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