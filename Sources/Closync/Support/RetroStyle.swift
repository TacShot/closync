import SwiftUI

struct RetroTypography {
    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .monospaced)
    }

    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

struct RetroShape: InsettableShape {
    var sharpCorners: Bool
    var radius: CGFloat = 14
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let adjusted = rect.insetBy(dx: insetAmount, dy: insetAmount)
        return RoundedRectangle(cornerRadius: sharpCorners ? 0 : radius, style: .continuous).path(in: adjusted)
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

struct RetroPanelModifier: ViewModifier {
    let palette: RetroPalette
    let sharpCorners: Bool
    var innerGlow: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                ZStack {
                    RetroShape(sharpCorners: sharpCorners, radius: 14)
                        .fill(.black.opacity(0.28))

                    if innerGlow {
                        RetroShape(sharpCorners: sharpCorners, radius: 14)
                            .stroke(palette.glow, lineWidth: 1.4)
                            .blur(radius: 10)
                    }

                    RetroShape(sharpCorners: sharpCorners, radius: 14)
                        .stroke(palette.frame.opacity(0.88), lineWidth: 1.1)
                }
            )
            .shadow(color: palette.glow, radius: 14, y: 0)
    }
}

extension View {
    func retroPanel(palette: RetroPalette, sharpCorners: Bool, innerGlow: Bool = true) -> some View {
        modifier(RetroPanelModifier(palette: palette, sharpCorners: sharpCorners, innerGlow: innerGlow))
    }
}

struct ScanlineOverlay: View {
    let palette: RetroPalette

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let time = context.date.timeIntervalSinceReferenceDate

            GeometryReader { proxy in
                let rows = max(Int(proxy.size.height / 3), 1)
                Canvas { context, size in
                    for row in 0 ..< rows {
                        let y = CGFloat(row) * 3
                        let alpha = row.isMultiple(of: 2) ? 0.26 : 0.14
                        let rect = CGRect(x: 0, y: y, width: size.width, height: 1.2)
                        context.fill(Path(rect), with: .color(.black.opacity(alpha)))
                    }

                    let sweepY = (CGFloat(time.truncatingRemainder(dividingBy: 3)) / 3) * size.height
                    let glowRect = CGRect(x: 0, y: sweepY, width: size.width, height: 36)
                    context.fill(Path(glowRect), with: .linearGradient(
                        Gradient(colors: [.clear, palette.glow.opacity(0.28), .clear]),
                        startPoint: CGPoint(x: 0, y: glowRect.minY),
                        endPoint: CGPoint(x: 0, y: glowRect.maxY)
                    ))
                }
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.28), .clear, .black.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
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
                let step: CGFloat = 34
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
                colors: [palette.glow.opacity(0.22), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 1100
            )

            Rectangle()
                .fill(
                    LinearGradient(colors: [.black.opacity(0.28), .clear, .black.opacity(0.22)], startPoint: .top, endPoint: .bottom)
                )
                .blur(radius: 70)
                .blendMode(.multiply)

            if scanlinesEnabled {
                ScanlineOverlay(palette: palette)
            }
        }
        .ignoresSafeArea()
    }
}
