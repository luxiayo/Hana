import Foundation

// MARK: - Data Manager Protocol

protocol PersistenceDataManaging: AnyObject {
    // Watch History
    func loadWatchHistory() -> [WatchHistoryRecordModel]
    func saveWatchHistory(_ records: [WatchHistoryRecordModel])
    func insertWatchHistory(_ record: WatchHistoryRecordModel)
    func deleteWatchHistory(_ record: WatchHistoryRecordModel)

    // Search History
    func loadSearchHistory() -> [SearchHistoryRecordModel]
    func insertSearchHistory(_ record: SearchHistoryRecordModel)
    func deleteSearchHistory(_ record: SearchHistoryRecordModel)

    // Advanced Search History
    func loadAdvancedSearchHistory() -> [AdvancedSearchHistoryRecordModel]
    func insertAdvancedSearchHistory(_ record: AdvancedSearchHistoryRecordModel)
    func deleteAdvancedSearchHistory(_ record: AdvancedSearchHistoryRecordModel)

    // Favorites
    func loadFavorites() -> [FavoriteVideoRecordModel]
    func insertFavorite(_ record: FavoriteVideoRecordModel)
    func deleteFavorite(_ record: FavoriteVideoRecordModel)

    // Watch Later
    func loadWatchLater() -> [WatchLaterRecordModel]
    func insertWatchLater(_ record: WatchLaterRecordModel)
    func deleteWatchLater(_ record: WatchLaterRecordModel)

    // Playlists
    func loadPlaylists() -> [PlaylistRecordModel]
    func insertPlaylist(_ record: PlaylistRecordModel)
    func deletePlaylist(_ record: PlaylistRecordModel)

    // Playlist Items
    func loadPlaylistItems() -> [PlaylistItemRecordModel]
    func insertPlaylistItem(_ record: PlaylistItemRecordModel)
    func deletePlaylistItem(_ record: PlaylistItemRecordModel)

    // Download Queue
    func loadDownloadQueue() -> [DownloadQueueRecordModel]
    func insertDownloadQueue(_ record: DownloadQueueRecordModel)
    func deleteDownloadQueue(_ record: DownloadQueueRecordModel)

    // Download Groups
    func loadDownloadGroups() -> [DownloadGroupRecordModel]
    func insertDownloadGroup(_ record: DownloadGroupRecordModel)
    func deleteDownloadGroup(_ record: DownloadGroupRecordModel)

    // HKeyframes
    func loadHKeyframeRecords() -> [HKeyframeRecordModel]
    func insertHKeyframeRecord(_ record: HKeyframeRecordModel)
    func deleteHKeyframeRecord(_ record: HKeyframeRecordModel)

    func save()
}

// MARK: - Watch History

final class WatchHistoryRecordModel: Codable, Identifiable {
    var id: String { videoCode }
    var videoCode: String
    var title: String
    var coverURLString: String?
    var releaseDate: Date?
    var watchDate: Date
    var progress: TimeInterval
    var duration: TimeInterval?
    var watchedAt: Date?

    init(
        videoCode: String,
        title: String,
        coverURLString: String? = nil,
        releaseDate: Date? = nil,
        watchDate: Date = Date(),
        progress: TimeInterval = 0,
        duration: TimeInterval? = nil,
        watchedAt: Date? = nil
    ) {
        self.videoCode = videoCode
        self.title = title
        self.coverURLString = coverURLString
        self.releaseDate = releaseDate
        self.watchDate = watchDate
        self.progress = progress
        self.duration = duration
        self.watchedAt = watchedAt
    }
}

extension WatchHistoryRecordModel {
    static let historyEntryRatio = 0.10
    static let watchedRatio = 0.80

    var playbackRatio: Double {
        guard let duration, duration > 0 else { return 0 }
        return min(max(progress / duration, 0), 1)
    }

    var isHistoryEligible: Bool {
        playbackRatio >= Self.historyEntryRatio
    }

    var isWatched: Bool {
        watchedAt != nil || playbackRatio >= Self.watchedRatio
    }
}

// MARK: - Search History

