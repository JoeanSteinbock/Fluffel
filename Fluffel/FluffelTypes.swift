import Foundation
import SpriteKit

// 移动方向枚举
enum MovementDirection {
    case up
    case down
    case left
    case right
}

// 场景边缘枚举
extension FluffelScene {
    enum SceneEdge {
        case top
        case bottom
        case left
        case right
    }
}