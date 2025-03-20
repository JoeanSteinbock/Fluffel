import Cocoa

/// 自定义背景视图，用于绘制主题相关的背景元素
class ThemeBackgroundView: NSView {
    var category: FluffelPixabayPlaylists.PlaylistCategory
    private var themeColor: NSColor
    private var animationTimer: Timer?
    private var phase: CGFloat = 0
    
    init(frame: NSRect, category: FluffelPixabayPlaylists.PlaylistCategory) {
        self.category = category
        self.themeColor = category.color.withAlphaComponent(0.15)
        super.init(frame: frame)
        self.wantsLayer = true
        self.layer?.cornerRadius = 0
        self.window?.styleMask.insert(.titled)
        self.window?.isOpaque = false
        self.window?.backgroundColor = .clear
        startAnimation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func startAnimation() {
        // 创建一个定时器，以平滑地更新背景动画
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.phase += 0.01
            if self.phase > CGFloat.pi * 2 {
                self.phase = 0
            }
            self.needsDisplay = true
        }
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    override func draw(_ dirtyRect: NSRect) {
          super.draw(dirtyRect)
          
          guard let context = NSGraphicsContext.current?.cgContext else { return }
          
          // 清除背景
          context.clear(dirtyRect)
          
          let categoryName = category.rawValue.lowercased()
          
          switch categoryName {
          case "relax":
              drawRelaxBackground(in: dirtyRect, context: context)
          case "focus":
              drawFocusBackground(in: dirtyRect, context: context)
          case "workout":
              drawWorkoutBackground(in: dirtyRect, context: context)
          case "party":
              drawPartyBackground(in: dirtyRect, context: context)
          case "productivity":
              drawProductivityBackground(in: dirtyRect, context: context)
          case "sleep":
              drawSleepBackground(in: dirtyRect, context: context)
          case "kids":
              drawKidsBackground(in: dirtyRect, context: context)
          case "fun":
              drawFunBackground(in: dirtyRect, context: context)
          case "ambient":
              drawAmbientBackground(in: dirtyRect, context: context)
          case "electronic":
              drawElectronicBackground(in: dirtyRect, context: context)
          case "motivation":
              drawMotivationBackground(in: dirtyRect, context: context)
          default:
              // Default case - draw a simple background
              drawRelaxBackground(in: dirtyRect, context: context)
          }
      }
    
    // 为"放松"主题绘制平滑的波浪
    private func drawRelaxBackground(in rect: CGRect, context: CGContext) {
        let color1 = category.color.withAlphaComponent(0.1)
        let color2 = category.color.withAlphaComponent(0.05)
        
        // 绘制多层波浪
        drawWaves(in: rect, context: context, color: color1, amplitude: 40, period: rect.width / 2, yOffset: rect.height / 3, phaseOffset: 0)
        drawWaves(in: rect, context: context, color: color2, amplitude: 30, period: rect.width / 3, yOffset: rect.height / 2, phaseOffset: CGFloat.pi / 2)
    }
    
    // 为"专注"主题绘制同心圆和螺旋
    private func drawFocusBackground(in rect: CGRect, context: CGContext) {
        let color1 = category.color.withAlphaComponent(0.1)
        let color2 = category.color.withAlphaComponent(0.05)
        
        // 绘制同心圆
        let centerX = rect.width / 2
        let centerY = rect.height / 2
        
        for i in stride(from: 0, to: 10, by: 1) {
            let radius = 50.0 + Double(i) * 60.0
            let alpha = 0.1 - Double(i) * 0.01
            
            context.setStrokeColor(category.color.withAlphaComponent(CGFloat(alpha)).cgColor)
            context.setLineWidth(1.0)
            context.addArc(center: CGPoint(x: centerX, y: centerY),
                           radius: CGFloat(radius),
                           startAngle: 0,
                           endAngle: CGFloat.pi * 2,
                           clockwise: false)
            context.strokePath()
        }
        
        // 绘制一些点线，模拟星空效果
        context.setFillColor(color1.cgColor)
        for _ in 0..<50 {
            let x = CGFloat.random(in: 0...rect.width)
            let y = CGFloat.random(in: 0...rect.height)
            let size = CGFloat.random(in: 1...3)
            
            context.fillEllipse(in: CGRect(x: x, y: y, width: size, height: size))
        }
    }
    
    // 为"锻炼"主题绘制活力线条
    private func drawWorkoutBackground(in rect: CGRect, context: CGContext) {
        let color1 = category.color.withAlphaComponent(0.1)
        
        // 绘制动态脉搏线
        context.setStrokeColor(color1.cgColor)
        context.setLineWidth(2.0)
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: rect.height / 2))
        
