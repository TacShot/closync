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
                            ToggleBlockButton(
                                title: appModel.automations[index].enabled ? "ARMED" : "OFFLINE",
                                isOn: binding(for: index)
                            )
                        }

                        Text(appModel.automations[index].behavior.uppercased())
                            .font(RetroTypography.body(11))
                            .foregroundStyle(appModel.palette.secondaryText)
                    }
                    .padding(12)
                    .background(.black.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .retroPanel(palette: appModel.palette)

            VStack(alignment: .leading, spacing: 12) {
                Text("CHAIN OUTPUT")
                    .font(RetroTypography.title(17))
                Text("Folder changed -> Verify file set -> Upload to Google Drive -> Mirror metadata to private GitHub -> Delete local cache on checksum match")
                    .font(RetroTypography.body(12))
                    .foregroundStyle(appModel.palette.secondaryText)

                RetroButton(title: "SIMULATE", isActive: true) {
                    appModel.advanceSimulation()
                }

                Spacer()
            }
            .frame(width: 300, alignment: .topLeading)
            .retroPanel(palette: appModel.palette)
        }
    }

    private func binding(for index: Int) -> Binding<Bool> {
        Binding(
            get: { appModel.automations[index].enabled },
            set: { appModel.automations[index].enabled = $0 }
        )
    }
}
