import Foundation

struct AutomationRule: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var trigger: String
    var behavior: String
    var enabled: Bool
    var cadence: String
}
