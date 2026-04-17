import SwiftUI

struct ManagementView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text("ACTION MODES")
                    .font(RetroTypography.title(17))

                ActionCard(title: "COPY", detail: "Duplicate selected files into a chosen destination folder.") {
                    Task { await appModel.performLocalAction(.copy) }
                }
                ActionCard(title: "MOVE", detail: "Move selected items into the chosen destination folder.") {
                    Task { await appModel.performLocalAction(.move) }
                }
                ActionCard(title: "DELETE", detail: "Send selected items to Trash.") {
                    Task { await appModel.performLocalAction(.delete) }
                }
                ActionCard(title: "BACKUP", detail: "Open the GitHub repository backup dialog.") {
                    appModel.showingGitHubBackupSheet = true
                }
            }
            .frame(width: 340)
            .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)

            VStack(alignment: .leading, spacing: 16) {
                Text("CURRENT TARGET")
                    .font(RetroTypography.title(17))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Destination")
                    Text(appModel.destinationFolderURL?.path ?? "No destination selected")
                        .foregroundStyle(appModel.palette.secondaryText)
                    Text("Selected connection")
                    Text(appModel.selectedConnection?.displayName ?? "None")
                        .foregroundStyle(appModel.palette.secondaryText)
                }
                .font(RetroTypography.body(12))

                HStack(spacing: 12) {
                    RetroButton(title: "SELECT FILES", isActive: true) {
                        appModel.selectedTab = .files
                    }
                    RetroButton(title: "CHOOSE DEST", isActive: false) {
                        appModel.chooseDestinationFolder()
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct ActionCard: View {
    let title: String
    let detail: String
    let action: () -> Void

    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(RetroTypography.body(14))
            Text(detail)
                .font(RetroTypography.body(11))
                .foregroundStyle(appModel.palette.secondaryText)
            RetroButton(title: title, isActive: title == "BACKUP", action: action)
                .frame(width: 160)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.black.opacity(0.16))
        .overlay(
            RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 10)
                .stroke(appModel.palette.frame.opacity(0.78), lineWidth: 1)
        )
    }
}
