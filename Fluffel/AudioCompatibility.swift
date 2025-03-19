import Foundation
import AVFoundation

// 音频会话兼容层，解决iOS和macOS平台API差异
class FluffelAudioSession {
    // 单例实例
    static let shared = FluffelAudioSession()
    
    // 私有初始化方法
    private init() {}
    
    // 配置音频会话，此方法在macOS上不做任何事情，但保持API兼容性
    func configureAudioSession() {
        #if os(iOS)
        // iOS平台代码 - 在macOS中编译时会被忽略
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            print("Successfully configured iOS audio session")
        } catch {
            print("Error setting up iOS audio session: \(error.localizedDescription)")
        }
        #else
        // macOS平台代码
        print("Audio session configuration is not required on macOS")
        #endif
    }
    
    // 停用音频会话，此方法在macOS上不做任何事情，但保持API兼容性
    func deactivateAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(false)
            print("Successfully deactivated iOS audio session")
        } catch {
            print("Error deactivating iOS audio session: \(error.localizedDescription)")
        }
        #else
        // macOS平台不需要操作
        print("Audio session deactivation is not required on macOS")
        #endif
    }
} 