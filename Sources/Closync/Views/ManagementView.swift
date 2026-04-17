import SwiftUI

struct ManagementView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selection = 0

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text("FLOW MODES")
                    .font(RetroTypography.title(17))

                ForEach(Array(appModel.jobs.enumerated()), id: \.offset) { index, job in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            selection = index
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(job.name.uppercased())
                                Text(job.direction.uppercased())
                                    .font(RetroTypography.body(11))
                                    .foregroundStyle(appModel.palette.secondaryText)
                            }
                            Spacer()
                            Text(job.state)
                                .font(RetroTypography.body(11))
                        }
                        .font(RetroTypography.body(13))
                        .padding(12)
                        .background(selection == index ? appModel.palette.frame.opacity(0.18) : .black.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(appModel.palette.frame.opacity(selection == index ? 1 : 0.5), lineWidth: 1)
                        )
                        .scaleEffect(selection == index ? 1.01 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 320)
            .retroPanel(palette: appModel.palette)

            VStack(alignment: .leading, spacing: 16) {
                Text("WORKLOAD PROFILE")
                    .font(RetroTypography.title(17))

                MetricPanel(title: "Selected Route", value: appModel.jobs[selection].state, caption: appModel.jobs[selection].name)

                HStack(spacing: 12) {
                    DraggableChip(title: "SYNC")
                    DraggableChip(title: "MOVE")
                    DraggableChip(title: "DELETE")
                    DraggableChip(title: "BACKUP")
                }

                Text("Drag a mode block as a seed for future flow authoring. The dataflow pane uses these same operation families for node routing.")
                    .font(RetroTypography.body(12))
                    .foregroundStyle(appModel.palette.secondaryText)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .retroPanel(palette: appModel.palette)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct DraggableChip: View {
    let title: String
    @Environment(AppModel.self) private var appModel
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        Text(title)
            .font(RetroTypography.body(14))
            .foregroundStyle(.black)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(appModel.palette.frame)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: appModel.palette.glow, radius: 10)
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.68)) {
                            dragOffset = .zero
                        }
                    }
            )
    }
}