        let segmentWidth: CGFloat = 20
        let segmentCount = Int(rect.width / segmentWidth) + 1
        
        for i in 0..<segmentCount {
            let x = CGFloat(i) * segmentWidth
            let pulseHeight = sin(CGFloat(i) * 0.5 + phase) * 20
            
            // 在某些点上添加心跳效果
            if i % 10 == 0 {
                path.addLine(to: CGPoint(x: x, y: rect.height / 2 - 40))
                path.addLine(to: CGPoint(x: x + 5, y: rect.height / 2 + 40))
                path.addLine(to: CGPoint(x: x + 10, y: rect.height / 2))
            } else {
                path.addLine(to: CGPoint(x: x, y: rect.height / 2 + pulseHeight))
            }
        }
        
        context.addPath(path)
        context.strokePath()
        
        // 添加一些横向线条
        for i in stride(from: 0, to: rect.height, by: 50) {
            context.move(to: CGPoint(x: 0, y: i))
            context.addLine(to: CGPoint(x: rect.width, y: i))
        }
        
        context.setStrokeColor(color1.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(0.5)
        context.strokePath()
    }
    
    // 为"派对"主题绘制彩色气泡和动态效果
    private func drawPartyBackground(in rect: CGRect, context: CGContext) {
        // 绘制彩色气泡
        let bubbleColors = [
            NSColor.systemPink.withAlphaComponent(0.1),
            NSColor.systemBlue.withAlphaComponent(0.1),
            NSColor.systemGreen.withAlphaComponent(0.1),
            NSColor.systemYellow.withAlphaComponent(0.1),
            NSColor.systemPurple.withAlphaComponent(0.1)
        ]
        
        // 基于phase生成不同的气泡位置
        for i in 0..<30 {
            let randomIndex = Int.random(in: 0..<bubbleColors.count)
            let color = bubbleColors[randomIndex]
            
            let x = sin(CGFloat(i) * 0.7 + phase) * rect.width/2 + rect.width/2
            let y = cos(CGFloat(i) * 0.5 + phase) * rect.height/2 + rect.height/2
            let size = CGFloat.random(in: 10...50)
            
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: CGRect(x: x - size/2, y: y - size/2, width: size, height: size))
        }
    }
    
    // 为"生产力"主题绘制动态进度条
     private func drawProductivityBackground(in rect: CGRect, context: CGContext) {
         // 绘制背景颜色
         context.setFillColor(category.color.withAlphaComponent(0.05).cgColor)
         context.fill(rect)
         
         // 绘制对角进度条
         let barColor = category.color.withAlphaComponent(0.2)
         context.setFillColor(barColor.cgColor)
         
         let barWidth: CGFloat = 20
         let barSpacing: CGFloat = 60
         let barCount = Int((rect.width + rect.height) / barSpacing) + 1
         
         for i in 0..<barCount {
             let offset = CGFloat(i) * barSpacing + (phase * 100).truncatingRemainder(dividingBy: barSpacing * 2) - barSpacing
             let xStart = offset
             let yStart = 0 - offset
             let xEnd = rect.width + offset
             let yEnd = rect.height - offset
             
             let path = CGMutablePath()
             path.move(to: CGPoint(x: xStart, y: yStart))
             path.addLine(to: CGPoint(x: xStart + barWidth, y: yStart + barWidth))
             path.addLine(to: CGPoint(x: xEnd + barWidth, y: yEnd + barWidth))
             path.addLine(to: CGPoint(x: xEnd, y: yEnd))
             path.closeSubpath()
             
             context.addPath(path)
             context.fillPath()
         }
     }
     
     // 为"睡眠"主题绘制星空和月光效果
     private func drawSleepBackground(in rect: CGRect, context: CGContext) {
         // 绘制深色背景
         let gradientColors = [NSColor.black.withAlphaComponent(0.3).cgColor,
                              category.color.withAlphaComponent(0.1).cgColor]
         let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                   colors: gradientColors as CFArray,
                                   locations: [0.0, 1.0])!
         context.drawLinearGradient(gradient,
                                    start: CGPoint(x: rect.midX, y: rect.minY),
                                    end: CGPoint(x: rect.midX, y: rect.maxY),
                                    options: [])
         
         // 绘制月亮
         let moonX = rect.width * 0.7
         let moonY = rect.height * 0.3
         let moonRadius: CGFloat = 50
         let moonGlow = category.color.withAlphaComponent(0.2)
         context.setFillColor(moonGlow.cgColor)
         context.fillEllipse(in: CGRect(x: moonX - moonRadius, y: moonY - moonRadius, width: moonRadius * 2, height: moonRadius * 2))
         
         // 绘制闪烁的星星
         context.setFillColor(NSColor.white.withAlphaComponent(0.3).cgColor)
         for i in 0..<50 {
             let x = CGFloat.random(in: 0...rect.width)
             let y = CGFloat.random(in: 0...rect.height)
             let size = CGFloat.random(in: 1...3)
             let alpha = abs(sin(phase + CGFloat(i) * 0.2)) * 0.3 + 0.1 // 闪烁效果
             context.setFillColor(NSColor.white.withAlphaComponent(alpha).cgColor)
             context.fillEllipse(in: CGRect(x: x - size/2, y: y - size/2, width: size, height: size))
         }
     }
     
     // 为"儿童"主题绘制跳动的彩色形状
     private func drawKidsBackground(in rect: CGRect, context: CGContext) {
         // 绘制背景颜色
         context.setFillColor(category.color.withAlphaComponent(0.05).cgColor)
         context.fill(rect)
         
         // 绘制跳动的星星和心形
         let shapeColors = [
             NSColor.systemRed.withAlphaComponent(0.3),
             NSColor.systemBlue.withAlphaComponent(0.3),
             NSColor.systemYellow.withAlphaComponent(0.3),
             NSColor.systemGreen.withAlphaComponent(0.3)
         ]
         
         for i in 0..<20 {
             let randomIndex = Int.random(in: 0..<shapeColors.count)
             let color = shapeColors[randomIndex]
             
             let x = CGFloat.random(in: 0...rect.width)
             let y = CGFloat.random(in: 0...rect.height)
             let size = CGFloat.random(in: 15...30)
             let bounce = sin(phase + CGFloat(i) * 0.5) * 5 // 跳动效果
             
             context.setFillColor(color.cgColor)
             
             // 随机选择星星或心形
             if i % 2 == 0 {
                 // 星星
                 drawStar(in: context, at: CGPoint(x: x, y: y + bounce), size: size)
             } else {
                 // 心形
                 drawHeart(in: context, at: CGPoint(x: x, y: y + bounce), size: size)
             }
         }
     }
     
     // 为"乐趣"主题绘制下落的彩纸效果
     private func drawFunBackground(in rect: CGRect, context: CGContext) {
         // 绘制背景颜色
         context.setFillColor(category.color.withAlphaComponent(0.05).cgColor)
         context.fill(rect)
         
         // 绘制下落的彩纸
         let confettiColors = [
             NSColor.systemPink.withAlphaComponent(0.3),
             NSColor.systemBlue.withAlphaComponent(0.3),
             NSColor.systemYellow.withAlphaComponent(0.3),
             NSColor.systemGreen.withAlphaComponent(0.3)
         ]
         
         for i in 0..<30 {
             let randomIndex = Int.random(in: 0..<confettiColors.count)
             let color = confettiColors[randomIndex]
             
             let x = CGFloat.random(in: 0...rect.width)
             let yOffset = (phase * 100 + CGFloat(i) * 20).truncatingRemainder(dividingBy: (rect.height + 50)) - 50
             let y = rect.height - yOffset
             let size = CGFloat.random(in: 5...15)
             let rotation = sin(phase + CGFloat(i) * 0.3) * CGFloat.pi / 4
             
             context.saveGState()
             context.translateBy(x: x, y: y)
             context.rotate(by: rotation)
             context.setFillColor(color.cgColor)
             context.fill(CGRect(x: -size/2, y: -size/2, width: size, height: size))
             context.restoreGState()
         }
     }
     
     // 为"环境"主题绘制极光效果
     private func drawAmbientBackground(in rect: CGRect, context: CGContext) {
         // 绘制背景颜色
         context.setFillColor(NSColor.black.withAlphaComponent(0.3).cgColor)
         context.fill(rect)
         
         // 绘制极光带
         let auroraColors = [
             category.color.withAlphaComponent(0.1),
             NSColor.systemGreen.withAlphaComponent(0.1),
             NSColor.systemPurple.withAlphaComponent(0.1)
         ]
         
         for i in 0..<3 {
             let color = auroraColors[i % auroraColors.count]
             let yOffset = rect.height * 0.2 + CGFloat(i) * rect.height * 0.2
             drawWaves(in: rect, context: context, color: color, amplitude: 50, period: rect.width / 2, yOffset: yOffset, phaseOffset: phase + CGFloat(i) * CGFloat.pi / 3)
         }
     }
     
     // 为"电子"主题绘制脉动的网格点
     private func drawElectronicBackground(in rect: CGRect, context: CGContext) {
         // 绘制背景颜色
         context.setFillColor(category.color.withAlphaComponent(0.05).cgColor)
         context.fill(rect)
         
         // 绘制网格点
         let dotColor = category.color.withAlphaComponent(0.3)
         let spacing: CGFloat = 40
         let dotSize: CGFloat = 4
         
         for x in stride(from: 0, to: rect.width, by: spacing) {
             for y in stride(from: 0, to: rect.height, by: spacing) {
                 let pulse = sin(phase + x * 0.02 + y * 0.02) * 2
                 let size = dotSize + pulse
                 context.setFillColor(dotColor.cgColor)
                 context.fillEllipse(in: CGRect(x: x - size/2, y: y - size/2, width: size, height: size))
                 
                 // 绘制连接线
                 if x + spacing < rect.width {
                     context.setStrokeColor(dotColor.withAlphaComponent(0.1).cgColor)
                     context.setLineWidth(1.0)
                     context.move(to: CGPoint(x: x, y: y))
                     context.addLine(to: CGPoint(x: x + spacing, y: y))
                     context.strokePath()
                 }
                 if y + spacing < rect.height {
                     context.setStrokeColor(dotColor.withAlphaComponent(0.1).cgColor)
                     context.setLineWidth(1.0)
                     context.move(to: CGPoint(x: x, y: y))
                     context.addLine(to: CGPoint(x: x, y: y + spacing))
                     context.strokePath()
                 }
             }
         }
     }
     
     // 为"激励"主题绘制日出和光线效果
     private func drawMotivationBackground(in rect: CGRect, context: CGContext) {
         // 绘制渐变背景（日出）
         let gradientColors = [category.color.withAlphaComponent(0.2).cgColor,
                              NSColor.black.withAlphaComponent(0.3).cgColor]
         let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                   colors: gradientColors as CFArray,
                                   locations: [0.0, 1.0])!
         context.drawLinearGradient(gradient,
                                    start: CGPoint(x: rect.midX, y: rect.minY),
                                    end: CGPoint(x: rect.midX, y: rect.maxY),
                                    options: [])
         
         // 绘制太阳
         let sunX = rect.width / 2
         let sunY = rect.height * 0.7 + sin(phase) * 20 // 太阳上下移动
         let sunRadius: CGFloat = 60
         context.setFillColor(category.color.withAlphaComponent(0.3).cgColor)
         context.fillEllipse(in: CGRect(x: sunX - sunRadius, y: sunY - sunRadius, width: sunRadius * 2, height: sunRadius * 2))
         
         // 绘制光线
         context.setStrokeColor(category.color.withAlphaComponent(0.2).cgColor)
         context.setLineWidth(2.0)
         for i in 0..<12 {
             let angle = CGFloat(i) * (CGFloat.pi / 6) + phase * 0.2
             let length = 100 + abs(sin(phase + CGFloat(i) * 0.3)) * 20 // 光线长度变化
             let xEnd = sunX + cos(angle) * length
             let yEnd = sunY + sin(angle) * length
             context.move(to: CGPoint(x: sunX, y: sunY))
             context.addLine(to: CGPoint(x: xEnd, y: yEnd))
         }
         context.strokePath()
     }
    
    // 通用的波浪绘制方法
    private func drawWaves(in rect: CGRect, context: CGContext, color: NSColor, amplitude: CGFloat, period: CGFloat, yOffset: CGFloat, phaseOffset: CGFloat) {
        context.setFillColor(color.cgColor)
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        
        let step: CGFloat = 5
        for x in stride(from: CGFloat(0), to: rect.width, by: step) {
            let relativePhase = phase + phaseOffset
            let y = amplitude * sin((x / period) * CGFloat.pi * 2 + relativePhase) + yOffset
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // 完成波浪路径
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.closeSubpath()
        
        context.addPath(path)
        context.fillPath()
    }
    
    // 绘制星星形状
     private func drawStar(in context: CGContext, at center: CGPoint, size: CGFloat) {
         let points = 5
         let outerRadius = size / 2
         let innerRadius = outerRadius * 0.4
         let path = CGMutablePath()
         
         for i in 0..<points * 2 {
             let angle = CGFloat(i) * CGFloat.pi / CGFloat(points) - CGFloat.pi / 2
             let radius = i % 2 == 0 ? outerRadius : innerRadius
             let x = center.x + cos(angle) * radius
             let y = center.y + sin(angle) * radius
             if i == 0 {
                 path.move(to: CGPoint(x: x, y: y))
             } else {
                 path.addLine(to: CGPoint(x: x, y: y))
             }
         }
         path.closeSubpath()
         
         context.addPath(path)
         context.fillPath()
     }
     
     // 绘制心形
     private func drawHeart(in context: CGContext, at center: CGPoint, size: CGFloat) {
         let path = CGMutablePath()
         let width = size
         let height = size * 1.2
         
         let x = center.x - width / 2
         let y = center.y - height / 2 + height * 0.2
         
         path.move(to: CGPoint(x: x + width / 2, y: y + height))
         path.addQuadCurve(to: CGPoint(x: x, y: y + height / 4),
                           control: CGPoint(x: x, y: y + height))
         path.addQuadCurve(to: CGPoint(x: x + width / 2, y: y),
                           control: CGPoint(x: x, y: y))
         path.addQuadCurve(to: CGPoint(x: x + width, y: y + height / 4),
                           control: CGPoint(x: x + width, y: y))
         path.addQuadCurve(to: CGPoint(x: x + width / 2, y: y + height),
                           control: CGPoint(x: x + width, y: y + height))
         path.closeSubpath()
         
         context.addPath(path)
         context.fillPath()
     }
}
