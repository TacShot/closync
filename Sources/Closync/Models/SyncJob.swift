import Foundation

struct SyncJob: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var direction: String
    var state: String
    var progress: Double
    var throughput: String
    var eta: String
}
