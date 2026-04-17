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

                Text("Drag nodes to re-layout edges live. Double-click a node to edit its action profile, or create a new box and wire it between existing nodes.")
                    .font(RetroTypography.body(12))
                    .foregroundStyle(appModel.palette.secondaryText)

                HStack(spacing: 10) {
                    RetroButton(title: "REFRESH", isActive: true) {
                        appModel.refreshLocalRoots()
                    }
                    RetroButton(title: "NEW BOX", isActive: false) {
                        appModel.presentNewNodeComposer()
                    }
                }

                if appModel.showingNewNodeComposer {
                    NewNodeComposer()
                } else if let editingID = appModel.editingNodeID,
                          let node = appModel.nodes.first(where: { $0.id == editingID }) {
                    NodeInspector(node: node)
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(appModel.edges) { edge in
                        ProgressMeter(
                            title: edge.label,
                            progress: edge.traffic,
                            detail: "\(Int(edge.traffic * 100))% route load"
                        )
                    }
                }

                Spacer()
            }
            .frame(width: 310)
            .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)
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
                    RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 18)
                        .fill(.black.opacity(0.17))

                    Canvas { context, size in
                        for edge in appModel.edges {
                            guard
                                let from = appModel.nodes.first(where: { $0.id == edge.from }),
                                let to = appModel.nodes.first(where: { $0.id == edge.to })
                            else { continue }

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

                            context.stroke(path, with: .color(appModel.palette.frame.opacity(0.28)), lineWidth: 1)
                            context.stroke(
                                path,
                                with: .color(appModel.palette.frame),
                                style: StrokeStyle(lineWidth: 2.4, lineCap: .square, dash: [10, 7], dashPhase: time * 80)
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
        .retroPanel(palette: appModel.palette, sharpCorners: appModel.sharpCornersEnabled)
    }
}

private struct FlowNodeView: View {
    let node: FlowNode
    let canvasSize: CGSize

    @Environment(AppModel.self) private var appModel
    @State private var hovering = false
    @State private var dragStartPosition: CGPoint?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(node.title)
                .font(RetroTypography.body(13))
            Text(node.subtitle.uppercased())
                .font(RetroTypography.body(10))
                .foregroundStyle(appModel.palette.secondaryText)
            ProgressMeter(title: node.kind.rawValue, progress: node.progress, detail: "LIVE FIGURE")
        }
        .frame(width: 190)
        .padding(10)
        .background(hovering ? appModel.palette.frame.opacity(0.12) : .black.opacity(0.16))
        .overlay(
            RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 12)
                .stroke(appModel.palette.frame.opacity(0.92), lineWidth: 1)
        )
        .shadow(color: appModel.palette.glow.opacity(hovering ? 1 : 0.45), radius: hovering ? 16 : 10)
        .scaleEffect(appModel.hoverAnimationsEnabled && hovering ? 1.03 : 1)
        .onHover { hovering in
            self.hovering = hovering
        }
        .onTapGesture(count: 2) {
            appModel.openNodeInspector(node.id)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let origin = dragStartPosition ?? node.position
                    dragStartPosition = origin
                    let newCenter = CGPoint(
                        x: origin.x * canvasSize.width + value.translation.width,
                        y: origin.y * canvasSize.height + value.translation.height
                    )
                    appModel.updateNodePosition(
                        id: node.id,
                        normalizedPosition: CGPoint(x: newCenter.x / canvasSize.width, y: newCenter.y / canvasSize.height)
                    )
                }
                .onEnded { _ in
                    dragStartPosition = nil
                }
        )
    }
}

private struct NodeInspector: View {
    let node: FlowNode
    @Environment(AppModel.self) private var appModel
    @State private var title = ""
    @State private var subtitle = ""
    @State private var kind: FlowNode.NodeKind = .transform

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NODE DIALOG")
                .font(RetroTypography.body(12))

