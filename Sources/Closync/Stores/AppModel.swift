import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    var palette: RetroPalette = .phosphorGreen
    var scanlinesEnabled = true
    var progressPanelVisible = true
    var hoverAnimationsEnabled = true
    var sharpCornersEnabled = false
    var selectedTab: NavigationTab = .dashboard

    var nodes: [FlowNode] = []
    var edges: [FlowEdge] = []
    var connections: [ProviderConnection] = []
    var automations: [AutomationRule] = []
    var recentOperations: [OperationSnapshot] = []
    var selectedItems: [FileSelectionItem] = []
    var selectedConnectionID: UUID?
    var destinationFolderURL: URL?
    var currentOperation: String = "Idle"
    var currentProgress: Double = 0
    var statusMessage: String = "Ready"
    var isBusy = false
    var logs: [ActivityLogEntry] = []
    var githubBackupDraft = GitHubBackupDraft()
    var showingGitHubBackupSheet = false
    var selectedLocalItemID: UUID?
    var selectedBrowserEntryID: UUID?
    var mediaPreview: MediaPreviewItem?
    var editingNodeID: UUID?
    var newNodeDraft = FlowNodeDraft()
    var showingNewNodeComposer = false

    var selectedConnection: ProviderConnection? {
        get { connections.first(where: { $0.id == selectedConnectionID }) }
        set {
            guard let newValue, let index = connections.firstIndex(where: { $0.id == newValue.id }) else { return }
            connections[index] = newValue
        }
    }

    var totalSelectedBytes: Int64 {
        selectedItems.reduce(0) { $0 + $1.sizeInBytes }
    }

    var totalSelectedEntries: Int {
        selectedItems.reduce(0) { $0 + max($1.itemCount, 1) }
    }

    var connectedProvidersCount: Int {
        connections.filter { $0.health == .online }.count
    }

    var recentSuccessfulActions: Int {
        logs.filter { $0.kind == .success }.count
    }

    var selectedLocalItem: FileSelectionItem? {
        selectedItems.first(where: { $0.id == selectedLocalItemID })
    }

    func configureInitialState(
        palette: RetroPalette,
        scanlinesEnabled: Bool,
        progressPanelVisible: Bool,
        hoverAnimationsEnabled: Bool,
        sharpCornersEnabled: Bool
    ) {
        guard connections.isEmpty else { return }

        self.palette = palette
        self.scanlinesEnabled = scanlinesEnabled
        self.progressPanelVisible = progressPanelVisible
        self.hoverAnimationsEnabled = hoverAnimationsEnabled
        self.sharpCornersEnabled = sharpCornersEnabled

        configureConnections()
        configureAutomations()
        configureFlow()
        refreshLocalRoots()
        addLog(title: "Closync Ready", detail: "Waiting for file selections and provider credentials.", kind: .info)
    }

    func configureConnections() {
        connections = [
            ProviderConnection(provider: .local, displayName: "Local Volumes", locationPath: NSHomeDirectory()),
            ProviderConnection(provider: .googleDrive),
            ProviderConnection(provider: .oneDrive),
            ProviderConnection(provider: .dropbox),
            ProviderConnection(provider: .github),
            ProviderConnection(provider: .iCloud)
        ]
        selectedConnectionID = connections.first?.id
    }

    func configureAutomations() {
        automations = [
            AutomationRule(name: "GitHub backup branch", trigger: "Manual or scheduled", behavior: "Create a dated branch and upload selected files", enabled: true, cadence: "CUSTOM"),
            AutomationRule(name: "Local archive copy", trigger: "On demand", behavior: "Copy selected files to a chosen destination folder", enabled: true, cadence: "MANUAL")
        ]
    }

    func configureFlow() {
        let source = UUID()
        let core = UUID()
        let target = UUID()

        nodes = [
            FlowNode(id: source, title: "SOURCE SET", subtitle: "No files selected", kind: .source, position: CGPoint(x: 0.16, y: 0.32), progress: 0),
            FlowNode(id: core, title: "ACTION CORE", subtitle: "Copy / Move / Delete / Backup", kind: .transform, position: CGPoint(x: 0.46, y: 0.45), progress: 0),
            FlowNode(id: target, title: "TARGET", subtitle: "Destination pending", kind: .destination, position: CGPoint(x: 0.78, y: 0.30), progress: 0)
        ]

        edges = [
            FlowEdge(from: source, to: core, label: "SELECT", traffic: 0),
            FlowEdge(from: core, to: target, label: "ROUTE", traffic: 0)
        ]
    }

    func refreshLocalRoots() {
        guard let localIndex = connections.firstIndex(where: { $0.provider == .local }) else { return }
        let localPath = connections[localIndex].locationPath.isEmpty ? NSHomeDirectory() : connections[localIndex].locationPath
        let localURL = URL(fileURLWithPath: localPath)
        connections[localIndex].browserEntries = FileSystemService.directoryContents(at: localURL)
        connections[localIndex].health = .online
        connections[localIndex].accountName = Host.current().localizedName ?? "This Mac"
        connections[localIndex].statusMessage = "Browsing \(localPath)"
        connections[localIndex].lastSyncDescription = RelativeDateTimeFormatter().localizedString(for: Date(), relativeTo: Date())

        if let iCloudIndex = connections.firstIndex(where: { $0.provider == .iCloud }),
           let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            connections[iCloudIndex].browserEntries = FileSystemService.directoryContents(at: iCloudURL)
            connections[iCloudIndex].health = .online
            connections[iCloudIndex].locationPath = iCloudURL.path
            connections[iCloudIndex].accountName = "iCloud Drive"
            connections[iCloudIndex].statusMessage = "Browsing \(iCloudURL.path)"
            connections[iCloudIndex].lastSyncDescription = RelativeDateTimeFormatter().localizedString(for: Date(), relativeTo: Date())
        }
        updateFlowMetrics()
    }

    func updateFlowMetrics() {
        let selectedCount = max(totalSelectedEntries, 0)
        let sourceProgress = selectedCount == 0 ? 0 : min(1, Double(selectedCount) / 100)
        let targetProgress: Double = destinationFolderURL == nil && (selectedConnection?.selectedRemotePath.isEmpty ?? true) ? 0 : 1
        let routeProgress = currentProgress

        if nodes.indices.contains(0) {
            nodes[0].subtitle = selectedItems.isEmpty ? "No files selected" : "\(selectedItems.count) roots / \(totalSelectedEntries) items"
            nodes[0].progress = sourceProgress
        }
        if nodes.indices.contains(1) {
            nodes[1].subtitle = currentOperation
            nodes[1].progress = routeProgress
        }
        if nodes.indices.contains(2) {
            nodes[2].subtitle = destinationFolderURL?.path ?? selectedConnection?.selectedRemotePath ?? "Destination pending"
            nodes[2].progress = targetProgress
        }
        if edges.indices.contains(0) {
            edges[0].traffic = sourceProgress
        }
        if edges.indices.contains(1) {
            edges[1].traffic = routeProgress
        }
    }

    func addLog(title: String, detail: String, kind: ActivityLogEntry.Kind) {
        logs.insert(ActivityLogEntry(timestamp: Date(), title: title, detail: detail, kind: kind), at: 0)
        logs = Array(logs.prefix(40))
        statusMessage = detail
    }

    func addItems(urls: [URL]) {
        guard !urls.isEmpty else { return }
        let items = urls.map(FileSystemService.metadata(for:))
        for item in items where !selectedItems.contains(where: { $0.url == item.url }) {
            selectedItems.append(item)
        }
        selectedTab = .files
        recentOperations.insert(OperationSnapshot(name: "Selection Updated", detail: "\(selectedItems.count) roots selected", state: "READY", progress: 1), at: 0)
        recentOperations = Array(recentOperations.prefix(8))
        addLog(title: "Items Added", detail: "\(items.count) path(s) selected for management.", kind: .success)
        updateFlowMetrics()
    }

    func clearSelections() {
        selectedItems.removeAll()
        selectedLocalItemID = nil
        mediaPreview = nil
        currentProgress = 0
        currentOperation = "Idle"
        addLog(title: "Selection Cleared", detail: "No files or folders are selected.", kind: .info)
        updateFlowMetrics()
    }

    func chooseFilesAndFolders() {
        addItems(urls: NativePanelService.chooseFilesAndFolders())
    }

    func chooseFoldersOnly() {
        addItems(urls: NativePanelService.chooseFolders())
    }

    func chooseDestinationFolder() {
        destinationFolderURL = NativePanelService.chooseDestinationFolder()
        if let destinationFolderURL {
            addLog(title: "Destination Selected", detail: destinationFolderURL.path, kind: .success)
        }
        updateFlowMetrics()
    }

    func removeItem(_ item: FileSelectionItem) {
        selectedItems.removeAll { $0.id == item.id }
        if selectedLocalItemID == item.id {
            selectedLocalItemID = nil
            mediaPreview = nil
        }
        updateFlowMetrics()
    }

    func selectLocalItem(_ item: FileSelectionItem) {
        selectedLocalItemID = item.id
        prepareLocalPreview(for: item)
    }

    func performLocalAction(_ action: FileOperationKind) async {
        guard !selectedItems.isEmpty else {
            addLog(title: "No Selection", detail: "Select files or folders before running an action.", kind: .warning)
            return
        }

        isBusy = true
        currentOperation = action.title
        currentProgress = 0.15
        updateFlowMetrics()

        do {
            try FileSystemService.perform(action, items: selectedItems, destination: destinationFolderURL)
            currentProgress = 1
            recentOperations.insert(
                OperationSnapshot(
                    name: action.title,
                    detail: "\(selectedItems.count) root item(s)",
                    state: "COMPLETE",
                    progress: 1
                ),
                at: 0
            )
            recentOperations = Array(recentOperations.prefix(8))
            addLog(title: "\(action.title) Complete", detail: "Processed \(selectedItems.count) selection(s).", kind: .success)

            if action == .move || action == .delete {
                selectedItems.removeAll()
            }
        } catch {
            currentProgress = 0
            addLog(title: "\(action.title) Failed", detail: error.localizedDescription, kind: .failure)
        }

        isBusy = false
        updateFlowMetrics()
        refreshLocalRoots()
    }

    func selectConnection(_ connectionID: UUID) {
        selectedConnectionID = connectionID
    }

    func updateConnection(_ connection: ProviderConnection) {
        guard let index = connections.firstIndex(where: { $0.id == connection.id }) else { return }
        connections[index] = connection
    }

    func refreshSelectedConnection() async {
        guard let connection = selectedConnection else { return }
        isBusy = true
        currentOperation = "CONNECT \(connection.provider.shortCode)"
        currentProgress = 0.2
        updateFlowMetrics()

        do {
            let result = try await CloudService.connect(connection)
            guard let index = connections.firstIndex(where: { $0.id == connection.id }) else { return }
            connections[index].accountName = result.accountName
            connections[index].statusMessage = result.statusMessage
            connections[index].usedCapacity = result.usedFraction
            connections[index].quotaDescription = result.quotaDescription
            connections[index].browserEntries = result.rootEntries
            connections[index].health = .online
            connections[index].lastSyncDescription = RelativeDateTimeFormatter().localizedString(for: Date(), relativeTo: Date())
            currentProgress = 1
            addLog(title: "Connection Ready", detail: "\(connections[index].displayName) authenticated and refreshed.", kind: .success)
        } catch {
            if let index = connections.firstIndex(where: { $0.id == connection.id }) {
                connections[index].health = .degraded
                connections[index].statusMessage = error.localizedDescription
            }
            currentProgress = 0
            addLog(title: "Connection Failed", detail: error.localizedDescription, kind: .failure)
        }

        isBusy = false
        updateFlowMetrics()
    }

    func browseSelectedConnection(path: String) async {
        guard let connection = selectedConnection else { return }
        isBusy = true
        currentOperation = "BROWSE \(connection.provider.shortCode)"
        currentProgress = 0.2
        updateFlowMetrics()

        do {
            let entries = try await CloudService.browse(connection, path: path)
            guard let index = connections.firstIndex(where: { $0.id == connection.id }) else { return }
            connections[index].selectedRemotePath = path
            connections[index].browserEntries = entries
            connections[index].health = .online
            connections[index].lastSyncDescription = RelativeDateTimeFormatter().localizedString(for: Date(), relativeTo: Date())
            currentProgress = 1
            addLog(title: "Remote Browser Updated", detail: path.isEmpty ? "Loaded provider root." : "Opened \(path).", kind: .success)
        } catch {
            currentProgress = 0
            addLog(title: "Browse Failed", detail: error.localizedDescription, kind: .failure)
        }

        isBusy = false
        updateFlowMetrics()
    }

    func prepareRemotePreview(for entry: CloudBrowserEntry) async {
        guard let connection = selectedConnection, !entry.isFolder else { return }
        selectedBrowserEntryID = entry.id
        do {
            let previewURL = try await CloudService.previewURL(for: connection, entry: entry)
            guard let kind = mediaKind(for: entry.name, mimeType: entry.mimeType) else {
                addLog(title: "Preview Unsupported", detail: "Preview is available only for images and videos.", kind: .warning)
                return
            }
            mediaPreview = MediaPreviewItem(title: entry.name, sourceURL: previewURL, kind: kind, providerName: connection.displayName)
            selectedTab = .files
            addLog(title: "Preview Ready", detail: "Loaded \(entry.name) from \(connection.displayName).", kind: .success)
        } catch {
            addLog(title: "Preview Failed", detail: error.localizedDescription, kind: .failure)
        }
    }

    func createGitHubBackupRepository() async {
        guard !selectedItems.isEmpty else {
            addLog(title: "No Selection", detail: "Select files or folders before creating a GitHub backup.", kind: .warning)
            return
        }

        isBusy = true
        currentOperation = "GITHUB BACKUP"
        currentProgress = 0.18
        updateFlowMetrics()

        do {
            guard let githubConnection = connections.first(where: { $0.provider == .github }) else {
                throw AppError.message("GitHub connection is not available.")
            }

            let result = try await CloudService.createGitHubRepositoryAndBackup(connection: githubConnection, draft: githubBackupDraft, items: selectedItems)
            currentProgress = 1
            showingGitHubBackupSheet = false
            addLog(title: "Backup Branch Created", detail: result, kind: .success)
            recentOperations.insert(OperationSnapshot(name: "GitHub Backup", detail: result, state: "COMPLETE", progress: 1), at: 0)
            recentOperations = Array(recentOperations.prefix(8))

            if let githubIndex = connections.firstIndex(where: { $0.provider == .github }) {
                connections[githubIndex].repoOwner = githubBackupDraft.owner.isEmpty ? connections[githubIndex].accountName : githubBackupDraft.owner
                connections[githubIndex].repoName = githubBackupDraft.repositoryName
                connections[githubIndex].health = .online
            }
        } catch {
            currentProgress = 0
            addLog(title: "GitHub Backup Failed", detail: error.localizedDescription, kind: .failure)
        }

        isBusy = false
        updateFlowMetrics()
    }

    func updateNodePosition(id: UUID, normalizedPosition: CGPoint) {
        guard let index = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[index].position = CGPoint(
            x: min(max(normalizedPosition.x, 0.08), 0.92),
            y: min(max(normalizedPosition.y, 0.12), 0.88)
        )
    }

    func openNodeInspector(_ nodeID: UUID) {
        editingNodeID = nodeID
        showingNewNodeComposer = false
    }

    func updateNode(
        id: UUID,
        title: String,
        subtitle: String,
        kind: FlowNode.NodeKind
    ) {
        guard let index = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[index].title = title
        nodes[index].subtitle = subtitle
        nodes[index].kind = kind
    }

    func presentNewNodeComposer() {
        showingNewNodeComposer = true
        editingNodeID = nil
        newNodeDraft = FlowNodeDraft()
        newNodeDraft.sourceNodeID = nodes.first?.id
    }

    func addNodeFromDraft() {
        let newNode = FlowNode(
            id: UUID(),
            title: newNodeDraft.title.uppercased(),
            subtitle: newNodeDraft.subtitle,
            kind: newNodeDraft.kind,
            position: CGPoint(x: 0.52, y: 0.58),
            progress: 0
        )
        nodes.append(newNode)

        if let sourceID = newNodeDraft.sourceNodeID {
            edges.append(FlowEdge(from: sourceID, to: newNode.id, label: "LINK", traffic: 0))
        }
        if let targetID = newNodeDraft.targetNodeID {
            edges.append(FlowEdge(from: newNode.id, to: targetID, label: "LINK", traffic: 0))
        }

        addLog(title: "Route Node Added", detail: "Created \(newNode.title).", kind: .success)
        openNodeInspector(newNode.id)
        showingNewNodeComposer = false
    }

    func presetActions(for node: FlowNode) -> [NodeActionPreset] {
        switch node.kind {
        case .source:
            [
                NodeActionPreset(title: "SOURCE SET", subtitle: selectedItems.isEmpty ? "No files selected" : "\(selectedItems.count) root items", kind: .source),
                NodeActionPreset(title: "CLOUD SRC", subtitle: selectedConnection?.displayName ?? "Choose provider", kind: .source)
            ]
        case .transform:
            [
                NodeActionPreset(title: "ACTION CORE", subtitle: "Copy / Move / Delete / Backup", kind: .transform),
                NodeActionPreset(title: "MEDIA VIEW", subtitle: "Preview images and video streams", kind: .transform)
            ]
        case .destination, .cleanup:
            [
                NodeActionPreset(title: "TARGET", subtitle: destinationFolderURL?.path ?? "Choose destination", kind: .destination),
                NodeActionPreset(title: "ARCHIVE", subtitle: "Remote repository or folder", kind: .destination)
            ]
        }
    }

    func applyPreset(_ preset: NodeActionPreset, to nodeID: UUID) {
        updateNode(id: nodeID, title: preset.title, subtitle: preset.subtitle, kind: preset.kind)
        addLog(title: "Node Updated", detail: "\(preset.title) preset applied.", kind: .success)
    }

    private func prepareLocalPreview(for item: FileSelectionItem) {
        guard !item.isDirectory, let kind = mediaKind(for: item.url.lastPathComponent, mimeType: nil) else {
            mediaPreview = nil
            return
        }
        mediaPreview = MediaPreviewItem(title: item.url.lastPathComponent, sourceURL: item.url, kind: kind, providerName: "Local")
    }

    private func mediaKind(for fileName: String, mimeType: String?) -> MediaKind? {
        let lower = fileName.lowercased()
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "webp", "heic", "tif", "tiff", "bmp"]
        let videoExtensions = ["mov", "mp4", "m4v", "avi", "mkv", "webm"]

        if imageExtensions.contains(where: { lower.hasSuffix(".\($0)") }) || (mimeType?.hasPrefix("image/") ?? false) {
            return .image
        }
        if videoExtensions.contains(where: { lower.hasSuffix(".\($0)") }) || (mimeType?.hasPrefix("video/") ?? false) {
            return .video
        }
        return nil
    }
}
