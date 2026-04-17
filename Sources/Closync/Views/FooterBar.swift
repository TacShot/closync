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
                RetroButton(title: "SELECT", isActive: false) {
                    appModel.chooseFilesAndFolders()
                }
                .frame(width: 110)

                RetroButton(title: "BACKUP", isActive: true) {
                    appModel.showingGitHubBackupSheet = true
                }
                .frame(width: 118)

                RetroButton(title: appModel.progressPanelVisible ? "HUD ON" : "HUD OFF", isActive: appModel.progressPanelVisible) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        appModel.progressPanelVisible.toggle()
                    }
                }
                .frame(width: 120)
            }
        }
        .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)
    }
}
