import Foundation

enum AppError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case let .message(message): message
        }
    }
}

struct CloudConnectionResult {
    var accountName: String
    var statusMessage: String
    var usedFraction: Double
    var quotaDescription: String
    var rootEntries: [CloudBrowserEntry]
}

enum CloudService {
    static func connect(_ connection: ProviderConnection) async throws -> CloudConnectionResult {
        switch connection.provider {
        case .local:
            let baseURL = URL(fileURLWithPath: connection.locationPath.isEmpty ? NSHomeDirectory() : connection.locationPath)
            let entries = FileSystemService.directoryContents(at: baseURL)
            return CloudConnectionResult(
                accountName: Host.current().localizedName ?? "This Mac",
                statusMessage: "Browsing \(baseURL.path)",
                usedFraction: localUsageFraction(for: baseURL),
                quotaDescription: "Local volume",
                rootEntries: entries
            )
        case .iCloud:
            guard let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
                throw AppError.message("iCloud Drive is not available for the current macOS account.")
            }
            let entries = FileSystemService.directoryContents(at: ubiquityURL)
            return CloudConnectionResult(
                accountName: "iCloud Drive",
                statusMessage: "Browsing \(ubiquityURL.path)",
                usedFraction: 0,
                quotaDescription: "Managed by Apple ID",
                rootEntries: entries
            )
        case .googleDrive:
            return try await connectGoogleDrive(connection)
        case .oneDrive:
            return try await connectOneDrive(connection)
        case .dropbox:
            return try await connectDropbox(connection)
        case .github:
            return try await connectGitHub(connection)
        }
    }

    static func browse(_ connection: ProviderConnection, path: String) async throws -> [CloudBrowserEntry] {
        switch connection.provider {
        case .local, .iCloud:
            let url = URL(fileURLWithPath: path)
            return FileSystemService.directoryContents(at: url)
        case .googleDrive:
            return try await browseGoogleDrive(connection, parentID: path)
        case .oneDrive:
            return try await browseOneDrive(connection, itemPath: path)
        case .dropbox:
            return try await browseDropbox(connection, path: path)
        case .github:
            return try await browseGitHub(connection, path: path)
        }
    }

    static func previewURL(for connection: ProviderConnection, entry: CloudBrowserEntry) async throws -> URL {
        switch connection.provider {
        case .local, .iCloud:
            return URL(fileURLWithPath: entry.path)
        case .github, .oneDrive:
            if let string = entry.previewURLString, let url = URL(string: string) {
                return url
            }
            throw AppError.message("Preview URL is unavailable for this item.")
        case .dropbox:
            if let string = entry.previewURLString, let url = URL(string: string) {
                return url
            }
            return try await dropboxTemporaryLink(token: connection.authToken, path: entry.path)
        case .googleDrive:
            throw AppError.message("Google Drive preview needs a signed download step and is not yet available in the viewer.")
        }
    }

    static func createGitHubRepositoryAndBackup(connection: ProviderConnection, draft: GitHubBackupDraft, items: [FileSelectionItem]) async throws -> String {
        let token = draft.token.isEmpty ? connection.authToken : draft.token
        guard !token.isEmpty else {
            throw AppError.message("Add a GitHub token with repo permissions before creating a repository.")
        }

        let createdRepo = try await createGitHubRepository(token: token, name: draft.repositoryName, description: draft.description, isPrivate: draft.makePrivate)
        let owner = createdRepo.ownerLogin
        let branchName = branchName(for: draft)
        let baseBranch = createdRepo.defaultBranch
        let baseSHA = try await githubReferenceSHA(token: token, owner: owner, repo: draft.repositoryName, branch: baseBranch)
        try await githubCreateBranch(token: token, owner: owner, repo: draft.repositoryName, branchName: branchName, fromSHA: baseSHA)

        for item in items {
            try await uploadToGitHubBackup(token: token, owner: owner, repo: draft.repositoryName, branch: branchName, item: item)
        }

        return "\(owner)/\(draft.repositoryName) @ \(branchName)"
    }

    private static func localUsageFraction(for url: URL) -> Double {
        guard let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]),
              let available = values.volumeAvailableCapacityForImportantUsage,
              let total = values.volumeTotalCapacity,
              total > 0 else {
            return 0
        }
        return Double(total - Int(available)) / Double(total)
    }

    private static func makeJSONRequest(url: URL, method: String = "GET", token: String? = nil, headers: [String: String] = [:], body: Data? = nil) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        if let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if body != nil, request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unexpected response"
            throw AppError.message(message)
        }
        return data
    }

    private static func connectGoogleDrive(_ connection: ProviderConnection) async throws -> CloudConnectionResult {
        guard !connection.authToken.isEmpty else {
            throw AppError.message("Add a Google Drive bearer token first.")
        }
        let aboutURL = URL(string: "https://www.googleapis.com/drive/v3/about?fields=user,storageQuota")!
        let data = try await makeJSONRequest(url: aboutURL, token: connection.authToken)
        let response = try JSONDecoder().decode(GoogleDriveAboutResponse.self, from: data)
        let entries = try await browseGoogleDrive(connection, parentID: "root")

        let used = Double(response.storageQuota.usage ?? "0") ?? 0
        let total = Double(response.storageQuota.limit ?? "0") ?? 0
        return CloudConnectionResult(
            accountName: response.user.displayName ?? response.user.emailAddress ?? "Google Drive",
            statusMessage: "Authenticated with Google Drive",
            usedFraction: total > 0 ? used / total : 0,
            quotaDescription: ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .file),
            rootEntries: entries
        )
    }

    private static func browseGoogleDrive(_ connection: ProviderConnection, parentID: String) async throws -> [CloudBrowserEntry] {
        let encodedParent = parentID == "root" ? "'root'+in+parents" : "'\(parentID)'+in+parents"
        let url = URL(string: "https://www.googleapis.com/drive/v3/files?q=\(encodedParent)&fields=files(id,name,mimeType,size,modifiedTime)")!
        let data = try await makeJSONRequest(url: url, token: connection.authToken)
        let response = try JSONDecoder().decode(GoogleDriveFilesResponse.self, from: data)
        return response.files.map {
            CloudBrowserEntry(
                name: $0.name,
                path: $0.id,
                isFolder: $0.mimeType == "application/vnd.google-apps.folder",
                sizeInBytes: Int64($0.size ?? "0"),
                modifiedDescription: $0.modifiedTime,
                previewURLString: nil,
                mimeType: $0.mimeType
            )
        }
    }

    private static func connectOneDrive(_ connection: ProviderConnection) async throws -> CloudConnectionResult {
        guard !connection.authToken.isEmpty else {
            throw AppError.message("Add a Microsoft Graph bearer token first.")
        }
        let driveURL = URL(string: "https://graph.microsoft.com/v1.0/me/drive")!
        let data = try await makeJSONRequest(url: driveURL, token: connection.authToken)
        let response = try JSONDecoder().decode(OneDriveDriveResponse.self, from: data)
        let entries = try await browseOneDrive(connection, itemPath: "root")
        return CloudConnectionResult(
            accountName: response.owner.user.displayName ?? "OneDrive",
            statusMessage: "Authenticated with Microsoft Graph",
            usedFraction: response.quota.total > 0 ? Double(response.quota.used) / Double(response.quota.total) : 0,
            quotaDescription: ByteCountFormatter.string(fromByteCount: response.quota.total, countStyle: .file),
            rootEntries: entries
        )
    }

    private static func browseOneDrive(_ connection: ProviderConnection, itemPath: String) async throws -> [CloudBrowserEntry] {
        let endpoint = itemPath == "root"
            ? "https://graph.microsoft.com/v1.0/me/drive/root/children"
            : "https://graph.microsoft.com/v1.0/me/drive/items/\(itemPath)/children"
        let data = try await makeJSONRequest(url: URL(string: endpoint)!, token: connection.authToken)
        let response = try JSONDecoder().decode(OneDriveChildrenResponse.self, from: data)
        return response.value.map {
            CloudBrowserEntry(
                name: $0.name,
                path: $0.id,
                isFolder: $0.folder != nil,
                sizeInBytes: $0.size,
                modifiedDescription: $0.lastModifiedDateTime,
                previewURLString: $0.downloadURL,
                mimeType: nil
            )
        }
    }

    private static func connectDropbox(_ connection: ProviderConnection) async throws -> CloudConnectionResult {
        guard !connection.authToken.isEmpty else {
            throw AppError.message("Add a Dropbox token first.")
        }
        let accountURL = URL(string: "https://api.dropboxapi.com/2/users/get_current_account")!
        let accountData = try await makeJSONRequest(url: accountURL, method: "POST", token: connection.authToken, body: Data("{}".utf8))
        let account = try JSONDecoder().decode(DropboxAccountResponse.self, from: accountData)
        let entries = try await browseDropbox(connection, path: "")
        return CloudConnectionResult(
            accountName: account.name.displayName,
            statusMessage: "Authenticated with Dropbox",
            usedFraction: 0,
            quotaDescription: "Dropbox account",
            rootEntries: entries
        )
    }

    private static func browseDropbox(_ connection: ProviderConnection, path: String) async throws -> [CloudBrowserEntry] {
        let url = URL(string: "https://api.dropboxapi.com/2/files/list_folder")!
        let body = try JSONEncoder().encode(DropboxListFolderRequest(path: path, recursive: false))
        let data = try await makeJSONRequest(url: url, method: "POST", token: connection.authToken, body: body)
        let response = try JSONDecoder().decode(DropboxFolderResponse.self, from: data)
        return response.entries.map {
            CloudBrowserEntry(
                name: $0.name,
                path: $0.pathDisplay ?? "",
                isFolder: $0.tag == "folder",
                sizeInBytes: $0.size,
                modifiedDescription: $0.serverModified,
                previewURLString: nil,
                mimeType: nil
            )
        }
    }

    private static func connectGitHub(_ connection: ProviderConnection) async throws -> CloudConnectionResult {
        guard !connection.authToken.isEmpty else {
            throw AppError.message("Add a GitHub token first.")
        }
        let userURL = URL(string: "https://api.github.com/user")!
        let data = try await makeJSONRequest(url: userURL, token: connection.authToken, headers: ["Accept": "application/vnd.github+json"])
        let user = try JSONDecoder().decode(GitHubUserResponse.self, from: data)
        let entries: [CloudBrowserEntry]
        if !connection.repoOwner.isEmpty, !connection.repoName.isEmpty {
            entries = try await browseGitHub(connection, path: "")
        } else {
            let reposURL = URL(string: "https://api.github.com/user/repos?per_page=100&sort=updated")!
            let repoData = try await makeJSONRequest(url: reposURL, token: connection.authToken, headers: ["Accept": "application/vnd.github+json"])
            let repos = try JSONDecoder().decode([GitHubRepositoryResponse].self, from: repoData)
            entries = repos.map {
                CloudBrowserEntry(
                    name: $0.fullName,
                    path: $0.name,
                    isFolder: true,
                    sizeInBytes: Int64($0.size * 1024),
                    modifiedDescription: $0.updatedAt
                )
            }
        }

        return CloudConnectionResult(
            accountName: user.login,
            statusMessage: "Authenticated with GitHub",
            usedFraction: 0,
            quotaDescription: "Repository API",
            rootEntries: entries
        )
    }

    private static func browseGitHub(_ connection: ProviderConnection, path: String) async throws -> [CloudBrowserEntry] {
        guard !connection.repoOwner.isEmpty, !connection.repoName.isEmpty else {
            throw AppError.message("Add both repository owner and repository name to browse GitHub files.")
        }
        let pathComponent = path.isEmpty ? "" : "/\(path)"
        let url = URL(string: "https://api.github.com/repos/\(connection.repoOwner)/\(connection.repoName)/contents\(pathComponent)")!
        let data = try await makeJSONRequest(url: url, token: connection.authToken, headers: ["Accept": "application/vnd.github+json"])
        if let entries = try? JSONDecoder().decode([GitHubContentEntry].self, from: data) {
            return entries.map {
                CloudBrowserEntry(name: $0.name, path: $0.path, isFolder: $0.type == "dir", sizeInBytes: Int64($0.size), modifiedDescription: nil, previewURLString: $0.downloadURL, mimeType: nil)
            }
        }

        let single = try JSONDecoder().decode(GitHubContentEntry.self, from: data)
        return [CloudBrowserEntry(name: single.name, path: single.path, isFolder: single.type == "dir", sizeInBytes: Int64(single.size), modifiedDescription: nil, previewURLString: single.downloadURL, mimeType: nil)]
    }

    private static func createGitHubRepository(token: String, name: String, description: String, isPrivate: Bool) async throws -> GitHubCreatedRepository {
        guard !name.isEmpty else {
            throw AppError.message("Add a repository name before creating a GitHub backup target.")
        }
        let url = URL(string: "https://api.github.com/user/repos")!
        let payload = GitHubCreateRepositoryRequest(name: name, description: description, isPrivate: isPrivate, autoInit: true)
        let data = try JSONEncoder().encode(payload)
        let responseData = try await makeJSONRequest(url: url, method: "POST", token: token, headers: ["Accept": "application/vnd.github+json"], body: data)
        let response = try JSONDecoder().decode(GitHubCreatedRepository.self, from: responseData)
        return response
    }

    private static func githubReferenceSHA(token: String, owner: String, repo: String, branch: String) async throws -> String {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/git/ref/heads/\(branch)")!
        let data = try await makeJSONRequest(url: url, token: token, headers: ["Accept": "application/vnd.github+json"])
        let response = try JSONDecoder().decode(GitHubRefResponse.self, from: data)
        return response.object.sha
    }

    private static func githubCreateBranch(token: String, owner: String, repo: String, branchName: String, fromSHA: String) async throws {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/git/refs")!
        let payload = GitHubCreateRefRequest(ref: "refs/heads/\(branchName)", sha: fromSHA)
        let data = try JSONEncoder().encode(payload)
        _ = try await makeJSONRequest(url: url, method: "POST", token: token, headers: ["Accept": "application/vnd.github+json"], body: data)
    }

    private static func uploadToGitHubBackup(token: String, owner: String, repo: String, branch: String, item: FileSelectionItem) async throws {
        if item.isDirectory {
            let enumerator = FileManager.default.enumerator(at: item.url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
            while let fileURL = enumerator?.nextObject() as? URL {
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                if values.isRegularFile == true {
                    let relativePath = fileURL.path.replacingOccurrences(of: item.url.deletingLastPathComponent().path + "/", with: "")
                    try await uploadGitHubFile(token: token, owner: owner, repo: repo, branch: branch, fileURL: fileURL, remotePath: relativePath)
                }
            }
        } else {
            try await uploadGitHubFile(token: token, owner: owner, repo: repo, branch: branch, fileURL: item.url, remotePath: item.url.lastPathComponent)
        }
    }

    private static func uploadGitHubFile(token: String, owner: String, repo: String, branch: String, fileURL: URL, remotePath: String) async throws {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/contents/\(remotePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? remotePath)")!
        let fileData = try Data(contentsOf: fileURL)
        let payload = GitHubUploadRequest(message: "Backup \(remotePath)", content: fileData.base64EncodedString(), branch: branch)
        let body = try JSONEncoder().encode(payload)
        _ = try await makeJSONRequest(url: url, method: "PUT", token: token, headers: ["Accept": "application/vnd.github+json"], body: body)
    }

    private static func branchName(for draft: GitHubBackupDraft) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return "backup/\(draft.timeframeValue)-\(draft.timeframeUnit.rawValue)-\(formatter.string(from: Date()))"
    }

    private static func dropboxTemporaryLink(token: String, path: String) async throws -> URL {
        let url = URL(string: "https://api.dropboxapi.com/2/files/get_temporary_link")!
        let body = try JSONEncoder().encode(DropboxTemporaryLinkRequest(path: path))
        let data = try await makeJSONRequest(url: url, method: "POST", token: token, body: body)
        let response = try JSONDecoder().decode(DropboxTemporaryLinkResponse.self, from: data)
        guard let result = URL(string: response.link) else {
            throw AppError.message("Dropbox did not return a usable temporary link.")
        }
        return result
    }
}

