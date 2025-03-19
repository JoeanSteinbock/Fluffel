import Foundation

// 导入播放列表模型
typealias Playlist = FluffelPixabayPlaylists.Playlist
typealias Track = FluffelPixabayPlaylists.Track

class FluffelPixabayService: NSObject {
    static let shared = FluffelPixabayService()
    private let session: URLSession
    private var playlists: [String: [PixabayAudio]] = [:]
    private let baseURL = "https://pixabay.com"
    
    private override init() {
        // 创建自定义的 URLSession 配置
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Safari/605.1.15",
            "Accept": "application/json",
            "Accept-Language": "en-US,en;q=0.9",
            "Cache-Control": "no-cache",
            "Pragma": "no-cache",
            "sec-ch-ua": "\"Chromium\";v=\"134\", \"Not:A-Brand\";v=\"24\", \"Microsoft Edge\";v=\"134\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"macOS\"",
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-origin",
            "x-fetch-bootstrap": "1"
        ]
        
        self.session = URLSession(configuration: config)
        super.init()
        loadPredefinedPlaylists()
    }
    
    private func loadPredefinedPlaylists() {
        print("Loading predefined playlists from playlists.json")
        
        // 获取 playlists.json 文件路径
        guard let url = Bundle.main.url(forResource: "playlists", withExtension: "json") else {
            print("Error: Could not find playlists.json in bundle")
            return
        }
        
        do {
            // 读取文件内容
            let data = try Data(contentsOf: url)
            let allPlaylists = try JSONDecoder().decode([PlaylistData].self, from: data)
            
            // 将播放列表按类别分类
            categorizeAndStorePlaylists(allPlaylists)
            
            // 打印加载信息
            print("Successfully loaded \(allPlaylists.count) playlists")
            for playlist in allPlaylists {
                print("- \(playlist.title) (\(playlist.audioCount) tracks, \(playlist.formattedDuration))")
                if let categories = playlist.categories {
                    print("  Categories: \(categories.joined(separator: ", "))")
                }
            }
            
        } catch {
            print("Error loading playlists.json: \(error)")
        }
    }
    
    private func categorizeAndStorePlaylists(_ allPlaylists: [PlaylistData]) {
        // 清空现有播放列表
        playlists.removeAll()
        
        // 遍历所有播放列表
        for playlist in allPlaylists {
            // 创建音频对象
            let audio = PixabayAudio(
                id: playlist.id,
                title: playlist.title,
                duration: playlist.duration,
                user: "Pixabay",
                audioURL: playlist.fullUrl
            )
            
            // 将播放列表添加到每个相关类别中
            if let categories = playlist.categories {
                for category in categories {
                    let categoryKey = category.lowercased()
                    if playlists[categoryKey] == nil {
                        playlists[categoryKey] = []
                    }
                    playlists[categoryKey]?.append(audio)
                }
            }
        }
        
        // 打印分类结果
        for (category, items) in playlists {
            print("Category '\(category)' has \(items.count) playlists")
        }
    }
    
    /// 从 Pixabay 获取播放列表内容
    func fetchPlaylistContent(playlistId: String, completion: @escaping (Result<[PixabayAudio], Error>) -> Void) {
        // 使用任意前缀（这里用 'p'）+ playlistId
        let urlString = "\(baseURL)/playlists/p-\(playlistId)/"
        print("Fetching playlist from URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            completion(.failure(PixabayError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("1", forHTTPHeaderField: "x-fetch-bootstrap")
        request.setValue("same-origin", forHTTPHeaderField: "sec-fetch-site")
        request.setValue("cors", forHTTPHeaderField: "sec-fetch-mode")
        request.setValue("empty", forHTTPHeaderField: "sec-fetch-dest")
        
        // 打印请求信息以便调试
        print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        // 发起请求
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(PixabayError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(PixabayError.serverError(statusCode: httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(PixabayError.noData))
                return
            }
            
            do {
                // 打印原始响应数据以便调试
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response preview: \(String(responseString.prefix(200)))...")
                }
                
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("JSON keys at root level: \(json.keys.joined(separator: ", "))")
                    
                    // 尝试从 page.playlist.tracks 路径获取
                    if let page = json["page"] as? [String: Any] {
                        print("JSON keys in page: \(page.keys.joined(separator: ", "))")
                        
                        // 路径1: page -> playlist -> tracks
                        if let playlist = page["playlist"] as? [String: Any],
                           let tracks = playlist["tracks"] as? [[String: Any]] {
                            
                            self.processTracks(tracks, completion: completion)
                            return
                        }
                        
                        // 路径2: page -> tracks (直接在page下)
                        if let tracks = page["tracks"] as? [[String: Any]] {
                            self.processTracks(tracks, completion: completion)
                            return
                        }
                        
                        // 路径3: page -> results (用于搜索结果)
                        if let results = page["results"] as? [[String: Any]] {
                            self.processTracks(results, completion: completion)
                            return
                        }
                    }
                    
                    // 路径4: bootstrap -> playlist -> tracks
                    if let bootstrap = json["bootstrap"] as? [String: Any],
                       let playlist = bootstrap["playlist"] as? [String: Any],
                       let tracks = playlist["tracks"] as? [[String: Any]] {
                        
                        self.processTracks(tracks, completion: completion)
                        return
                    }
                    
                    completion(.failure(PixabayError.htmlParsingError("Could not find tracks in the JSON structure")))
                } else {
                    completion(.failure(PixabayError.htmlParsingError("Invalid JSON structure")))
                }
            } catch {
                print("JSON parsing error: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // 处理曲目数据的辅助方法
    private func processTracks(_ tracks: [[String: Any]], completion: @escaping (Result<[PixabayAudio], Error>) -> Void) {
        let audios = tracks.compactMap { track -> PixabayAudio? in
            // 尝试提取基本信息
            guard let id = track["id"] as? Int else {
                print("Missing ID in track: \(track)")
                return nil
            }
            
            // 提取标题（可能是 title 或 name 字段）
            var title: String
            if let titleValue = track["title"] as? String {
                title = titleValue
            } else if let nameValue = track["name"] as? String {
                title = nameValue
            } else {
                print("Missing title in track ID \(id)")
                title = "Unknown Title"
            }
            
            // 提取时长
            let duration: Int
            if let durationValue = track["duration"] as? Int {
                duration = durationValue
            } else {
                print("Missing duration in track ID \(id), using default")
                duration = 0
            }
            
            // 提取用户名
            var user: String
            if let userValue = track["username"] as? String {
                user = userValue
            } else if let userValue = track["user"] as? String {
                user = userValue
            } else if let userObject = track["user"] as? [String: Any], 
                      let username = userObject["username"] as? String {
                user = username
            } else {
                print("Missing username in track ID \(id)")
                user = "Unknown Artist"
            }
            
            // 提取音频 URL
            var audioURL: String
            if let audioValue = track["audio_url"] as? String {
                audioURL = audioValue
                print("Found audio_url for track \(id): \(audioURL)")
            } else if let sources = track["sources"] as? [String: Any], 
                      let src = sources["src"] as? String {
                audioURL = src
                print("Found sources.src for track \(id): \(audioURL)")
            } else {
                print("Missing audio URL in track ID \(id)")
                return nil  // 没有 URL 无法播放，直接跳过
            }
            
            // 确保 URL 是安全合法的
            if !audioURL.hasPrefix("http") {
                print("URL doesn't have http prefix: \(audioURL)")
                // 尝试添加前缀
                if audioURL.hasPrefix("//") {
                    audioURL = "https:" + audioURL
                    print("Fixed URL with https prefix: \(audioURL)")
                } else {
                    // 尝试构建完整的 URL
                    audioURL = "https://pixabay.com" + audioURL
                    print("Attempted to fix URL: \(audioURL)")
                }
            }
            
            // 最后检查 URL 合法性
            guard URL(string: audioURL) != nil else {
                print("Failed to create valid URL from string: \(audioURL)")
                return nil
            }
            
            return PixabayAudio(
                id: id,
                title: title,
                duration: duration,
                user: user,
                audioURL: audioURL
            )
        }
        
        if audios.isEmpty {
            print("No valid tracks found in the response")
            completion(.failure(PixabayError.noData))
        } else {
            print("Successfully parsed \(audios.count) tracks")
            // 打印每个音轨的信息
            for (index, audio) in audios.enumerated() {
                print("Track \(index+1): \(audio.title) by \(audio.user), duration: \(audio.duration)s, URL: \(audio.audioURL)")
            }
            completion(.success(audios))
        }
    }
    
    /// 获取音频列表（优先从 Pixabay 获取，失败时使用预定义列表）
    func fetchAudioList(category: String, completion: @escaping (Result<[PixabayAudio], Error>) -> Void) {
        // 首先尝试从预定义播放列表中获取
        if let categoryPlaylists = playlists[category.lowercased()] {
            completion(.success(categoryPlaylists))
            return
        }
        
        // 如果预定义列表中没有，则尝试从 Pixabay 获取
        // 根据类别获取对应的播放列表 ID
        let playlistId: String
        switch category.lowercased() {
        case "relax":
            playlistId = "17503730" // Chill Beats
        case "focus":
            playlistId = "22139477" // Cosmos
        case "party":
            playlistId = "24274664" // Dance Party
        case "workout":
            playlistId = "22335330" // Running
        default:
            completion(.failure(PixabayError.noData))
            return
        }
        
        // 获取播放列表内容
        fetchPlaylistContent(playlistId: playlistId, completion: completion)
    }
    
    /// 获取播放列表
    func fetchPlaylist(category: FluffelPixabayPlaylists.PlaylistCategory, completion: @escaping (Result<FluffelPixabayPlaylists.Playlist, Error>) -> Void) {
        fetchAudioList(category: category.searchPath) { result in
            switch result {
            case .success(let audios):
                let tracks = audios.map { audio in
                    FluffelPixabayPlaylists.Track(
                        id: String(audio.id),
                        title: audio.title,
                        artist: audio.user,
                        duration: audio.duration,
                        url: audio.audioURL
                    )
                }
                
                // 从预定义播放列表中获取额外信息
                let description: String
                let bgImageSrc: String?
                
                if let url = Bundle.main.url(forResource: "playlists", withExtension: "json"),
                   let data = try? Data(contentsOf: url),
                   let allPlaylists = try? JSONDecoder().decode([PlaylistData].self, from: data),
                   let matchingPlaylist = allPlaylists.first(where: { $0.belongsTo(category: category.searchPath) }) {
                    description = matchingPlaylist.description
                    bgImageSrc = matchingPlaylist.bgImageSrc
                } else {
                    description = "A collection of \(category.rawValue.lowercased()) music"
                    bgImageSrc = nil
                }
                
                let playlist = FluffelPixabayPlaylists.Playlist(
                    id: category.rawValue.lowercased(),
                    title: category.rawValue,
                    description: description,
                    tracks: tracks
                )
                
                completion(.success(playlist))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Models

/// 用于解析预定义播放列表数据的模型
struct PlaylistData: Codable {
    let id: Int
    let title: String
    let description: String
    let duration: Int
    let audioCount: Int
    let publicUrl: String
    let categories: [String]?
    let bgImageSrc: String?
    let isFeatured: Bool?
    
    // 辅助方法：获取格式化的时长
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // 辅助方法：获取完整的 URL
    var fullUrl: String {
        return "https://pixabay.com\(publicUrl)"
    }
    
    // 辅助方法：检查是否属于某个类别
    func belongsTo(category: String) -> Bool {
        return categories?.contains { $0.lowercased() == category.lowercased() } ?? false
    }
}

/// 用于音频数据的模型
struct PixabayAudio: Codable {
    let id: Int
    let title: String
    let duration: Int
    let user: String
    let audioURL: String
}

/// 用于错误处理的枚举
enum PixabayError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case serverError(statusCode: Int)
    case htmlParsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .htmlParsingError(let message):
            return "HTML parsing error: \(message)"
        }
    }
} 
