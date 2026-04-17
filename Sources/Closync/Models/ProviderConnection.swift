import Foundation

enum ConnectionHealth: String, CaseIterable {
    case online
    case degraded
    case offline

    var label: String {
        rawValue.uppercased()
    }
}

struct ProviderConnection: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var provider: String
    var path: String
    var health: ConnectionHealth
    var usedCapacity: Double
    var lastSync: String
}
