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

    var oauthGuideURL: URL? {
        switch self {
        case .local:
            nil
        case .googleDrive:
            URL(string: "https://developers.google.com/identity/protocols/oauth2")
        case .oneDrive:
            URL(string: "https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow")
        case .dropbox:
            URL(string: "https://developers.dropbox.com/oauth-guide")
        case .github:
            URL(string: "https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps")
        case .iCloud:
            URL(string: "https://support.apple.com/guide/mac-help/access-icloud-drive-files-on-mac-mchle5a61431/mac")
        }
    }

    var tokenPortalURL: URL? {
        switch self {
        case .local, .iCloud:
            nil
        case .googleDrive:
            URL(string: "https://developers.google.com/oauthplayground/")
        case .oneDrive:
            URL(string: "https://developer.microsoft.com/en-us/graph/graph-explorer")
        case .dropbox:
            URL(string: "https://www.dropbox.com/developers/apps")
        case .github:
            URL(string: "https://github.com/settings/tokens")
        }
    }

    var developerConsoleURL: URL? {
        switch self {
        case .local, .iCloud:
            nil
        case .googleDrive:
            URL(string: "https://console.cloud.google.com/apis/credentials")
        case .oneDrive:
            URL(string: "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade")
        case .dropbox:
            URL(string: "https://www.dropbox.com/developers/apps")
        case .github:
            URL(string: "https://github.com/settings/developers")
        }
    }

    var recommendedScopes: String {
        switch self {
        case .local:
            "macOS file access"
        case .googleDrive:
            "drive.readonly, drive.file"
        case .oneDrive:
            "Files.Read, Files.ReadWrite"
        case .dropbox:
            "files.metadata.read, files.content.read"
        case .github:
            "repo, read:user"
        case .iCloud:
            "Signed-in iCloud Drive access"
        }
    }

    var oauthInstructions: String {
        switch self {
        case .local:
            "Use the folder picker to choose local or external-drive paths."
        case .googleDrive:
            "Create OAuth credentials in Google Cloud, authorize Drive scopes, then paste the bearer token here or use OAuth Playground."
        case .oneDrive:
            "Register an app in Azure, grant Microsoft Graph file scopes, sign in, then paste the Graph bearer token."
        case .dropbox:
            "Create a Dropbox app, generate an access token or OAuth code, then paste the access token here."
        case .github:
            "Create a GitHub OAuth App or token with repo scope, then paste the token here for repo browsing and backups."
        case .iCloud:
            "iCloud Drive uses your signed-in Apple account on this Mac and does not need a pasted token."
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
    var previewURLString: String?
    var mimeType: String?
}

struct ProviderConnection: Identifiable, Hashable, Codable {
    let id: UUID
    var provider: CloudProvider
    var displayName: String
    var accountName: String
    var authToken: String
    var clientID: String
    var clientSecret: String
    var oauthRedirectURI: String
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
        clientID: String = "",
        clientSecret: String = "",
        oauthRedirectURI: String = "http://localhost",
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
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.oauthRedirectURI = oauthRedirectURI
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
