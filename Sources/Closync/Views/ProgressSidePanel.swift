import SwiftUI

struct ProgressSidePanel: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LIVE OPS")
                .font(RetroTypography.title(18))

            ProgressMeter(title: appModel.currentOperation, progress: appModel.currentProgress, detail: appModel.statusMessage)

            VStack(alignment: .leading, spacing: 10) {
                Text("RECENT OPERATIONS")
                    .font(RetroTypography.body(12))

                if appModel.recentOperations.isEmpty {
                    Text("No file actions executed yet.")
                        .font(RetroTypography.body(11))
                        .foregroundStyle(appModel.palette.secondaryText)
                } else {
                    ForEach(appModel.recentOperations) { operation in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(operation.name)
                                .font(RetroTypography.body(12))
                            Text(operation.detail)
                                .font(RetroTypography.body(10))
                                .foregroundStyle(appModel.palette.secondaryText)
                            ProgressMeter(title: operation.state, progress: operation.progress, detail: operation.detail)
                        }
                    }
                }
            }

            Spacer()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)
    }
}
