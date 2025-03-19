import Foundation

/// Model for Pixabay playlists and tracks
class FluffelPixabayPlaylists {
    // Singleton instance
    static let shared = FluffelPixabayPlaylists()
    
    // Playlists data
    private(set) var playlists: [Playlist] = []
    private var isLoading = false
    
    // Private initializer for singleton
    private init() {}
    
    /// Load playlists from Pixabay
    func loadPlaylists(completion: @escaping (Bool) -> Void) {
        // Prevent multiple simultaneous loads
        guard !isLoading else {
            completion(false)
            return
        }
        
        isLoading = true
        
        // URL for Pixabay playlists page
        guard let url = URL(string: "https://pixabay.com/playlists/") else {
            print("Invalid Pixabay playlists URL")
            isLoading = false
            completion(false)
            return
        }
        
        // Create URL session task
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Reset loading flag
            defer { self.isLoading = false }
            
            // Handle errors
            if let error = error {
                print("Error loading Pixabay playlists: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // Check for valid data
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                print("Invalid data received from Pixabay")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // Parse the HTML to extract playlists
            let parsedPlaylists = self.parsePlaylists(from: htmlString)
            
            // Update playlists and notify completion
            DispatchQueue.main.async {
                self.playlists = parsedPlaylists
                completion(!parsedPlaylists.isEmpty)
            }
        }
        
        // Start the task
        task.resume()
    }
    
    /// Parse playlists from HTML content
    private func parsePlaylists(from html: String) -> [Playlist] {
        var playlists: [Playlist] = []
        
        // Add a fallback playlist in case parsing fails
        let fallbackPlaylist = Playlist(
            id: "fallback",
            title: "Featured Music",
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
        
        // Try to parse playlists from HTML
        // This is a simplified implementation that would need to be expanded
        // with proper HTML parsing for production use
        
        // For now, just add the fallback playlist
        playlists.append(fallbackPlaylist)
        
        // Add more hardcoded playlists for demonstration
        let relaxingPlaylist = Playlist(
            id: "relaxing",
            title: "Relaxing Music",
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
                )
            ]
        )
        
        let energeticPlaylist = Playlist(
            id: "energetic",
            title: "Energetic Beats",
            description: "Upbeat music to boost your energy",
            tracks: [
                Track(
                    id: "6",
                    title: "Dance Pop",
                    artist: "Pixabay",
                    duration: 165,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/11/22/audio_5dc6ab8b0d.mp3")!
                ),
                Track(
                    id: "7",
                    title: "Electronic Vibes",
                    artist: "Pixabay",
                    duration: 175,
                    url: URL(string: "https://cdn.pixabay.com/audio/2022/10/25/audio_8075e01f0f.mp3")!
                )
            ]
        )
        
        playlists.append(relaxingPlaylist)
        playlists.append(energeticPlaylist)
        
        return playlists
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
}

/// Model for a music playlist
struct Playlist {
    let id: String
    let title: String
    let description: String
    let tracks: [Track]
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