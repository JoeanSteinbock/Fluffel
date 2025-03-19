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
        // 预定义的播放列表数据
        let playlistsData = """
        [
            {
                "id": 24274664,
                "title": "Dance Party",
                "description": "A selection of tracks by the Pixabay community to set the mood for your next dance party.",
                "duration": 3139,
                "audioCount": 19,
                "publicUrl": "/playlists/dance-party-24274664/"
            },
            {
                "id": 23032217,
                "title": "Zen Meditation",
                "description": "This is the place to find peace. Take a deep breath, close your eyes and immerse yourself...",
                "duration": 19388,
                "audioCount": 30,
                "publicUrl": "/playlists/zen-meditation-23032217/"
            },
            {
                "id": 22139477,
                "title": "Cosmos",
                "description": "This is what space feels like... Dive deep into our selected cosmic tracks and touch the stars.",
                "duration": 11360,
                "audioCount": 49,
                "publicUrl": "/playlists/cosmos-22139477/"
            },
            {
                "id": 17503730,
                "title": "Chill Beats",
                "description": "Chill Beats playlist: Smooth, mellow and laid-back rhythms. Perfect for cooking, relaxing, de-stressing.",
                "duration": 4334,
                "audioCount": 25,
                "publicUrl": "/playlists/chill-beats-17503730/"
            },
            {
                "id": 20707654,
                "title": "Nature Sleep Sounds",
                "description": "Soothe your senses with the sounds of whispering winds, rustling leaves, and rain for a tranquil sleep.",
                "duration": 13970,
                "audioCount": 35,
                "publicUrl": "/playlists/nature-sleep-sounds-20707654/"
            },
            {
                "id": 17501847,
                "title": "Get Focused",
                "description": "A stimulating mix to get your brain into the right flow. Conquer your workload with our tunnel vision tracks.",
                "duration": 9606,
                "audioCount": 35,
                "publicUrl": "/playlists/get-focused-17501847/"
            },
            {
                "id": 17503543,
                "title": "LoFi Chillout",
                "description": "Relax & unwind with our Lofi Chillout playlist. Perfect beats for working, relaxing, or chilling out.",
                "duration": 3980,
                "audioCount": 27,
                "publicUrl": "/playlists/lofi-chillout-17503543/"
            },
            {
                "id": 17501840,
                "title": "LoFi Study",
                "description": "Boost focus with our Lofi Study playlist. Smooth, calming beats to enhance concentration and productivity.",
                "duration": 4375,
                "audioCount": 24,
                "publicUrl": "/playlists/lofi-study-17501840/"
            },
            {
                "id": 17501839,
                "title": "Ambient Sleep",
                "description": "Dream peacefully with our soothing and calming melodies featuring ambient tunes for a quality sleep.",
                "duration": 12696,
                "audioCount": 24,
                "publicUrl": "/playlists/ambient-sleep-17501839/"
            },
            {
                "id": 22334466,
                "title": "Yoga Session",
                "description": "Selected tracks for balancing mind and body. This is the perfect playlist for your peaceful and relaxing yoga session.",
                "duration": 9576,
                "audioCount": 23,
                "publicUrl": "/playlists/yoga-session-22334466/"
            },
            {
                "id": 22335330,
                "title": "Running",
                "description": "Your daily dose of motivation. Get up, run better and run faster with Pixabay top tracks!",
                "duration": 3192,
                "audioCount": 29,
                "publicUrl": "/playlists/running-22335330/"
            },
            {
                "id": 17503542,
                "title": "Gym Workout",
                "description": "Pump up your workout with full of high-energy tracks to boost motivation and performance.",
                "duration": 3089,
                "audioCount": 22,
                "publicUrl": "/playlists/gym-workout-17503542/"
            }
        ]
        """
        
        // 解析 JSON 数据
        if let data = playlistsData.data(using: .utf8),
           let allPlaylists = try? JSONDecoder().decode([PlaylistData].self, from: data) {
            
            // 将播放列表按类别分类
            categorizeAndStorePlaylists(allPlaylists)
        }
    }
    
    private func categorizeAndStorePlaylists(_ allPlaylists: [PlaylistData]) {
        // 按类别过滤播放列表
        let relaxPlaylists = allPlaylists.filter { playlist in
            let title = playlist.title.lowercased()
            return title.contains("chill") || title.contains("ambient") || 
                   title.contains("zen") || title.contains("sleep") ||
                   title.contains("yoga")
        }
        
        let workoutPlaylists = allPlaylists.filter { playlist in
            let title = playlist.title.lowercased()
            return title.contains("gym") || title.contains("running") ||
                   title.contains("workout")
        }
        
        let focusPlaylists = allPlaylists.filter { playlist in
            let title = playlist.title.lowercased()
            return title.contains("study") || title.contains("focus") ||
                   title.contains("cosmos")
        }
        
        let partyPlaylists = allPlaylists.filter { playlist in
            let title = playlist.title.lowercased()
            return title.contains("party") || title.contains("dance")
        }
        
        // 为每个类别创建音频列表
        playlists["relax"] = relaxPlaylists.map { createAudioFromPlaylist($0) }
        playlists["workout"] = workoutPlaylists.map { createAudioFromPlaylist($0) }
        playlists["focus"] = focusPlaylists.map { createAudioFromPlaylist($0) }
        playlists["party"] = partyPlaylists.map { createAudioFromPlaylist($0) }
        
        // 打印加载的播放列表信息
        for (category, items) in playlists {
            print("Loaded \(items.count) playlists for category '\(category)'")
        }
    }
    
    private func createAudioFromPlaylist(_ playlist: PlaylistData) -> PixabayAudio {
        return PixabayAudio(
            id: playlist.id,
            title: playlist.title,
            duration: playlist.duration,
            user: "Pixabay",
            audioURL: "https://pixabay.com\(playlist.publicUrl)"
        )
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
            // 如果没有匹配的播放列表，使用预定义的
            if let categoryPlaylists = playlists[category.lowercased()] {
                completion(.success(categoryPlaylists))
            } else {
                completion(.failure(PixabayError.noData))
            }
            return
        }
        
        // 获取播放列表内容
        fetchPlaylistContent(playlistId: playlistId) { result in
            switch result {
            case .success(let audios):
                completion(.success(audios))
            case .failure(_):
                // 如果获取失败，使用预定义播放列表
                if let categoryPlaylists = self.playlists[category.lowercased()] {
                    completion(.success(categoryPlaylists))
                } else {
                    completion(.failure(PixabayError.noData))
                }
            }
        }
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
                
                let playlist = FluffelPixabayPlaylists.Playlist(
                    id: category.rawValue.lowercased(),
                    title: category.rawValue,
                    description: "A collection of \(category.rawValue.lowercased()) music from Pixabay",
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
