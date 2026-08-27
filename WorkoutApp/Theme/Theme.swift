import SwiftUI

enum AccentOption: String, CaseIterable, Identifiable {
    case orange, coral, blue, teal, green, purple, indigo, red

    var id: String { rawValue }

    var title: String {
        switch self {
        case .orange: return "Orange"
        case .coral: return "Coral"
        case .blue: return "Blue"
        case .teal: return "Teal"
        case .green: return "Green"
        case .purple: return "Purple"
        case .indigo: return "Indigo"
        case .red: return "Red"
        }
    }

    var color: Color {
        switch self {
        case .orange: return Color(red: 0.98, green: 0.42, blue: 0.18)
        case .coral: return Color(red: 0.95, green: 0.35, blue: 0.38)
        case .blue: return Color(red: 0.20, green: 0.48, blue: 0.96)
        case .teal: return Color(red: 0.12, green: 0.65, blue: 0.62)
        case .green: return Color(red: 0.22, green: 0.70, blue: 0.38)
        case .purple: return Color(red: 0.56, green: 0.35, blue: 0.90)
        case .indigo: return Color(red: 0.35, green: 0.40, blue: 0.85)
        case .red: return Color(red: 0.90, green: 0.22, blue: 0.25)
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg, lb

    var id: String { rawValue }

    var title: String { rawValue.uppercased() }

    func fromKg(_ kg: Double) -> Double {
        self == .kg ? kg : kg * 2.2046226218
    }

    func toKg(_ value: Double) -> Double {
        self == .kg ? value : value / 2.2046226218
    }

    func format(_ kg: Double, decimals: Int = 1) -> String {
        let value = fromKg(kg)
        return String(format: "%.\(decimals)f %@", value, rawValue)
    }
}

enum Theme {
    static let cardCorner: CGFloat = 16

    static var background: Color { Color(.systemBackground) }
    static var cardFill: Color { Color(.secondarySystemBackground) }
    static var groupedBackground: Color { Color(.systemGroupedBackground) }
    static var cardBorder: Color { Color.primary.opacity(0.10) }
    static var mutedFill: Color { Color.primary.opacity(0.10) }
    static var mutedText: Color { Color.secondary }
}

struct OpaqueCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .strokeBorder(Theme.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func opaqueCard() -> some View {
        modifier(OpaqueCard())
    }
}

enum RIRPalette {
    static func color(for rir: Int, accent: Color) -> Color {
        switch rir {
        case ...1: return Color(red: 0.90, green: 0.22, blue: 0.25)
        case 2: return Color(red: 0.95, green: 0.52, blue: 0.12)
        case 3: return accent
        default: return Color.secondary.opacity(0.75)
        }
    }

    static func label(for rir: Int) -> String {
        switch rir {
        case ...1: return "High"
        case 2: return "Hard"
        case 3: return "Productive"
        default: return "Easy"
        }
    }

    static func display(_ rir: Int) -> String {
        rir >= 5 ? "5+" : "\(rir)"
    }
}