private struct GoogleDriveAboutResponse: Decodable {
    struct User: Decodable {
        var displayName: String?
        var emailAddress: String?
    }
    struct StorageQuota: Decodable {
        var limit: String?
        var usage: String?
    }
    var user: User
    var storageQuota: StorageQuota
}

private struct GoogleDriveFilesResponse: Decodable {
    struct File: Decodable {
        var id: String
        var name: String
        var mimeType: String
        var size: String?
        var modifiedTime: String?
    }
    var files: [File]
}

private struct OneDriveDriveResponse: Decodable {
    struct Owner: Decodable {
        struct User: Decodable { var displayName: String? }
        var user: User
    }
    struct Quota: Decodable {
        var total: Int64
        var used: Int64
    }
    var owner: Owner
    var quota: Quota
}

private struct OneDriveChildrenResponse: Decodable {
    struct Entry: Decodable {
        struct Folder: Decodable {}
        var id: String
        var name: String
        var size: Int64
        var lastModifiedDateTime: String?
        var folder: Folder?
        var downloadURL: String?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case size
            case lastModifiedDateTime
            case folder
            case downloadURL = "@microsoft.graph.downloadUrl"
        }
    }
    var value: [Entry]
}

private struct DropboxAccountResponse: Decodable {
    struct Name: Decodable { var displayName: String }
    var name: Name
}

