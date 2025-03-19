# Fluffel 说话功能使用指南

## 概述

Fluffel 现在可以通过对话气泡显示文本了！这个新功能让 Fluffel 能够与用户进行更多互动，包括问候、讲笑话、分享事实或进行简单的对话。

## 功能特点

1. **对话气泡显示**：当 Fluffel 说话时，会在其上方显示一个卡通风格的对话气泡
2. **动画效果**：对话气泡有淡入淡出动画效果
3. **自动调整**：气泡大小会根据文本内容自动调整
4. **方向感知**：气泡会根据 Fluffel 在屏幕上的位置自动调整方向，避免超出屏幕边界
5. **多语言支持**：支持中文和其他 Unicode 字符

## 如何使用

### 通过菜单触发

应用添加了一个 "Fluffel" 菜单，包含以下选项：

- **问候**：让 Fluffel 随机说一句问候语（快捷键：Cmd+G）
- **讲笑话**：让 Fluffel 随机讲一个笑话（快捷键：Cmd+J）
- **分享事实**：让 Fluffel 随机分享一个关于自己的事实（快捷键：Cmd+F）
- **进行对话**：让 Fluffel 进行一段连续的对话（快捷键：Cmd+C）

### 通过点击触发

直接点击 Fluffel 也会触发随机问候。

### 通过代码调用

在你的代码中，你可以使用以下方法让 Fluffel 说话：

```swift
// 基本用法
fluffel.speak(text: "Hello! I'm Fluffel!", duration: 3.0)

// 带完成回调的用法
fluffel.speak(text: "This is a message", duration: 2.0) {
    print("Speaking finished!")
}

// 自定义字体大小
fluffel.speak(text: "This is a big font message", duration: 2.0, fontSize: 16.0)
```

## 技术细节

说话功能实现在 `FluffelSpecialActions.swift` 文件中，主要包括：

1. **对话气泡创建**：使用 `SKShapeNode` 创建气泡背景
2. **文本显示**：使用 `SKLabelNode` 显示文本内容
3. **动画效果**：使用 `SKAction` 实现淡入淡出效果
4. **自动调整**：根据文本长度和内容动态调整气泡大小
5. **位置适应**：根据 Fluffel 在屏幕上的位置调整气泡方向和位置

## 定制说话内容

如果你想添加或修改 Fluffel 能说的话，可以编辑 `FluffelSpeakingDemo.swift` 文件中的内容数组：

- `greetings`：问候语集合
- `jokes`：笑话集合 
- `facts`：事实集合
- `conversation`：连续对话内容

## 注意事项

- 当 Fluffel 开始其他动作（如行走、下落等）时，对话气泡会自动消失
- 说话持续时间可以通过 `duration` 参数自定义
- 说话完成后可以通过完成回调执行后续操作 