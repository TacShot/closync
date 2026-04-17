import SwiftUI

struct GitHubBackupSheet: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("GITHUB REPOSITORY BACKUP")
                .font(RetroTypography.title(22))

            Text("Create a new private repository, create a backup branch from your chosen timeframe, and upload the selected files or folders.")
                .font(RetroTypography.body(12))
                .foregroundStyle(appModel.palette.secondaryText)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        LabeledTextField(title: "Token", text: Binding(
                            get: { appModel.githubBackupDraft.token },
                            set: { appModel.githubBackupDraft.token = $0 }
                        ), secure: true)
                        LabeledTextField(title: "Owner", text: Binding(
                            get: { appModel.githubBackupDraft.owner },
                            set: { appModel.githubBackupDraft.owner = $0 }
                        ))
                        LabeledTextField(title: "Repository", text: Binding(
                            get: { appModel.githubBackupDraft.repositoryName },
                            set: { appModel.githubBackupDraft.repositoryName = $0 }
                        ))
                        LabeledTextField(title: "Description", text: Binding(
                            get: { appModel.githubBackupDraft.description },
                            set: { appModel.githubBackupDraft.description = $0 }
                        ))
                    }

                    ToggleBlockButton(title: "Private Repo", isOn: Binding(
                        get: { appModel.githubBackupDraft.makePrivate },
                        set: { appModel.githubBackupDraft.makePrivate = $0 }
                    ))

                    HStack(spacing: 12) {
                        Stepper("Interval: \(appModel.githubBackupDraft.timeframeValue)", value: Binding(
                            get: { appModel.githubBackupDraft.timeframeValue },
                            set: { appModel.githubBackupDraft.timeframeValue = max(1, $0) }
                        ), in: 1 ... 48)
                        Picker("Unit", selection: Binding(
                            get: { appModel.githubBackupDraft.timeframeUnit },
                            set: { appModel.githubBackupDraft.timeframeUnit = $0 }
                        )) {
                            ForEach(BackupTimeUnit.allCases) { unit in
                                Text(unit.label).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)

                VStack(alignment: .leading, spacing: 12) {
                    Text("SELECTED ROOTS")
                        .font(RetroTypography.body(13))
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(appModel.selectedItems) { item in
                                Text(item.url.lastPathComponent)
                                    .font(RetroTypography.body(11))
                                    .foregroundStyle(appModel.palette.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 170)

                    HStack(spacing: 10) {
                        RetroButton(title: "ADD FILES", isActive: false) {
                            appModel.chooseFilesAndFolders()
                        }
                        RetroButton(title: "CREATE REPO", isActive: true) {
                            Task { await appModel.createGitHubBackupRepository() }
                        }
                    }
                }
                .frame(width: 280, alignment: .topLeading)
                .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 860, height: 520)
        .background(RetroGridBackground(palette: appModel.palette, scanlinesEnabled: appModel.scanlinesEnabled))
        .foregroundStyle(appModel.palette.frame)
    }
}

private struct LabeledTextField: View {
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
                    .stroke(appModel.palette.frame.opacity(0.7), lineWidth: 1)
            )
        }
    }
}
