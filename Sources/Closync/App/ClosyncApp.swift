import AppKit
import SwiftUI

@main
struct ClosyncApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("selectedPalette") private var selectedPaletteRawValue = RetroPalette.phosphorGreen.rawValue
    @AppStorage("scanlinesEnabled") private var scanlinesEnabled = true
    @AppStorage("progressPanelVisible") private var progressPanelVisible = true
    @AppStorage("hoverAnimationsEnabled") private var hoverAnimationsEnabled = true
    @AppStorage("sharpCornersEnabled") private var sharpCornersEnabled = false

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environment(appModel)
                .preferredColorScheme(.dark)
                .task {
                    appModel.configureInitialState(
                        palette: RetroPalette(rawValue: selectedPaletteRawValue) ?? .phosphorGreen,
                        scanlinesEnabled: scanlinesEnabled,
                        progressPanelVisible: progressPanelVisible,
                        hoverAnimationsEnabled: hoverAnimationsEnabled,
                        sharpCornersEnabled: sharpCornersEnabled
                    )
                }
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
                .frame(minWidth: 1240, minHeight: 800)
        }
        .windowResizability(.contentSize)
        .commands {
            SidebarCommands()
            CommandMenu("Flow") {
                Button("Select Files or Folders") {
                    appModel.chooseFilesAndFolders()
                }
                .keyboardShortcut("o")

                Button(appModel.progressPanelVisible ? "Hide Progress Panel" : "Show Progress Panel") {
                    appModel.progressPanelVisible.toggle()
                    progressPanelVisible = appModel.progressPanelVisible
                }
                .keyboardShortcut("p")

                Button("Choose Destination") {
                    appModel.chooseDestinationFolder()
                }
                .keyboardShortcut("d")

                Button("Open GitHub Backup Dialog") {
                    appModel.showingGitHubBackupSheet = true
                }
                .keyboardShortcut("b")
            }
        }

        Settings {
            SettingsView()
                .environment(appModel)
                .preferredColorScheme(.dark)
                .frame(width: 640, height: 520)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