final class SearchHistoryRecordModel: Codable, Identifiable {
    var id: String { query }
    var query: String
    var createdAt: Date

    init(query: String, createdAt: Date = Date()) {
        self.query = query
        self.createdAt = createdAt
    }
}

// MARK: - Advanced Search History

final class AdvancedSearchHistoryRecordModel: Codable, Identifiable {
    var id: String { criteriaKey }
    var criteriaKey: String
    var summary: String
    var criteriaJSON: String
    var createdAt: Date

    init(criteria: HanimeSearchCriteria, createdAt: Date = Date()) {
        let criteria = criteria.normalized()
        self.criteriaKey = criteria.historyKey
        self.summary = criteria.summary
        self.criteriaJSON = criteria.encodedJSONString() ?? "{}"
        self.createdAt = createdAt
    }

    var criteria: HanimeSearchCriteria {
        HanimeSearchCriteria.decoded(from: criteriaJSON) ?? .empty
    }
}

// MARK: - Favorite Video

final class FavoriteVideoRecordModel: Codable, Identifiable {
    var id: String { videoCode }
    var videoCode: String
    var title: String
    var coverURLString: String?
    var createdAt: Date

    init(
        videoCode: String,
        title: String,
        coverURLString: String? = nil,
        createdAt: Date = Date()
    ) {
        self.videoCode = videoCode
        self.title = title
        self.coverURLString = coverURLString
        self.createdAt = createdAt
    }
}

// MARK: - Watch Later

final class WatchLaterRecordModel: Codable, Identifiable {
    var id: String { videoCode }
    var videoCode: String
    var title: String
    var coverURLString: String?
    var createdAt: Date

    init(
        videoCode: String,
        title: String,
        coverURLString: String? = nil,
        createdAt: Date = Date()
    ) {
        self.videoCode = videoCode
        self.title = title
        self.coverURLString = coverURLString
        self.createdAt = createdAt
    }
}

// MARK: - Playlist

final class PlaylistRecordModel: Codable, Identifiable {
    var id: String
    var title: String
    var detail: String
    var coverURLString: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        detail: String = "",
        coverURLString: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.coverURLString = coverURLString
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Playlist Item

final class PlaylistItemRecordModel: Codable, Identifiable {
    var id: String
    var playlistID: String
    var videoCode: String
    var title: String
    var coverURLString: String?
    var createdAt: Date

    init(
        playlistID: String,
        videoCode: String,
        title: String,
        coverURLString: String? = nil,
        createdAt: Date = Date()
    ) {
        self.playlistID = playlistID
        self.videoCode = videoCode
        self.title = title
        self.coverURLString = coverURLString
        self.createdAt = createdAt
        self.id = "\(playlistID)-\(videoCode)"
    }
}

// MARK: - Download Queue

final class DownloadQueueRecordModel: Codable, Identifiable {
    var id: String
    var videoCode: String
    var title: String
    var coverURLString: String?
    var quality: String
    var mediaURLString: String
    var downloadGroupName: String = "默认分组"
    var createdAt: Date
    var status: String
    var localFileURLString: String?
    var errorMessage: String?
    var completedAt: Date?
    var progress: Double
    var retryCount: Int
    var backgroundSessionIdentifier: String?
    var backgroundTaskIdentifier: Int?
    var backgroundTaskStartedAt: Date?
    var backgroundTaskUpdatedAt: Date?
    var downloadedByteCount: Int64?
    var expectedByteCount: Int64?
    var completionNotificationSentAt: Date?

