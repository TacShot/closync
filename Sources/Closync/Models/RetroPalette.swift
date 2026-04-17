import SwiftUI

enum RetroPalette: String, CaseIterable, Identifiable {
    case phosphorGreen
    case amberGrid
    case cyanConsole

    var id: String { rawValue }

    var name: String {
        switch self {
        case .phosphorGreen: "Phosphor"
        case .amberGrid: "Amber"
        case .cyanConsole: "Cyan"
        }
    }

    var frame: Color {
        switch self {
        case .phosphorGreen: Color(red: 0.18, green: 0.96, blue: 0.31)
        case .amberGrid: Color(red: 1.0, green: 0.86, blue: 0.23)
        case .cyanConsole: Color(red: 0.30, green: 0.98, blue: 0.95)
        }
    }

    var glow: Color {
        switch self {
        case .phosphorGreen: Color(red: 0.15, green: 0.90, blue: 0.30, opacity: 0.45)
        case .amberGrid: Color(red: 1.0, green: 0.73, blue: 0.12, opacity: 0.5)
        case .cyanConsole: Color(red: 0.19, green: 0.86, blue: 0.98, opacity: 0.5)
        }
    }

    var backgroundTop: Color {
        switch self {
        case .phosphorGreen: Color(red: 0.02, green: 0.11, blue: 0.05)
        case .amberGrid: Color(red: 0.16, green: 0.09, blue: 0.01)
        case .cyanConsole: Color(red: 0.01, green: 0.09, blue: 0.11)
        }
    }

    var backgroundBottom: Color {
        switch self {
        case .phosphorGreen: Color(red: 0.00, green: 0.04, blue: 0.02)
        case .amberGrid: Color(red: 0.09, green: 0.04, blue: 0.00)
        case .cyanConsole: Color(red: 0.00, green: 0.03, blue: 0.05)
        }
    }

    var secondaryText: Color {
        frame.opacity(0.68)
    }
}
