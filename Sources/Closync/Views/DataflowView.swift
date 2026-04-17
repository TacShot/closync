import SwiftUI

struct DataflowView: View {
    @Environment(AppModel.self) private var appModel
    @Namespace private var graphNamespace

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            FlowCanvasView(namespace: graphNamespace)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 16) {
                Text("ROUTE MAP")
                    .font(RetroTypography.title(17))

                Text("Drag nodes to redesign motion paths. Trigger actions simulate upload, cleanup, and provider sync while the wireframe graph animates traffic.")
                    .font(RetroTypography.body(12))
                    .foregroundStyle(appModel.palette.secondaryText)

                RetroButton(title: "PULSE", isActive: true) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        appModel.advanceSimulation()
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(appModel.edges) { edge in
                        ProgressMeter(
                            title: edge.label,
                            progress: edge.traffic,
                            detail: "LINK SIGNAL \(Int(edge.traffic * 100))%"
                        )
                    }
                }

                Spacer()
            }
            .frame(width: 280)
            .retroPanel(palette: appModel.palette)
        }
    }
}

private struct FlowCanvasView: View {
    @Environment(AppModel.self) private var appModel
    let namespace: Namespace.ID

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.black.opacity(0.17))

                    Canvas { context, size in
                        for edge in appModel.edges {
                            guard
                                let from = appModel.nodes.first(where: { $0.id == edge.from }),
                                let to = appModel.nodes.first(where: { $0.id == edge.to })
                            else {
                                continue
                            }

                            let start = CGPoint(x: from.position.x * size.width, y: from.position.y * size.height)
                            let end = CGPoint(x: to.position.x * size.width, y: to.position.y * size.height)
                            let controlOffset = abs(end.x - start.x) * 0.35
                            var path = Path()
                            path.move(to: start)
                            path.addCurve(
                                to: end,
                                control1: CGPoint(x: start.x + controlOffset, y: start.y),
                                control2: CGPoint(x: end.x - controlOffset, y: end.y)
                            )

                            context.stroke(path, with: .color(appModel.palette.frame.opacity(0.35)), lineWidth: 1)

                            let dashPhase = time * 90 * edge.traffic
                            context.stroke(
                                path,
                                with: .color(appModel.palette.frame),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [9, 8], dashPhase: dashPhase)
                            )
                        }
                    }

                    ForEach(appModel.nodes) { node in
                        FlowNodeView(node: node, canvasSize: proxy.size)
                            .position(x: node.position.x * proxy.size.width, y: node.position.y * proxy.size.height)
                            .matchedGeometryEffect(id: node.id, in: namespace)
                    }
                }
            }
        }
        .retroPanel(palette: appModel.palette)
    }
}

private struct FlowNodeView: View {
    let node: FlowNode
    let canvasSize: CGSize

    @Environment(AppModel.self) private var appModel
    @State private var hovering = false
    @State private var dragTranslation: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(node.title)
                .font(RetroTypography.body(13))
            Text(node.subtitle.uppercased())
                .font(RetroTypography.body(10))
                .foregroundStyle(appModel.palette.secondaryText)
            ProgressMeter(title: node.kind.rawValue, progress: node.progress, detail: "NODE CHARGE")
        }
        .frame(width: 180)
        .padding(10)
        .background(hovering ? appModel.palette.frame.opacity(0.12) : .black.opacity(0.16))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(appModel.palette.frame.opacity(0.92), lineWidth: 1)
        )
        .shadow(color: appModel.palette.glow.opacity(hovering ? 1 : 0.45), radius: hovering ? 16 : 10)
        .scaleEffect(hovering ? 1.03 : 1)
        .offset(dragTranslation)
        .onHover { hovering in
            self.hovering = hovering
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragTranslation = value.translation
                }
                .onEnded { value in
                    let newCenter = CGPoint(
                        x: node.position.x * canvasSize.width + value.translation.width,
                        y: node.position.y * canvasSize.height + value.translation.height
                    )
                    appModel.updateNodePosition(
                        id: node.id,
                        normalizedPosition: CGPoint(
                            x: newCenter.x / canvasSize.width,
                            y: newCenter.y / canvasSize.height
                        )
                    )
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                        dragTranslation = .zero
                    }
                }
        )
    }
}
