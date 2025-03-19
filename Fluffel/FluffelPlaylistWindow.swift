import Cocoa

class FluffelPlaylistWindow: NSWindow {
    // 播放列表视图
    private var playlistView: NSView!
    private var category: FluffelPixabayPlaylists.PlaylistCategory
    internal weak var appDelegate: AppDelegate?
    
    init(category: FluffelPixabayPlaylists.PlaylistCategory, delegate: AppDelegate) {
        self.category = category
        self.appDelegate = delegate
        
        // 创建窗口
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        self.title = "\(category.rawValue) Music"
        self.center()
        self.isReleasedWhenClosed = false
        self.backgroundColor = NSColor.windowBackgroundColor
        
        // 设置最小尺寸
        self.minSize = NSSize(width: 300, height: 400)
        
        // 创建内容视图
        setupContentView()
    }
    
    private func setupContentView() {
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
        if let playlist = FluffelPixabayPlaylists.shared.getPlaylistByCategory(category) {
            // 添加播放列表标题
            let headerView = createHeaderView(playlist: playlist)
            containerView.addSubview(headerView)
            
            // 添加分隔线
            let separator = createSeparator()
            containerView.addSubview(separator)
            
            // 添加曲目列表
            var lastView: NSView = separator
            for (index, track) in playlist.tracks.enumerated() {
                let trackView = createTrackView(track: track, isLast: index == playlist.tracks.count - 1)
                containerView.addSubview(trackView)
                
                // 设置约束
                NSLayoutConstraint.activate([
                    trackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    trackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    trackView.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 8)
                ])
                
                lastView = trackView
            }
            
            // 设置容器视图约束
            NSLayoutConstraint.activate([
                headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
                headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                
                separator.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
                separator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                
                lastView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
            ])
        }
        
        // 设置文档视图
        scrollView.documentView = containerView
        
        // 添加滚动视图到主视图
        playlistView.addSubview(scrollView)
        
        // 设置内容视图
        contentView = playlistView
    }
    
    private func createHeaderView(playlist: Playlist) -> NSView {
        let headerView = NSView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建标题标签
        let titleLabel = NSTextField(labelWithString: playlist.title)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        headerView.addSubview(titleLabel)
        
        // 创建描述标签
        let descLabel = NSTextField(labelWithString: playlist.description)
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabelColor
        headerView.addSubview(descLabel)
        
        // 创建播放全部按钮
        let playAllButton = NSButton(title: "Play All", target: self, action: #selector(playAllTracks))
        playAllButton.translatesAutoresizingMaskIntoConstraints = false
        playAllButton.bezelStyle = .rounded
        headerView.addSubview(playAllButton)
        
        // 创建随机播放按钮
        let shuffleButton = NSButton(title: "Shuffle", target: self, action: #selector(shufflePlaylist))
        shuffleButton.translatesAutoresizingMaskIntoConstraints = false
        shuffleButton.bezelStyle = .rounded
        headerView.addSubview(shuffleButton)
        
        // 设置约束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            playAllButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 12),
            playAllButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            
            shuffleButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 12),
            shuffleButton.leadingAnchor.constraint(equalTo: playAllButton.trailingAnchor, constant: 8),
            
            headerView.bottomAnchor.constraint(equalTo: playAllButton.bottomAnchor)
        ])
        
        return headerView
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
    
    private func createTrackView(track: Track, isLast: Bool) -> NSView {
        let trackView = NSView()
        trackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建曲目标题标签
        let titleLabel = NSTextField(labelWithString: track.title)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 14)
        trackView.addSubview(titleLabel)
        
        // 创建艺术家标签
        let artistLabel = NSTextField(labelWithString: track.artist)
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        artistLabel.font = .systemFont(ofSize: 12)
        artistLabel.textColor = .secondaryLabelColor
        trackView.addSubview(artistLabel)
        
        // 创建时长标签
        let durationLabel = NSTextField(labelWithString: track.formattedDuration)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = .systemFont(ofSize: 12)
        durationLabel.textColor = .secondaryLabelColor
        trackView.addSubview(durationLabel)
        
        // 创建播放按钮
        let playButton = NSButton(image: NSImage(systemSymbolName: "play.circle", accessibilityDescription: "Play")!, target: self, action: #selector(playTrack(_:)))
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.bezelStyle = .circular
        playButton.isBordered = false
        playButton.tag = Int(track.id) ?? 0
        trackView.addSubview(playButton)
        
        // 设置约束
        NSLayoutConstraint.activate([
            playButton.leadingAnchor.constraint(equalTo: trackView.leadingAnchor, constant: 16),
            playButton.centerYAnchor.constraint(equalTo: trackView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 24),
            playButton.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: trackView.topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
            
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            artistLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            durationLabel.trailingAnchor.constraint(equalTo: trackView.trailingAnchor, constant: -16),
            durationLabel.centerYAnchor.constraint(equalTo: trackView.centerYAnchor),
            
            trackView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // 如果不是最后一个曲目，添加分隔线
        if !isLast {
            let separator = createSeparator()
            trackView.addSubview(separator)
            
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: trackView.trailingAnchor),
                separator.bottomAnchor.constraint(equalTo: trackView.bottomAnchor)
            ])
        }
        
        return trackView
    }
    
    // MARK: - Actions
    
    @objc private func playAllTracks() {
        if let playlist = FluffelPixabayPlaylists.shared.getPlaylistByCategory(category) {
            appDelegate?.playPlaylist(playlist)
        }
    }
    
    @objc private func shufflePlaylist() {
        if let playlist = FluffelPixabayPlaylists.shared.getPlaylistByCategory(category),
           let track = FluffelPixabayPlaylists.shared.getRandomTrack(from: playlist) {
            appDelegate?.playTrack(track)
        }
    }
    
    @objc private func playTrack(_ sender: NSButton) {
        if let track = FluffelPixabayPlaylists.shared.getTrack(id: String(sender.tag)) {
            appDelegate?.playTrack(track)
        }
    }
} 
