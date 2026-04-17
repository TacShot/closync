import Foundation

enum FileSystemService {
    static func metadata(for url: URL) -> FileSelectionItem {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .totalFileAllocatedSizeKey])
        let isDirectory = values?.isDirectory ?? false
        let folderSummary = isDirectory ? summarizeDirectory(at: url) : (0, 1)
        let byteSize = isDirectory ? folderSummary.0 : Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
        let itemCount = isDirectory ? folderSummary.1 : 1
        return FileSelectionItem(url: url, isDirectory: isDirectory, sizeInBytes: byteSize, itemCount: itemCount)
    }

    static func summarizeDirectory(at url: URL) -> (Int64, Int) {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return (0, 0)
        }

        var totalSize: Int64 = 0
        var totalItems = 0

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]) else {
                continue
            }

            if values.isRegularFile == true {
                totalItems += 1
                totalSize += Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
            }
        }

        return (totalSize, totalItems)
    }

    static func directoryContents(at url: URL) -> [CloudBrowserEntry] {
        let fileManager = FileManager.default
        let urls = (try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return urls.sorted(by: { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() }).map { itemURL in
            let values = try? itemURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
            return CloudBrowserEntry(
                name: itemURL.lastPathComponent,
                path: itemURL.path,
                isFolder: values?.isDirectory ?? false,
                sizeInBytes: Int64(values?.fileSize ?? 0),
                modifiedDescription: values?.contentModificationDate.map { RelativeDateTimeFormatter().localizedString(for: $0, relativeTo: Date()) }
            )
        }
    }

    static func perform(_ action: FileOperationKind, items: [FileSelectionItem], destination: URL?) throws {
        let fileManager = FileManager.default
        switch action {
        case .copy:
            guard let destination else { throw AppError.message("Pick a destination folder before copying.") }
            try items.forEach { item in
                let target = uniqueDestination(for: item.url, destination: destination)
                try fileManager.copyItem(at: item.url, to: target)
            }
        case .move:
            guard let destination else { throw AppError.message("Pick a destination folder before moving.") }
            try items.forEach { item in
                let target = uniqueDestination(for: item.url, destination: destination)
                try fileManager.moveItem(at: item.url, to: target)
            }
        case .delete:
            try items.forEach { item in
                try fileManager.trashItem(at: item.url, resultingItemURL: nil)
            }
        case .backup:
            guard let destination else { throw AppError.message("Pick a destination folder before creating a local backup.") }
            let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let backupRoot = destination.appendingPathComponent("Closync Backup \(timestamp)", isDirectory: true)
            try fileManager.createDirectory(at: backupRoot, withIntermediateDirectories: true)
            try items.forEach { item in
                try fileManager.copyItem(at: item.url, to: backupRoot.appendingPathComponent(item.url.lastPathComponent))
            }
        }
    }

    static func mountedLocalVolumes() -> [URL] {
        FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: [.skipHiddenVolumes]) ?? []
    }

    private static func uniqueDestination(for source: URL, destination: URL) -> URL {
        let fileManager = FileManager.default
        let preferred = destination.appendingPathComponent(source.lastPathComponent)
        guard !fileManager.fileExists(atPath: preferred.path) else {
            let stem = source.deletingPathExtension().lastPathComponent
            let ext = source.pathExtension
            let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let fileName = ext.isEmpty ? "\(stem)-\(timestamp)" : "\(stem)-\(timestamp).\(ext)"
            return destination.appendingPathComponent(fileName)
        }
        return preferred
    }
}
