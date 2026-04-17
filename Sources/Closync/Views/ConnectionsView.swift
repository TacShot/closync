import SwiftUI

struct ConnectionsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Text("PROVIDER MESH")
                    .font(RetroTypography.title(18))

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 14)], spacing: 14) {
                        ForEach(appModel.connections) { connection in
                            ConnectionCard(connection: connection, isSelected: appModel.selectedConnectionID == connection.id)
                                .environment(appModel)
                                .onTapGesture {
                                    appModel.selectConnection(connection.id)
                                }
                        }
                    }
                }
            }
            .frame(width: 420)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)

            if let connection = appModel.selectedConnection {
                ConnectionDetailPane(connectionID: connection.id)
                    .environment(appModel)
            }
        }
    }
}

private struct ConnectionCard: View {
    let connection: ProviderConnection
    let isSelected: Bool

    @Environment(AppModel.self) private var appModel
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(connection.displayName.uppercased())
                    .font(RetroTypography.body(13))
                Spacer()
                Text(connection.health.label)
                    .font(RetroTypography.body(11))
                    .foregroundStyle(connection.health == .offline ? .red : appModel.palette.frame)
            }

            Text(connection.provider.title.uppercased())
                .font(RetroTypography.body(11))
                .foregroundStyle(appModel.palette.secondaryText)

            Text(connection.statusMessage)
                .font(RetroTypography.body(10))
                .foregroundStyle(appModel.palette.secondaryText)
                .lineLimit(3)

            ProgressMeter(title: "Capacity", progress: connection.usedCapacity, detail: connection.quotaDescription)
        }
        .padding(12)
        .background((hovering || isSelected) ? appModel.palette.frame.opacity(0.08) : .black.opacity(0.14))
        .overlay(
            RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 12)
                .stroke(appModel.palette.frame.opacity(isSelected ? 1 : 0.88), lineWidth: isSelected ? 1.4 : 1)
        )
        .clipShape(RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 12))
        .shadow(color: hovering ? appModel.palette.glow : .clear, radius: 14)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                self.hovering = hovering
            }
        }
    }
}

private struct ConnectionDetailPane: View {
    let connectionID: UUID

    @Environment(AppModel.self) private var appModel

    var body: some View {
        let connection = currentConnection

        VStack(alignment: .leading, spacing: 16) {
            Text("\(connection.displayName.uppercased()) PANEL")
                .font(RetroTypography.title(18))

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LabeledConnectionField(title: "Display Name", text: binding(\.displayName))

                    if connection.provider.usesTokenAuthentication {
                        LabeledConnectionField(title: "Access Token", text: binding(\.authToken), secure: true)
                    }

                    if connection.provider == .github {
                        LabeledConnectionField(title: "Repo Owner", text: binding(\.repoOwner))
                        LabeledConnectionField(title: "Repo Name", text: binding(\.repoName))
                    }

                    if connection.provider == .local || connection.provider == .iCloud {
                        LabeledConnectionField(title: "Base Path", text: binding(\.locationPath))
                    }

                    HStack(spacing: 10) {
                        RetroButton(title: "CONNECT", isActive: true) {
                            Task { await appModel.refreshSelectedConnection() }
                        }
                        RetroButton(title: "BROWSE ROOT", isActive: false) {
                            Task {
                                let path = currentRootPath(for: connection)
                                await appModel.browseSelectedConnection(path: path)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("REMOTE BROWSER")
                            .font(RetroTypography.body(12))

                        if connection.browserEntries.isEmpty {
                            Text("No entries loaded.")
                                .font(RetroTypography.body(11))
                                .foregroundStyle(appModel.palette.secondaryText)
                        } else {
                            ForEach(connection.browserEntries) { entry in
                                Button {
                                    if entry.isFolder {
                                        Task { await appModel.browseSelectedConnection(path: entry.path) }
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entry.name.uppercased())
                                                .font(RetroTypography.body(11))
                                            Text(entry.path)
                                                .font(RetroTypography.body(10))
                                                .foregroundStyle(appModel.palette.secondaryText)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Text(entry.isFolder ? "DIR" : "FILE")
                                            .font(RetroTypography.body(10))
                                    }
                                    .padding(10)
                                    .background(.black.opacity(0.14))
                                    .overlay(
                                        RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 8)
                                            .stroke(appModel.palette.frame.opacity(0.65), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)
    }

    private var currentConnection: ProviderConnection {
        appModel.connections.first(where: { $0.id == connectionID })!
    }

    private func binding(_ keyPath: WritableKeyPath<ProviderConnection, String>) -> Binding<String> {
        Binding(
            get: { currentConnection[keyPath: keyPath] },
            set: { newValue in
                var copy = currentConnection
                copy[keyPath: keyPath] = newValue
                appModel.updateConnection(copy)
            }
        )
    }

    private func currentRootPath(for connection: ProviderConnection) -> String {
        switch connection.provider {
        case .local, .iCloud:
            return connection.locationPath
        case .googleDrive:
            return "root"
        case .oneDrive:
            return "root"
        case .dropbox, .github:
            return ""
        }
    }
}

private struct LabeledConnectionField: View {
    let title: String
    @Binding var text: String
    var secure = false

    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(RetroTypography.body(11))
                .foregroundStyle(appModel.palette.secondaryText)

            Group {
                if secure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .font(RetroTypography.body(12))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.black.opacity(0.18))
            .overlay(
                RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 8)
                    .stroke(appModel.palette.frame.opacity(0.75), lineWidth: 1)
            )
        }
    }
}
