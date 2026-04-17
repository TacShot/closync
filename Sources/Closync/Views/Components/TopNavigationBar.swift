import SwiftUI

struct TopNavigationBar: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        HStack(spacing: 10) {
            ClosyncLogoView()

            VStack(alignment: .leading, spacing: 4) {
                Text("MR-01/MASS")
                    .font(RetroTypography.body(11))
                    .foregroundStyle(appModel.palette.secondaryText)
                Text("CLSYNC-\(AppConfig.version)/\(appModel.selectedTab.subtitle.uppercased())")
                    .font(RetroTypography.body(16))
                    .foregroundStyle(appModel.palette.frame)
            }

            Spacer()

            HStack(spacing: 8) {
                ForEach(NavigationTab.allCases) { tab in
                    RetroButton(title: tab.title, isActive: appModel.selectedTab == tab) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            appModel.selectedTab = tab
                        }
                    }
                    .frame(width: 94)
                }
            }
        }
        .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)
    }
}
