import SwiftUI

struct MetricPanel: View {
    let title: String
    let value: String
    let caption: String

    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(RetroTypography.body(12))
                .foregroundStyle(appModel.palette.secondaryText)

            Text(value)
                .font(RetroTypography.title(28))
                .foregroundStyle(appModel.palette.frame)

            Text(caption.uppercased())
                .font(RetroTypography.body(11))
                .foregroundStyle(appModel.palette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)
    }
}

struct ProgressMeter: View {
    let title: String
    let progress: Double
    let detail: String

    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title.uppercased())
                Spacer()
                Text("\(Int(progress * 100))%")
            }
            .font(RetroTypography.body(12))
            .foregroundStyle(appModel.palette.frame)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 4)
                        .fill(.black.opacity(0.25))

                    RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 4)
                        .fill(appModel.palette.frame)
                        .frame(width: proxy.size.width * progress)
                        .shadow(color: appModel.palette.glow, radius: 8)
                }
            }
            .frame(height: 14)

            Text(detail.uppercased())
                .font(RetroTypography.body(11))
                .foregroundStyle(appModel.palette.secondaryText)
        }
    }
}
