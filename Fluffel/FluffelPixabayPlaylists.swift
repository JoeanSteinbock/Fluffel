import Foundation
import AppKit

/// Model for Pixabay playlists and tracks
class FluffelPixabayPlaylists {
    // Singleton instance
    static let shared = FluffelPixabayPlaylists()
    
    /// Model for a music playlist
    struct Playlist {
        let id: String
        let title: String
        let description: String
        let tracks: [Track]
        
        /// 获取播放列表的总时长（秒）
        var totalDuration: Int {
            return tracks.reduce(0) { $0 + $1.duration }
        }
        
        /// 格式化的总时长（mm:ss）
        var formattedTotalDuration: String {
            let minutes = totalDuration / 60
            let seconds = totalDuration % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Model for a music track
    struct Track {
        let id: String
        let title: String
        let artist: String
        let duration: Int // in seconds
        let url: String
        
        /// Format duration as mm:ss
        var formattedDuration: String {
            let minutes = duration / 60
            let seconds = duration % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // Playlists data
    private var playlists: [PlaylistCategory: [Track]] = [:]
    private var isLoading = false
    
    // 预设的播放列表类别
    enum PlaylistCategory: String, CaseIterable {
        case relax = "Relax"
        case workout = "Workout"
        case focus = "Focus"
        case party = "Party"
        
        var icon: String {
            switch self {
            case .relax: return "🌊"
            case .workout: return "💪"
            case .focus: return "🎯"
            case .party: return "🎉"
            }
        }
        
        var color: NSColor {
            switch self {
            case .relax: return .systemBlue
            case .workout: return .systemRed
            case .focus: return .systemOrange
            case .party: return .systemPurple
            }
        }
        
        // 获取搜索路径
        var searchPath: String {
            return rawValue.lowercased()
        }
    }
    
    // Private initializer for singleton
    private init() {
        print("FluffelPixabayPlaylists initialized")
        loadPlaylists { _ in }
    }
    
    /// Load playlists from Pixabay
    func loadPlaylists(completion: @escaping (Bool) -> Void) {
        print("Starting loadPlaylists")
        
        // 防止多次同时加载
        guard !isLoading else {
            print("Already loading playlists, skipping")
            completion(false)
            return
        }
        
        isLoading = true
        print("Setting isLoading flag")
        
        // 清空现有播放列表
        playlists.removeAll()
        
        // 创建 DispatchGroup 来管理异步加载
        let group = DispatchGroup()
        var hasError = false
        
        // 为每个类别加载播放列表
        for category in PlaylistCategory.allCases {
            print("Loading playlist for category: \(category.rawValue)")
            group.enter()
            
            FluffelPixabayService.shared.fetchAudioList(category: category.searchPath) { result in
                print("Received result for category: \(category.rawValue)")
                
                switch result {
                case .success(let audios):
                    print("Successfully loaded \(audios.count) tracks for \(category.rawValue)")
                    // 转换为 Track 对象并保存
                    let tracks = audios.map { audio in
                        Track(
                            id: String(audio.id),
                            title: audio.title,
                            artist: audio.user,
                            duration: audio.duration,
                            url: audio.audioURL
                        )
                    }
                    
                    // 保存到对应类别
                    DispatchQueue.main.async {
                        self.playlists[category] = tracks
                    }
                    
                case .failure(let error):
                    print("Failed to load playlist for \(category.rawValue): \(error.localizedDescription)")
                    hasError = true
                }
                
                group.leave()
            }
        }
        
        // 所有请求完成后的处理
        group.notify(queue: .main) {
            print("All playlist requests completed")
            self.isLoading = false
            completion(!hasError)
        }
    }
    
    /// 获取指定类别的播放列表
    func getPlaylist(for category: PlaylistCategory) -> [Track] {
        print("Getting playlist for category: \(category.rawValue)")
        let tracks = playlists[category] ?? []
        print("Found \(tracks.count) tracks for category \(category.rawValue)")
        return tracks
    }
    
    /// 获取所有播放列表类别
    func getAllCategories() -> [PlaylistCategory] {
        return PlaylistCategory.allCases
    }
    
    /// 获取播放列表中的随机曲目
    func getRandomTrack(from playlist: PlaylistCategory) -> Track? {
        return playlists[playlist]?.randomElement()
    }
    
    /// 获取所有播放列表中的随机曲目
    func getRandomTrack() -> Track? {
        let allTracks = playlists.flatMap { $0.value }
        return allTracks.randomElement()
    }
    
    // 加载预设播放列表（作为后备）
    private func loadPresetPlaylists() {
        // 为每个类别创建预设播放列表
        for category in PlaylistCategory.allCases {
            playlists[category] = createPresetTracks(for: category)
        }
    }
    
    // 创建预设曲目（作为后备）
    private func createPresetTracks(for category: PlaylistCategory) -> [Track] {
        // 根据类别创建预设曲目
        switch category {
        case .relax:
            return [
                Track(id: "1", title: "Morning Coffee", artist: "Relaxing Beats", duration: 180, url: "preset/morning_coffee.mp3"),
                Track(id: "2", title: "Sunset Vibes", artist: "Chill Music", duration: 240, url: "preset/sunset_vibes.mp3"),
                Track(id: "3", title: "Urban Dreams", artist: "City Sounds", duration: 200, url: "preset/urban_dreams.mp3")
            ]
        case .workout:
            return [
                Track(id: "4", title: "Ocean Waves", artist: "Nature Sounds", duration: 300, url: "preset/ocean_waves.mp3"),
                Track(id: "5", title: "Gentle Rain", artist: "Ambient Nature", duration: 360, url: "preset/gentle_rain.mp3"),
                Track(id: "6", title: "Forest Morning", artist: "Natural World", duration: 240, url: "preset/forest_morning.mp3")
            ]
        case .focus:
            return [
                Track(id: "7", title: "Power Up", artist: "Energy Beats", duration: 180, url: "preset/power_up.mp3"),
                Track(id: "8", title: "Morning Run", artist: "Workout Music", duration: 200, url: "preset/morning_run.mp3"),
                Track(id: "9", title: "Dance Time", artist: "Party Mix", duration: 220, url: "preset/dance_time.mp3")
            ]
        case .party:
            return [
                Track(id: "10", title: "Summer Joy", artist: "Happy Tunes", duration: 180, url: "preset/summer_joy.mp3"),
                Track(id: "11", title: "Sunny Day", artist: "Positive Vibes", duration: 200, url: "preset/sunny_day.mp3"),
                Track(id: "12", title: "Good Times", artist: "Feel Good", duration: 190, url: "preset/good_times.mp3")
            ]
        }
    }
}
