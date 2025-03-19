//
//  ViewController.swift
//  Fluffel
//
//  Created by Anton Lee on 16/3/2025.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {

    @IBOutlet var skView: SKView!
    var scene: FluffelScene?
    
    // 调试相关
    private var isDebugMode = false
    private var debugLabel: NSTextField?
    private var debugToggleButton: NSButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.skView {
            // 创建场景
            let scene = FluffelScene()
            scene.scaleMode = .resizeFill
            scene.size = view.frame.size
            view.presentScene(scene)
            self.scene = scene
            
            view.ignoresSiblingOrder = true
            
            // 添加调试视图
            setupDebugControls()
        }
    }
    
    private func setupDebugControls() {
        // 创建调试开关按钮
        let button = NSButton(frame: NSRect(x: 10, y: 10, width: 100, height: 30))
        button.title = "调试模式: 关"
        button.bezelStyle = .rounded
        button.setButtonType(.toggle)
        button.state = .off
        button.target = self
        button.action = #selector(toggleDebugMode)
        self.view.addSubview(button)
        debugToggleButton = button
        
        // 创建调试信息标签
        let label = NSTextField(frame: NSRect(x: 120, y: 10, width: 300, height: 100))
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.backgroundColor = .clear
        label.textColor = .red
        label.font = NSFont.systemFont(ofSize: 10)
        label.stringValue = ""
        label.isHidden = true
        self.view.addSubview(label)
        debugLabel = label
        
        // 注册接收调试信息的通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDebugInfo),
            name: .fluffelDebugInfo,
            object: nil
        )
    }
    
    @objc private func toggleDebugMode(_ sender: NSButton) {
        isDebugMode = (sender.state == .on)
        debugToggleButton?.title = "调试模式: \(isDebugMode ? "开" : "关")"
        debugLabel?.isHidden = !isDebugMode
        scene?.setDebugMode(isDebugMode)
    }
    
    @objc private func handleDebugInfo(_ notification: Notification) {
        guard isDebugMode,
              let userInfo = notification.userInfo,
              let debugInfo = userInfo["debugInfo"] as? String else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.debugLabel?.stringValue = debugInfo
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // 初始化场景大小
        if let view = self.skView, let scene = view.scene {
            scene.size = view.frame.size
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        // 更新场景大小以匹配视图大小
        if let view = self.skView, let scene = view.scene {
            scene.size = view.frame.size
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}

