import SwiftUI

struct RetroTypography {
    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .monospaced)
    }

    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

struct RetroPanelModifier: ViewModifier {
    let palette: RetroPalette
    var innerGlow: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.black.opacity(0.28))

                    if innerGlow {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(palette.glow, lineWidth: 1.3)
                            .blur(radius: 8)
                    }

                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(palette.frame.opacity(0.88), lineWidth: 1.1)
                }
            )
            .shadow(color: palette.glow, radius: 14, y: 0)
    }
}

extension View {
    func retroPanel(palette: RetroPalette, innerGlow: Bool = true) -> some View {
        modifier(RetroPanelModifier(palette: palette, innerGlow: innerGlow))
    }
}

struct ScanlineOverlay: View {
    let palette: RetroPalette

    var body: some View {
        GeometryReader { proxy in
            let rows = max(Int(proxy.size.height / 4), 1)
            Canvas { context, size in
                for row in 0 ..< rows {
                    let y = CGFloat(row) * 4
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(.black.opacity(0.30)))
                }
            }
            .overlay {
                LinearGradient(
                    colors: [
                        palette.glow.opacity(0.10),
                        .clear,
                        .black.opacity(0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .allowsHitTesting(false)
        .blendMode(.screen)
    }
}

struct RetroGridBackground: View {
    let palette: RetroPalette
    let scanlinesEnabled: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [palette.backgroundTop, palette.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Canvas { context, size in
                let step: CGFloat = 36
                var path = Path()

                stride(from: CGFloat.zero, through: size.width, by: step).forEach { x in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }

                stride(from: CGFloat.zero, through: size.height, by: step).forEach { y in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }

                context.stroke(path, with: .color(palette.frame.opacity(0.07)), lineWidth: 0.8)
            }

            RadialGradient(
                colors: [palette.glow.opacity(0.18), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 900
            )

            if scanlinesEnabled {
                ScanlineOverlay(palette: palette)
            }
        }
        .ignoresSafeArea()
    }
}
