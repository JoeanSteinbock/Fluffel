import Cocoa

class FluffelPlaylistWindow: NSWindow {
    // 播放列表视图
    private var playlistView: NSView!
    private var category: FluffelPixabayPlaylists.PlaylistCategory
    internal weak var appDelegate: AppDelegate?
    
    init(category: FluffelPixabayPlaylists.PlaylistCategory, delegate: AppDelegate) {
        print("Initializing playlist window for category: \(category.rawValue)")
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
        self.title = "\(category.rawValue) Playlists"
        self.center()
        self.isReleasedWhenClosed = false
        self.backgroundColor = NSColor.windowBackgroundColor
        
        // 设置最小尺寸
        self.minSize = NSSize(width: 300, height: 400)
        
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
            
            NSLayoutConstraint.activate([
                loadingText.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                loadingText.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
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
        
        // 添加曲目列表
        var lastView: NSView = separator
        for (index, track) in tracks.enumerated() {
            let trackView = createTrackView(track: track, isLast: index == tracks.count - 1)
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
        
        // 创建标题标签
        let titleLabel = NSTextField(labelWithString: category.rawValue)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        headerView.addSubview(titleLabel)
        
        // 创建统计信息标签
        let statsLabel = NSTextField(labelWithString: "\(tracks.count) playlists · \(formattedDuration)")
        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        statsLabel.font = .systemFont(ofSize: 12)
        statsLabel.textColor = .secondaryLabelColor
        headerView.addSubview(statsLabel)
        
        // 创建描述标签
        let descLabel = NSTextField(wrappingLabelWithString: getPlaylistDescription(for: category))
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.font = .systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabelColor
        headerView.addSubview(descLabel)
        
        // 创建播放全部按钮
        let playAllButton = NSButton(title: "Play All", target: self, action: #selector(playAllTracks))
        playAllButton.translatesAutoresizingMaskIntoConstraints = false
        playAllButton.bezelStyle = .rounded
        playAllButton.contentTintColor = category.color
        headerView.addSubview(playAllButton)
        
        // 创建随机播放按钮
        let shuffleButton = NSButton(title: "Shuffle", target: self, action: #selector(shufflePlaylist))
        shuffleButton.translatesAutoresizingMaskIntoConstraints = false
        shuffleButton.bezelStyle = .rounded
        shuffleButton.contentTintColor = category.color
        headerView.addSubview(shuffleButton)
        
        // 如果有背景图片，添加背景图片视图
        if let bgImageUrl = getPlaylistBackgroundImage(for: category) {
            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            // 异步加载图片
            DispatchQueue.global().async {
                if let imageData = try? Data(contentsOf: bgImageUrl),
                   let image = NSImage(data: imageData) {
                    DispatchQueue.main.async {
                        imageView.image = image
                        imageView.wantsLayer = true
                        imageView.layer?.cornerRadius = 8
                        imageView.layer?.masksToBounds = true
                    }
                }
            }
            
            headerView.addSubview(imageView)
            
            // 设置图片视图约束
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: headerView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 120),
                imageView.heightAnchor.constraint(equalToConstant: 120)
            ])
            
            // 调整其他元素的约束以适应图片
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                
                statsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                statsLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                statsLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
                
                descLabel.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 8),
                descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
                
                playAllButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 12),
                playAllButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                
                shuffleButton.topAnchor.constraint(equalTo: playAllButton.topAnchor),
                shuffleButton.leadingAnchor.constraint(equalTo: playAllButton.trailingAnchor, constant: 8),
                
                headerView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
        } else {
            // 没有图片时的约束
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
                titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
                
                statsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                statsLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
                statsLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
                
                descLabel.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 8),
                descLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
                descLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
                
                playAllButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 12),
                playAllButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
                
                shuffleButton.topAnchor.constraint(equalTo: playAllButton.topAnchor),
                shuffleButton.leadingAnchor.constraint(equalTo: playAllButton.trailingAnchor, constant: 8),
                
                headerView.bottomAnchor.constraint(equalTo: playAllButton.bottomAnchor)
            ])
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
    
    private func createTrackView(track: Track, isLast: Bool) -> NSView {
        let trackView = NSView()
        trackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建曲目标题标签
        let titleLabel = NSTextField(labelWithString: track.title)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        trackView.addSubview(titleLabel)
        
        // 创建艺术家标签（在这里显示为"Pixabay播放列表"）
        let artistLabel = NSTextField(labelWithString: "Pixabay Playlist")
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
    
    @objc private func playTrack(_ sender: NSButton) {
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
                        if let firstAudio = audios.first {
                            // 创建Track并播放
                            let audioTrack = Track(
                                id: String(firstAudio.id),
                                title: firstAudio.title,
                                artist: firstAudio.user,
                                duration: firstAudio.duration,
                                url: firstAudio.audioURL
                            )
                            self?.appDelegate?.playTrack(audioTrack)
                            print("Playing audio: \(firstAudio.title)")
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
