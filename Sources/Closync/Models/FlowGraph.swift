import CoreGraphics
import Foundation

struct FlowNode: Identifiable, Hashable {
    enum NodeKind: String, CaseIterable, Hashable {
        case source
        case transform
        case destination
        case cleanup
    }

    let id: UUID
    var title: String
    var subtitle: String
    var kind: NodeKind
    var position: CGPoint
    var progress: Double
}

struct FlowEdge: Identifiable, Hashable {
    let id = UUID()
    var from: UUID
    var to: UUID
    var label: String
    var traffic: Double
}
