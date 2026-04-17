import Foundation

enum CloudProvider: String, CaseIterable, Identifiable, Codable {
    case local
    case googleDrive
    case oneDrive
    case dropbox
    case github
    case iCloud

    var id: String { rawValue }

    var title: String {
        switch self {
        case .local: "Local"
        case .googleDrive: "Google Drive"
        case .oneDrive: "OneDrive"
        case .dropbox: "Dropbox"
        case .github: "GitHub"
        case .iCloud: "iCloud"
        }
    }

    var shortCode: String {
        switch self {
        case .local: "LOC"
        case .googleDrive: "GDR"
        case .oneDrive: "ODR"
        case .dropbox: "DBX"
        case .github: "GIT"
        case .iCloud: "ICL"
        }
    }

    var usesTokenAuthentication: Bool {
        switch self {
        case .local, .iCloud:
            false
        case .googleDrive, .oneDrive, .dropbox, .github:
            true
        }
    }

    var supportsRemoteBrowser: Bool {
        switch self {
        case .local, .iCloud, .googleDrive, .oneDrive, .dropbox, .github:
            true
        }
    }

    var defaultStatusMessage: String {
        switch self {
        case .local: "Pick folders on this Mac or external volumes."
        case .googleDrive: "Paste an OAuth bearer token to browse Drive files."
        case .oneDrive: "Paste a Microsoft Graph bearer token to browse files."
        case .dropbox: "Paste a Dropbox token to browse folders."
        case .github: "Paste a GitHub token to browse repos and create backups."
        case .iCloud: "Uses your signed-in iCloud Drive container on this Mac."
        }
    }
}

enum ConnectionHealth: String, CaseIterable, Codable {
    case online
    case degraded
    case offline

    var label: String { rawValue.uppercased() }
}

struct CloudBrowserEntry: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var path: String
    var isFolder: Bool
    var sizeInBytes: Int64?
    var modifiedDescription: String?
}

struct ProviderConnection: Identifiable, Hashable, Codable {
    let id: UUID
    var provider: CloudProvider
    var displayName: String
    var accountName: String
    var authToken: String
    var locationPath: String
    var selectedRemotePath: String
    var repoOwner: String
    var repoName: String
    var statusMessage: String
    var quotaDescription: String
    var health: ConnectionHealth
    var usedCapacity: Double
    var lastSyncDescription: String
    var browserEntries: [CloudBrowserEntry]

    init(
        id: UUID = UUID(),
        provider: CloudProvider,
        displayName: String? = nil,
        accountName: String = "",
        authToken: String = "",
        locationPath: String = "",
        selectedRemotePath: String = "",
        repoOwner: String = "",
        repoName: String = "",
        statusMessage: String? = nil,
        quotaDescription: String = "N/A",
        health: ConnectionHealth = .offline,
        usedCapacity: Double = 0,
        lastSyncDescription: String = "Never",
        browserEntries: [CloudBrowserEntry] = []
    ) {
        self.id = id
        self.provider = provider
        self.displayName = displayName ?? provider.title
        self.accountName = accountName
        self.authToken = authToken
        self.locationPath = locationPath
        self.selectedRemotePath = selectedRemotePath
        self.repoOwner = repoOwner
        self.repoName = repoName
        self.statusMessage = statusMessage ?? provider.defaultStatusMessage
        self.quotaDescription = quotaDescription
        self.health = health
        self.usedCapacity = usedCapacity
        self.lastSyncDescription = lastSyncDescription
        self.browserEntries = browserEntries
    }
}
