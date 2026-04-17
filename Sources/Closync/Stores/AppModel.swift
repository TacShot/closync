import Foundation
import Observation

@Observable
final class AppModel {
    var palette: RetroPalette = .phosphorGreen
    var scanlinesEnabled = true
    var progressPanelVisible = true
    var selectedTab: NavigationTab = .dashboard
    var dashboardFilter = "ALL"
    var interactionPulse = 0
    var hoveredControlID: String?
    var nodes: [FlowNode] = []
    var edges: [FlowEdge] = []
    var connections: [ProviderConnection] = []
    var jobs: [SyncJob] = []
    var automations: [AutomationRule] = []

    func configureInitialState(palette: RetroPalette, scanlinesEnabled: Bool, progressPanelVisible: Bool) {
        guard nodes.isEmpty else { return }

        self.palette = palette
        self.scanlinesEnabled = scanlinesEnabled
        self.progressPanelVisible = progressPanelVisible

        let ingest = UUID()
        let mirror = UUID()
        let archive = UUID()
        let cleanup = UUID()

        nodes = [
            FlowNode(id: ingest, title: "LOCAL SRC", subtitle: "/Volumes/Projects", kind: .source, position: CGPoint(x: 0.14, y: 0.28), progress: 0.85),
            FlowNode(id: mirror, title: "SYNC CORE", subtitle: "Diff / Verify / Copy", kind: .transform, position: CGPoint(x: 0.44, y: 0.42), progress: 0.59),
            FlowNode(id: archive, title: "CLOUD VAULT", subtitle: "Drive + Dropbox + Git", kind: .destination, position: CGPoint(x: 0.76, y: 0.24), progress: 0.76),
            FlowNode(id: cleanup, title: "LOCAL CLEAN", subtitle: "Remove on success", kind: .cleanup, position: CGPoint(x: 0.76, y: 0.72), progress: 0.41)
        ]

        edges = [
            FlowEdge(from: ingest, to: mirror, label: "SCAN", traffic: 0.35),
            FlowEdge(from: mirror, to: archive, label: "UPLOAD", traffic: 0.68),
            FlowEdge(from: mirror, to: cleanup, label: "PURGE", traffic: 0.42)
        ]

        connections = [
            ProviderConnection(name: "Studio SSD", provider: "Local", path: "/Volumes/StudioSSD", health: .online, usedCapacity: 0.54, lastSync: "2m ago"),
            ProviderConnection(name: "Google Drive", provider: "Cloud", path: "drive://creative-archive", health: .online, usedCapacity: 0.72, lastSync: "5m ago"),
            ProviderConnection(name: "OneDrive 365", provider: "Cloud", path: "odrive://ops-share", health: .degraded, usedCapacity: 0.43, lastSync: "18m ago"),
            ProviderConnection(name: "GitHub Vault", provider: "Private Repo", path: "git@github.com:private/archive.git", health: .online, usedCapacity: 0.20, lastSync: "11m ago"),
            ProviderConnection(name: "iCloud", provider: "Cloud", path: "icloud://Closync", health: .online, usedCapacity: 0.61, lastSync: "1m ago"),
            ProviderConnection(name: "Dropbox Cold", provider: "Cloud", path: "dropbox://cold-storage", health: .offline, usedCapacity: 0.33, lastSync: "2h ago")
        ]

        jobs = [
            SyncJob(name: "Media offload", direction: "LOCAL -> DRIVE", state: "RUNNING", progress: 0.81, throughput: "482 MB/s", eta: "00:58"),
            SyncJob(name: "Research mirror", direction: "GITHUB <-> SSD", state: "SYNCING", progress: 0.47, throughput: "82 MB/s", eta: "03:14"),
            SyncJob(name: "Cloud backup", direction: "LOCAL -> DROPBOX", state: "QUEUED", progress: 0.12, throughput: "22 MB/s", eta: "07:22")
        ]

        automations = [
            AutomationRule(name: "Nightly ingest", trigger: "Folder change + 22:00", behavior: "Upload to Drive then remove local cache", enabled: true, cadence: "DAILY"),
            AutomationRule(name: "Repo mirror", trigger: "USB mount", behavior: "Sync docs to private GitHub repo", enabled: true, cadence: "EVENT"),
            AutomationRule(name: "Cold backup", trigger: "Friday 19:00", behavior: "Mirror selected roots to Dropbox and iCloud", enabled: false, cadence: "WEEKLY")
        ]
    }

    func advanceSimulation() {
        interactionPulse += 1

        for index in jobs.indices {
            jobs[index].progress = min(1, jobs[index].progress + Double.random(in: 0.03 ... 0.14))
            jobs[index].state = jobs[index].progress >= 1 ? "COMPLETE" : "RUNNING"
        }

        for index in nodes.indices {
            nodes[index].progress = min(1, max(0.1, nodes[index].progress + Double.random(in: -0.08 ... 0.16)))
        }

        for index in edges.indices {
            edges[index].traffic = min(1, max(0.1, edges[index].traffic + Double.random(in: -0.12 ... 0.18)))
        }
    }

    func updateNodePosition(id: UUID, normalizedPosition: CGPoint) {
        guard let index = nodes.firstIndex(where: { $0.id == id }) else { return }
        nodes[index].position = CGPoint(
            x: min(max(normalizedPosition.x, 0.08), 0.92),
            y: min(max(normalizedPosition.y, 0.12), 0.88)
        )
    }
}
