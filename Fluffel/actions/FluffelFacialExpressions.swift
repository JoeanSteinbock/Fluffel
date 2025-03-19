import SpriteKit
import Cocoa

// Fluffel 的面部表情扩展
extension Fluffel {
    
    // 惊讶表情 - 用于下落时
    func surprisedFace() {
        // 确保在主线程上执行UI操作
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.surprisedFace()
            }
            return
        }
        
        // 眼睛变大
        leftEye.setScale(1.3)
        rightEye.setScale(1.3)
        
        // 嘴巴变成O形
        let oMouthPath = CGMutablePath()
        oMouthPath.addEllipse(in: CGRect(x: -5, y: -10, width: 10, height: 8))
        mouth.path = oMouthPath
        mouth.fillColor = NSColor(calibratedRed: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
    }
    
    // 修正微笑方法，使用向上的曲线而不是向下的曲线
    func smile() {
        // 确保在主线程上执行UI操作
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.smile()
            }
            return
        }
        
        // 创建一个真正的微笑曲线 (向上弯曲)
        let smilePath = CGMutablePath()
        smilePath.move(to: CGPoint(x: -7, y: -8))
        // 修正控制点，在 SpriteKit 中，较大的 y 值表示向下，所以使用 -14 使曲线向上弯曲
        smilePath.addQuadCurve(to: CGPoint(x: 7, y: -8), control: CGPoint(x: 0, y: -14))
        
        mouth.path = smilePath
    }
    
    // 担忧表情
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
        // 担忧的表情，嘴巴向下弯曲
        worriedPath.addQuadCurve(to: CGPoint(x: 7, y: -8), control: CGPoint(x: 0, y: -4))
        
        mouth.path = worriedPath
    }
    
    // 添加一个眨眼的开心表情
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
    }
    
    // 欢悦表情 - 适合听音乐时显示
    func expressionDelight() {
        // 确保在主线程上执行UI操作
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.expressionDelight()
            }
            return
        }
        
        // 稍微更大的眼睛，显示愉悦
        leftEye.setScale(1.1)
        rightEye.setScale(1.1)
        
        // 微笑表情，但弧度更大，显示更加愉悦
        let delightedMouthPath = CGMutablePath()
        delightedMouthPath.move(to: CGPoint(x: -8, y: -8))
        delightedMouthPath.addQuadCurve(to: CGPoint(x: 8, y: -8), control: CGPoint(x: 0, y: -16))
        mouth.path = delightedMouthPath
        
        // 使脸颊稍微更红，表示兴奋
        leftCheek.fillColor = NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.7, alpha: 0.5)
        rightCheek.fillColor = NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.7, alpha: 0.5)
        
        // 定时恢复脸颊颜色
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            self.leftCheek.fillColor = NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.7, alpha: 0.3)
            self.rightCheek.fillColor = NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.7, alpha: 0.3)
        }
    }
} 