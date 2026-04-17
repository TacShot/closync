import SwiftUI

struct AutomationsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text("TRIGGER CHAINS")
                    .font(RetroTypography.title(17))

                ForEach(Array(appModel.automations.indices), id: \.self) { index in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(appModel.automations[index].name.uppercased())
                                    .font(RetroTypography.body(13))
                                Text("\(appModel.automations[index].trigger.uppercased()) // \(appModel.automations[index].cadence)")
                                    .font(RetroTypography.body(11))
                                    .foregroundStyle(appModel.palette.secondaryText)
                            }
                            Spacer()
                            ToggleBlockButton(title: appModel.automations[index].enabled ? "ARMED" : "OFFLINE", isOn: binding(for: index))
                        }

                        Text(appModel.automations[index].behavior.uppercased())
                            .font(RetroTypography.body(11))
                            .foregroundStyle(appModel.palette.secondaryText)
                    }
                    .padding(12)
                    .background(.black.opacity(0.16))
                    .overlay(
                        RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 12)
                            .stroke(appModel.palette.frame.opacity(0.8), lineWidth: 1)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)

            VStack(alignment: .leading, spacing: 12) {
                Text("BACKUP CADENCE")
                    .font(RetroTypography.title(17))
                Text("GitHub branch interval: every \(appModel.githubBackupDraft.timeframeValue) \(appModel.githubBackupDraft.timeframeUnit.rawValue)")
                    .font(RetroTypography.body(12))
                    .foregroundStyle(appModel.palette.secondaryText)

                RetroButton(title: "OPEN BACKUP DIALOG", isActive: true) {
                    appModel.showingGitHubBackupSheet = true
                }

                Spacer()
            }
            .frame(width: 320, alignment: .topLeading)
            .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)
        }
    }

    private func binding(for index: Int) -> Binding<Bool> {
        Binding(
            get: { appModel.automations[index].enabled },
            set: { appModel.automations[index].enabled = $0 }
        )
    }
}
