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
    private func fetchPlaylistContent(playlistId: String, completion: @escaping (Result<[PixabayAudio], Error>) -> Void) {
        // 使用任意前缀（这里用 'p'）+ playlistId
        let urlString = "\(baseURL)/playlists/p-\(playlistId)/"
        guard let url = URL(string: urlString) else {
            completion(.failure(PixabayError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
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
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let page = json["page"] as? [String: Any],
                   let playlist = page["playlist"] as? [String: Any],
                   let tracks = playlist["tracks"] as? [[String: Any]] {
                    
                    let audios = tracks.compactMap { track -> PixabayAudio? in
                        guard let id = track["id"] as? Int,
                              let title = track["title"] as? String,
                              let duration = track["duration"] as? Int,
                              let user = track["username"] as? String,
                              let audioURL = track["audio_url"] as? String else {
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
                    
                    completion(.success(audios))
                } else {
                    completion(.failure(PixabayError.htmlParsingError("Invalid JSON structure")))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
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