private struct DropboxFolderResponse: Decodable {
    struct Entry: Decodable {
        enum CodingKeys: String, CodingKey {
            case tag = ".tag"
            case name
            case pathDisplay = "path_display"
            case size
            case serverModified = "server_modified"
        }
        var tag: String
        var name: String
        var pathDisplay: String?
        var size: Int64?
        var serverModified: String?
    }
    var entries: [Entry]
}

private struct GitHubUserResponse: Decodable {
    var login: String
}

private struct GitHubRepositoryResponse: Decodable {
    var name: String
    var fullName: String
    var size: Int
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case name
        case fullName = "full_name"
        case size
        case updatedAt = "updated_at"
    }
}

private struct GitHubContentEntry: Decodable {
    var name: String
    var path: String
    var type: String
    var size: Int
    var downloadURL: String?

    enum CodingKeys: String, CodingKey {
        case name
        case path
        case type
        case size
        case downloadURL = "download_url"
    }
}

private struct GitHubCreateRepositoryRequest: Encodable {
    var name: String
    var description: String
    var isPrivate: Bool
    var autoInit: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case isPrivate = "private"
        case autoInit = "auto_init"
    }
}

private struct GitHubCreatedRepository: Decodable {
    struct Owner: Decodable { var login: String }
    var owner: Owner
    var defaultBranch: String

    var ownerLogin: String { owner.login }

    enum CodingKeys: String, CodingKey {
        case owner
        case defaultBranch = "default_branch"
    }
}

private struct GitHubRefResponse: Decodable {
    struct Object: Decodable { var sha: String }
    var object: Object
}

private struct GitHubCreateRefRequest: Encodable {
    var ref: String
    var sha: String
}

private struct GitHubUploadRequest: Encodable {
    var message: String
    var content: String
    var branch: String
}

private struct DropboxListFolderRequest: Encodable {
    var path: String
    var recursive: Bool
}

private struct DropboxTemporaryLinkRequest: Encodable {
    var path: String
}

private struct DropboxTemporaryLinkResponse: Decodable {
    var link: String
}
