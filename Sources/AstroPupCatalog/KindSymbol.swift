import SwiftUI

public extension DSOKind {
    /// Shared chart/glyph color for the kind, matching `KindSymbol`'s strokes — so
    /// a map dot and a row glyph stay consistent. The single source of truth for the
    /// family (Gallery's rows, Sky's chart), so colors can't drift between apps.
    var chartColor: Color {
        switch self {
        case .galaxy, .galaxyGroup:          Color(red: 0.90, green: 0.70, blue: 0.50)
        case .brightNebula:                  Color(red: 1.00, green: 0.50, blue: 0.40)
        case .darkNebula:                    Color(red: 0.62, green: 0.58, blue: 0.70)
        case .planetaryNebula:               Color(red: 0.50, green: 1.00, blue: 0.70)
        case .openCluster, .globularCluster: Color(red: 1.00, green: 0.95, blue: 0.50)
        case .star:                          Color(red: 1.00, green: 0.93, blue: 0.66)
        case .other:                         Color(white: 0.7)
        }
    }
}

/// Kind-specific glyph for a catalog object — the family's shared marker so the
/// shapes/colors match across apps (Gallery rows, Sky chart): galaxy = ellipse,
/// galaxy group = two ellipses, nebula = square, planetary = crosshair circle,
/// open cluster = dashed circle, globular = crosshair circle, star = star, other = dot.
public struct KindSymbol: View {
    public let kind: DSOKind
    public var size: CGFloat

    public init(kind: DSOKind, size: CGFloat = 14) {
        self.kind = kind; self.size = size
    }

    private var galaxyColor:      Color { Color(red: 0.90, green: 0.70, blue: 0.50) }
    private var brightNebulaColor: Color { Color(red: 1.00, green: 0.50, blue: 0.40) }
    private var darkNebulaColor:  Color { Color(red: 0.62, green: 0.58, blue: 0.70) }
    private var planetaryColor:   Color { Color(red: 0.50, green: 1.00, blue: 0.70) }
    private var clusterColor:   Color { Color(red: 1.00, green: 0.95, blue: 0.50) }
    private var starColor:      Color { Color(red: 1.00, green: 0.93, blue: 0.66) }

    public var body: some View {
        Group {
            switch kind {
            case .galaxy:
                Ellipse().stroke(galaxyColor, lineWidth: 1)
                    .frame(width: size, height: size * 0.6)
            case .galaxyGroup:
                ZStack {   // two overlapping ellipses → a group of galaxies
                    Ellipse().stroke(galaxyColor, lineWidth: 1)
                        .frame(width: size * 0.68, height: size * 0.42).offset(x: -size * 0.11, y: -size * 0.08)
                    Ellipse().stroke(galaxyColor, lineWidth: 1)
                        .frame(width: size * 0.68, height: size * 0.42).offset(x: size * 0.11, y: size * 0.08)
                }
            case .brightNebula:
                // Solid square — emission / reflection / SNR, the prime targets.
                Rectangle().stroke(brightNebulaColor, lineWidth: 1)
                    .frame(width: size * 0.85, height: size * 0.85)
            case .darkNebula:
                // Dashed, muted outline — absorption nebulae read as a faint silhouette.
                Rectangle().stroke(darkNebulaColor, style: StrokeStyle(lineWidth: 1, dash: [1.5, 1.5]))
                    .frame(width: size * 0.85, height: size * 0.85)
            case .planetaryNebula:
                Circle().stroke(planetaryColor, lineWidth: 1)
                    .frame(width: size * 0.85, height: size * 0.85)
                    .overlay(crosshair(color: planetaryColor, size: size * 0.85))
            case .openCluster:
                Circle().strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [1, 1]))
                    .foregroundStyle(clusterColor)
                    .frame(width: size * 0.95, height: size * 0.95)
            case .globularCluster:
                Circle().stroke(clusterColor, lineWidth: 1)
                    .frame(width: size * 0.95, height: size * 0.95)
                    .overlay(crosshair(color: clusterColor, size: size * 0.95))
            case .star:
                Image(systemName: "star.fill")
                    .font(.system(size: size * 0.78))
                    .foregroundStyle(starColor)
            case .other:
                Circle().fill(.secondary.opacity(0.55))
                    .frame(width: size * 0.4, height: size * 0.4)
            }
        }
        .frame(width: size, height: size)
        .help(kind.displayName)
    }

    @ViewBuilder
    private func crosshair(color: Color, size s: CGFloat) -> some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: s / 2)); p.addLine(to: CGPoint(x: s, y: s / 2))
            p.move(to: CGPoint(x: s / 2, y: 0)); p.addLine(to: CGPoint(x: s / 2, y: s))
        }
        .stroke(color, lineWidth: 0.7)
    }
}

#if DEBUG
#Preview("Kind glyphs") {
    HStack(spacing: 18) {
        ForEach(DSOKind.allCases, id: \.self) { kind in
            VStack(spacing: 6) {
                KindSymbol(kind: kind, size: 22)
                Text(kind.displayName).font(.caption2)
            }
        }
    }
    .padding(24)
    .background(Color(red: 0.04, green: 0.05, blue: 0.10))
}
#endif
