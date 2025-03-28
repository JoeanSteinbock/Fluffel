import Cocoa

class FluffelPlaylistWindow: NSWindow {
    // 播放列表视图
    private var playlistView: NSView!
    private var category: FluffelPixabayPlaylists.PlaylistCategory
    internal weak var appDelegate: AppDelegate?
    
    // 网格布局常量 - 调整为更优雅的比例
    private let gridItemWidth: CGFloat = 220  // 增大卡片宽度
    private let gridItemHeight: CGFloat = 160 // 使卡片成为更美观的长方形
    private let gridSpacing: CGFloat = 24     // 增加间距使布局更宽敞
    private let edgeInsets: CGFloat = 32      // 增加边缘间距
    
    // 背景视图
    private var backgroundView: ThemeBackgroundView!
    
    init(category: FluffelPixabayPlaylists.PlaylistCategory, delegate: AppDelegate) {
        print("Initializing playlist window for category: \(category.rawValue)")
        self.category = category
        self.appDelegate = delegate
        
        // 获取播放列表数据以确定窗口高度
        let tracks = FluffelPixabayPlaylists.shared.getPlaylist(for: category)
        
        // 计算合适的窗口高度 - 当项目少于3个（只有一行）时使用较小的高度
        let itemsPerRow = max(2, Int(736 / (gridItemWidth + gridSpacing)))
        let rowCount = (tracks.count + itemsPerRow - 1) / itemsPerRow
        let windowHeight: CGFloat = rowCount <= 1 ? 450 : 700 // 少于3个项目时使用较小的高度
        
        // 创建固定大小的窗口 (不可调整大小)
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable], // 移除.resizable选项
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        self.title = "\(category.icon) \(category.rawValue) Playlists"
        self.center()
        self.isReleasedWhenClosed = false
        
        // 设置窗口背景为白色，背景元素会叠加在上面
        self.backgroundColor = .windowBackgroundColor
        
        // 设置窗口置顶
        self.level = .floating
        
        // 自定义标题栏样式
        stylizeTitlebar()
        
        // 创建内容视图
        setupContentView()
        
