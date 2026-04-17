import SwiftUI

struct DashboardView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                MetricPanel(title: "Connected Providers", value: "\(appModel.connectedProvidersCount)", caption: "Live authenticated endpoints")
                MetricPanel(title: "Selected Roots", value: "\(appModel.selectedItems.count)", caption: "Files or folders in the working set")
                MetricPanel(title: "Selected Data", value: ByteCountFormatter.string(fromByteCount: appModel.totalSelectedBytes, countStyle: .file), caption: "Actual bytes from selected items")
                MetricPanel(title: "Completed Actions", value: "\(appModel.recentSuccessfulActions)", caption: "Successful file or connection operations")
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("WORKSPACE STATUS")
                        .font(RetroTypography.title(17))

                    ProgressMeter(title: "Selection Coverage", progress: min(1, Double(appModel.totalSelectedEntries) / 100), detail: "\(appModel.totalSelectedEntries) contained items")
                    ProgressMeter(title: "Connection Coverage", progress: Double(appModel.connectedProvidersCount) / Double(max(appModel.connections.count, 1)), detail: "\(appModel.connectedProvidersCount) providers online")
                    ProgressMeter(title: "Operation Progress", progress: appModel.currentProgress, detail: appModel.currentOperation)

                    HStack(spacing: 12) {
                        RetroButton(title: "OPEN FILES", isActive: true) {
                            appModel.selectedTab = .files
                        }
                        RetroButton(title: "REFRESH NET", isActive: false) {
                            Task { await appModel.refreshSelectedConnection() }
                        }
                        RetroButton(title: "SET DEST", isActive: false) {
                            appModel.chooseDestinationFolder()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)

                DashboardActivityPanel()
                    .frame(width: 380)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct DashboardActivityPanel: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("EVENT LOG")
                .font(RetroTypography.title(17))

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(appModel.logs.prefix(8)) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title.uppercased())
                                .font(RetroTypography.body(11))
                            Text(entry.detail)
                                .font(RetroTypography.body(10))
                                .foregroundStyle(appModel.palette.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 6)
                    }
                }
            }
        }
        .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)
    }
}
