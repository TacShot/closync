import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ZStack {
            RetroGridBackground(palette: appModel.palette, scanlinesEnabled: appModel.scanlinesEnabled)

            VStack(spacing: 16) {
                TopNavigationBar()

                HStack(alignment: .top, spacing: 16) {
                    mainPanel

                    if appModel.progressPanelVisible {
                        ProgressSidePanel()
                            .frame(width: 300)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }

                FooterBar()
            }
            .padding(20)
            .foregroundStyle(appModel.palette.frame)
        }
    }

    @ViewBuilder
    private var mainPanel: some View {
        switch appModel.selectedTab {
        case .dashboard:
            DashboardView()
        case .management:
            ManagementView()
        case .dataflow:
            DataflowView()
        case .connections:
            ConnectionsView()
        case .automations:
            AutomationsView()
        case .settings:
            SettingsView()
        }
    }
}
