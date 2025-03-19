import Cocoa

// 表示一个屏幕上的窗口
struct ScreenWindow {
    let id: CGWindowID
    let frame: CGRect
    let title: String?
    let ownerName: String?
    let level: Int
    
    // 添加边缘类型枚举
    enum EdgeType {
        case top
        case bottom
        case left
        case right
        
        var description: String {
            switch self {
            case .top: return "顶部"
            case .bottom: return "底部"
            case .left: return "左侧"
            case .right: return "右侧"
            }
        }
        
        // 获取相反的边缘方向
        var opposite: EdgeType {
            switch self {
            case .top: return .bottom
            case .bottom: return .top
            case .left: return .right
            case .right: return .left
            }
        }
    }
    
    // 计算窗口边缘
    var topEdge: CGRect {
        return CGRect(x: frame.minX, y: frame.maxY - 1, width: frame.width, height: 2)
    }
    
    var bottomEdge: CGRect {
        return CGRect(x: frame.minX, y: frame.minY - 1, width: frame.width, height: 2)
    }
    
    var leftEdge: CGRect {
        return CGRect(x: frame.minX - 1, y: frame.minY, width: 2, height: frame.height)
    }
    
    var rightEdge: CGRect {
        return CGRect(x: frame.maxX - 1, y: frame.minY, width: 2, height: frame.height)
    }
    
    // 检查点是否在某一边缘上 - 改进检测算法，更严格
    func isPointOnEdge(_ point: CGPoint, tolerance: CGFloat) -> EdgeType? {
        // 首先检查点是否在窗口的外部边缘附近
        // 只有当点不在窗口内部时才认为它可能在边缘上
        let expandedFrame = frame.insetBy(dx: -tolerance, dy: -tolerance)
        let innerFrame = frame.insetBy(dx: tolerance, dy: tolerance)
        
        // 如果点在扩展边框内但不在内部边框内，则可能在边缘上
        if expandedFrame.contains(point) && !innerFrame.contains(point) {
            // 计算到各边的距离
            let distanceToTop = abs(point.y - frame.maxY)
            let distanceToBottom = abs(point.y - frame.minY)
            let distanceToLeft = abs(point.x - frame.minX)
            let distanceToRight = abs(point.x - frame.maxX)
            
            // 找出最近的边缘
            let minDistance = min(distanceToTop, distanceToBottom, distanceToLeft, distanceToRight)
            
            // 确保距离足够近
            if minDistance <= tolerance {
                // 返回最近的边缘
                if minDistance == distanceToTop {
                    return .top
                } else if minDistance == distanceToBottom {
                    return .bottom
                } else if minDistance == distanceToLeft {
                    return .left
                } else {
                    return .right
                }
            }
        }
        
        return nil
    }
} 