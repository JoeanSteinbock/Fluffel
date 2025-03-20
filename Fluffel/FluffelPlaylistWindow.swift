import Cocoa

class FluffelPlaylistWindow: NSWindow {
    // 播放列表视图
    private var playlistView: NSView!
    private var category: FluffelPixabayPlaylists.PlaylistCategory
    internal weak var appDelegate: AppDelegate?
    
    // 网格布局常量
    private let gridItemWidth: CGFloat = 180
    private let gridItemHeight: CGFloat = 180
    private let gridSpacing: CGFloat = 20
    private let edgeInsets: CGFloat = 24
    
    init(category: FluffelPixabayPlaylists.PlaylistCategory, delegate: AppDelegate) {
        print("Initializing playlist window for category: \(category.rawValue)")
        self.category = category
        self.appDelegate = delegate
        
        // 创建更大的窗口
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        self.title = "\(category.rawValue) Playlists"
        self.center()
        self.isReleasedWhenClosed = false
        self.backgroundColor = NSColor.windowBackgroundColor
        
        // 设置最小尺寸
        self.minSize = NSSize(width: 500, height: 500)
        
        // 设置窗口置顶
        self.level = .floating
        
        // 创建内容视图
        setupContentView()
        
        print("Playlist window initialized")
    }
    
    private func setupContentView() {
        print("Setting up content view")
        
        // 创建主视图
        playlistView = NSView(frame: contentView?.bounds ?? .zero)
        playlistView.wantsLayer = true
        
        // 创建滚动视图
        let scrollView = NSScrollView(frame: playlistView.bounds)
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        
        // 创建播放列表容器
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 获取播放列表
        print("Fetching tracks for category: \(category.rawValue)")
        let tracks = FluffelPixabayPlaylists.shared.getPlaylist(for: category)
        print("Retrieved \(tracks.count) tracks")
        
        // 如果没有曲目，显示加载中状态
        if tracks.isEmpty {
            print("No tracks found, loading playlists")
            // 显示加载指示器
            let loadingText = NSTextField(labelWithString: "Loading playlists...")
            loadingText.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(loadingText)
            
            // 添加加载动画
            let spinner = NSProgressIndicator()
            spinner.style = .spinning
            spinner.controlSize = .regular
            spinner.isIndeterminate = true
            spinner.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(spinner)
            spinner.startAnimation(nil)
            
            NSLayoutConstraint.activate([
                loadingText.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                loadingText.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -30),
                
                spinner.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                spinner.topAnchor.constraint(equalTo: loadingText.bottomAnchor, constant: 16),
                spinner.widthAnchor.constraint(equalToConstant: 32),
                spinner.heightAnchor.constraint(equalToConstant: 32)
            ])
            
            // 开始加载播放列表
            FluffelPixabayPlaylists.shared.loadPlaylists { [weak self] success in
                print("Playlists load completed with success: \(success)")
                DispatchQueue.main.async {
                    self?.refreshContentView()
                }
            }
        } else {
            print("Setting up UI with \(tracks.count) tracks")
            setupUIWithTracks(tracks, in: containerView)
        }
        
        // 设置文档视图
        scrollView.documentView = containerView
        
        // 添加滚动视图到主视图
        playlistView.addSubview(scrollView)
        scrollView.frame = playlistView.bounds
        
        // 设置内容视图
        contentView = playlistView
        
