import AppKit
import SwiftUI

@main
struct ClosyncApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("selectedPalette") private var selectedPaletteRawValue = RetroPalette.phosphorGreen.rawValue
    @AppStorage("scanlinesEnabled") private var scanlinesEnabled = true
    @AppStorage("progressPanelVisible") private var progressPanelVisible = true

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
                        progressPanelVisible: progressPanelVisible
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
                .frame(minWidth: 1240, minHeight: 800)
        }
        .windowResizability(.contentSize)
        .commands {
            SidebarCommands()
            CommandMenu("Flow") {
                Button("Run Active Workload") {
                    appModel.advanceSimulation()
                }
                .keyboardShortcut("r")

                Button(appModel.progressPanelVisible ? "Hide Progress Panel" : "Show Progress Panel") {
                    appModel.progressPanelVisible.toggle()
                    progressPanelVisible = appModel.progressPanelVisible
                }
                .keyboardShortcut("p")
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
