import Cocoa
import ApplicationServices

// 引用 ScreenWindow 类
// 删除此处的 ScreenWindow 定义

class WindowUtility {
    // 类型别名，以保持一致性
    typealias EdgeType = ScreenWindow.EdgeType
    
    // 屏幕边缘检测的缓存，减少不必要的重复计算
    private static var lastCheckTime: TimeInterval = 0
    private static var cachedWindows: [ScreenWindow] = []
    private static let cacheLifetime: TimeInterval = 0.5 // 0.5秒缓存
    
    // 获取屏幕上所有可见的窗口（带缓存）
    static func getAllVisibleWindows() -> [ScreenWindow] {
        let currentTime = NSDate().timeIntervalSince1970
        
        // 如果缓存有效，直接返回缓存结果
        if currentTime - lastCheckTime < cacheLifetime && !cachedWindows.isEmpty {
            return cachedWindows
        }
        
        // 获取主显示器
        guard NSScreen.main != nil else {
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
            
            // 忽略非常小的窗口（可能是系统UI元素）
            if width < 50 || height < 50 {
                continue
            }
            
            // 获取窗口标题和所有者名称（应用程序名）
            let title = windowInfo[kCGWindowName as String] as? String
            let ownerName = windowInfo[kCGWindowOwnerName as String] as? String
            
            // 排除自己的窗口，避免错误识别
            if ownerName == "Fluffel" {
                continue
            }
            
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
        
        // 更新缓存
        cachedWindows = windows
        lastCheckTime = currentTime
        
        return windows
    }
    
    // 查找最近的窗口边缘 - 严格版
    static func findNearestEdge(to point: CGPoint, tolerance: CGFloat = 5.0) -> (window: ScreenWindow, edge: EdgeType, distance: CGFloat)? {
        // 验证点是否在任何屏幕内
        var pointInScreen = false
        for screen in NSScreen.screens {
            if screen.frame.contains(point) {
                pointInScreen = true
                break
            }
        }
        
        if !pointInScreen {
            return nil
        }
        
        let windows = getAllVisibleWindows()
        var closestEdge: (window: ScreenWindow, edge: EdgeType, distance: CGFloat)? = nil
        
        for window in windows {
            // 检查点是否接近某一边缘
            if let edgeType = window.isPointOnEdge(point, tolerance: tolerance) {
                var distance: CGFloat = 0
                
                // 计算到边缘的精确距离
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
                
                // 使用严格标准：距离必须小于容差的一半
                if distance > tolerance * 0.5 {
                    continue
                }
                
                // 如果这是首个找到的边缘，或距离更近，则更新结果
                if closestEdge == nil || distance < closestEdge!.distance {
                    closestEdge = (window, edgeType, distance)
                }
            }
        }
        
        return closestEdge
    }
    
    // 检查点是否在任何窗口的边缘上 - 严格版
    static func isPointOnWindowEdge(_ point: CGPoint, tolerance: CGFloat = 5.0) -> (isOnEdge: Bool, edge: EdgeType?, window: ScreenWindow?) {
        // 检查是否有窗口边缘
        if let (window, edge, _) = findNearestEdge(to: point, tolerance: tolerance) {
            return (true, edge, window)
        }
        
        // 检查是否在屏幕边缘
        guard let mainScreen = NSScreen.main else {
            return (false, nil, nil)
        }
        
        // 转换屏幕坐标
        let screenFrame = mainScreen.frame
        
        // 计算与屏幕边缘的距离
        let distanceToTop = abs(point.y - screenFrame.maxY)
        let distanceToBottom = abs(point.y - screenFrame.minY)
        let distanceToLeft = abs(point.x - screenFrame.minX)
        let distanceToRight = abs(point.x - screenFrame.maxX)
        
        // 找出最近的边缘
        let minDistance = min(distanceToTop, distanceToBottom, distanceToLeft, distanceToRight)
        
        // 如果非常接近屏幕边缘
        if minDistance <= tolerance * 0.5 {
            if minDistance == distanceToTop {
                return (true, .top, nil)
            } else if minDistance == distanceToBottom {
                return (true, .bottom, nil)
            } else if minDistance == distanceToLeft {
                return (true, .left, nil)
            } else {
                return (true, .right, nil)
            }
        }
        
        return (false, nil, nil)
    }
    
    // 屏幕检测调试
    static func logWindowsUnderPoint(_ point: CGPoint) {
        let windows = getAllVisibleWindows()
        print("--- 检测 \(point.x), \(point.y) 坐标下的窗口 ---")
        
        var foundWindows = 0
        for window in windows {
            let expandedFrame = window.frame.insetBy(dx: -5, dy: -5)
            if expandedFrame.contains(point) {
                print("窗口: \(window.title ?? "无标题"), 应用: \(window.ownerName ?? "未知"), 大小: \(window.frame.width)x\(window.frame.height)")
                foundWindows += 1
            }
        }
        
        if foundWindows == 0 {
            print("该坐标下没有找到窗口")
        }
        
        // 检查是否在任何窗口边缘
        let (isOnEdge, edge, edgeWindow) = isPointOnWindowEdge(point)
        if isOnEdge {
            print("检测到边缘: \(edge?.description ?? "未知"), 窗口: \(edgeWindow?.title ?? "屏幕边缘")")
        } else {
            print("没有检测到边缘")
        }
    }
}
