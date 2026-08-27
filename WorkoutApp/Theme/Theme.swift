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

    func format(_ kg: Double, decimals: Int = 2) -> String {
        "\(formatNumber(kg, decimals: decimals)) \(rawValue)"
    }

    func formatNumber(_ kg: Double, decimals: Int = 2) -> String {
        Formatters.trimmedNumber(fromKg(kg), decimals: decimals)
    }
}

enum DistanceUnit: String, CaseIterable, Identifiable {
    case km, mi

    var id: String { rawValue }

    var title: String { self == .km ? "km" : "mi" }

    func fromMeters(_ meters: Double) -> Double {
        self == .km ? meters / 1000.0 : meters / 1609.344
    }

    func paceMinutesPerUnit(duration: TimeInterval, meters: Double) -> Double? {
        let distance = fromMeters(meters)
        guard distance > 0, duration > 0 else { return nil }
        return (duration / 60.0) / distance
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
    static func color(for rir: Int, accent _: Color) -> Color {
        switch rir {
        case ...1: return Color(red: 0.90, green: 0.22, blue: 0.25)
        case 2, 3: return Color(red: 0.95, green: 0.78, blue: 0.12)
        case 4: return Color(red: 0.22, green: 0.70, blue: 0.38)
        default: return Color(red: 0.25, green: 0.55, blue: 0.90)
        }
    }

    static func label(for rir: Int) -> String {
        switch rir {
        case ...1: return "High"
        case 2, 3: return "Hard"
        case 4: return "Productive"
        default: return "Easy"
        }
    }

    static func display(_ rir: Int) -> String {
        rir >= 5 ? "5+" : "\(rir)"
    }
}