            TextField("Title", text: $title)
                .textFieldStyle(.plain)
                .font(RetroTypography.body(12))
                .padding(8)
                .background(.black.opacity(0.16))
                .overlay(RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 8).stroke(appModel.palette.frame.opacity(0.7), lineWidth: 1))

            TextField("Subtitle", text: $subtitle)
                .textFieldStyle(.plain)
                .font(RetroTypography.body(12))
                .padding(8)
                .background(.black.opacity(0.16))
                .overlay(RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 8).stroke(appModel.palette.frame.opacity(0.7), lineWidth: 1))

            Picker("Kind", selection: $kind) {
                ForEach(FlowNode.NodeKind.allCases, id: \.self) { kind in
                    Text(kind.rawValue.uppercased()).tag(kind)
                }
            }
            .pickerStyle(.menu)

            HStack(spacing: 8) {
                RetroButton(title: "SAVE", isActive: true) {
                    appModel.updateNode(id: node.id, title: title, subtitle: subtitle, kind: kind)
                }
                RetroButton(title: "SOURCE SET", isActive: false) {
                    if let preset = appModel.presetActions(for: node).first {
                        appModel.applyPreset(preset, to: node.id)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("PRESETS")
                    .font(RetroTypography.body(11))
                    .foregroundStyle(appModel.palette.secondaryText)
                ForEach(appModel.presetActions(for: node)) { preset in
                    Button {
                        appModel.applyPreset(preset, to: node.id)
                        title = preset.title
                        subtitle = preset.subtitle
                        kind = preset.kind
                    } label: {
                        Text("[\(preset.title)]")
                            .font(RetroTypography.body(11))
                            .foregroundStyle(appModel.palette.frame)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            title = node.title
            subtitle = node.subtitle
            kind = node.kind
        }
    }
}

private struct NewNodeComposer: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NEW ROUTE BOX")
                .font(RetroTypography.body(12))

            TextField("Title", text: Binding(
                get: { appModel.newNodeDraft.title },
                set: { appModel.newNodeDraft.title = $0 }
            ))
            .textFieldStyle(.plain)
            .font(RetroTypography.body(12))
            .padding(8)
            .background(.black.opacity(0.16))
            .overlay(RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 8).stroke(appModel.palette.frame.opacity(0.7), lineWidth: 1))

            TextField("Subtitle", text: Binding(
                get: { appModel.newNodeDraft.subtitle },
                set: { appModel.newNodeDraft.subtitle = $0 }
            ))
            .textFieldStyle(.plain)
            .font(RetroTypography.body(12))
            .padding(8)
            .background(.black.opacity(0.16))
            .overlay(RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 8).stroke(appModel.palette.frame.opacity(0.7), lineWidth: 1))

            Picker("Role", selection: Binding(
                get: { appModel.newNodeDraft.kind },
                set: { appModel.newNodeDraft.kind = $0 }
            )) {
                ForEach(FlowNode.NodeKind.allCases, id: \.self) { kind in
                    Text(kind.rawValue.uppercased()).tag(kind)
                }
            }
            .pickerStyle(.menu)

            Picker("Source", selection: Binding(
                get: { appModel.newNodeDraft.sourceNodeID },
                set: { appModel.newNodeDraft.sourceNodeID = $0 }
            )) {
                Text("NONE").tag(UUID?.none)
                ForEach(appModel.nodes) { node in
                    Text(node.title).tag(Optional(node.id))
                }
            }
            .pickerStyle(.menu)

            Picker("Target", selection: Binding(
                get: { appModel.newNodeDraft.targetNodeID },
                set: { appModel.newNodeDraft.targetNodeID = $0 }
            )) {
                Text("NONE").tag(UUID?.none)
                ForEach(appModel.nodes) { node in
                    Text(node.title).tag(Optional(node.id))
                }
            }
            .pickerStyle(.menu)

            HStack(spacing: 8) {
                RetroButton(title: "CREATE", isActive: true) {
                    appModel.addNodeFromDraft()
                }
                RetroButton(title: "CANCEL", isActive: false) {
                    appModel.showingNewNodeComposer = false
                }
            }
        }
    }
}