        print("Content view setup completed")
    }
    
    // 添加刷新方法
    private func refreshContentView() {
        print("Refreshing content view")
        let tracks = FluffelPixabayPlaylists.shared.getPlaylist(for: category)
        print("Retrieved \(tracks.count) tracks after refresh")
        
        // 重新创建内容视图
        setupContentView()
    }
    
    private func setupUIWithTracks(_ tracks: [Track], in containerView: NSView) {
        // 创建播放列表标题
        let headerView = createHeaderView(category: category)
        containerView.addSubview(headerView)
        
        // 添加分隔线
        let separator = createSeparator()
        containerView.addSubview(separator)
        
        // 计算网格布局参数
        let availableWidth = 600 - (edgeInsets * 2) // 窗口宽度减去两侧边距
        let itemsPerRow = Int(availableWidth / (gridItemWidth + gridSpacing))
        let actualSpacing = (availableWidth - (CGFloat(itemsPerRow) * gridItemWidth)) / CGFloat(itemsPerRow - 1)
        
        // 创建网格容器视图
        let gridContainer = NSView()
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(gridContainer)
        
        // 添加播放列表项到网格
        var currentRow = 0
        var currentColumn = 0
        
        for (index, track) in tracks.enumerated() {
            let itemView = createPlaylistItemView(track: track, index: index)
            gridContainer.addSubview(itemView)
            
            // 计算位置
            let xPosition = CGFloat(currentColumn) * (gridItemWidth + actualSpacing)
            let yPosition = CGFloat(currentRow) * (gridItemHeight + gridSpacing)
            
            // 设置约束
            NSLayoutConstraint.activate([
                itemView.widthAnchor.constraint(equalToConstant: gridItemWidth),
                itemView.heightAnchor.constraint(equalToConstant: gridItemHeight),
                itemView.leadingAnchor.constraint(equalTo: gridContainer.leadingAnchor, constant: xPosition),
                itemView.topAnchor.constraint(equalTo: gridContainer.topAnchor, constant: yPosition)
            ])
            
            // 更新行列位置
            currentColumn += 1
            if currentColumn >= itemsPerRow {
                currentColumn = 0
                currentRow += 1
            }
        }
        
        // 计算网格容器高度
        let rowCount = (tracks.count + itemsPerRow - 1) / itemsPerRow
        let gridHeight = CGFloat(rowCount) * gridItemHeight + CGFloat(rowCount - 1) * gridSpacing
        
        // 设置容器视图约束
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: edgeInsets),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -edgeInsets),
            
            separator.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            gridContainer.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 24),
            gridContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: edgeInsets),
            gridContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -edgeInsets),
            gridContainer.heightAnchor.constraint(equalToConstant: gridHeight),
            gridContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24)
        ])
    }
    
    private func createHeaderView(category: FluffelPixabayPlaylists.PlaylistCategory) -> NSView {
        let headerView = NSView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 获取播放列表数据
        let tracks = FluffelPixabayPlaylists.shared.getPlaylist(for: category)
        let totalDuration = tracks.reduce(0) { $0 + $1.duration }
        let formattedDuration = { () -> String in
            let minutes = totalDuration / 60
            let seconds = totalDuration % 60
            return String(format: "%d:%02d", minutes, seconds)
        }()
        
        // 创建类别图标标签
        let iconLabel = NSTextField(labelWithString: category.icon)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.font = .systemFont(ofSize: 28)
        iconLabel.alignment = .center
        iconLabel.backgroundColor = .clear
        iconLabel.isBezeled = false
        iconLabel.isEditable = false
        iconLabel.isSelectable = false
        headerView.addSubview(iconLabel)
        
        // 创建标题容器
        let titleContainer = NSView()
        titleContainer.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleContainer)
        
        // 创建标题标签
        let titleLabel = NSTextField(labelWithString: category.rawValue)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = category.color
        titleContainer.addSubview(titleLabel)
        
        // 创建统计信息标签，添加图标
        let statsView = NSStackView()
        statsView.translatesAutoresizingMaskIntoConstraints = false
        statsView.orientation = .horizontal
        statsView.spacing = 2
        titleContainer.addSubview(statsView)
        
        // 添加播放列表数量图标和标签
        let playlistIcon = NSImageView()
        playlistIcon.translatesAutoresizingMaskIntoConstraints = false
        playlistIcon.image = NSImage(systemSymbolName: "music.note.list", accessibilityDescription: "Playlists")
        playlistIcon.contentTintColor = .secondaryLabelColor
        
        let playlistCountLabel = NSTextField(labelWithString: "\(tracks.count) playlists")
        playlistCountLabel.translatesAutoresizingMaskIntoConstraints = false
        playlistCountLabel.font = .systemFont(ofSize: 12)
        playlistCountLabel.textColor = .secondaryLabelColor
        
        // 添加时长图标和标签
        let durationIcon = NSImageView()
        durationIcon.translatesAutoresizingMaskIntoConstraints = false
        durationIcon.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Duration")
        durationIcon.contentTintColor = .secondaryLabelColor
        
        let durationLabel = NSTextField(labelWithString: formattedDuration)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = .systemFont(ofSize: 12)
        durationLabel.textColor = .secondaryLabelColor
        
        // 添加所有组件到统计视图
        statsView.addArrangedSubview(playlistIcon)
        statsView.addArrangedSubview(playlistCountLabel)
        statsView.addArrangedSubview(NSTextField(labelWithString: "•")) // 分隔符
        statsView.addArrangedSubview(durationIcon)
        statsView.addArrangedSubview(durationLabel)
        
        // 创建描述标签
        let descLabel = NSTextField(wrappingLabelWithString: getPlaylistDescription(for: category))
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabelColor
        headerView.addSubview(descLabel)
        
        // 创建按钮容器
        let buttonContainer = NSStackView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.orientation = .horizontal
        buttonContainer.spacing = 12
        headerView.addSubview(buttonContainer)
        
        // 创建播放全部按钮（带图标）
        let playAllButton = NSButton()
        playAllButton.translatesAutoresizingMaskIntoConstraints = false
        playAllButton.title = "Play All"
        playAllButton.bezelStyle = .rounded
        playAllButton.contentTintColor = category.color
        playAllButton.image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "Play")
        playAllButton.imagePosition = .imageLeading
        playAllButton.target = self
        playAllButton.action = #selector(playAllTracks)
        buttonContainer.addArrangedSubview(playAllButton)
        
        // 创建随机播放按钮（带图标）
        let shuffleButton = NSButton()
        shuffleButton.translatesAutoresizingMaskIntoConstraints = false
        shuffleButton.title = "Shuffle"
        shuffleButton.bezelStyle = .rounded
        shuffleButton.contentTintColor = category.color
        shuffleButton.image = NSImage(systemSymbolName: "shuffle", accessibilityDescription: "Shuffle")
        shuffleButton.imagePosition = .imageLeading
        shuffleButton.target = self
        shuffleButton.action = #selector(shufflePlaylist)
        buttonContainer.addArrangedSubview(shuffleButton)
        
        // 设置约束
        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            iconLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 60),
            iconLabel.heightAnchor.constraint(equalToConstant: 60),
            
            titleContainer.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 16),
            titleContainer.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleContainer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor),
            
            statsView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            statsView.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            
            descLabel.topAnchor.constraint(equalTo: statsView.bottomAnchor, constant: 12),
            descLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            buttonContainer.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 16),
            buttonContainer.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            
            headerView.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor, constant: 8)
        ])
        
        // 设置每个图标的尺寸约束
        for view in statsView.arrangedSubviews {
            if let imageView = view as? NSImageView {
                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalToConstant: 14),
                    imageView.heightAnchor.constraint(equalToConstant: 14)
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
        separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
        
        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        return separator
    }
    
    // 创建播放列表项视图（图片卡片）
    private func createPlaylistItemView(track: Track, index: Int) -> NSView {
        let itemView = NSView()
        itemView.translatesAutoresizingMaskIntoConstraints = false
        itemView.wantsLayer = true
        itemView.layer?.cornerRadius = 8
        itemView.layer?.masksToBounds = true
        
        // 创建背景图片视图
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 8
        imageView.layer?.masksToBounds = true
        imageView.imageScaling = .scaleProportionallyUpOrDown
        
        // 异步加载图片
        if let bgImageUrl = getPlaylistItemImage(for: track, fallbackCategory: category) {
            DispatchQueue.global().async {
                if let imageData = try? Data(contentsOf: bgImageUrl),
                   let image = NSImage(data: imageData) {
                    DispatchQueue.main.async {
                        imageView.image = image
                    }
                } else {
                    // 如果加载失败，使用默认图片
                    DispatchQueue.main.async {
                        imageView.image = NSImage(named: "NSApplicationIcon")
                    }
                }
            }
        } else {
            // 设置默认图片
            imageView.image = NSImage(named: "NSApplicationIcon")
        }
        
        // 创建半透明遮罩，使文字更清晰
        let overlayView = NSView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.wantsLayer = true
        overlayView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.5).cgColor
        
        // 创建标题标签
        let titleLabel = NSTextField(labelWithString: track.title)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 2
        titleLabel.backgroundColor = .clear
        
        // 创建时长标签
        let durationLabel = NSTextField(labelWithString: track.formattedDuration)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = NSFont.systemFont(ofSize: 12)
        durationLabel.textColor = .white
        durationLabel.backgroundColor = .clear
        
        // 创建播放按钮（初始透明度为0，鼠标悬停时显示）
        let playButton = NSButton(image: NSImage(systemSymbolName: "play.circle.fill", accessibilityDescription: "Play")!, target: self, action: #selector(playPlaylist(_:)))
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.bezelStyle = .circular
        playButton.isBordered = false
        playButton.contentTintColor = .white
        playButton.tag = Int(track.id) ?? 0
        playButton.alphaValue = 0
        
        // 添加子视图
        itemView.addSubview(imageView)
        itemView.addSubview(overlayView)
        itemView.addSubview(titleLabel)
        itemView.addSubview(durationLabel)
        itemView.addSubview(playButton)
        
        // 设置约束
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: itemView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: itemView.bottomAnchor),
            
            overlayView.leadingAnchor.constraint(equalTo: itemView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: itemView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: itemView.bottomAnchor),
            overlayView.heightAnchor.constraint(equalToConstant: 64),
            
            titleLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: durationLabel.topAnchor, constant: -4),
            
            durationLabel.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
            durationLabel.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
            durationLabel.bottomAnchor.constraint(equalTo: itemView.bottomAnchor, constant: -8),
            
            playButton.centerXAnchor.constraint(equalTo: itemView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: itemView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 48),
            playButton.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        // 添加悬停效果
        setupHoverEffects(for: itemView, playButton: playButton)
        
        return itemView
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
    
    // 设置悬停效果
    private func setupHoverEffects(for view: NSView, playButton: NSButton) {
        // 使用跟踪区域监听鼠标进入/离开事件
        let trackingArea = NSTrackingArea(
            rect: view.bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: ["view": view, "playButton": playButton]
        )
        view.addTrackingArea(trackingArea)
    }
    
    // 处理鼠标进入事件
    override func mouseEntered(with event: NSEvent) {
        guard let userInfo = event.trackingArea?.userInfo,
              let view = userInfo["view"] as? NSView,
              let playButton = userInfo["playButton"] as? NSButton else {
            super.mouseEntered(with: event)
            return
        }
        
        // 显示播放按钮
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            playButton.animator().alphaValue = 1.0
            
            // 添加高亮效果
            view.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.1).cgColor
        }
    }
    
    // 处理鼠标离开事件
    override func mouseExited(with event: NSEvent) {
        guard let userInfo = event.trackingArea?.userInfo,
              let view = userInfo["view"] as? NSView,
              let playButton = userInfo["playButton"] as? NSButton else {
            super.mouseExited(with: event)
            return
        }
        
        // 隐藏播放按钮
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            playButton.animator().alphaValue = 0.0
            
            // 移除高亮效果
            view.layer?.backgroundColor = NSColor.clear.cgColor
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
} 

