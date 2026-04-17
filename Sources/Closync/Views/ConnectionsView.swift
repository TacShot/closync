import SwiftUI

struct ConnectionsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PROVIDER MESH")
                .font(RetroTypography.title(18))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 14)], spacing: 14) {
                ForEach(appModel.connections) { connection in
                    ConnectionCard(connection: connection)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .retroPanel(palette: appModel.palette)
    }
}

private struct ConnectionCard: View {
    let connection: ProviderConnection
    @Environment(AppModel.self) private var appModel
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(connection.name.uppercased())
                    .font(RetroTypography.body(13))
                Spacer()
                Text(connection.health.label)
                    .font(RetroTypography.body(11))
                    .foregroundStyle(connection.health == .offline ? .red : appModel.palette.frame)
            }

            Text(connection.provider.uppercased())
                .font(RetroTypography.body(11))
                .foregroundStyle(appModel.palette.secondaryText)

            Text(connection.path)
                .font(RetroTypography.body(10))
                .foregroundStyle(appModel.palette.secondaryText)
                .lineLimit(2)

            ProgressMeter(title: "Capacity", progress: connection.usedCapacity, detail: "LAST SYNC \(connection.lastSync)")
        }
        .padding(12)
        .background(hovering ? appModel.palette.frame.opacity(0.08) : .black.opacity(0.14))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(appModel.palette.frame.opacity(0.88), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: hovering ? appModel.palette.glow : .clear, radius: 14)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                self.hovering = hovering
            }
        }
    }
}
