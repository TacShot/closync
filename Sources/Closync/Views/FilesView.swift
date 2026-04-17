import AVKit
import UniformTypeIdentifiers
import SwiftUI

struct FilesView: View {
    @Environment(AppModel.self) private var appModel
    @State private var isDropTargeted = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Text("FILE CONTROL")
                    .font(RetroTypography.title(18))

                DropZoneView(isTargeted: $isDropTargeted)
                    .environment(appModel)
                    .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                        Task { await handleDrop(providers) }
                        return true
                    }

                HStack(spacing: 12) {
                    RetroButton(title: "ADD", isActive: true) {
                        appModel.chooseFilesAndFolders()
                    }
                    RetroButton(title: "FOLDERS", isActive: false) {
                        appModel.chooseFoldersOnly()
                    }
                    RetroButton(title: "DEST", isActive: false) {
                        appModel.chooseDestinationFolder()
                    }
                    RetroButton(title: "CLEAR", isActive: false) {
                        appModel.clearSelections()
                    }
                }

                ScrollView {
                    VStack(spacing: 10) {
                        if appModel.selectedItems.isEmpty {
                            EmptySelectionView()
                                .environment(appModel)
                        } else {
                            ForEach(appModel.selectedItems) { item in
                                FileRow(item: item, isSelected: appModel.selectedLocalItemID == item.id) {
                                    appModel.removeItem(item)
                                }
                                .environment(appModel)
                                .onTapGesture {
                                    appModel.selectLocalItem(item)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)

            VStack(alignment: .leading, spacing: 16) {
                Text("ACTIONS")
                    .font(RetroTypography.title(18))

                if let destination = appModel.destinationFolderURL {
                    Text("DESTINATION")
                        .font(RetroTypography.body(12))
                    Text(destination.path)
                        .font(RetroTypography.body(11))
                        .foregroundStyle(appModel.palette.secondaryText)
                }

                HStack(spacing: 10) {
                    actionButton(.copy)
                    actionButton(.move)
                }
                HStack(spacing: 10) {
                    actionButton(.delete)
                    actionButton(.backup)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("SELECTION")
                        .font(RetroTypography.body(12))
                    Text("\(appModel.selectedItems.count) roots")
                    Text("\(appModel.totalSelectedEntries) contained items")
                    Text(ByteCountFormatter.string(fromByteCount: appModel.totalSelectedBytes, countStyle: .file))
                }
                .font(RetroTypography.body(12))
                .foregroundStyle(appModel.palette.secondaryText)

                MediaViewerPanel()
                    .environment(appModel)

                Spacer()
            }
            .frame(width: 360, alignment: .topLeading)
            .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)
        }
    }

    @ViewBuilder
    private func actionButton(_ action: FileOperationKind) -> some View {
        RetroButton(title: action.title, isActive: action == .backup) {
            if action == .backup {
                appModel.showingGitHubBackupSheet = true
            } else {
                Task { await appModel.performLocalAction(action) }
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) async {
        var urls: [URL] = []
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier),
               let item = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier),
               let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                urls.append(url)
            }
        }

        if !urls.isEmpty {
            appModel.addItems(urls: urls)
        }
    }
}

private struct MediaViewerPanel: View {
    @Environment(AppModel.self) private var appModel
    @State private var player: AVPlayer?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MEDIA VIEWER")
                .font(RetroTypography.body(12))

            if let preview = appModel.mediaPreview {
                Text(preview.title.uppercased())
                    .font(RetroTypography.body(11))
                Text(preview.providerName.uppercased())
                    .font(RetroTypography.body(10))
                    .foregroundStyle(appModel.palette.secondaryText)

                Group {
                    switch preview.kind {
                    case .image:
                        RemoteImageView(url: preview.sourceURL)
                    case .video:
                        VideoPlayer(player: player)
                            .frame(height: 180)
                            .onAppear {
                                player = AVPlayer(url: preview.sourceURL)
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .clipShape(RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 10))

                if preview.kind == .video {
                    HStack(spacing: 10) {
                        RetroButton(title: "PLAY", isActive: true) {
                            player?.play()
                        }
                        RetroButton(title: "PAUSE", isActive: false) {
                            player?.pause()
                        }
                    }
                }
            } else {
                Text("Select a local image/video or a previewable remote media file from Connections.")
                    .font(RetroTypography.body(11))
                    .foregroundStyle(appModel.palette.secondaryText)
            }
        }
    }
}

private struct RemoteImageView: View {
    let url: URL

    var body: some View {
        if url.isFileURL, let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 180)
        } else {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                case .failure:
                    Text("Preview unavailable")
                        .frame(maxWidth: .infinity, minHeight: 180)
                default:
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 180)
                }
            }
        }
    }
}

private struct DropZoneView: View {
    @Environment(AppModel.self) private var appModel
    @Binding var isTargeted: Bool

    var body: some View {
        VStack(spacing: 14) {
            Text("DROP FILES / FOLDERS")
                .font(RetroTypography.title(18))
            Text("Drag items here or use the ADD buttons to select files, folders, and external-drive paths.")
                .font(RetroTypography.body(12))
                .foregroundStyle(appModel.palette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(
            RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 16)
                .fill(isTargeted ? appModel.palette.frame.opacity(0.16) : .black.opacity(0.15))
        )
        .overlay(
            RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [8, 6]))
                .foregroundStyle(appModel.palette.frame)
        )
    }
}

private struct EmptySelectionView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No items selected")
                .font(RetroTypography.body(13))
            Text("Use drag and drop, the file picker, or provider browsers to build a working set.")
                .font(RetroTypography.body(11))
                .foregroundStyle(appModel.palette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.black.opacity(0.16))
        .overlay(
            RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 10)
                .stroke(appModel.palette.frame.opacity(0.65), lineWidth: 1)
        )
    }
}

private struct FileRow: View {
    let item: FileSelectionItem
    let isSelected: Bool
    let remove: () -> Void

    @Environment(AppModel.self) private var appModel
    @State private var hovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.url.lastPathComponent.uppercased())
                    .font(RetroTypography.body(13))
                Text(item.url.path)
                    .font(RetroTypography.body(10))
                    .foregroundStyle(appModel.palette.secondaryText)
                    .lineLimit(2)
                Text("\(item.isDirectory ? "FOLDER" : "FILE") // \(item.itemCount) item(s) // \(ByteCountFormatter.string(fromByteCount: item.sizeInBytes, countStyle: .file))")
                    .font(RetroTypography.body(10))
                    .foregroundStyle(appModel.palette.secondaryText)
            }

            Spacer()

            Button(action: remove) {
                Text("[X]")
                    .font(RetroTypography.body(12))
                    .foregroundStyle(appModel.palette.frame)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background((hovering || isSelected) ? appModel.palette.frame.opacity(0.08) : .black.opacity(0.14))
        .overlay(
            RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 10)
                .stroke(appModel.palette.frame.opacity(isSelected ? 1 : 0.85), lineWidth: isSelected ? 1.4 : 1)
        )
        .onHover { hovering in
            self.hovering = hovering
        }
    }
}
