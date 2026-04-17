import SwiftUI

struct RetroButton: View {
    let title: String
    let isActive: Bool
    var action: () -> Void

    @Environment(AppModel.self) private var appModel
    @State private var hovering = false
    @State private var pressing = false

    var body: some View {
        Button(action: {
            action()
        }) {
            Text("[\(title)]")
                .font(RetroTypography.body(15))
                .tracking(0.8)
                .foregroundStyle(isActive ? .black : appModel.palette.frame)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isActive ? appModel.palette.frame : .black.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(appModel.palette.frame.opacity(0.85), lineWidth: 1)
                )
                .shadow(color: hovering || pressing ? appModel.palette.glow : .clear, radius: 12)
                .scaleEffect(pressing ? 0.97 : hovering ? 1.02 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: pressing)
                .animation(.easeOut(duration: 0.15), value: hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            self.hovering = hovering
        }
        .pressEvents(onPress: {
            pressing = true
        }, onRelease: {
            pressing = false
        })
    }
}

struct ToggleBlockButton: View {
    let title: String
    @Binding var isOn: Bool

    @Environment(AppModel.self) private var appModel
    @State private var hovering = false

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 10) {
                Text(isOn ? "■" : "□")
                Text(title.uppercased())
            }
            .font(RetroTypography.body(14))
            .foregroundStyle(isOn ? .black : appModel.palette.frame)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isOn ? appModel.palette.frame : .black.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(appModel.palette.frame.opacity(0.9), lineWidth: 1)
            )
            .shadow(color: hovering ? appModel.palette.glow : .clear, radius: 10)
            .offset(y: hovering ? -1 : 0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            self.hovering = hovering
        }
    }
}

private struct PressEvents: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

private extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEvents(onPress: onPress, onRelease: onRelease))
    }
}
