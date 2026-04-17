import SwiftUI

struct RetroButton: View {
    let title: String
    let isActive: Bool
    var action: () -> Void

    @Environment(AppModel.self) private var appModel
    @State private var hovering = false
    @State private var pressing = false

    var body: some View {
        Button(action: action) {
            Text("[\(title)]")
                .font(RetroTypography.body(15))
                .tracking(0.8)
                .foregroundStyle(isActive ? .black : appModel.palette.frame)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 8)
                        .fill(isActive ? appModel.palette.frame : .black.opacity(0.18))
                )
                .overlay(
                    RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 8)
                        .stroke(appModel.palette.frame.opacity(0.85), lineWidth: 1)
                )
                .shadow(color: hoverGlowEnabled ? appModel.palette.glow : .clear, radius: 12)
                .scaleEffect(appModel.hoverAnimationsEnabled ? (pressing ? 0.97 : hovering ? 1.02 : 1.0) : 1.0)
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

    private var hoverGlowEnabled: Bool {
        appModel.hoverAnimationsEnabled && (hovering || pressing)
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
                RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 6)
                    .fill(isOn ? appModel.palette.frame : .black.opacity(0.18))
            )
            .overlay(
                RetroShape(sharpCorners: appModel.sharpCornersEnabled, radius: 6)
                    .stroke(appModel.palette.frame.opacity(0.9), lineWidth: 1)
            )
            .shadow(color: appModel.hoverAnimationsEnabled && hovering ? appModel.palette.glow : .clear, radius: 10)
            .offset(y: appModel.hoverAnimationsEnabled && hovering ? -1 : 0)
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
