import AppKit
import Foundation

enum NativePanelService {
    @MainActor
    static func chooseFilesAndFolders() -> [URL] {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.resolvesAliases = true
        panel.prompt = "Select"
        return panel.runModal() == .OK ? panel.urls : []
    }

    @MainActor
    static func chooseFolders() -> [URL] {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.resolvesAliases = true
        panel.prompt = "Select"
        return panel.runModal() == .OK ? panel.urls : []
    }

    @MainActor
    static func chooseDestinationFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose Destination"
        return panel.runModal() == .OK ? panel.url : nil
    }
}
