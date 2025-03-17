import Cocoa
import ApplicationServices

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
    
    // 检查点是否在某一边缘上
    func isPointOnEdge(_ point: CGPoint, tolerance: CGFloat) -> EdgeType? {
        let expandedTop = topEdge.insetBy(dx: 0, dy: -tolerance)
        if expandedTop.contains(point) {
            return .top
        }
        
        let expandedBottom = bottomEdge.insetBy(dx: 0, dy: -tolerance)
        if expandedBottom.contains(point) {
            return .bottom
        }
        
        let expandedLeft = leftEdge.insetBy(dx: -tolerance, dy: 0)
        if expandedLeft.contains(point) {
            return .left
        }
        
        let expandedRight = rightEdge.insetBy(dx: -tolerance, dy: 0)
        if expandedRight.contains(point) {
            return .right
        }
        
        return nil
    }
}

class WindowUtility {
    // 类型别名，以保持一致性
    typealias EdgeType = ScreenWindow.EdgeType
    
    // 获取屏幕上所有可见的窗口
    static func getAllVisibleWindows() -> [ScreenWindow] {
        // 获取主显示器
        guard let mainDisplay = NSScreen.main else {
            return []
        }
        
        // 获取所有窗口的列表
        let windowsListOptions: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowInfoList = CGWindowListCopyWindowInfo(windowsListOptions, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        
        // 把每个窗口信息转换为 ScreenWindow 对象
        var windows: [ScreenWindow] = []
        
        for windowInfo in windowInfoList {
            // 检查窗口是否是应用程序窗口
            guard let windowLayer = windowInfo[kCGWindowLayer as String] as? Int,
                  let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID,
                  let bounds = windowInfo[kCGWindowBounds as String] as? [String: CGFloat] else {
                continue
            }
            
            // 排除桌面和 Dock
            if windowLayer < 0 {
                continue
            }
            
            // 创建窗口边框
            let x = bounds["X"] ?? 0
            let y = bounds["Y"] ?? 0
            let width = bounds["Width"] ?? 0
            let height = bounds["Height"] ?? 0
            
            // 获取窗口标题和所有者名称（应用程序名）
            let title = windowInfo[kCGWindowName as String] as? String
            let ownerName = windowInfo[kCGWindowOwnerName as String] as? String
            
            // 创建 ScreenWindow 对象并添加到结果列表
            let window = ScreenWindow(
                id: windowID,
                frame: CGRect(x: x, y: y, width: width, height: height),
                title: title,
                ownerName: ownerName,
                level: windowLayer
            )
            
            windows.append(window)
        }
        
        return windows
    }
    
    // 查找最近的窗口边缘
    static func findNearestEdge(to point: CGPoint, tolerance: CGFloat = 10.0) -> (window: ScreenWindow, edge: EdgeType, distance: CGFloat)? {
        let windows = getAllVisibleWindows()
        var closestEdge: (window: ScreenWindow, edge: EdgeType, distance: CGFloat)? = nil
        
        for window in windows {
            // 检查点是否接近某一边缘
            if let edgeType = window.isPointOnEdge(point, tolerance: tolerance) {
                var distance: CGFloat = 0
                
                // 计算到边缘的距离
                switch edgeType {
                case .top:
                    distance = abs(point.y - window.frame.maxY)
                case .bottom:
                    distance = abs(point.y - window.frame.minY)
                case .left:
                    distance = abs(point.x - window.frame.minX)
                case .right:
                    distance = abs(point.x - window.frame.maxX)
                }
                
                // 如果这是首个找到的边缘，或距离更近，则更新结果
                if closestEdge == nil || distance < closestEdge!.distance {
                    closestEdge = (window, edgeType, distance)
                }
            }
        }
        
        return closestEdge
    }
    
    // 检查点是否在任何窗口的边缘上
    static func isPointOnWindowEdge(_ point: CGPoint, tolerance: CGFloat = 10.0) -> (isOnEdge: Bool, edge: EdgeType?, window: ScreenWindow?) {
        if let (window, edge, _) = findNearestEdge(to: point, tolerance: tolerance) {
            return (true, edge, window)
        }
        return (false, nil, nil)
    }
}
