import SwiftUI

struct ClosyncLogoView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 8)
                    .fill(.black.opacity(0.18))
                    .frame(width: 42, height: 42)
                Path { path in
                    path.move(to: CGPoint(x: 10, y: 12))
                    path.addLine(to: CGPoint(x: 21, y: 21))
                    path.addLine(to: CGPoint(x: 32, y: 10))
                    path.move(to: CGPoint(x: 10, y: 30))
                    path.addLine(to: CGPoint(x: 21, y: 21))
                    path.addLine(to: CGPoint(x: 32, y: 32))
                }
                .stroke(appModel.palette.frame, style: StrokeStyle(lineWidth: 2.2, lineCap: .square))
            }
            .overlay(
                RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 8)
                    .stroke(appModel.palette.frame.opacity(0.78), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("CLOSYNC")
                    .font(RetroTypography.title(16))
                    .tracking(1.4)
                Text("SYNC / STREAM / BACKUP")
                    .font(RetroTypography.body(9))
                    .foregroundStyle(appModel.palette.secondaryText)
            }
        }
    }
}
