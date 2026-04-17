import Foundation

enum FileOperationKind: String, CaseIterable, Identifiable, Codable {
    case copy
    case move
    case delete
    case backup

    var id: String { rawValue }

    var title: String { rawValue.uppercased() }
}

struct OperationSnapshot: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var detail: String
    var state: String
    var progress: Double
}
