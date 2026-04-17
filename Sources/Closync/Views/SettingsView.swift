import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @AppStorage("selectedPalette") private var selectedPaletteRawValue = RetroPalette.phosphorGreen.rawValue
    @AppStorage("scanlinesEnabled") private var scanlinesEnabled = true
    @AppStorage("progressPanelVisible") private var progressPanelVisible = true
    @AppStorage("hoverAnimationsEnabled") private var hoverAnimationsEnabled = true
    @AppStorage("sharpCornersEnabled") private var sharpCornersEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("SYSTEM UTILITIES")
                .font(RetroTypography.title(22))
                .foregroundStyle(appModel.palette.frame)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("VISUAL PROFILE")
                        .font(RetroTypography.body(13))

                    Picker("Theme", selection: $selectedPaletteRawValue) {
                        ForEach(RetroPalette.allCases) { palette in
                            Text(palette.name.uppercased()).tag(palette.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    ToggleBlockButton(title: "CRT Scanlines", isOn: $scanlinesEnabled)
                    ToggleBlockButton(title: "Sharp Corners", isOn: $sharpCornersEnabled)
                    ToggleBlockButton(title: "Progress Panel", isOn: $progressPanelVisible)
                    ToggleBlockButton(title: "Hover Motion", isOn: $hoverAnimationsEnabled)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)

                VStack(alignment: .leading, spacing: 14) {
                    Text("BUILD / PACKAGE")
                        .font(RetroTypography.body(13))
                    Text("Version \(AppConfig.version)")
                    Text("Outputs: dist/Closync.app + dist/Closync-macos-\(AppConfig.version).zip")
                    Text("Cloud services use live REST API calls and native local/iCloud filesystem browsing in this build.")
                        .foregroundStyle(appModel.palette.secondaryText)
                }
                .font(RetroTypography.body(12))
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(4)
        .onChange(of: selectedPaletteRawValue) { _, newValue in
            appModel.palette = RetroPalette(rawValue: newValue) ?? .phosphorGreen
        }
        .onChange(of: scanlinesEnabled) { _, newValue in
            appModel.scanlinesEnabled = newValue
        }
        .onChange(of: progressPanelVisible) { _, newValue in
            appModel.progressPanelVisible = newValue
        }
        .onChange(of: hoverAnimationsEnabled) { _, newValue in
            appModel.hoverAnimationsEnabled = newValue
        }
        .onChange(of: sharpCornersEnabled) { _, newValue in
            appModel.sharpCornersEnabled = newValue
        }
    }
}
