import Foundation

struct FileSelectionItem: Identifiable, Hashable, Codable {
    let id: UUID
    var url: URL
    var isDirectory: Bool
    var sizeInBytes: Int64
    var itemCount: Int

    init(id: UUID = UUID(), url: URL, isDirectory: Bool, sizeInBytes: Int64, itemCount: Int) {
        self.id = id
        self.url = url
        self.isDirectory = isDirectory
        self.sizeInBytes = sizeInBytes
        self.itemCount = itemCount
    }
}

struct ActivityLogEntry: Identifiable, Hashable, Codable {
    enum Kind: String, Codable {
        case info
        case success
        case warning
        case failure
    }

    var id = UUID()
    var timestamp: Date
    var title: String
    var detail: String
    var kind: Kind
}

enum BackupTimeUnit: String, CaseIterable, Identifiable, Codable {
    case hours
    case days
    case weeks
    case months

    var id: String { rawValue }

    var label: String { rawValue.uppercased() }
}

struct GitHubBackupDraft: Codable, Hashable {
    var token: String = ""
    var owner: String = ""
    var repositoryName: String = ""
    var description: String = ""
    var baseBranch: String = "main"
    var timeframeValue: Int = 1
    var timeframeUnit: BackupTimeUnit = .weeks
    var makePrivate = true
}
