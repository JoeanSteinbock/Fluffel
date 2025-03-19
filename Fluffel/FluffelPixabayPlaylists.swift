import Foundation
import AppKit

/// Model for Pixabay playlists and tracks
class FluffelPixabayPlaylists {
    // Singleton instance
    static let shared = FluffelPixabayPlaylists()
    
    // Playlists data
    private(set) var playlists: [Playlist] = []
    private var isLoading = false
    
    // 预设的播放列表类别
    enum PlaylistCategory: String, CaseIterable {
        case featured = "Featured"
        case relaxing = "Relaxing"
        case energetic = "Energetic"
        case ambient = "Ambient"
        case happy = "Happy"
        case focus = "Focus"
        
        var icon: String {
            switch self {
            case .featured: return "star.fill"
            case .relaxing: return "leaf.fill"
            case .energetic: return "bolt.fill"
            case .ambient: return "cloud.fill"
            case .happy: return "sun.max.fill"
            case .focus: return "brain.head.profile"
            }
        }
        
        var color: NSColor {
            switch self {
            case .featured: return .systemYellow
            case .relaxing: return .systemGreen
            case .energetic: return .systemRed
            case .ambient: return .systemBlue
            case .happy: return .systemOrange
            case .focus: return .systemPurple
            }
        }
    }
    
    // Private initializer for singleton
    private init() {
        // 初始化时加载预设播放列表
        loadPresetPlaylists()
    }
    
    /// 加载预设的播放列表
    private func loadPresetPlaylists() {
        playlists = [
            createFeaturedPlaylist(),
            createRelaxingPlaylist(),
            createEnergeticPlaylist(),
            createAmbientPlaylist(),
            createHappyPlaylist(),
            createFocusPlaylist()
        ]
    }
    
    /// 创建精选播放列表
    private func createFeaturedPlaylist() -> Playlist {
        return Playlist(
            id: PlaylistCategory.featured.rawValue.lowercased(),
            title: PlaylistCategory.featured.rawValue,
            description: "A selection of featured music from Pixabay",
            tracks: [
                Track(
                    id: "1",
                    title: "Inspiring Acoustic",
                    artist: "Pixabay",
                    duration: 180,
                    url: URL(string: "https://cdn.pixabay.com/audio/2023/07/30/audio_e0908e8569.mp3")!
                ),
                Track(
                    id: "2",
                    title: "Happy Upbeat",
                    artist: "Pixabay",
                    duration: 160,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/10/30/audio_f8a4d46a0a.mp3")!
                ),
                Track(
                    id: "3",
                    title: "Relaxing Ambient",
                    artist: "Pixabay",
                    duration: 200,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/01/18/audio_d0c6ff1bbd.mp3")!
                )
            ]
        )
    }
    
    /// 创建放松播放列表
    private func createRelaxingPlaylist() -> Playlist {
        return Playlist(
            id: PlaylistCategory.relaxing.rawValue.lowercased(),
            title: PlaylistCategory.relaxing.rawValue,
            description: "Calm and peaceful tracks for relaxation",
            tracks: [
                Track(
                    id: "4",
                    title: "Gentle Piano",
                    artist: "Pixabay",
                    duration: 190,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/03/15/audio_942d0d0c89.mp3")!
                ),
                Track(
                    id: "5",
                    title: "Meditation Sounds",
                    artist: "Pixabay",
                    duration: 210,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/05/27/audio_1808fbf07a.mp3")!
                ),
                Track(
                    id: "6",
                    title: "Ocean Waves",
                    artist: "Pixabay",
                    duration: 180,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/08/04/audio_2dde3c6c73.mp3")!
                )
            ]
        )
    }
    
    /// 创建活力播放列表
    private func createEnergeticPlaylist() -> Playlist {
        return Playlist(
            id: PlaylistCategory.energetic.rawValue.lowercased(),
            title: PlaylistCategory.energetic.rawValue,
            description: "Upbeat music to boost your energy",
            tracks: [
                Track(
                    id: "7",
                    title: "Dance Pop",
                    artist: "Pixabay",
                    duration: 165,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/11/22/audio_5dc6ab8b0d.mp3")!
                ),
                Track(
                    id: "8",
                    title: "Electronic Vibes",
                    artist: "Pixabay",
                    duration: 175,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/10/25/audio_8075e01f0f.mp3")!
                ),
                Track(
                    id: "9",
                    title: "Upbeat Rock",
                    artist: "Pixabay",
                    duration: 155,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/09/10/audio_69a61cd6d6.mp3")!
                )
            ]
        )
    }
    
