import SpriteKit
import Cocoa

// Fluffel 的面部表情扩展
extension Fluffel {
    
    // 惊讶表情 - 用于下落时 - Morty风格
    func surprisedFace() {
        // 确保在主线程上执行UI操作
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.surprisedFace()
            }
            return
        }
        
        // 眼睛变得更大 - Morty惊讶时眼睛会非常大
        leftEye.setScale(1.5)
        rightEye.setScale(1.5)
        
        // 嘴巴变成O形 - 更小的O形，更符合Morty的表情
        let oMouthPath = CGMutablePath()
        oMouthPath.addEllipse(in: CGRect(x: -5, y: -10, width: 10, height: 6))
        mouth.path = oMouthPath
        mouth.fillColor = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        
        // 确保鼻子可见
        nose.isHidden = false
    }
    
    // Morty 风格的微笑 - 更加紧张和不确定
    func smile() {
        // 确保在主线程上执行UI操作
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.smile()
            }
            return
        }
        
        // 创建一个 Morty 风格的微笑 - 不太确定的微笑
        let smilePath = CGMutablePath()
        smilePath.move(to: CGPoint(x: -7, y: -8))
        // 控制点更平，显示不太确定的微笑
        smilePath.addQuadCurve(to: CGPoint(x: 7, y: -8), control: CGPoint(x: 0, y: -11))
        
        mouth.path = smilePath
        
        // 确保鼻子可见
        nose.isHidden = false
    }
    
    // Morty 风格的担忧表情 - 更加明显的下垂
    func worried() {
        // 确保在主线程上执行UI操作
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.worried()
            }
            return
        }
        
        let worriedPath = CGMutablePath()
        worriedPath.move(to: CGPoint(x: -7, y: -8))
        // 更加担忧的表情，嘴巴明显向下弯曲
        worriedPath.addQuadCurve(to: CGPoint(x: 7, y: -8), control: CGPoint(x: 0, y: -2))
        
        mouth.path = worriedPath
        
        // 确保鼻子可见
        nose.isHidden = false
    }
    
    // 添加一个眨眼的表情
    func blink() {
        // 确保在主线程上执行UI操作
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.blink()
            }
            return
        }
        
        // 眨眼动画序列
        let close = SKAction.scaleY(to: 0.3, duration: 0.1)
        let open = SKAction.scaleY(to: 1.0, duration: 0.1)
        let blinkAction = SKAction.sequence([close, open])
        
        leftEye.run(blinkAction)
        rightEye.run(blinkAction)
        
        // 确保头发和鼻子可见
        hair.isHidden = false
        nose.isHidden = false
    }
    
    // 欢悦表情 - Morty风格，紧张但兴奋
    func expressionDelight() {
        // 确保在主线程上执行UI操作
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.expressionDelight()
            }
            return
        }
        
        // Morty风格的大眼睛，显示兴奋但略带紧张
        leftEye.setScale(1.3)
        rightEye.setScale(1.3)
        
        // Morty风格的微笑，有点不确定但很开心
        let delightedMouthPath = CGMutablePath()
        delightedMouthPath.move(to: CGPoint(x: -8, y: -8))
        delightedMouthPath.addQuadCurve(to: CGPoint(x: 8, y: -8), control: CGPoint(x: 0, y: -14))
        mouth.path = delightedMouthPath
        
        // 使脸颊稍微更红，表示兴奋但不太明显
        leftCheek.fillColor = NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.6, alpha: 0.4)
        rightCheek.fillColor = NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.6, alpha: 0.4)
        
        // 确保鼻子可见
        nose.isHidden = false
        
        // 定时恢复脸颊颜色
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            self.leftCheek.fillColor = NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.6, alpha: 0.2)
            self.rightCheek.fillColor = NSColor(calibratedRed: 1.0, green: 0.7, blue: 0.6, alpha: 0.2)
        }
    }
}
