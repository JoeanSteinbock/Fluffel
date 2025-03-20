import Foundation
import SpriteKit

// 移动方向枚举
enum MovementDirection {
    case up
    case down
    case left
    case right
}

// 移除场景边缘枚举
// extension FluffelScene {
//    enum SceneEdge {
//        case top
//        case bottom
//        case left
//        case right
//    }
// }

// 通知名称扩展
extension NSNotification.Name {
    static let fluffelDidMove = NSNotification.Name("fluffelDidMove")
    static let fluffelWillSpeak = NSNotification.Name("fluffelWillSpeak")
    static let fluffelDidStopSpeaking = NSNotification.Name("fluffelDidStopSpeaking")
    static let fluffelWillPlayMusic = NSNotification.Name("fluffelWillPlayMusic")
    static let fluffelDidStopMusic = NSNotification.Name("fluffelDidStopMusic")
    static let fluffelDidUpdateCategories = NSNotification.Name("fluffelDidUpdateCategories")
    static let fluffelDebugInfo = NSNotification.Name("fluffelDebugInfo") // 添加调试信息通知
    static let fluffelDidFinishPlayingMusic = NSNotification.Name("fluffelDidFinishPlayingMusic") // 添加音乐播放完成通知
}