    init(
        videoCode: String,
        title: String,
        coverURLString: String?,
        quality: String,
        mediaURLString: String,
        createdAt: Date = Date(),
        status: String = "等待下载"
    ) {
        self.videoCode = videoCode
        self.title = title
        self.coverURLString = coverURLString
        self.quality = quality
        self.mediaURLString = mediaURLString
        self.downloadGroupName = "默认分组"
        self.createdAt = createdAt
        self.status = status
        self.localFileURLString = nil
        self.errorMessage = nil
        self.completedAt = nil
        self.progress = 0
        self.retryCount = 0
        self.backgroundSessionIdentifier = nil
        self.backgroundTaskIdentifier = nil
        self.backgroundTaskStartedAt = nil
        self.backgroundTaskUpdatedAt = nil
        self.downloadedByteCount = nil
        self.expectedByteCount = nil
        self.completionNotificationSentAt = nil
        self.id = "\(videoCode)-\(quality)-\(mediaURLString)"
    }
}

// MARK: - Download Group

final class DownloadGroupRecordModel: Codable, Identifiable {
    var id: String { name }
    var name: String
    var createdAt: Date

    init(name: String, createdAt: Date = Date()) {
        self.name = name
        self.createdAt = createdAt
    }
}

// MARK: - JSON File Data Manager

final class JSONPersistenceManager: PersistenceDataManaging {
    static let shared = JSONPersistenceManager()
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    private let queue = DispatchQueue(label: "com.hana.persistence", qos: .utility)

    private var baseURL: URL {
        let url = try! fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return url.appendingPathComponent("HanaData", isDirectory: true)
    }