        print("Playlist window initialized")
    }
    
    private func setupContentView() {
        print("Setting up content view")
        
        // Create main view
        playlistView = NSView(frame: contentView?.bounds ?? .zero)
        playlistView.wantsLayer = true
        
        // Create theme background view
        backgroundView = ThemeBackgroundView(frame: playlistView.bounds, category: category)
        backgroundView.autoresizingMask = [.width, .height]
        playlistView.addSubview(backgroundView)
        
        // Add frosted glass effect background
        let visualEffectView = NSVisualEffectView(frame: playlistView.bounds)
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.material = .sheet
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.alphaValue = 0.3
        playlistView.addSubview(visualEffectView)
        
        // Create scroll view
        let scrollView = NSScrollView(frame: playlistView.bounds)
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        
        // Create playlist container
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Get playlists
        print("Fetching tracks for category: \(category.rawValue)")
        let tracks = FluffelPixabayPlaylists.shared.getPlaylist(for: category)
        print("Retrieved \(tracks.count) tracks")
        
        // If no tracks, show loading state
        if tracks.isEmpty {
            print("No tracks found, showing loading state")
            // Show loading indicator
            let loadingText = NSTextField(labelWithString: "Loading playlists...")
            loadingText.translatesAutoresizingMaskIntoConstraints = false
            loadingText.font = .systemFont(ofSize: 18, weight: .medium)
            loadingText.textColor = .labelColor
            containerView.addSubview(loadingText)
            
            let spinner = NSProgressIndicator()
            spinner.style = .spinning
            spinner.controlSize = .large
            spinner.isIndeterminate = true
            spinner.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(spinner)
            spinner.startAnimation(nil)
            
            NSLayoutConstraint.activate([
                loadingText.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                loadingText.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -40),
                
                spinner.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                spinner.topAnchor.constraint(equalTo: loadingText.bottomAnchor, constant: 24),
                spinner.widthAnchor.constraint(equalToConstant: 42),
                spinner.heightAnchor.constraint(equalToConstant: 42)
            ])
            
            // Start loading playlists
            FluffelPixabayPlaylists.shared.loadPlaylists { [weak self] success in
                print("Playlists load completed with success: \(success)")
                DispatchQueue.main.async {
                    if success {
                        // Remove loading indicators
                        loadingText.removeFromSuperview()
                        spinner.removeFromSuperview()
                        // Refresh the content view with the loaded data
                        let tracks = FluffelPixabayPlaylists.shared.getPlaylist(for: self?.category ?? .relax)
                        if tracks.isEmpty {
                            print("Tracks still empty after loading, showing empty state")
                            self?.setupUIWithTracks([], in: containerView)
                        } else {
                            self?.setupUIWithTracks(tracks, in: containerView)
                        }
                    } else {
                        // Show error state if loading fails
                        loadingText.stringValue = "Failed to load playlists"
                        spinner.stopAnimation(nil)
                        spinner.removeFromSuperview()
                        // Still show the empty state view
                        self?.setupUIWithTracks([], in: containerView)
                    }
                }
            }
        } else {
            print("Setting up UI with \(tracks.count) tracks")
            setupUIWithTracks(tracks, in: containerView)
        }
        
        // Set document view
        scrollView.documentView = containerView
        
        // Add scroll view to main view
        playlistView.addSubview(scrollView)
        scrollView.frame = playlistView.bounds
        
        // Ensure the containerView's height is at least as tall as the scrollView's visible area
        // and can expand to fit all content
        if let clipView = scrollView.contentView.superview {
            NSLayoutConstraint.activate([
                containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                containerView.heightAnchor.constraint(greaterThanOrEqualTo: clipView.heightAnchor)
            ])
        }
        
        // Make sure scrollView has proper settings
        scrollView.hasVerticalScroller = true
        scrollView.verticalScrollElasticity = .allowed
        scrollView.autohidesScrollers = false
        
        // Set content view
        contentView = playlistView
        
        print("Content view setup completed")
    }
    
    // 添加标题栏样式方法
    private func stylizeTitlebar() {
        // 确保窗口有标题栏
        guard let titlebar = self.standardWindowButton(.closeButton)?.superview?.superview else {
            return
        }
        
        // 为标题栏添加观察者，以便在窗口大小调整时重新配置样式
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: self
        )
        
        // 为窗口的标题文本添加颜色（标题栏上的文本）
        if let titleView = titlebar.subviews.first(where: { $0 is NSTextField }) as? NSTextField {
            titleView.textColor = category.color
            titleView.font = .systemFont(ofSize: 14, weight: .semibold)
        }
        
        // 为关闭、最小化和缩放按钮添加主题色调
        if let closeButton = self.standardWindowButton(.closeButton),
           let minimizeButton = self.standardWindowButton(.miniaturizeButton),
           let zoomButton = self.standardWindowButton(.zoomButton) {
            
            // 简单地增强按钮的视觉样式
            for button in [closeButton, minimizeButton, zoomButton] {
                if let buttonCell = button.cell as? NSButtonCell {
                    buttonCell.highlightsBy = .contentsCellMask
                }
            }
        }
    }
    
    // 处理窗口大小调整
    @objc private func windowDidResize(_ notification: Notification) {
        // 更新背景视图布局
        backgroundView?.needsDisplay = true
        
        // 重新计算滚动视图布局等
        if let scrollView = self.contentView?.subviews.first(where: { $0 is NSScrollView }) as? NSScrollView,
           let documentView = scrollView.documentView,
           let containerWidth = contentView?.frame.width {
            
            // 更新容器视图宽度约束
            for constraint in documentView.constraints where constraint.firstAttribute == .width {
                constraint.constant = containerWidth
            }
        }
    }
    
    deinit {
        // 移除通知观察者
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUIWithTracks(_ tracks: [Track], in containerView: NSView) {
        print("Setting up UI with tracks: \(tracks.count)")
        
        // Create playlist header
        let headerView = createHeaderView(category: category)
        containerView.addSubview(headerView)
        
        // Add separator
        let separator = createSeparator()
        containerView.addSubview(separator)
        
        // Calculate grid layout parameters
        let frameWidth = (contentView?.frame.width ?? 800)
        let availableWidth = frameWidth - (edgeInsets * 2)
        
        // Calculate the number of items per row
        let maxItemsPerRow = max(2, Int(availableWidth / (gridItemWidth + gridSpacing)))
        let actualItemsPerRow = maxItemsPerRow
        let actualHorizontalSpacing = (availableWidth - (CGFloat(actualItemsPerRow) * gridItemWidth)) / CGFloat(max(1, actualItemsPerRow - 1))
        
        // Create grid container view
        let gridContainer = NSView()
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(gridContainer)
        
        // Check if there is enough data
        if tracks.isEmpty {
            print("Tracks are empty, showing empty state view")
            // Create "no data" placeholder view
            let emptyStateView = createEmptyStateView()
            gridContainer.addSubview(emptyStateView)
            
            // Align emptyStateView to the top of gridContainer
            NSLayoutConstraint.activate([
                emptyStateView.topAnchor.constraint(equalTo: gridContainer.topAnchor, constant: 20),
                emptyStateView.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor),
                emptyStateView.trailingAnchor.constraint(equalTo: gridContainer.trailingAnchor),
                emptyStateView.bottomAnchor.constraint(equalTo: gridContainer.bottomAnchor, constant: -20)
            ])
            
            // Set container view constraints
            NSLayoutConstraint.activate([
                headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
                headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: edgeInsets),
                headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -edgeInsets),
                
                separator.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
                separator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: edgeInsets),
                separator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -edgeInsets),
                
                gridContainer.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 24),
                gridContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: edgeInsets),
                gridContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -edgeInsets),
                
                containerView.widthAnchor.constraint(equalToConstant: frameWidth)
            ])
            
            return
        }
        
        // If there is data, add playlist items to the grid
        var currentRow = 0
        var currentColumn = 0
        
        // Add animation delay factor
        let animationBaseDelay = 0.05
        
        for (index, track) in tracks.enumerated() {
            let itemView = createPlaylistItemView(track: track, index: index)
            gridContainer.addSubview(itemView)
            
            // Set initial opacity for animation
            itemView.alphaValue = 0
            
            // Calculate position
            let xPosition = CGFloat(currentColumn) * (gridItemWidth + actualHorizontalSpacing)
            let yPosition = CGFloat(currentRow) * (gridItemHeight + gridSpacing)
            
            // Set constraints
            NSLayoutConstraint.activate([
                itemView.widthAnchor.constraint(equalToConstant: gridItemWidth),
                itemView.heightAnchor.constraint(equalToConstant: gridItemHeight),
                itemView.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor, constant: xPosition),
                itemView.topAnchor.constraint(equalTo: gridContainer.topAnchor, constant: yPosition)
            ])
            
            // Add animation
            let staggerDelay = TimeInterval(index) * animationBaseDelay
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                context.allowsImplicitAnimation = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + staggerDelay) {
                    itemView.animator().alphaValue = 1.0
                    
                    let scaleAnimation = CASpringAnimation(keyPath: "transform.scale")
                    scaleAnimation.fromValue = 0.95
                    scaleAnimation.toValue = 1.0
                    scaleAnimation.duration = 0.4
                    scaleAnimation.damping = 12.0
                    itemView.layer?.add(scaleAnimation, forKey: "scale")
                }
            })
            
            // Update row and column positions
            currentColumn += 1
            if currentColumn >= actualItemsPerRow {
                currentColumn = 0
                currentRow += 1
            }
        }
        
        // Calculate grid container height with a minimum height
        let rowCount = (tracks.count + actualItemsPerRow - 1) / actualItemsPerRow
        let calculatedGridHeight = CGFloat(rowCount) * gridItemHeight + CGFloat(max(0, rowCount - 1)) * gridSpacing
        
        // Adjust minimum height based on number of items
        let minimumGridHeight: CGFloat = rowCount <= 1 ? 200 : 300 // Use smaller height for single row
        let gridHeight = max(calculatedGridHeight, minimumGridHeight)
        
        // Set container view constraints
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: edgeInsets),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -edgeInsets),
            
            separator.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: edgeInsets),
            separator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -edgeInsets),
            
            gridContainer.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 24),
            gridContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: edgeInsets),
            gridContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -edgeInsets),
            gridContainer.heightAnchor.constraint(equalToConstant: gridHeight),
            
            // Add bottom constraint to ensure all content is included in scrollable area
            gridContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -edgeInsets),
            
            containerView.widthAnchor.constraint(equalToConstant: frameWidth)
        ])
    }
    
    // 添加刷新方法
    @objc private func refreshContentView() {
        print("Refreshing content view")
        let tracks = FluffelPixabayPlaylists.shared.getPlaylist(for: category)
        print("Retrieved \(tracks.count) tracks after refresh")
        
        // 显示加载提示
        let toast = NSTextField(labelWithString: "Refreshing...")
        toast.translatesAutoresizingMaskIntoConstraints = false
        toast.alignment = .center
        toast.backgroundColor = NSColor(white: 0.0, alpha: 0.7)
        toast.textColor = .white
        toast.font = .systemFont(ofSize: 12)
        toast.isBezeled = false
        toast.isEditable = false
        toast.isSelectable = false
        toast.wantsLayer = true
        toast.layer?.cornerRadius = 8
        
        self.contentView?.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: self.contentView!.centerXAnchor),
            toast.centerYAnchor.constraint(equalTo: self.contentView!.centerYAnchor),
            toast.widthAnchor.constraint(lessThanOrEqualToConstant: 120),
            toast.heightAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])
        
        // 开始加载播放列表
        FluffelPixabayPlaylists.shared.loadPlaylists { [weak self] success in
            DispatchQueue.main.async {
                toast.removeFromSuperview()
                
                if success {
                    // 重新创建内容视图
                    self?.setupContentView()
                } else {
                    // 显示错误提示
                    self?.showToast(message: "Failed to refresh playlists", in: self?.contentView)
                }
            }
        }
    }
    
    
    // 创建分类标题视图
    private func createHeaderView(category: FluffelPixabayPlaylists.PlaylistCategory) -> NSView {
        let headerView = NSView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 获取播放列表数据
        let tracks = FluffelPixabayPlaylists.shared.getPlaylist(for: category)
        
        // 计算总时长
        let totalDuration = tracks.reduce(0) { $0 + $1.duration }
        
        // 格式化时长
        let formattedDuration = { () -> String in
            let minutes = totalDuration / 60
            let seconds = totalDuration % 60
            return String(format: "%d:%02d", minutes, seconds)
        }()
        
        // 创建类别图标标签 - 增加背景效果
        let iconContainer = NSView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.wantsLayer = true
        iconContainer.layer?.cornerRadius = 30
        iconContainer.layer?.backgroundColor = category.color.withAlphaComponent(0.15).cgColor
        headerView.addSubview(iconContainer)
        
        let iconLabel = NSTextField(labelWithString: category.icon)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.font = .systemFont(ofSize: 30)
        iconLabel.textColor = category.color
        iconLabel.alignment = .center
        iconLabel.backgroundColor = .clear
        iconLabel.isBezeled = false
        iconLabel.isEditable = false
        iconLabel.isSelectable = false
        iconContainer.addSubview(iconLabel)
        
        // 居中图标
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor)
        ])
        
        // 创建标题容器
        let titleContainer = NSView()
        titleContainer.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleContainer)
        
        // 创建标题标签 - 使用更大的字体
        let titleLabel = NSTextField(labelWithString: category.rawValue)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = category.color
        titleContainer.addSubview(titleLabel)
        
        // 创建统计信息标签，添加图标
        let statsView = NSStackView()
        statsView.translatesAutoresizingMaskIntoConstraints = false
        statsView.orientation = .horizontal
        statsView.spacing = 6
        titleContainer.addSubview(statsView)
        
        // 添加播放列表数量图标和标签
        let playlistIcon = NSImageView()
        playlistIcon.translatesAutoresizingMaskIntoConstraints = false
        playlistIcon.image = NSImage(systemSymbolName: "music.note.list", accessibilityDescription: "Playlists")
        playlistIcon.contentTintColor = .secondaryLabelColor
        
        let playlistCountLabel = NSTextField(labelWithString: "\(tracks.count) playlists")
        playlistCountLabel.translatesAutoresizingMaskIntoConstraints = false
        playlistCountLabel.font = .systemFont(ofSize: 13)
        playlistCountLabel.textColor = .secondaryLabelColor
        
        // 添加时长图标和标签
        let durationIcon = NSImageView()
        durationIcon.translatesAutoresizingMaskIntoConstraints = false
        durationIcon.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Duration")
        durationIcon.contentTintColor = .secondaryLabelColor
        
        let durationLabel = NSTextField(labelWithString: formattedDuration)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = .systemFont(ofSize: 13)
        durationLabel.textColor = .secondaryLabelColor
        
        // 添加分隔符
        let separator = NSTextField(labelWithString: "•")
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.font = .systemFont(ofSize: 13)
        separator.textColor = .secondaryLabelColor
        separator.backgroundColor = .clear
        separator.isBezeled = false
        separator.isEditable = false
        separator.isSelectable = false
        
        // 添加所有组件到统计视图
        statsView.addArrangedSubview(playlistIcon)
        statsView.addArrangedSubview(playlistCountLabel)
        statsView.addArrangedSubview(separator)
        statsView.addArrangedSubview(durationIcon)
        statsView.addArrangedSubview(durationLabel)
        
        // 创建描述标签 - 使用更好的字体风格
        let descLabel = NSTextField(wrappingLabelWithString: getPlaylistDescription(for: category))
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabelColor
        descLabel.preferredMaxLayoutWidth = 500
        headerView.addSubview(descLabel)
        
        // 创建按钮容器
        let buttonContainer = NSStackView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.orientation = .horizontal
        buttonContainer.spacing = 16
        headerView.addSubview(buttonContainer)
        
        // 使用新方法创建按钮
        let playAllButton = createStyledButton(title: "Play All", icon: "play.fill", action: #selector(playAllTracks), isPrimary: true)
        playAllButton.action = #selector(playAllTracks)
        buttonContainer.addArrangedSubview(playAllButton)
        
        let shuffleButton = createStyledButton(title: "Shuffle", icon: "shuffle", action: #selector(shufflePlaylist), isPrimary: false)
        shuffleButton.action = #selector(shufflePlaylist)
        buttonContainer.addArrangedSubview(shuffleButton)
        
        let nextButton = createStyledButton(title: "Next", icon: "forward.fill", action: #selector(playNextTrack), isPrimary: false)
        nextButton.action = #selector(playNextTrack)
        buttonContainer.addArrangedSubview(nextButton)
        
        // 设置约束 - 调整布局以增加空间
        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            iconContainer.topAnchor.constraint(equalTo: headerView.topAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 60),
            iconContainer.heightAnchor.constraint(equalToConstant: 60),
            
            titleContainer.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 20),
            titleContainer.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleContainer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor),
            
            statsView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            statsView.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            
            descLabel.topAnchor.constraint(equalTo: statsView.bottomAnchor, constant: 16),
            descLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            buttonContainer.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 20),
            buttonContainer.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            
            headerView.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor, constant: 12)
        ])
        
        // 设置按钮大小
        for button in buttonContainer.arrangedSubviews {
            if let button = button as? NSButton {
                NSLayoutConstraint.activate([
                    button.heightAnchor.constraint(equalToConstant: 32)
                ])
            }
        }
        
        // 设置每个图标的尺寸约束
        for view in statsView.arrangedSubviews {
            if let imageView = view as? NSImageView {
                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalToConstant: 16),
                    imageView.heightAnchor.constraint(equalToConstant: 16)
                ])
            }
        }
        
        return headerView
    }
    
    // 获取播放列表描述
    private func getPlaylistDescription(for category: FluffelPixabayPlaylists.PlaylistCategory) -> String {
        if let url = Bundle.main.url(forResource: "playlists", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let allPlaylists = try? JSONDecoder().decode([PlaylistData].self, from: data),
           let matchingPlaylist = allPlaylists.first(where: { $0.categories?.contains(category.rawValue.lowercased()) ?? false }) {
            return matchingPlaylist.description
        }
        return "A collection of \(category.rawValue.lowercased()) music"
    }
    
    // 获取播放列表背景图片 URL
    private func getPlaylistBackgroundImage(for category: FluffelPixabayPlaylists.PlaylistCategory) -> URL? {
        if let url = Bundle.main.url(forResource: "playlists", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let allPlaylists = try? JSONDecoder().decode([PlaylistData].self, from: data),
           let matchingPlaylist = allPlaylists.first(where: { $0.categories?.contains(category.rawValue.lowercased()) ?? false }),
           let bgImageSrc = matchingPlaylist.bgImageSrc {
            return URL(string: bgImageSrc)
        }
        return nil
    }
    
    private func createSeparator() -> NSView {
        let separator = NSView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.wantsLayer = true
        
        // 创建渐变分隔线
        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        
        // 使用分类颜色作为渐变的一部分
        let clearColor = NSColor.clear.cgColor
        let separatorColor = category.color.withAlphaComponent(0.5).cgColor
        let defaultSeparatorColor = NSColor.separatorColor.withAlphaComponent(0.5).cgColor
        
        gradientLayer.colors = [
            clearColor,
            defaultSeparatorColor,
            separatorColor,
            defaultSeparatorColor,
            clearColor
        ]
        
        gradientLayer.locations = [0.0, 0.2, 0.5, 0.8, 1.0]
        
        separator.layer?.addSublayer(gradientLayer)
        
        // 分隔线高度
        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // 在布局更新时更新渐变层的frame
        // 使用自定义类扩展来实现布局更新
        class SeparatorView: NSView {
            var gradientLayer: CAGradientLayer?
            
            override func layout() {
                super.layout()
                // 更新渐变层的尺寸
                if let gradientLayer = gradientLayer {
                    gradientLayer.frame = self.bounds
                }
            }
        }
        
        // 创建一个自定义的SeparatorView
        let finalSeparator = SeparatorView()
        finalSeparator.gradientLayer = gradientLayer
        finalSeparator.translatesAutoresizingMaskIntoConstraints = false
        finalSeparator.wantsLayer = true
        finalSeparator.layer?.addSublayer(gradientLayer)
        
        // 设置自定义视图的高度约束
        NSLayoutConstraint.activate([
            finalSeparator.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // 初始化渐变层的尺寸
        gradientLayer.frame = finalSeparator.bounds
        
        return finalSeparator
    }
    
    // 创建更美观的按钮并添加悬停效果
    private func createStyledButton(title: String, icon: String, action: Selector, isPrimary: Bool = true) -> NSButton {
        let button = NSButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.title = title
        button.font = .systemFont(ofSize: 14, weight: .medium)
        button.bezelStyle = .rounded
        
        if isPrimary {
            // 主要按钮使用主题色
            button.bezelColor = category.color.withAlphaComponent(0.1)
            button.contentTintColor = category.color
        } else {
            // 次要按钮使用灰色
            button.bezelColor = NSColor.controlColor.withAlphaComponent(0.1)
            button.contentTintColor = .secondaryLabelColor
        }
        
        button.image = NSImage(systemSymbolName: icon, accessibilityDescription: title)
        button.imagePosition = .imageLeading
        button.target = self
        
        // 添加悬停时颜色变化效果
        button.wantsLayer = true
        
        // 添加用户信息，表明按钮是否为主要按钮
        let userInfo: [String: Any] = ["button": button, "isPrimary": isPrimary]
        
        // 添加鼠标进入/退出监听
        let trackingArea = NSTrackingArea(
            rect: button.bounds, 
            options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect],
            owner: self,
            userInfo: userInfo
        )
        button.addTrackingArea(trackingArea)
        
        return button
    }
    
    // 修改创建播放列表项视图方法，实现图片'cover'效果
    private func createPlaylistItemView(track: Track, index: Int) -> NSView {
        let itemView = NSView()
        itemView.translatesAutoresizingMaskIntoConstraints = false
        itemView.wantsLayer = true
        itemView.layer?.cornerRadius = 12
        itemView.layer?.masksToBounds = true
        
        // 添加阴影容器视图
        let shadowContainer = NSView()
        shadowContainer.translatesAutoresizingMaskIntoConstraints = false
        shadowContainer.wantsLayer = true
        shadowContainer.layer?.cornerRadius = 12
        shadowContainer.layer?.shadowColor = NSColor.black.cgColor
        shadowContainer.layer?.shadowOpacity = 0.2
        shadowContainer.layer?.shadowOffset = CGSize(width: 0, height: 2)
        shadowContainer.layer?.shadowRadius = 8
        shadowContainer.addSubview(itemView)
        
        // 确保阴影容器和卡片保持相同大小
        NSLayoutConstraint.activate([
            itemView.topAnchor.constraint(equalTo: shadowContainer.topAnchor),
            itemView.leadingAnchor.constraint(equalTo: shadowContainer.leadingAnchor),
            itemView.trailingAnchor.constraint(equalTo: shadowContainer.trailingAnchor),
            itemView.bottomAnchor.constraint(equalTo: shadowContainer.bottomAnchor)
        ])
        
        // 添加卡片背景色（渐变）
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: gridItemWidth, height: gridItemHeight)
        gradientLayer.cornerRadius = 12
        
        // 根据分类设置渐变色
        let color1 = category.color.withAlphaComponent(0.1).cgColor
        let color2 = category.color.withAlphaComponent(0.05).cgColor
        gradientLayer.colors = [color1, color2]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        itemView.wantsLayer = true
        itemView.layer?.addSublayer(gradientLayer)
        
        // 创建背景图片容器视图 - 使用CALayer实现真正的cover效果
        let imageLayer = CALayer()
        imageLayer.frame = CGRect(x: 0, y: 0, width: gridItemWidth, height: gridItemHeight)
        imageLayer.contentsGravity = .resizeAspectFill
        imageLayer.masksToBounds = true
        imageLayer.cornerRadius = 12
        
        // 将图层添加到视图
        itemView.layer?.addSublayer(imageLayer)
        
        // 异步加载图片
        if let bgImageUrl = getPlaylistItemImage(for: track, fallbackCategory: category) {
            DispatchQueue.global().async {
                if let imageData = try? Data(contentsOf: bgImageUrl),
                   let image = NSImage(data: imageData) {
                    // 创建CGImage用于CALayer
                    if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                        DispatchQueue.main.async {
                            // 设置内容并添加渐入动画
                            CATransaction.begin()
                            CATransaction.setAnimationDuration(0.4)
                            
                            // 为内容设置渐变动画
                            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
                            fadeAnimation.fromValue = 0.0
                            fadeAnimation.toValue = 1.0
                            fadeAnimation.duration = 0.4
                            
                            imageLayer.add(fadeAnimation, forKey: "fadeIn")
                            imageLayer.contents = cgImage
                            imageLayer.opacity = 1.0
                            
                            CATransaction.commit()
                        }
                    }
                } else {
                    // 如果加载失败，使用默认图片
                    DispatchQueue.main.async {
                        if let defaultImage = NSImage(named: "NSApplicationIcon"),
                           let cgImage = defaultImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                            imageLayer.contents = cgImage
                        }
                    }
                }
            }
        } else {
            // 设置默认图片
            if let defaultImage = NSImage(named: "NSApplicationIcon"),
               let cgImage = defaultImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                imageLayer.contents = cgImage
            }
        }
        
        // 创建渐变遮罩，使文字更清晰（从下到上的黑色渐变）
        let overlayLayer = CAGradientLayer()
        overlayLayer.frame = CGRect(x: 0, y: 0, width: gridItemWidth, height: gridItemHeight)
        overlayLayer.colors = [
            NSColor.black.withAlphaComponent(0.7).cgColor,
            NSColor.black.withAlphaComponent(0.2).cgColor,
            NSColor.clear.cgColor
        ]
        overlayLayer.locations = [0.0, 0.6, 1.0]
        overlayLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        overlayLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        overlayLayer.cornerRadius = 12
        
        // 将渐变覆盖层添加到视图
        itemView.layer?.addSublayer(overlayLayer)
        
        // 创建标题标签 (使用自定义样式以增强可读性)
        let titleLabel = NSTextField(labelWithString: track.title)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 2
        titleLabel.backgroundColor = .clear
        titleLabel.wantsLayer = true
        
        // 创建时长标签 (改进样式，添加图标)
        let durationStack = NSStackView()
        durationStack.translatesAutoresizingMaskIntoConstraints = false
        durationStack.orientation = .horizontal
        durationStack.spacing = 4
        
        let clockIcon = NSImageView()
        clockIcon.translatesAutoresizingMaskIntoConstraints = false
        clockIcon.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Duration")
        clockIcon.contentTintColor = .white
        
        let durationLabel = NSTextField(labelWithString: track.formattedDuration)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = NSFont.systemFont(ofSize: 12)
        durationLabel.textColor = .white
        durationLabel.backgroundColor = .clear
        
        durationStack.addArrangedSubview(clockIcon)
        durationStack.addArrangedSubview(durationLabel)
        
        // 设置图标尺寸
        NSLayoutConstraint.activate([
            clockIcon.widthAnchor.constraint(equalToConstant: 12),
            clockIcon.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        // 创建播放按钮（初始透明度为0，鼠标悬停时显示）
        let playButton = NSButton(image: NSImage(systemSymbolName: "play.circle.fill", accessibilityDescription: "Play")!, target: self, action: #selector(playPlaylist(_:)))
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.bezelStyle = .circular
        playButton.isBordered = false
        playButton.contentTintColor = .white
        playButton.tag = Int(track.id) ?? 0
        playButton.alphaValue = 0
        
        // 设置播放按钮大小 - 使用较小的初始尺寸
        let buttonSize: CGFloat = 42
        NSLayoutConstraint.activate([
            playButton.widthAnchor.constraint(equalToConstant: buttonSize),
            playButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])
        
        // 添加子视图
        itemView.addSubview(titleLabel)
        itemView.addSubview(durationStack)
        itemView.addSubview(playButton)
        
        // 设置约束
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: durationStack.topAnchor, constant: -4),
            
            durationStack.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 12),
            durationStack.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -12),
            
            playButton.centerXAnchor.constraint(equalTo: itemView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: itemView.centerYAnchor)
        ])
        
        // 设置悬停效果
        setupHoverEffects(for: itemView, playButton: playButton)
        
        return shadowContainer
    }
    
    // 获取播放列表项图片 URL
    private func getPlaylistItemImage(for track: Track, fallbackCategory: FluffelPixabayPlaylists.PlaylistCategory) -> URL? {
        // 首先尝试从播放列表数据中获取图片
        if let url = Bundle.main.url(forResource: "playlists", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let allPlaylists = try? JSONDecoder().decode([PlaylistData].self, from: data) {
            
            // 尝试通过 ID 匹配
            if let matchingPlaylist = allPlaylists.first(where: { String($0.id) == track.id }),
               let bgImageSrc = matchingPlaylist.bgImageSrc {
                return URL(string: bgImageSrc)
            }
            
            // 如果没有精确匹配，随机选择一个相同类别的图片
            let categoryPlaylists = allPlaylists.filter { $0.categories?.contains(fallbackCategory.rawValue.lowercased()) ?? false }
            if let randomPlaylist = categoryPlaylists.randomElement(),
               let bgImageSrc = randomPlaylist.bgImageSrc {
                return URL(string: bgImageSrc)
            }
        }
        
        // 如果没有找到任何图片，返回 nil
        return nil
    }
    
    // 增强的悬停效果设置
    private func setupHoverEffects(for view: NSView, playButton: NSButton) {
        // 清除现有的跟踪区域
        for trackingArea in view.trackingAreas {
            view.removeTrackingArea(trackingArea)
        }
        
        // 使用跟踪区域监听鼠标进入/离开事件
        let trackingArea = NSTrackingArea(
            rect: view.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: ["view": view, "playButton": playButton]
        )
        view.addTrackingArea(trackingArea)
    }
    
    // 添加鼠标悬停处理方法
    override func mouseEntered(with event: NSEvent) {
        if let userInfo = event.trackingArea?.userInfo {
            // 处理播放列表项卡片
            if let view = userInfo["view"] as? NSView,
               let playButton = userInfo["playButton"] as? NSButton {
                // 显示播放按钮及应用悬停效果
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    
                    // 按钮淡入
                    playButton.animator().alphaValue = 1.0
                    
                    // 按钮放大3倍
                    playButton.frame = NSRect(
                        x: playButton.frame.origin.x - playButton.frame.width,
                        y: playButton.frame.origin.y - playButton.frame.height,
                        width: playButton.frame.width * 3,
                        height: playButton.frame.height * 3
                    )
                    
                    // 添加放大和阴影效果
                    view.wantsLayer = true
                    
                    // 使卡片轻微放大
                    let scaleTransform = CATransform3DMakeScale(1.03, 1.03, 1.0)
                    view.layer?.transform = scaleTransform
                    
                    // 增强阴影效果
                    if let shadowLayer = view.layer?.sublayers?.first(where: { $0 is CAGradientLayer }) {
                        shadowLayer.opacity = 0.8
                    }
                    
                    // 如果是阴影容器（外层视图），增强阴影效果
                    if view.superview?.layer?.shadowOpacity != nil {
                        view.superview?.layer?.shadowOpacity = 0.4
                        view.superview?.layer?.shadowRadius = 12
                    }
                    
                    // 应用高亮效果（在卡片边缘添加微妙的发光效果）
                    view.layer?.borderWidth = 1.5
                    view.layer?.borderColor = category.color.withAlphaComponent(0.6).cgColor
                }
            }
            // 处理按钮悬停
            else if let button = userInfo["button"] as? NSButton {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    
                    // 根据按钮类型改变悬停效果
                    let isPrimary = userInfo["isPrimary"] as? Bool ?? true
                    
                    if isPrimary {
                        // 主要按钮效果
                        button.bezelColor = category.color.withAlphaComponent(0.2)
                        button.contentTintColor = category.color.blended(withFraction: 0.2, of: .white) ?? category.color
                    } else {
                        // 次要按钮效果
                        button.bezelColor = NSColor.controlColor.withAlphaComponent(0.2)
                        button.contentTintColor = NSColor.secondaryLabelColor.blended(withFraction: 0.2, of: .white) ?? .secondaryLabelColor
                    }
                    
                    if button.layer?.shadowOpacity == nil {
                        button.layer?.shadowOpacity = 0.3
                        button.layer?.shadowOffset = CGSize(width: 0, height: 1)
                        button.layer?.shadowRadius = 3
                        button.layer?.masksToBounds = false
                    }
                }
            }
        } else {
            super.mouseEntered(with: event)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if let userInfo = event.trackingArea?.userInfo {
            // 处理播放列表项卡片
            if let view = userInfo["view"] as? NSView,
               let playButton = userInfo["playButton"] as? NSButton {
                // 隐藏播放按钮并恢复默认效果
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    
                    // 按钮淡出
                    playButton.animator().alphaValue = 0.0
                    
                    // 还原按钮大小
                    playButton.frame = NSRect(
                        x: playButton.frame.origin.x + playButton.frame.width/3,
                        y: playButton.frame.origin.y + playButton.frame.height/3,
                        width: playButton.frame.width/3,
                        height: playButton.frame.height/3
                    )
                    
                    // 恢复原始缩放
                    view.layer?.transform = CATransform3DIdentity
                    
                    // 恢复默认阴影效果
                    if let shadowLayer = view.layer?.sublayers?.first(where: { $0 is CAGradientLayer }) {
                        shadowLayer.opacity = 0.4
                    }
                    
                    // 如果是阴影容器（外层视图），恢复默认阴影
                    if view.superview?.layer?.shadowOpacity != nil {
                        view.superview?.layer?.shadowOpacity = 0.2
                        view.superview?.layer?.shadowRadius = 8
                    }
                    
                    // 移除边框高亮
                    view.layer?.borderWidth = 0
                }
            }
            // 处理按钮离开
            else if let button = userInfo["button"] as? NSButton {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    
                    // 根据按钮类型恢复原始样式
                    let isPrimary = userInfo["isPrimary"] as? Bool ?? true
                    
                    if isPrimary {
                        // 恢复主要按钮样式
                        button.bezelColor = category.color.withAlphaComponent(0.1)
                        button.contentTintColor = category.color
                    } else {
                        // 恢复次要按钮样式
                        button.bezelColor = NSColor.controlColor.withAlphaComponent(0.1)
                        button.contentTintColor = .secondaryLabelColor
                    }
                    
                    // 移除阴影
                    button.layer?.shadowOpacity = 0
                }
            }
        } else {
            super.mouseExited(with: event)
        }
    }
    
    // MARK: - Actions
    
    @objc private func playAllTracks() {
        let playlists = FluffelPixabayPlaylists.shared.getPlaylist(for: category)
        if let firstPlaylist = playlists.first {
            // 调用单个播放列表的播放方法
            fetchAndPlayPlaylist(id: firstPlaylist.id)
        }
    }
    
    @objc private func shufflePlaylist() {
        let playlists = FluffelPixabayPlaylists.shared.getPlaylist(for: category)
        if let randomPlaylist = playlists.randomElement() {
            // 获取随机播放列表并播放
            fetchAndPlayPlaylist(id: randomPlaylist.id, shouldShuffle: true)
        }
    }
    
    @objc private func playNextTrack() {
        // 调用AppDelegate的播放下一首方法
        appDelegate?.playNextTrack(self)
    }
    
    @objc private func playPlaylist(_ sender: NSButton) {
        let tracks = FluffelPixabayPlaylists.shared.getPlaylist(for: category)
        let playlistId = String(sender.tag)
        if let track = tracks.first(where: { $0.id == playlistId }) {
            // 开始获取播放列表内容
            print("Fetching playlist content for ID: \(playlistId)")
            
            // 显示加载提示
            let parentView = sender.superview
            
            // 保存原始图标
            let originalImage = sender.image
            
            // 更改按钮图标为加载中
            let loadingImage = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: "Loading")!
            sender.image = loadingImage
            
            // 禁用按钮
            sender.isEnabled = false
            
            // 添加旋转动画
            let animation = CABasicAnimation(keyPath: "transform.rotation")
            animation.fromValue = 0.0
            animation.toValue = 2.0 * Double.pi
            animation.duration = 1.0
            animation.repeatCount = .infinity
            sender.wantsLayer = true
            sender.layer?.add(animation, forKey: "rotationAnimation")
            
            // 获取播放列表内容
            FluffelPixabayService.shared.fetchPlaylistContent(playlistId: playlistId) { [weak self] result in
                DispatchQueue.main.async {
                    // 恢复UI状态
                    sender.layer?.removeAnimation(forKey: "rotationAnimation")
                    sender.image = originalImage
                    sender.isEnabled = true
                    
                    switch result {
                    case .success(let audios):
                        if !audios.isEmpty {
                            // 创建播放列表队列
                            let allTracks = audios.map { audio in
                                Track(
                                    id: String(audio.id),
                                    title: audio.title,
                                    artist: audio.user,
                                    duration: audio.duration,
                                    url: audio.audioURL
                                )
                            }
                            
                            // 播放第一首歌曲并保存播放列表
                            if let firstTrack = allTracks.first {
                                self?.appDelegate?.playTrack(firstTrack)
                                // 存储播放列表，以便之后播放下一首
                                // 注意：这里假设 AppDelegate 有一个接收完整播放列表的方法
                                self?.appDelegate?.storePlaylistQueue(allTracks)
                                print("Playing entire playlist starting with: \(firstTrack.title)")
                                self?.showToast(message: "Playing playlist: \(track.title)", in: parentView)
                            }
                        } else {
                            print("Playlist is empty")
                            self?.showToast(message: "This playlist is empty", in: parentView)
                        }
                    case .failure(let error):
                        print("Failed to fetch playlist content: \(error.localizedDescription)")
                        self?.showToast(message: "Failed to load playlist", in: parentView)
                    }
                }
            }
        }
    }
    
    // 显示临时提示消息
    private func showToast(message: String, in parentView: NSView?) {
        guard let parentView = parentView else { return }
        
        let toast = NSTextField(labelWithString: message)
        toast.translatesAutoresizingMaskIntoConstraints = false
        toast.alignment = .center
        toast.backgroundColor = NSColor(white: 0.0, alpha: 0.7)
        toast.textColor = .white
        toast.font = .systemFont(ofSize: 12)
        toast.isBezeled = false
        toast.isEditable = false
        toast.isSelectable = false
        toast.wantsLayer = true
        toast.layer?.cornerRadius = 8
        
        parentView.window?.contentView?.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: parentView.window!.contentView!.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: parentView.window!.contentView!.bottomAnchor, constant: -20),
            toast.widthAnchor.constraint(lessThanOrEqualToConstant: 200),
            toast.heightAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])
        
        // 2秒后淡出消失
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.5
                toast.animator().alphaValue = 0
            }, completionHandler: {
                toast.removeFromSuperview()
            })
        }
    }
    
    // 新增方法：获取并播放播放列表
    private func fetchAndPlayPlaylist(id: String, shouldShuffle: Bool = false) {
        print("Fetching and playing playlist: \(id), shuffle: \(shouldShuffle)")
        
        // 显示加载提示
        let toast = NSTextField(labelWithString: shouldShuffle ? "Loading random track..." : "Loading playlist...")
        toast.translatesAutoresizingMaskIntoConstraints = false
        toast.alignment = .center
        toast.backgroundColor = NSColor(white: 0.0, alpha: 0.7)
        toast.textColor = .white
        toast.font = .systemFont(ofSize: 12)
        toast.isBezeled = false
        toast.isEditable = false
        toast.isSelectable = false
        toast.wantsLayer = true
        toast.layer?.cornerRadius = 8
        
        self.contentView?.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: self.contentView!.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: self.contentView!.bottomAnchor, constant: -20),
            toast.widthAnchor.constraint(lessThanOrEqualToConstant: 200),
            toast.heightAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])
        
        FluffelPixabayService.shared.fetchPlaylistContent(playlistId: id) { [weak self] result in
            DispatchQueue.main.async {
                // 移除提示
                toast.removeFromSuperview()
                
                switch result {
                case .success(let audios):
                    guard !audios.isEmpty else {
                        print("Playlist is empty")
                        self?.showToast(message: "This playlist is empty", in: self?.contentView)
                        return
                    }
                    
                    // 选择要播放的音频
                    let audioToPlay: PixabayAudio
                    if shouldShuffle {
                        audioToPlay = audios.randomElement()!
                    } else {
                        audioToPlay = audios.first!
                    }
                    
                    // 创建Track并播放
                    let audioTrack = Track(
                        id: String(audioToPlay.id),
                        title: audioToPlay.title,
                        artist: audioToPlay.user,
                        duration: audioToPlay.duration,
                        url: audioToPlay.audioURL
                    )
                    self?.appDelegate?.playTrack(audioTrack)
                    print("Playing audio: \(audioToPlay.title)")
                    self?.showToast(message: "Now playing: \(audioToPlay.title)", in: self?.contentView)
                    
                case .failure(let error):
                    print("Failed to fetch playlist content: \(error.localizedDescription)")
                    self?.showToast(message: "Failed to load playlist", in: self?.contentView)
                }
            }
        }
    }
    
    private func createEmptyStateView() -> NSView {
        print("Creating empty state view")
        let emptyView = NSView()
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create icon
        let icon = NSImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = NSImage(systemSymbolName: "music.note.list", accessibilityDescription: "No music")
        icon.contentTintColor = category.color.withAlphaComponent(0.5)
        icon.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        icon.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        // Create title
        let title = NSTextField(labelWithString: "No playlists available")
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = .systemFont(ofSize: 18, weight: .medium)
        title.textColor = .labelColor
        title.alignment = .center
        
        // Create description
        let description = NSTextField(labelWithString: "Try refreshing the page or check back later")
        description.translatesAutoresizingMaskIntoConstraints = false
        description.font = .systemFont(ofSize: 14)
        description.textColor = .secondaryLabelColor
        description.alignment = .center
        
        // Create refresh button
        let refreshButton = NSButton(title: "Refresh", target: self, action: #selector(refreshContentView))
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.bezelStyle = .rounded
        refreshButton.font = .systemFont(ofSize: 13)
        refreshButton.contentTintColor = category.color
        
        // Add to container
        emptyView.addSubview(icon)
        emptyView.addSubview(title)
        emptyView.addSubview(description)
        emptyView.addSubview(refreshButton)
        
        // Set constraints
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            icon.topAnchor.constraint(equalTo: emptyView.topAnchor, constant: 20),
            icon.widthAnchor.constraint(equalToConstant: 60),
            icon.heightAnchor.constraint(equalToConstant: 60),
            
            title.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 16),
            title.leadingAnchor.constraint(greaterThanOrEqualTo: emptyView.leadingAnchor, constant: 20),
            title.trailingAnchor.constraint(lessThanOrEqualTo: emptyView.trailingAnchor, constant: -20),
            
            description.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            description.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            description.leadingAnchor.constraint(greaterThanOrEqualTo: emptyView.leadingAnchor, constant: 20),
            description.trailingAnchor.constraint(lessThanOrEqualTo: emptyView.trailingAnchor, constant: -20),
            
            refreshButton.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            refreshButton.topAnchor.constraint(equalTo: description.bottomAnchor, constant: 20),
            // Ensure the refreshButton is tied to the bottom of the emptyView to give it height
            refreshButton.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor, constant: -20)
        ])
        
        return emptyView
    }
}

