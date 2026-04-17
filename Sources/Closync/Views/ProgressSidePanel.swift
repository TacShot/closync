import SwiftUI

struct ProgressSidePanel: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LIVE TRANSFER HUD")
                .font(RetroTypography.title(18))

            ForEach(appModel.jobs) { job in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(job.name.uppercased())
                                .font(RetroTypography.body(13))
                            Text(job.direction.uppercased())
                                .font(RetroTypography.body(11))
                                .foregroundStyle(appModel.palette.secondaryText)
                        }
                        Spacer()
                        Text(job.state)
                            .font(RetroTypography.body(11))
                    }

                    ProgressMeter(title: "Progress", progress: job.progress, detail: "\(job.throughput) // ETA \(job.eta)")
                }
                .padding(10)
                .background(.black.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text("ROUTE SIGNAL")
                    .font(RetroTypography.body(12))
                Text("Queue depth stable // checksum verified // adaptive pruning armed")
                    .font(RetroTypography.body(11))
                    .foregroundStyle(appModel.palette.secondaryText)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .retroPanel(palette: appModel.palette)
    }
}
