# Fluffel 文本转语音功能使用指南

## 概述

Fluffel 现在支持文本转语音（TTS）功能！当 Fluffel 说话时，不仅会显示对话气泡，还会用可爱的语音朗读文本内容，让互动体验更加生动有趣。

## 前提条件

要使用 TTS 功能，您需要：

1. 拥有 Google Cloud Platform 账户
2. 启用 Google Cloud Text-to-Speech API
3. 创建 API 密钥并添加到 Fluffel 中

## 设置步骤

1. **创建 Google Cloud 项目**（如果您还没有）：
   - 访问 [Google Cloud Console](https://console.cloud.google.com/)
   - 点击导航菜单中的"新建项目"
   - 输入项目名称（例如"fluffel-tts"）并创建

2. **启用计费**（必须为项目启用计费才能使用 API）：
   - 在导航菜单中选择"结算"
   - 按照提示为您的项目启用结算

3. **启用 Text-to-Speech API**：
   - 在导航菜单中选择"API 和服务" > "库"
   - 搜索"Text-to-Speech"
   - 选择 "Cloud Text-to-Speech API" 并点击"启用"

4. **创建 API 密钥**：
   - 在导航菜单中选择"API 和服务" > "凭据"
   - 点击"创建凭据" > "API 密钥"
   - 复制生成的 API 密钥
   - （推荐）设置 API 密钥限制，仅允许 Text-to-Speech API 访问

## 在 Fluffel 中设置 API 密钥

1. 启动 Fluffel 应用程序
2. 从菜单栏中选择 "Fluffel" > "Set API Key"
3. 在弹出的窗口中粘贴您的 Google Cloud API 密钥
4. 点击"测试"确认密钥工作正常
5. 点击"保存"保存密钥

## 使用方法

### 测试 TTS 功能

1. 启动 Fluffel 应用程序
2. 从菜单栏中选择 "Fluffel" > "Test TTS"
3. 如果您还没有设置 API 密钥，系统会提示您进行设置
4. 设置完成后，您应该能听到 Fluffel 说话："Hello, I'm Fluffel, your fluffy desktop pet!"

### 自定义语音

默认情况下，Fluffel 使用 Google 的 `en-US-Chirp3-HD-Kore` 声音，这是一个听起来可爱且适合 Fluffel 角色的声音。如果您想更改语音，可以修改 `FluffelTTSService.swift` 文件中的 `VoiceConfig` 结构体。

Google Cloud 提供了多种不同语言和风格的声音选项，您可以在 [Google Cloud TTS 文档](https://cloud.google.com/text-to-speech/docs/voices) 中查看完整列表。

### 添加新的对话内容

您可以通过编辑 `Fluffel/Resources/FluffelDialogues.json` 文件来添加新的对话内容。TTS 系统会自动朗读这些对话。

## 技术说明

TTS 功能的实现基于以下组件：

1. **FluffelTTSService**：负责与 Google Cloud Text-to-Speech API 通信并播放返回的音频
2. **AVFoundation**：用于播放音频
3. **Google Cloud Text-to-Speech API**：将文本转换为语音

## 故障排除

如果您遇到 TTS 相关问题：

1. **无声音输出**：
   - 检查系统音量
   - 确认您已正确设置 API 密钥
   - 检查控制台日志中的错误消息

2. **API 错误**：
   - 验证您的 API 密钥是否有效
   - 确保您已启用计费
   - 检查您是否超出了 API 配额
   - 确保 API 密钥没有限制从 Fluffel 应用访问

3. **语音质量问题**：
   - 尝试不同的声音选项
   - 对过长的文本进行分段处理

## API 密钥安全建议

为了保护您的 API 密钥安全：

1. 在 Google Cloud Console 中设置密钥限制，仅允许从特定 IP 地址或仅用于特定 API
2. 定期轮换您的 API 密钥
3. 不要在共享计算机上使用 Fluffel，因为 API 密钥存储在本地用户配置中

## 资源使用注意事项

Google Cloud Text-to-Speech API 是一项付费服务，有以下注意事项：

1. 每月有一定的免费配额（通常为 100 万字符）
2. 超出免费配额后将按使用量收费
3. 使用高质量 HD 语音会消耗更多配额

## 未来改进计划

- 支持多语言 TTS
- 添加语音速度和音调控制
- 在气泡中显示语音状态指示
- 为不同的 Fluffel 状态使用不同的语音风格 