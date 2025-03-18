import SpriteKit
import AppKit

// Fluffel 的工具类扩展
extension Fluffel {
    
    // 将 Fluffel 当前外观保存为图标
    func saveAppearanceAsIcon() {
        // 创建一个比实际大小稍大的图像，以容纳发光效果
        let size = CGSize(width: 200, height: 200)
        let renderer = SKView(frame: NSRect(origin: .zero, size: size))
        
        // 创建场景
        let scene = SKScene(size: size)
        scene.backgroundColor = .clear
        
        // 复制当前节点
        let fluffelCopy = self.copy() as! Fluffel
        fluffelCopy.position = CGPoint(x: size.width/2, y: size.height/2)
        fluffelCopy.setScale(2.0) // 放大一点以获得更好的质量
        scene.addChild(fluffelCopy)
        
        // 渲染场景
        renderer.presentScene(scene)
        
        // 创建图像
        if let image = renderer.texture(from: scene)?.cgImage() {
            let nsImage = NSImage(cgImage: image, size: size)
            
            // 保存到应用程序支持目录
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let fluffelDir = appSupport.appendingPathComponent("Fluffel")
                let iconPath = fluffelDir.appendingPathComponent("icon.png")
                
                do {
                    // 创建目录（如果不存在）
                    try FileManager.default.createDirectory(at: fluffelDir, withIntermediateDirectories: true)
                    
                    // 将图像保存为 PNG
                    if let tiffData = nsImage.tiffRepresentation,
                       let bitmapImage = NSBitmapImageRep(data: tiffData),
                       let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                        try pngData.write(to: iconPath)
                        print("图标已保存到: \(iconPath.path)")
                    }
                } catch {
                    print("保存图标时出错: \(error)")
                }
            }
        }
    }
} 