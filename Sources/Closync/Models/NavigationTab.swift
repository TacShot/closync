import Foundation

enum NavigationTab: String, CaseIterable, Identifiable {
    case dashboard
    case files
    case management
    case dataflow
    case connections
    case automations
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "STAT"
        case .files: "FILE"
        case .management: "CORE"
        case .dataflow: "LINK"
        case .connections: "NET"
        case .automations: "AUTO"
        case .settings: "UTIL"
        }
    }

    var subtitle: String {
        switch self {
        case .dashboard: "Dashboard"
        case .files: "Files"
        case .management: "Management"
        case .dataflow: "Dataflow"
        case .connections: "Connections"
        case .automations: "Automations"
        case .settings: "Settings"
        }
    }
}
