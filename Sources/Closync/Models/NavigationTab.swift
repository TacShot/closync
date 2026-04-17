import Foundation

enum NavigationTab: String, CaseIterable, Identifiable {
    case dashboard
    case management
    case dataflow
    case connections
    case automations
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "STAT"
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
        case .management: "Management"
        case .dataflow: "Dataflow"
        case .connections: "Connections"
        case .automations: "Automations"
        case .settings: "Settings"
        }
    }
}
