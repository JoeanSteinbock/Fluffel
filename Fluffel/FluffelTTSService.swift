import Cocoa
import AVFoundation

/// FluffelTTSService 负责处理文本转语音功能
class FluffelTTSService {
    
    // 单例实例
    static let shared = FluffelTTSService()
    
    // 用于播放音频的播放器
    private var audioPlayer: AVAudioPlayer?
    
    // 当前是否正在播放语音
    private var isPlaying = false
    
    // 请求队列，避免并发问题
    private let requestQueue = DispatchQueue(label: "com.fluffel.tts.requestQueue")
    
    // 语音配置
    private struct VoiceConfig {
        static let languageCode = "en-US"
        static let voiceName = "en-US-Chirp3-HD-Kore" // 默认使用可爱的声音
        static let audioEncoding = "LINEAR16"
    }
    
    // 私有初始化方法
    private init() {}
    
    /// 将文本转换为语音并播放
    /// - Parameters:
    ///   - text: 要转换为语音的文本
    ///   - completion: 播放完成后的回调
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        // 确保在后台线程处理网络请求
        requestQueue.async { [weak self] in
            guard let self = self else { return }
            
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
            
            // 获取认证信息
            self.getAuthToken { token in
                guard let token = token else {
                    print("TTS 错误: 无法获取认证令牌")
                    DispatchQueue.main.async { completion?() }
                    return
                }
                
                // 发送 API 请求
                self.sendTTSRequest(requestBody: requestBody, token: token) { audioData in
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
    }
    
    /// 获取 Google Cloud 认证令牌
    private func getAuthToken(completion: @escaping (String?) -> Void) {
        // 使用 gcloud CLI 获取令牌
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["gcloud", "auth", "print-access-token"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let token = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                completion(token)
            } else {
                completion(nil)
            }
        } catch {
            print("TTS 错误: 无法执行 gcloud 命令: \(error)")
            completion(nil)
        }
    }
    
    /// 发送 Text-to-Speech API 请求
    private func sendTTSRequest(requestBody: [String: Any], token: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: "https://texttospeech.googleapis.com/v1/text:synthesize") else {
            completion(nil)
            return
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let projectTask = Process()
        projectTask.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        projectTask.arguments = ["gcloud", "config", "list", "--format=value(core.project)"]
        
        let projectPipe = Pipe()
        projectTask.standardOutput = projectPipe
        
        do {
            try projectTask.run()
            let projectData = projectPipe.fileHandleForReading.readDataToEndOfFile()
            if let project = String(data: projectData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                request.setValue(project, forHTTPHeaderField: "X-Goog-User-Project")
            }
        } catch {
            print("TTS 错误: 无法获取项目ID: \(error)")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("TTS API 错误: \(error)")
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