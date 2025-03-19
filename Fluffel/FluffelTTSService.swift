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
    
    // 语音配置
    private struct VoiceConfig {
        static let languageCode = "en-US"
        static let voiceName = "en-US-Chirp3-HD-Kore" // 默认使用可爱的声音
        static let audioEncoding = "LINEAR16"
    }
    
    // 私有初始化方法
    private override init() {
        super.init()
        // 尝试从 UserDefaults 加载 API 密钥
        apiKey = UserDefaults.standard.string(forKey: "GoogleCloudAPIKey")
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
                print("TTS 错误: 未设置 API 密钥")
                DispatchQueue.main.async { completion?() }
                return
            }
            
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
                    "audioEncoding": VoiceConfig.audioEncoding
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