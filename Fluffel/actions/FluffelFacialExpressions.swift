import SpriteKit
import Cocoa

// Fluffel 的面部表情扩展
extension Fluffel {
    
    // 惊讶表情 - 用于下落时
    func surprisedFace() {
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
        // 创建一个真正的微笑曲线 (向上弯曲)
        let smilePath = CGMutablePath()
        smilePath.move(to: CGPoint(x: -7, y: -8))
        // 修正控制点，在 SpriteKit 中，较大的 y 值表示向下，所以使用 -14 使曲线向上弯曲
        smilePath.addQuadCurve(to: CGPoint(x: 7, y: -8), control: CGPoint(x: 0, y: -14))
        
        mouth.path = smilePath
    }
    
    // 担忧表情
    func worried() {
        let worriedPath = CGMutablePath()
        worriedPath.move(to: CGPoint(x: -7, y: -8))
        // 担忧的表情，嘴巴向下弯曲
        worriedPath.addQuadCurve(to: CGPoint(x: 7, y: -8), control: CGPoint(x: 0, y: -4))
        
        mouth.path = worriedPath
    }
    
    // 添加一个眨眼的开心表情
    func happyBlink() {
        // 眨眼动画序列
        let close = SKAction.scaleY(to: 0.3, duration: 0.1)
        let open = SKAction.scaleY(to: 1.0, duration: 0.1)
        let blinkAction = SKAction.sequence([close, open])
        
        leftEye.run(blinkAction)
        rightEye.run(blinkAction)
    }
} 