    private init() {
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    // MARK: - File Operations

    private func loadJSON<T: Codable>(_ type: T.Type, from file: String) -> T? {
        let url = baseURL.appendingPathComponent(file)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private func saveJSON<T: Codable>(_ value: T, to file: String) {
        let url = baseURL.appendingPathComponent(file)
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - PersistenceDataManaging

    func loadWatchHistory() -> [WatchHistoryRecordModel] {
        loadJSON([WatchHistoryRecordModel].self, from: "watchHistory.json") ?? []
    }

    func saveWatchHistory(_ records: [WatchHistoryRecordModel]) {
        saveJSON(records, to: "watchHistory.json")
    }

    func insertWatchHistory(_ record: WatchHistoryRecordModel) {
        var records = loadWatchHistory()
        records.removeAll { $0.videoCode == record.videoCode }
        records.append(record)
        saveWatchHistory(records)
    }

    func deleteWatchHistory(_ record: WatchHistoryRecordModel) {
        var records = loadWatchHistory()
        records.removeAll { $0.videoCode == record.videoCode }
        saveWatchHistory(records)
    }

    func loadSearchHistory() -> [SearchHistoryRecordModel] {
        loadJSON([SearchHistoryRecordModel].self, from: "searchHistory.json") ?? []
    }

    func insertSearchHistory(_ record: SearchHistoryRecordModel) {
        var records = loadSearchHistory()
        records.removeAll { $0.query == record.query }
        records.append(record)
        saveJSON(records, to: "searchHistory.json")
    }

    func deleteSearchHistory(_ record: SearchHistoryRecordModel) {
        var records = loadSearchHistory()
        records.removeAll { $0.query == record.query }
        saveJSON(records, to: "searchHistory.json")
    }

    func loadAdvancedSearchHistory() -> [AdvancedSearchHistoryRecordModel] {
        loadJSON([AdvancedSearchHistoryRecordModel].self, from: "advancedSearchHistory.json") ?? []
    }

    func insertAdvancedSearchHistory(_ record: AdvancedSearchHistoryRecordModel) {
        var records = loadAdvancedSearchHistory()
        records.removeAll { $0.criteriaKey == record.criteriaKey }
        records.append(record)
        saveJSON(records, to: "advancedSearchHistory.json")
    }

    func deleteAdvancedSearchHistory(_ record: AdvancedSearchHistoryRecordModel) {
        var records = loadAdvancedSearchHistory()
        records.removeAll { $0.criteriaKey == record.criteriaKey }
        saveJSON(records, to: "advancedSearchHistory.json")
    }

    func loadFavorites() -> [FavoriteVideoRecordModel] {
        loadJSON([FavoriteVideoRecordModel].self, from: "favorites.json") ?? []
    }

    func insertFavorite(_ record: FavoriteVideoRecordModel) {
        var records = loadFavorites()
        records.removeAll { $0.videoCode == record.videoCode }
        records.append(record)
        saveJSON(records, to: "favorites.json")
    }

    func deleteFavorite(_ record: FavoriteVideoRecordModel) {
        var records = loadFavorites()
        records.removeAll { $0.videoCode == record.videoCode }
        saveJSON(records, to: "favorites.json")
    }

    func loadWatchLater() -> [WatchLaterRecordModel] {
        loadJSON([WatchLaterRecordModel].self, from: "watchLater.json") ?? []
    }

    func insertWatchLater(_ record: WatchLaterRecordModel) {
        var records = loadWatchLater()
        records.removeAll { $0.videoCode == record.videoCode }
        records.append(record)
        saveJSON(records, to: "watchLater.json")
    }

    func deleteWatchLater(_ record: WatchLaterRecordModel) {
        var records = loadWatchLater()
        records.removeAll { $0.videoCode == record.videoCode }
        saveJSON(records, to: "watchLater.json")
    }

    func loadPlaylists() -> [PlaylistRecordModel] {
        loadJSON([PlaylistRecordModel].self, from: "playlists.json") ?? []
    }

    func insertPlaylist(_ record: PlaylistRecordModel) {
        var records = loadPlaylists()
        records.removeAll { $0.id == record.id }
        records.append(record)
        saveJSON(records, to: "playlists.json")
    }

    func deletePlaylist(_ record: PlaylistRecordModel) {
        var records = loadPlaylists()
        records.removeAll { $0.id == record.id }
        saveJSON(records, to: "playlists.json")
    }

    func loadPlaylistItems() -> [PlaylistItemRecordModel] {
        loadJSON([PlaylistItemRecordModel].self, from: "playlistItems.json") ?? []
    }

    func insertPlaylistItem(_ record: PlaylistItemRecordModel) {
        var records = loadPlaylistItems()
        records.removeAll { $0.id == record.id }
        records.append(record)
        saveJSON(records, to: "playlistItems.json")
    }

    func deletePlaylistItem(_ record: PlaylistItemRecordModel) {
        var records = loadPlaylistItems()
        records.removeAll { $0.id == record.id }
        saveJSON(records, to: "playlistItems.json")
    }

    func loadDownloadQueue() -> [DownloadQueueRecordModel] {
        loadJSON([DownloadQueueRecordModel].self, from: "downloadQueue.json") ?? []
    }

    func insertDownloadQueue(_ record: DownloadQueueRecordModel) {
        var records = loadDownloadQueue()
        records.removeAll { $0.id == record.id }
        records.append(record)
        saveJSON(records, to: "downloadQueue.json")
    }

    func deleteDownloadQueue(_ record: DownloadQueueRecordModel) {
        var records = loadDownloadQueue()
        records.removeAll { $0.id == record.id }
        saveJSON(records, to: "downloadQueue.json")
    }

    func loadDownloadGroups() -> [DownloadGroupRecordModel] {
        loadJSON([DownloadGroupRecordModel].self, from: "downloadGroups.json") ?? []
    }

    func insertDownloadGroup(_ record: DownloadGroupRecordModel) {
        var records = loadDownloadGroups()
        records.removeAll { $0.name == record.name }
        records.append(record)
        saveJSON(records, to: "downloadGroups.json")
    }

    func deleteDownloadGroup(_ record: DownloadGroupRecordModel) {
        var records = loadDownloadGroups()
        records.removeAll { $0.name == record.name }
        saveJSON(records, to: "downloadGroups.json")
    }

    func loadHKeyframeRecords() -> [HKeyframeRecordModel] {
        loadJSON([HKeyframeRecordModel].self, from: "hKeyframes.json") ?? []
    }

    func insertHKeyframeRecord(_ record: HKeyframeRecordModel) {
        var records = loadHKeyframeRecords()
        records.removeAll { $0.videoCode == record.videoCode }
        records.append(record)
        saveJSON(records, to: "hKeyframes.json")
    }

    func deleteHKeyframeRecord(_ record: HKeyframeRecordModel) {
        var records = loadHKeyframeRecords()
        records.removeAll { $0.videoCode == record.videoCode }
        saveJSON(records, to: "hKeyframes.json")
    }

    func save() {}
}