    /// 创建环境音乐播放列表
    private func createAmbientPlaylist() -> Playlist {
        return Playlist(
            id: PlaylistCategory.ambient.rawValue.lowercased(),
            title: PlaylistCategory.ambient.rawValue,
            description: "Atmospheric and ambient soundscapes",
            tracks: [
                Track(
                    id: "10",
                    title: "Space Dreams",
                    artist: "Pixabay",
                    duration: 220,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/04/27/audio_db63c5f745.mp3")!
                ),
                Track(
                    id: "11",
                    title: "Night Atmosphere",
                    artist: "Pixabay",
                    duration: 200,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/06/15/audio_9a71da6d6a.mp3")!
                ),
                Track(
                    id: "12",
                    title: "Forest Sounds",
                    artist: "Pixabay",
                    duration: 180,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/07/08/audio_47c5c68d1a.mp3")!
                )
            ]
        )
    }
    
    /// 创建快乐播放列表
    private func createHappyPlaylist() -> Playlist {
        return Playlist(
            id: PlaylistCategory.happy.rawValue.lowercased(),
            title: PlaylistCategory.happy.rawValue,
            description: "Cheerful and uplifting tunes",
            tracks: [
                Track(
                    id: "13",
                    title: "Happy Ukulele",
                    artist: "Pixabay",
                    duration: 145,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/12/05/audio_c8c8a73467.mp3")!
                ),
                Track(
                    id: "14",
                    title: "Sunny Day",
                    artist: "Pixabay",
                    duration: 160,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/11/15/audio_5b5e741045.mp3")!
                ),
                Track(
                    id: "15",
                    title: "Playful Tune",
                    artist: "Pixabay",
                    duration: 150,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/10/18/audio_a5c5e5f578.mp3")!
                )
            ]
        )
    }
    
    /// 创建专注播放列表
    private func createFocusPlaylist() -> Playlist {
        return Playlist(
            id: PlaylistCategory.focus.rawValue.lowercased(),
            title: PlaylistCategory.focus.rawValue,
            description: "Music for concentration and productivity",
            tracks: [
                Track(
                    id: "16",
                    title: "Study Time",
                    artist: "Pixabay",
                    duration: 210,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/08/22/audio_4f66a1f5d6.mp3")!
                ),
                Track(
                    id: "17",
                    title: "Deep Focus",
                    artist: "Pixabay",
                    duration: 195,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/09/30/audio_7c6cd86c45.mp3")!
                ),
                Track(
                    id: "18",
                    title: "Concentration",
                    artist: "Pixabay",
                    duration: 185,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/07/12/audio_6f95e8d478.mp3")!
                )
            ]
        )
    }
    
    /// Load playlists from Pixabay
    func loadPlaylists(completion: @escaping (Bool) -> Void) {
        // 防止多次同时加载
        guard !isLoading else {
            completion(false)
            return
        }
        
        isLoading = true
        
        // 如果已经有预设播放列表，直接返回成功
        if !playlists.isEmpty {
            isLoading = false
            completion(true)
            return
        }
        
        // 加载预设播放列表
        loadPresetPlaylists()
        isLoading = false
        completion(true)
    }
    
    /// Get a playlist by ID
    func getPlaylist(id: String) -> Playlist? {
        return playlists.first { $0.id == id }
    }
    
    /// Get a track by ID from any playlist
    func getTrack(id: String) -> Track? {
        for playlist in playlists {
            if let track = playlist.tracks.first(where: { $0.id == id }) {
                return track
            }
        }
        return nil
    }
    
    /// 获取指定类别的播放列表
    func getPlaylistByCategory(_ category: PlaylistCategory) -> Playlist? {
        return getPlaylist(id: category.rawValue.lowercased())
    }
    
    /// 获取所有播放列表类别
    func getAllCategories() -> [PlaylistCategory] {
        return [.featured, .relaxing, .energetic, .ambient, .happy, .focus]
    }
    
    /// 获取播放列表中的随机曲目
    func getRandomTrack(from playlist: Playlist) -> Track? {
        guard !playlist.tracks.isEmpty else { return nil }
        return playlist.tracks.randomElement()
    }
    
    /// 获取所有播放列表中的随机曲目
    func getRandomTrack() -> Track? {
        let allTracks = playlists.flatMap { $0.tracks }
        return allTracks.randomElement()
    }
}

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
    let url: URL
    
    /// Format duration as mm:ss
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
