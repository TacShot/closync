import SwiftUI

struct DashboardView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                MetricPanel(title: "Active Paths", value: "\(appModel.connections.count)", caption: "Providers and volumes linked")
                MetricPanel(title: "Automation Rules", value: "\(appModel.automations.filter(\.enabled).count)", caption: "Enabled event pipelines")
                MetricPanel(title: "Live Throughput", value: "586 MB/S", caption: "Aggregate transfer velocity")
                MetricPanel(title: "Retention Save", value: "1.8 TB", caption: "Local data cleared after upload")
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("ACTIVE JOBS")
                        .font(RetroTypography.title(17))

                    ForEach(appModel.jobs) { job in
                        ProgressMeter(title: job.name, progress: job.progress, detail: "\(job.direction) // \(job.throughput)")
                    }

                    HStack(spacing: 12) {
                        RetroButton(title: "RUN FLOW", isActive: true) {
                            appModel.advanceSimulation()
                        }
                        RetroButton(title: "ARM BACKUP", isActive: false) {
                            appModel.selectedTab = .automations
                        }
                        RetroButton(title: "OPEN NET", isActive: false) {
                            appModel.selectedTab = .connections
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .retroPanel(palette: appModel.palette)

                DashboardTelemetryPanel()
                    .frame(width: 360)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct DashboardTelemetryPanel: View {
    @Environment(AppModel.self) private var appModel
    @State private var phase: CGFloat = .zero

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate

            VStack(alignment: .leading, spacing: 14) {
                Text("SIGNAL TRACE")
                    .font(RetroTypography.title(17))

                Canvas { context, size in
                    var path = Path()
                    for index in stride(from: 0.0, through: size.width, by: 4) {
                        let normalized = index / size.width
                        let y = size.height * 0.5 + sin(normalized * 18 + time * 3) * 26 + cos(normalized * 9 + time * 1.8) * 10
                        if index == 0 {
                            path.move(to: CGPoint(x: index, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: index, y: y))
                        }
                    }
                    context.stroke(path, with: .color(appModel.palette.frame), lineWidth: 2)
                }
                .frame(height: 140)
                .background(.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text("LATEST EVENTS")
                        .font(RetroTypography.body(12))
                    Text("16:57 checksum lane realigned")
                    Text("16:58 drive target warmed")
                    Text("16:58 staged purge verified")
                    Text("16:59 iCloud delta indexed")
                }
                .font(RetroTypography.body(11))
                .foregroundStyle(appModel.palette.secondaryText)
            }
            .retroPanel(palette: appModel.palette)
        }
    }
}
