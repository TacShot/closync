import SwiftUI

struct FooterBar: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("STATUS: \(appModel.isBusy ? "BUSY" : "READY") // CONNECTED \(appModel.connectedProvidersCount)/\(appModel.connections.count)")
                Text("VERSION: \(AppConfig.version) // THEME: \(appModel.palette.name.uppercased()) // \(appModel.sharpCornersEnabled ? "SHARP" : "ROUND")")
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

                RetroButton(title: "SELECT", isActive: false) {
                    appModel.chooseFilesAndFolders()
                }
                .frame(width: 110)

                RetroButton(title: "BACKUP", isActive: true) {
                    appModel.showingGitHubBackupSheet = true
                }
                .frame(width: 118)

                SettingsLink {
                    Text("[MENU]")
                        .font(RetroTypography.body(15))
                        .foregroundStyle(appModel.palette.frame)
                        .padding(.vertical, 10)
                        .frame(width: 110)
                }
                .buttonStyle(.plain)
                .overlay(
                    RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 8)
                        .stroke(appModel.palette.frame.opacity(0.9), lineWidth: 1)
                )
            }
        }
        .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)
    }
}
