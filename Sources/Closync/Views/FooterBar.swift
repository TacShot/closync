import SwiftUI

struct FooterBar: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SYSTEM STATUS: NOMINAL // \(appModel.connections.filter { $0.health == .online }.count) LINKS ACTIVE")
                Text("VERSION CLASS: \(AppConfig.version) // UI PROFILE: \(appModel.palette.name.uppercased())")
            }
            .font(RetroTypography.body(11))
            .foregroundStyle(appModel.palette.secondaryText)

            Spacer()

            HStack(spacing: 10) {
                RetroButton(title: appModel.progressPanelVisible ? "HUD ON" : "HUD OFF", isActive: appModel.progressPanelVisible) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        appModel.progressPanelVisible.toggle()
                    }
                }
                .frame(width: 120)

                RetroButton(title: "SCAN", isActive: false) {
                    appModel.advanceSimulation()
                }
                .frame(width: 110)

                SettingsLink {
                    Text("[MENU]")
                        .font(RetroTypography.body(15))
                        .foregroundStyle(appModel.palette.frame)
                        .padding(.vertical, 10)
                        .frame(width: 110)
                }
                .buttonStyle(.plain)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(appModel.palette.frame.opacity(0.9), lineWidth: 1)
                )
            }
        }
        .retroPanel(palette: appModel.palette)
    }
}
