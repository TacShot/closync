# Closync

Closync is a native macOS file orchestration app for moving, copying, deleting, backing up, previewing, and routing files across local volumes, external drives, and connected cloud providers with a retro CRT-inspired interface.

## Highlights

- Native SwiftUI macOS desktop app with animated route-map editing
- Local file and folder management with drag-and-drop plus native pickers
- Connection panels for Local, iCloud, Google Drive, OneDrive, Dropbox, and GitHub
- In-app OAuth guidance with provider links for app registration, authorization help, and token acquisition
- GitHub repository backup flow with private repo creation and dated backup branches
- Media viewer for local and previewable remote image/video content
- Toggleable CRT scanlines and sharp-corner or rounded-corner chrome

## Run

Requirements:

- macOS 14 or later
- Xcode Command Line Tools with Swift 6

Build:

```bash
swift build
```

Build, package, and launch the app bundle:

```bash
./script/build_and_run.sh
```

Verify the packaged app launches:

```bash
./script/build_and_run.sh --verify
```

Outputs:

- `dist/Closync.app`
- `dist/Closync-macos-0.2.0.zip`

## Using The App

### Files

1. Open the `FILE` tab.
2. Drag files/folders into the drop zone or use `ADD` / `FOLDERS`.
3. Choose a destination with `DEST` when using copy, move, or local backup.
4. Click a file row to preview supported images and videos.
5. Run `COPY`, `MOVE`, `DELETE`, or `BACKUP`.

### Connections

1. Open the `NET` tab.
2. Pick a provider card.
3. Read the OAuth instructions shown in the provider panel.
4. Use the in-app links:
   - `AUTH GUIDE` for provider OAuth flow docs
   - `TOKEN` for token-generation helpers or token settings
   - `PORTAL` for provider developer console/app registration
5. Paste the resulting access token and press `CONNECT`.
6. Browse folders, and click previewable remote files to open them in the media viewer.

Note:

- Local and iCloud do not require pasted tokens.
- Google Drive preview streaming is not fully implemented yet because it needs a signed authenticated download step.

### Route Map

1. Open the `LINK` tab.
2. Drag nodes to reposition the live path wires.
3. Double-click a node to open its edit dialog in the route panel.
4. Use `NEW BOX` to create new nodes and connect them between existing boxes.

### GitHub Backup

1. Select files or folders in `FILE`.
2. Press `BACKUP` or open the GitHub backup dialog.
3. Enter token, repo details, and interval metadata.
4. Create the repo and backup branch directly from the app.

## Architecture

Closync is organized as a Swift Package with a focused native macOS structure:

- `Sources/Closync/App`
  App entry point, versioning, commands, and window setup.
- `Sources/Closync/Stores`
  `AppModel` owns app-wide state, file selection, route-map state, connection state, logs, and preview state.
- `Sources/Closync/Models`
  Value types for providers, files, route nodes, automations, previews, and backup drafts.
- `Sources/Closync/Services`
  Native file panels, filesystem actions, provider API clients, preview URL resolution, and OAuth URL helpers.
- `Sources/Closync/Views`
  Dashboard, files, route map, connections, settings, automations, and reusable retro UI components.
- `Sources/Closync/Support`
  Shared styling primitives, CRT scanline rendering, and shape utilities.

## Implementation Notes

- UI is written in SwiftUI and optimized for desktop pointer interactions.
- File actions use `FileManager` and native `NSOpenPanel`.
- Remote provider integration currently uses REST APIs with bearer tokens:
  - Google Drive API
  - Microsoft Graph
  - Dropbox API
  - GitHub REST API
- GitHub backup creation uses repository creation, branch creation, and content upload endpoints.
- Media streaming currently works for local files and previewable remote links where providers expose direct or temporary URLs.

## Current Gaps

- Full embedded OAuth callback handling is not yet implemented because providers require user-registered client applications and redirect handling.
- Google Drive media preview still needs an authenticated download handoff for viewer playback.
- Remote upload/sync execution beyond GitHub backup is still a next-step expansion.

## License

Personal project scaffold. Add your preferred license before distribution.
